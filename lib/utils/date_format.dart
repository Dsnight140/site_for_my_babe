import 'package:intl/intl.dart';

const List<String> kMonthNames = [
  'января',
  'февраля',
  'марта',
  'апреля',
  'мая',
  'июня',
  'июля',
  'августа',
  'сентября',
  'октября',
  'ноября',
  'декабря',
];

String formatDateRussian(DateTime date) {
  return '${date.day} ${kMonthNames[date.month - 1]} ${date.year}';
}

String formatDateShortRussian(DateTime date) {
  return DateFormat('d MMM', 'ru').format(date);
}
