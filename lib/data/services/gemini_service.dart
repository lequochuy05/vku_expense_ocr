// GeminiService — gọi Gemini API để phân tích chi tiêu
// QUAN TRỌNG: Không hardcode API key. Đọc từ environment config.
// Chỉ gửi dữ liệu tổng hợp (không gửi ảnh hay raw OCR text)
// Offline: không crash app khi không có mạng
library;

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_exception.dart';
import '../../domain/models/spending_summary.dart';

/// Model câu trả lời của Gemini
class GeminiAdvice {
  const GeminiAdvice({
    required this.summary,
    required this.insights,
    required this.recommendations,
    required this.disclaimer,
    required this.generatedAt,
  });

  final String summary;
  final List<String> insights;
  final List<String> recommendations;
  final String disclaimer;
  final DateTime generatedAt;

  factory GeminiAdvice.fromText(String text) {
    // Xử lý phản hồi văn bản tự do từ Gemini
    return GeminiAdvice(
      summary: text,
      insights: [],
      recommendations: [],
      disclaimer: 'Lời khuyên này chỉ mang tính tham khảo, dựa trên dữ liệu chi tiêu bạn cung cấp.',
      generatedAt: DateTime.now(),
    );
  }

  factory GeminiAdvice.fromJson(Map<String, dynamic> json) {
    return GeminiAdvice(
      summary: json['summary'] as String? ?? '',
      insights: (json['insights'] as List<dynamic>?)?.cast<String>() ?? [],
      recommendations: (json['recommendations'] as List<dynamic>?)?.cast<String>() ?? [],
      disclaimer: json['disclaimer'] as String? ??
          'Lời khuyên này chỉ mang tính tham khảo.',
      generatedAt: DateTime.now(),
    );
  }
}

class GeminiService {
  GeminiService({required this.apiKey, http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  final String apiKey;
  final http.Client _httpClient;

  // Endpoint Gemini API (gemini-2.0-flash — hiệu quả và nhanh)
  // Xem tài liệu: https://ai.google.dev/api/generate-content
  static const _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  static const _timeout = Duration(seconds: 30);

  /// Phân tích chi tiêu và đưa ra lời khuyên
  /// Chỉ nhận SpendingSummary — không nhận ảnh hay dữ liệu cá nhân khác
  Future<GeminiAdvice> analyzeSpending(SpendingSummary summary) async {
    if (apiKey.isEmpty) {
      throw const GeminiException('API key chưa được cấu hình');
    }

    final prompt = _buildPrompt(summary);

    try {
      final response = await _httpClient
          .post(
            Uri.parse('$_baseUrl?key=$apiKey'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': prompt}
                  ]
                }
              ],
              'generationConfig': {
                'temperature': 0.7,
                'maxOutputTokens': 1024,
              },
              'safetySettings': [
                {
                  'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
                  'threshold': 'BLOCK_ONLY_HIGH',
                }
              ],
            }),
          )
          .timeout(_timeout);

      return _parseResponse(response);
    } on GeminiException {
      rethrow;
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw GeminiException('Gemini API timeout sau 30 giây', cause: e);
      }
      throw GeminiException('Lỗi kết nối Gemini API', cause: e);
    }
  }

  /// Tạo prompt tiếng Việt gửi cho Gemini
  /// Chỉ gửi dữ liệu tổng hợp — không gửi tên, số điện thoại, hay thông tin cá nhân
  String _buildPrompt(SpendingSummary summary) {
    final aiData = summary.toAiSummary();
    final categoriesText = (aiData['categories'] as List<dynamic>)
        .map((c) => '- ${c['name']}: ${c['amount_vnd']} VND (${c['percentage']}%)')
        .join('\n');

    final changeText = summary.changePercentage != null
        ? 'Thay đổi so với kỳ trước: ${summary.changePercentage!.toStringAsFixed(1)}%'
        : 'Không có dữ liệu kỳ trước để so sánh.';

    return '''
Bạn là một cố vấn tài chính cá nhân thân thiện, đang giúp một sinh viên Việt Nam quản lý chi tiêu.

Dữ liệu chi tiêu trong kỳ (${aiData['period']}):
- Tổng chi tiêu: ${aiData['total_amount_vnd']} VND
- Số giao dịch: ${aiData['transaction_count']}
- $changeText

Chi tiết theo danh mục:
$categoriesText

Hãy phân tích và đưa ra:
1. Nhận xét tổng quan về tình hình chi tiêu
2. Các danh mục chiếm tỷ trọng cao bất thường
3. 3-5 lời khuyên cụ thể để tiết kiệm
4. Kế hoạch chi tiêu đề xuất cho kỳ tới

Lưu ý:
- Trả lời bằng tiếng Việt, thân thiện và dễ hiểu
- Đây là dữ liệu sinh viên, hãy phù hợp với ngân sách sinh viên
- Cuối cùng thêm một câu tuyên bố miễn trách: "Lời khuyên này chỉ mang tính tham khảo."
''';
  }

  /// Parse HTTP response từ Gemini
  GeminiAdvice _parseResponse(http.Response response) {
    if (response.statusCode == 401) {
      throw const GeminiException('API key không hợp lệ hoặc đã hết hạn',
          statusCode: 401);
    }
    if (response.statusCode == 429) {
      throw const GeminiException('Vượt quá giới hạn tần suất Gemini API',
          statusCode: 429);
    }
    if (response.statusCode >= 500) {
      throw GeminiException(
          'Lỗi server Gemini (${response.statusCode})',
          statusCode: response.statusCode);
    }
    if (response.statusCode != 200) {
      throw GeminiException(
          'Lỗi HTTP ${response.statusCode}',
          statusCode: response.statusCode);
    }

    try {
      final json = jsonDecode(utf8.decode(response.bodyBytes))
          as Map<String, dynamic>;

      // Kiểm tra cấu trúc JSON trước khi truy cập
      final candidates = json['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        throw const GeminiException('Gemini không trả về kết quả');
      }

      final content = candidates[0]['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List<dynamic>?;
      final text = parts?.firstOrNull?['text'] as String?;

      if (text == null || text.isEmpty) {
        throw const GeminiException('Nội dung phản hồi từ Gemini trống');
      }

      // Không thực thi code từ AI — chỉ hiển thị văn bản
      return GeminiAdvice.fromText(text);
    } on GeminiException {
      rethrow;
    } catch (e) {
      throw GeminiException('Không thể đọc phản hồi từ Gemini', cause: e);
    }
  }

  void dispose() => _httpClient.close();
}

final geminiServiceProvider = Provider<GeminiService?>((ref) {
  // Đọc API key từ SharedPreferences hoặc dart-define (an toàn hơn)
  // Nếu chưa cấu hình thì trả về null — UI sẽ hiển thị hướng dẫn
  const apiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
  if (apiKey.isEmpty) return null;

  final service = GeminiService(apiKey: apiKey);
  ref.onDispose(service.dispose);
  return service;
});
