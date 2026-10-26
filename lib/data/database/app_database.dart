// AppDatabase — quản lý SQLite cho VKU Expense AI
// Sử dụng migration version để nâng cấp schema an toàn
// Tất cả query dùng parameterized để tránh SQL injection
library;

import 'package:sqflite/sqflite.dart' hide DatabaseException;
import 'package:path/path.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';

class AppDatabase {
  AppDatabase._();

  static AppDatabase? _instance;
  static Database? _database;

  static AppDatabase get instance {
    _instance ??= AppDatabase._();
    return _instance!;
  }

  /// Lấy instance database, khởi tạo nếu chưa có
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.databaseName);

    try {
      return await openDatabase(
        path,
        version: AppConstants.databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onConfigure: _onConfigure,
      );
    } catch (e) {
      throw DatabaseException('Không thể mở database', cause: e);
    }
  }

  /// Bật WAL mode để cải thiện hiệu suất đọc/ghi đồng thời
  /// Trên Android SQLite, PRAGMA journal_mode trả về kết quả nên phải dùng rawQuery
  Future<void> _onConfigure(Database db) async {
    try {
      await db.rawQuery('PRAGMA journal_mode=WAL');
    } catch (_) {}
    try {
      await db.execute('PRAGMA foreign_keys=ON');
    } catch (_) {}
  }

  /// Tạo schema ban đầu (version 1)
  Future<void> _onCreate(Database db, int version) async {
    await _createVersion1(db);
  }

  /// Migration: upgrade từ version cũ sang version mới
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Khi cần thêm cột hoặc bảng mới, thêm case ở đây
    // Ví dụ: if (oldVersion < 2) await _migrateV1ToV2(db);
  }

  /// Schema version 1
  Future<void> _createVersion1(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.tableExpenses} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount INTEGER NOT NULL,
        category TEXT NOT NULL,
        transaction_date TEXT NOT NULL,
        note TEXT,
        merchant TEXT,
        source_type TEXT NOT NULL DEFAULT 'manual',
        raw_ocr_text TEXT,
        image_path TEXT,
        payment_method TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Index cho query theo ngày (dùng nhiều nhất)
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_expenses_date
      ON ${AppConstants.tableExpenses}(transaction_date)
    ''');

    // Index cho query theo danh mục
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_expenses_category
      ON ${AppConstants.tableExpenses}(category)
    ''');

    // Bảng settings: key-value store đơn giản
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.tableSettings} (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  /// Đóng database khi không còn cần (hiếm khi gọi trong app)
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  /// Xóa toàn bộ dữ liệu (dùng trong settings → Clear All)
  Future<void> clearAll() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(AppConstants.tableExpenses);
      // Giữ lại settings, chỉ xóa dữ liệu chi tiêu
    });
  }
}
