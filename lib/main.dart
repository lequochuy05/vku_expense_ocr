// Entrypoint của ứng dụng VKU Expense AI
// Khởi tạo Riverpod ProviderScope bao bọc toàn bộ app
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo locale tiếng Việt cho intl (ngày tháng, số)
  try {
    await initializeDateFormatting('vi', null);
  } catch (e) {
    debugPrint('[Config] initializeDateFormatting error: $e');
  }

  // Load .env nếu có (chỉ cho development)
  // CẢNH BÁO: .env trong APK không bảo vệ bí mật thật sự
  // Dùng dart-define hoặc backend proxy cho production
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // File .env không tồn tại — chạy không có Gemini
    debugPrint('[Config] Không tìm thấy .env — Gemini API sẽ không khả dụng');
  }

  runApp(
    const ProviderScope(
      child: VkuExpenseApp(),
    ),
  );
}
