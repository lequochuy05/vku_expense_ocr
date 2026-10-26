import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:vku_expense_ocr/core/errors/app_exception.dart';
import 'package:vku_expense_ocr/data/services/gemini_service.dart';
import 'package:vku_expense_ocr/domain/models/expense_category.dart';
import 'package:vku_expense_ocr/domain/models/spending_summary.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  setUpAll(() {
    registerFallbackValue(Uri.parse('https://example.com'));
  });

  late MockHttpClient mockClient;
  late GeminiService geminiService;

  setUp(() {
    mockClient = MockHttpClient();
    geminiService = GeminiService(apiKey: 'TEST_API_KEY', httpClient: mockClient);
  });

  final sampleSummary = SpendingSummary(
    periodStart: DateTime(2026, 10, 1),
    periodEnd: DateTime(2026, 10, 31),
    totalAmount: 1500000,
    transactionCount: 12,
    previousPeriodAmount: 1200000,
    categoryBreakdown: const [
      CategorySummary(
        category: ExpenseCategory.food,
        totalAmount: 900000,
        transactionCount: 8,
        percentage: 60.0,
      ),
      CategorySummary(
        category: ExpenseCategory.transport,
        totalAmount: 600000,
        transactionCount: 4,
        percentage: 40.0,
      ),
    ],
    dailyBreakdown: const [],
  );

  group('GeminiService Unit Tests', () {
    test('successful 200 response parses advice text correctly', () async {
      const mockResponseText = '''
      1. Tình hình chi tiêu: Bạn đã chi 1.500.000 VND trong tháng 10.
      2. Danh mục nổi bật: Ăn uống chiếm 60% tổng chi tiêu.
      3. Lời khuyên: Nấu ăn tại nhà để tiết kiệm chi phí sinh viên.
      Lời khuyên này chỉ mang tính tham khảo.
      ''';

      final mockBody = jsonEncode({
        'candidates': [
          {
            'content': {
              'parts': [
                {'text': mockResponseText}
              ]
            }
          }
        ]
      });

      when(() => mockClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response.bytes(
            utf8.encode(mockBody),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          ));

      final advice = await geminiService.analyzeSpending(sampleSummary);

      expect(advice.summary, contains('Tình hình chi tiêu'));
      expect(advice.summary, contains('Lời khuyên'));
      expect(advice.disclaimer, isNotEmpty);
    });

    test('throws GeminiException with 401 status on invalid API key', () async {
      when(() => mockClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response('Unauthorized', 401));

      expect(
        () => geminiService.analyzeSpending(sampleSummary),
        throwsA(isA<GeminiException>().having((e) => e.statusCode, 'statusCode', 401)),
      );
    });

    test('throws GeminiException with 429 on rate limit', () async {
      when(() => mockClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response('Rate limit exceeded', 429));

      expect(
        () => geminiService.analyzeSpending(sampleSummary),
        throwsA(isA<GeminiException>().having((e) => e.statusCode, 'statusCode', 429)),
      );
    });

    test('throws GeminiException on empty API key', () async {
      final unconfiguredService = GeminiService(apiKey: '');
      expect(
        () => unconfiguredService.analyzeSpending(sampleSummary),
        throwsA(isA<GeminiException>()),
      );
    });

    test('verifies request body sends only aggregated summary without sensitive data', () async {
      String? capturedBody;
      when(() => mockClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((invocation) async {
        capturedBody = invocation.namedArguments[#body] as String?;
        return http.Response(
            jsonEncode({
              'candidates': [
                {
                  'content': {
                    'parts': [
                      {'text': 'Advice'}
                    ]
                  }
                }
              ]
            }),
            200);
      });

      await geminiService.analyzeSpending(sampleSummary);

      expect(capturedBody, isNotNull);
      final decoded = jsonDecode(capturedBody!) as Map<String, dynamic>;
      final promptText = decoded['contents'][0]['parts'][0]['text'] as String;

      // Contains summary numbers
      expect(promptText, contains('1500000'));
      expect(promptText, contains('Ăn uống'));

      // Ensures no raw photos or credentials
      expect(promptText, isNot(contains('base64')));
      expect(promptText, isNot(contains('imagePath')));
    });
  });
}
