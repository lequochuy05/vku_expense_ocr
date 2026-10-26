// Các hằng số toàn cục của ứng dụng VKU Expense AI
// Không đặt API key ở đây — chỉ đặt các giá trị cấu hình không nhạy cảm
library;

class AppConstants {
  AppConstants._();

  // Thông tin ứng dụng
  static const String appName = 'VKU Expense AI';
  static const String appVersion = '1.0.0';
  static const String packageName = 'vkuexpenseocr';

  // Database
  static const String databaseName = 'vku_expense.db';
  static const int databaseVersion = 1;

  // Bảng database
  static const String tableExpenses = 'expenses';
  static const String tableSettings = 'settings';

  // Múi giờ mặc định
  static const String defaultTimezone = 'Asia/Ho_Chi_Minh';

  // Tiền tệ
  static const String currencyCode = 'VND';
  static const String currencySymbol = '₫';

  // Giới hạn phân trang
  static const int defaultPageSize = 20;
  static const int maxRecentTransactions = 5;

  // Giới hạn Gemini
  static const int geminiTimeoutSeconds = 30;
  static const int geminiMaxRetries = 2;

  // Nguồn nhập liệu
  static const String sourceManual = 'manual';
  static const String sourceOcr = 'ocr';
  static const String sourceTransfer = 'transfer';

  // SharedPreferences keys
  static const String prefThemeMode = 'theme_mode';
  static const String prefMonthlyBudget = 'monthly_budget';
  static const String prefGeminiApiKey = 'gemini_api_key';
  static const String prefStatsPeriod = 'stats_period';
}
