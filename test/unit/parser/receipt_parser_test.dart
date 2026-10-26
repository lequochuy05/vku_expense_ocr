import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_ocr/features/receipt_scanner/domain/receipt_parser.dart';
import 'package:vku_expense_ocr/domain/models/receipt_ocr_result.dart';
import 'package:vku_expense_ocr/domain/models/expense_category.dart';
import 'package:vku_expense_ocr/core/utils/currency_formatter.dart';

void main() {
  group('CurrencyFormatter Unit Tests', () {
    test('format VND numbers correctly', () {
      expect(CurrencyFormatter.format(125000), contains('125.000'));
      expect(CurrencyFormatter.format(1250000), contains('1.250.000'));
      expect(CurrencyFormatter.format(0), contains('0'));
    });

    test('parse various Vietnamese currency representations', () {
      expect(CurrencyFormatter.parse('125.000'), equals(125000));
      expect(CurrencyFormatter.parse('125,000'), equals(125000));
      expect(CurrencyFormatter.parse('1.250.000 đ'), equals(1250000));
      expect(CurrencyFormatter.parse('1,250,000 VND'), equals(1250000));
      expect(CurrencyFormatter.parse('125000'), equals(125000));
      expect(CurrencyFormatter.parse('85.000 đồng'), equals(85000));
      expect(CurrencyFormatter.parse(''), isNull);
    });

    test('formatCompact handles K, M, B abbreviations', () {
      expect(CurrencyFormatter.formatCompact(50000), contains('50K'));
      expect(CurrencyFormatter.formatCompact(2500000), contains('2.5M'));
      expect(CurrencyFormatter.formatCompact(1500000000), contains('1.5B'));
    });
  });

  group('ReceiptParser - Amount Extraction Tests', () {
    test('extracts amount with high priority label TỔNG CỘNG', () {
      const ocr = '''
      HIGHLANDS COFFEE
      234 Tran Phu, Da Nang
      Ngày: 12/10/2026
      1x Ca phe sua da   35.000
      1x Tra sen vang    55.000
      TỔNG CỘNG: 90.000 VND
      Tiền khách đưa: 100.000
      Tiền thừa: 10.000
      ''';
      final result = ReceiptParser.parse(ocr);
      expect(result.amount, equals(90000));
      expect(result.merchant, contains('Highlands Coffee'));
      expect(result.categorySuggestion, equals(ExpenseCategory.food));
      expect(result.confidence, equals(OcrConfidence.high));
    });

    test('extracts amount with GRAND TOTAL label', () {
      const ocr = '''
      LOTTERIA VIETNAM
      Subtotal: 120.000
      Discount: 20.000
      GRAND TOTAL: 100.000
      ''';
      final result = ReceiptParser.parse(ocr);
      expect(result.amount, equals(100000));
      expect(result.categorySuggestion, equals(ExpenseCategory.food));
    });

    test('ignores tiền thừa and discount when finding total', () {
      const ocr = '''
      MINISTOP VIET NAM
      Thành tiền: 150.000 đ
      Giảm giá: 10.000 đ
      Tổng thanh toán: 140.000 đ
      Tiền mặt: 200.000 đ
      Tiền thừa: 60.000 đ
      ''';
      final result = ReceiptParser.parse(ocr);
      expect(result.amount, equals(140000));
    });

    test('extracts amount when label and number are on separate lines', () {
      const ocr = '''
      THE COFFEE HOUSE
      TỔNG TIỀN
      85.000
      Cảm ơn quý khách
      ''';
      final result = ReceiptParser.parse(ocr);
      expect(result.amount, equals(85000));
    });

    test('handles fallback when no total label is present', () {
      const ocr = '''
      QUAN AN BINH DAN
      Com ga
      35.000
      ''';
      final result = ReceiptParser.parse(ocr);
      expect(result.amount, equals(35000));
      expect(result.warnings, isNotEmpty);
    });

    test('handles empty and whitespace OCR text gracefully', () {
      final result = ReceiptParser.parse('   ');
      expect(result.confidence, equals(OcrConfidence.unknown));
      expect(result.amount, isNull);
      expect(result.warnings, contains('Văn bản OCR trống'));
    });
  });

  group('ReceiptParser - Date Extraction Tests', () {
    test('extracts dd/MM/yyyy date format', () {
      const ocr = '''
      WINMART+
      Ngày: 15/10/2026 18:30
      Tổng cộng: 215.000
      ''';
      final result = ReceiptParser.parse(ocr);
      expect(result.transactionDate, equals(DateTime(2026, 10, 15)));
      expect(result.categorySuggestion, equals(ExpenseCategory.shopping));
    });

    test('extracts Ngày dd tháng MM năm yyyy format', () {
      const ocr = '''
      Nha Sach Fahasa
      Ngày 20 tháng 11 năm 2026
      Thành tiền: 350.000
      ''';
      final result = ReceiptParser.parse(ocr);
      expect(result.transactionDate, equals(DateTime(2026, 11, 20)));
    });

    test('extracts ISO yyyy-MM-dd date format', () {
      const ocr = '''
      GRAB VIETNAM
      2026-10-12 08:30
      Total: 45.000
      ''';
      final result = ReceiptParser.parse(ocr);
      expect(result.transactionDate, equals(DateTime(2026, 10, 12)));
      expect(result.categorySuggestion, equals(ExpenseCategory.transport));
    });

    test('handles 2-digit year format (dd/MM/yy)', () {
      const ocr = '''
      Circle K
      12/10/26
      Total: 50.000
      ''';
      final result = ReceiptParser.parse(ocr);
      expect(result.transactionDate, equals(DateTime(2026, 10, 12)));
    });
  });

  group('ReceiptParser - Merchant Extraction Tests', () {
    test('ignores phone numbers, addresses, and POS headers', () {
      const ocr = '''
      0905123456
      Dia chi: 123 Nguyen Luong Bang, Da Nang
      Hoa don ban le
      PHỞ HÀ NỘI
      1x Pho bo: 45.000
      Tổng: 45.000
      ''';
      final result = ReceiptParser.parse(ocr);
      expect(result.merchant, equals('Phở Hà Nội'));
      expect(result.categorySuggestion, equals(ExpenseCategory.food));
    });
  });

  group('ReceiptParser - Payment Method & Categories', () {
    test('detects payment methods', () {
      const ocrCard = 'Total: 100.000 - Thanh toan: The Visa';
      expect(ReceiptParser.parse(ocrCard).paymentMethod, equals('card'));

      const ocrTransfer = 'Thanh toan Momo - So tien: 50.000';
      expect(ReceiptParser.parse(ocrTransfer).paymentMethod, equals('transfer'));

      const ocrCash = 'Tien mat: 80.000';
      expect(ReceiptParser.parse(ocrCash).paymentMethod, equals('cash'));
    });

    test('categorizes utilities and transport properly', () {
      const ocrElectric = 'Cong ty Dien Luc EVN - Tien dien: 500.000';
      expect(ReceiptParser.parse(ocrElectric).categorySuggestion,
          equals(ExpenseCategory.utilities));

      const ocrGrab = 'Chuyen xe GrabCar - Cuoc phi: 85.000';
      expect(ReceiptParser.parse(ocrGrab).categorySuggestion,
          equals(ExpenseCategory.transport));
    });
  });
}
