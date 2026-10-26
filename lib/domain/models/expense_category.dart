// Enum danh mục chi tiêu với metadata: tên tiếng Việt, icon, màu
library;

import 'package:flutter/material.dart';

enum ExpenseCategory {
  food('Ăn uống', Icons.restaurant, Color(0xFFFF6B6B)),
  transport('Di chuyển', Icons.directions_car, Color(0xFF4ECDC4)),
  shopping('Mua sắm', Icons.shopping_bag, Color(0xFF45B7D1)),
  utilities('Hóa đơn', Icons.receipt_long, Color(0xFFF7DC6F)),
  housing('Nhà ở', Icons.home, Color(0xFF82E0AA)),
  health('Sức khỏe', Icons.local_hospital, Color(0xFFBB8FCE)),
  education('Giáo dục', Icons.school, Color(0xFF85C1E9)),
  entertainment('Giải trí', Icons.movie, Color(0xFFFF9F43)),
  other('Khác', Icons.more_horiz, Color(0xFFAEB6BF));

  const ExpenseCategory(this.displayName, this.icon, this.color);

  final String displayName;
  final IconData icon;
  final Color color;

  /// Parse từ chuỗi lưu trong database
  static ExpenseCategory fromString(String value) {
    return ExpenseCategory.values.firstWhere(
      (cat) => cat.name == value,
      orElse: () => ExpenseCategory.other,
    );
  }

  /// Gợi ý danh mục từ văn bản OCR hoặc tên merchant
  /// Trả về null nếu không có gợi ý rõ ràng
  static ExpenseCategory? suggestFromText(String text) {
    final lower = text.toLowerCase();

    // Ăn uống: nhà hàng, cà phê, đồ ăn
    if (_matchesAny(lower, [
      'phở', 'cơm', 'bún', 'bánh', 'cafe', 'coffee', 'trà', 'tea',
      'restaurant', 'ăn', 'food', 'nhà hàng', 'quán', 'beer', 'bia',
      'pizza', 'burger', 'kfc', 'mcdonalds', 'lotteria', 'highlands',
      'the coffee house', 'trung nguyên', 'phúc long',
    ])) {
      return ExpenseCategory.food;
    }

    // Di chuyển: grab, taxi, xăng
    if (_matchesAny(lower, [
      'grab', 'taxi', 'uber', 'be app', 'parking', 'xăng', 'petrol',
      'gasoline', 'bus', 'xe bus', 'metro', 'tàu', 'vé', 'ticket',
      'gojek', 'giao hàng',
    ])) {
      return ExpenseCategory.transport;
    }

    // Mua sắm: siêu thị, shop, mart
    if (_matchesAny(lower, [
      'shop', 'store', 'mart', 'supermarket', 'siêu thị', 'bigc', 'co.opmart',
      'vinmart', 'winmart', 'lotte', 'aeon', 'ikea', 'fashion', 'thời trang',
      'lazada', 'shopee', 'tiki', 'điện máy', 'thế giới di động',
    ])) {
      return ExpenseCategory.shopping;
    }

    // Hóa đơn: điện, nước, internet
    if (_matchesAny(lower, [
      'điện', 'electric', 'nước', 'water', 'internet', 'wifi', 'evn',
      'mobifone', 'viettel', 'vinaphone', 'bill', 'hóa đơn', 'invoice',
    ])) {
      return ExpenseCategory.utilities;
    }

    // Nhà ở: thuê nhà, chung cư
    if (_matchesAny(lower, [
      'thuê nhà', 'rent', 'chung cư', 'apartment', 'nhà trọ', 'phòng trọ',
    ])) {
      return ExpenseCategory.housing;
    }

    // Sức khỏe: bệnh viện, thuốc, phòng khám
    if (_matchesAny(lower, [
      'bệnh viện', 'hospital', 'clinic', 'phòng khám', 'thuốc', 'medicine',
      'pharmacy', 'nhà thuốc', 'gym', 'spa', 'fitness',
    ])) {
      return ExpenseCategory.health;
    }

    // Giáo dục: học phí, sách vở
    if (_matchesAny(lower, [
      'học phí', 'tuition', 'school', 'trường', 'sách', 'book', 'vku',
      'đại học', 'university', 'khóa học', 'course', 'library',
    ])) {
      return ExpenseCategory.education;
    }

    // Giải trí: rạp phim, game, du lịch
    if (_matchesAny(lower, [
      'cinema', 'phim', 'cgv', 'bhd', 'galaxy', 'game', 'steam',
      'netflix', 'spotify', 'travel', 'du lịch', 'hotel', 'khách sạn',
    ])) {
      return ExpenseCategory.entertainment;
    }

    return null; // Không có gợi ý rõ ràng
  }

  static bool _matchesAny(String text, List<String> keywords) =>
      keywords.any((kw) => text.contains(kw));
}
