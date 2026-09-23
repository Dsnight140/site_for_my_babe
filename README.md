## Cloudinary для фотографий

Фото загружаются в Cloudinary через unsigned upload preset, а ссылки сохраняются в Firebase Firestore.

1. Создай аккаунт на Cloudinary и открой **Settings -> Upload -> Upload presets**.
2. Создай preset с режимом **Unsigned**.
3. Запускай приложение с параметрами:

```bash
flutter run \
	--dart-define=CLOUDINARY_CLOUD_NAME=твоё_имя_cloud \
	--dart-define=CLOUDINARY_UPLOAD_PRESET=твой_unsigned_preset
```

API secret в приложение добавлять нельзя.
# Ours 💕

Приватное приложение для двоих — совместный трекер отношений.

## Возможности

- **Главная** — счётчик дней вместе, цикл, быстрый настрой настроения, дневник писем, дни рождения
- **Вишлист** — общие желания с категориями и фильтрами
- **Воспоминания** — записи по датам с фото и заметками
- **Настроение** — отслеживание настроения каждого партнёра
- **Фото** — моментальные фото с камеры, подписи, Cloudinary, корзина и восстановление

## Технологии

- Flutter
- Firebase (Firestore, Auth, Cloud Functions, FCM)
- Cloudinary (хранение изображений)
- SharedPreferences (оффлайн-кэш)

## Запуск

```bash
flutter pub get
flutter run
```

Для загрузки изображений укажи Cloudinary-параметры через VS Code-профиль
**Ours с Cloudinary** или запусти:

```bash
flutter run \
	--dart-define=CLOUDINARY_CLOUD_NAME=твоё_имя_cloud \
	--dart-define=CLOUDINARY_UPLOAD_PRESET=твой_unsigned_preset
```
