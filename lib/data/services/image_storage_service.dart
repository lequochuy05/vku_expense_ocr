// Service quản lý lưu trữ ảnh hóa đơn cục bộ
// Lưu đường dẫn tệp vào SQLite thay vì lưu base64/blob
library;

import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/errors/app_exception.dart';

class ImageStorageService {
  ImageStorageService({this.uuid = const Uuid()});

  final Uuid uuid;

  /// Thư mục lưu trữ hóa đơn trong ứng dụng
  Future<Directory> get _receiptsDirectory async {
    final appDir = await getApplicationDocumentsDirectory();
    final receiptsDir = Directory(p.join(appDir.path, 'receipts'));
    if (!await receiptsDir.exists()) {
      await receiptsDir.create(recursive: true);
    }
    return receiptsDir;
  }

  /// Sao chép ảnh từ nguồn tạm sang bộ nhớ lâu dài của ứng dụng
  /// Trả về đường dẫn tệp đã lưu
  Future<String> saveReceiptImage(File sourceFile) async {
    try {
      if (!await sourceFile.exists()) {
        throw const ImageStorageException('Tệp ảnh nguồn không tồn tại');
      }

      final dir = await _receiptsDirectory;
      final extension = p.extension(sourceFile.path);
      final fileName = '${uuid.v4()}$extension';
      final targetPath = p.join(dir.path, fileName);

      final savedFile = await sourceFile.copy(targetPath);
      return savedFile.path;
    } catch (e) {
      if (e is AppException) rethrow;
      throw ImageStorageException('Không thể lưu ảnh hóa đơn: $e', cause: e);
    }
  }

  /// Xóa tệp ảnh khi xóa giao dịch
  Future<bool> deleteReceiptImage(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      // Không crash app nếu xóa tệp ảnh phụ thất bại
      return false;
    }
  }

  /// Kiểm tra ảnh có tồn tại không
  Future<bool> imageExists(String filePath) async {
    return File(filePath).exists();
  }
}

final imageStorageServiceProvider = Provider<ImageStorageService>((ref) {
  return ImageStorageService();
});
