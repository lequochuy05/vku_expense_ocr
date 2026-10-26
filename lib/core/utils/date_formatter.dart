// Định dạng ngày tháng theo chuẩn Việt Nam
library;

import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static final _fullFormat = DateFormat('dd/MM/yyyy');
  static final _shortFormat = DateFormat('dd/MM');
  static final _monthYearFormat = DateFormat('MM/yyyy');
  static final _timeFormat = DateFormat('HH:mm');
  static final _fullWithTime = DateFormat('dd/MM/yyyy HH:mm');
  static final _isoFormat = DateFormat('yyyy-MM-dd');
  static final _isoWithTime = DateFormat('yyyy-MM-ddTHH:mm:ss');

  /// 2026-10-12 → "12/10/2026"
  static String formatDate(DateTime date) => _fullFormat.format(date);

  /// 2026-10-12 → "12/10"
  static String formatShort(DateTime date) => _shortFormat.format(date);

  /// 2026-10-12 → "10/2026"
  static String formatMonthYear(DateTime date) => _monthYearFormat.format(date);

  /// 2026-10-12 → "Thứ Hai, 12/10/2026"
  static String formatFull(DateTime date) =>
      '${weekdayFull(date)}, ${_fullFormat.format(date)}';

  /// DateTime → "14:30"
  static String formatTime(DateTime date) => _timeFormat.format(date);

  /// DateTime → "12/10/2026 14:30"
  static String formatDateTime(DateTime date) => _fullWithTime.format(date);

  /// DateTime → "2026-10-12" (lưu vào SQLite)
  static String toIso(DateTime date) => _isoFormat.format(date);

  /// DateTime → "2026-10-12T14:30:00" (created_at, updated_at)
  static String toIsoWithTime(DateTime date) => _isoWithTime.format(date);

  /// Parse chuỗi ISO từ SQLite → DateTime
  static DateTime? fromIso(String? text) {
    if (text == null || text.isEmpty) return null;
    return DateTime.tryParse(text);
  }

  /// Tên thứ trong tuần bằng tiếng Việt (viết tắt)
  static String weekdayShort(DateTime date) {
    const names = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    // weekday: 1=Monday ... 7=Sunday
    return names[date.weekday - 1];
  }

  /// Tên thứ đầy đủ tiếng Việt
  static String weekdayFull(DateTime date) {
    const names = [
      'Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm',
      'Thứ Sáu', 'Thứ Bảy', 'Chủ Nhật',
    ];
    return names[date.weekday - 1];
  }

  /// Lấy ngày đầu tiên của tháng
  static DateTime firstDayOfMonth(DateTime date) =>
      DateTime(date.year, date.month, 1);

  /// Lấy ngày cuối cùng của tháng
  static DateTime lastDayOfMonth(DateTime date) =>
      DateTime(date.year, date.month + 1, 0);

  /// Lấy 7 ngày gần nhất (bao gồm hôm nay)
  static List<DateTime> last7Days() {
    final today = DateTime.now();
    return List.generate(
      7,
      (i) => DateTime(today.year, today.month, today.day - 6 + i),
    );
  }

  /// Kiểm tra 2 ngày có cùng ngày không (bỏ qua giờ)
  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
