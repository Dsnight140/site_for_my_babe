const {onDocumentCreated, onDocumentUpdated} = require("firebase-functions/v2/firestore");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");

initializeApp();
const db = getFirestore();

async function partnerToken(coupleId, senderId) {
  const couple = (await db.doc(`couples/${coupleId}`).get()).data() || {};
  const partnerId = couple.partner1_uid === senderId
    ? couple.partner2_uid
    : couple.partner1_uid;
  if (!partnerId) return null;
  const user = (await db.doc(`users/${partnerId}`).get()).data() || {};
  return user.fcmToken || null;
}

async function sendToPartner(coupleId, senderId, title, body, data) {
  const token = await partnerToken(coupleId, senderId);
  if (!token) return;
  await getMessaging().send({
    token,
    notification: {title, body},
    data: data || {},
    android: {notification: {channelId: "general_channel"}},
    apns: {payload: {aps: {sound: "default"}}},
  });
}

exports.notifyNewWish = onDocumentCreated(
  "couples/{coupleId}/wishes/{wishId}",
  async (event) => {
    const wish = event.data.data();
    if (!wish.creatorId) return;
    await sendToPartner(
      event.params.coupleId,
      wish.creatorId,
      "Новое желание 🎁",
      `${wish.title || "Партнёр добавил желание"}`,
      {type: "wish", wishId: event.params.wishId},
    );
  },
);

exports.notifyNewPigeon = onDocumentCreated(
  "couples/{coupleId}/pigeons/{pigeonId}",
  async (event) => {
    const pigeon = event.data.data();
    if (!pigeon.senderId) return;
    await sendToPartner(
      event.params.coupleId,
      pigeon.senderId,
      "Тебе прилетел голубь 🕊️",
      `${pigeon.senderName || "Половинка"} написал(а) письмо`,
      {type: "pigeon", pigeonId: event.params.pigeonId},
    );
  },
);

exports.notifyMoodChange = onDocumentUpdated(
  "couples/{coupleId}",
  async (event) => {
    const before = event.data.before.data() || {};
    const after = event.data.after.data() || {};
    const beforeMoods = before.moods || {};
    const afterMoods = after.moods || {};
    const changed = Object.entries(afterMoods).find(([uid, mood]) => {
      return beforeMoods[uid]?.mood !== mood?.mood;
    });
    if (!changed) return;
    const [senderId, mood] = changed;
    await sendToPartner(
      event.params.coupleId,
      senderId,
      "Партнёр изменил(а) настроение 💭",
      mood.mood || "Новое настроение",
      {type: "mood", uid: senderId},
    );
  },
);