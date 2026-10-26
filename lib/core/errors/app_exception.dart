// Định nghĩa các exception tùy chỉnh cho VKU Expense AI
// Sử dụng sealed class để buộc phải xử lý tất cả các trường hợp lỗi
library;

/// Base exception class cho toàn bộ ứng dụng
sealed class AppException implements Exception {
  const AppException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message${cause != null ? ' (cause: $cause)' : ''}';
}

/// Lỗi database — không thể đọc/ghi SQLite
final class DatabaseException extends AppException {
  const DatabaseException(super.message, {super.cause});
}

/// Lỗi OCR — không nhận diện được văn bản
final class OcrException extends AppException {
  const OcrException(super.message, {super.cause});
}

/// Lỗi phân tích hóa đơn — Regex không khớp
final class ParseException extends AppException {
  const ParseException(super.message, {super.cause});
}

/// Lỗi mạng — không kết nối được internet
final class NetworkException extends AppException {
  const NetworkException(super.message, {super.cause});
}

/// Lỗi Gemini API — HTTP error, timeout, parse lỗi
final class GeminiException extends AppException {
  const GeminiException(super.message, {this.statusCode, super.cause});

  final int? statusCode;

  @override
  String toString() =>
      'GeminiException[$statusCode]: $message${cause != null ? ' (cause: $cause)' : ''}';
}

/// Lỗi xác thực — dữ liệu không hợp lệ
final class ValidationException extends AppException {
  const ValidationException(super.message, {super.cause});
}

/// Lỗi quyền truy cập — camera, storage bị từ chối
final class PermissionException extends AppException {
  const PermissionException(super.message, {super.cause});
}

/// Lỗi lưu ảnh
final class ImageStorageException extends AppException {
  const ImageStorageException(super.message, {super.cause});
}
