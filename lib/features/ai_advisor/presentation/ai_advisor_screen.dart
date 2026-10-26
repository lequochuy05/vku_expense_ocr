// Màn hình AI Advisor — phân tích chi tiêu bằng Gemini
// Hiển thị rõ ràng: dữ liệu thật vs lời khuyên AI
// Offline-first: không crash khi không có mạng
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/network/connectivity_service.dart';
import '../../../data/repositories/expense_repository_impl.dart';
import '../../../data/services/gemini_service.dart';
import '../../../domain/models/spending_summary.dart';
import '../../../core/errors/app_exception.dart';

final advisorSpendingDataProvider =
    FutureProvider<SpendingSummary>((ref) async {
  final repo = ref.watch(expenseRepositoryProvider);
  final now = DateTime.now();
  final start = DateFormatter.firstDayOfMonth(now);
  final end = DateFormatter.lastDayOfMonth(now);
  final prevStart =
      DateFormatter.firstDayOfMonth(DateTime(now.year, now.month - 1));
  final prevEnd =
      DateFormatter.lastDayOfMonth(DateTime(now.year, now.month - 1));

  return repo.getSpendingSummary(
    startDate: start,
    endDate: end,
    previousStart: prevStart,
    previousEnd: prevEnd,
  );
});

class AiAdviceNotifier extends StateNotifier<AsyncValue<GeminiAdvice?>> {
  AiAdviceNotifier(this.ref) : super(const AsyncValue.data(null));

  final Ref ref;

  Future<void> analyze(SpendingSummary summary) async {
    state = const AsyncValue.loading();

    try {
      final connectivity = ref.read(connectivityServiceProvider);
      final hasNet = await connectivity.hasConnection();
      if (!hasNet) {
        state = AsyncValue.error(
            const NetworkException('Không có kết nối mạng'),
            StackTrace.current);
        return;
      }

      final gemini = ref.read(geminiServiceProvider);
      if (gemini == null) {
        state = AsyncValue.error(
            const GeminiException('Gemini API chưa được cấu hình'),
            StackTrace.current);
        return;
      }

      final advice = await gemini.analyzeSpending(summary);
      state = AsyncValue.data(advice);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final aiAdviceNotifierProvider =
    StateNotifierProvider<AiAdviceNotifier, AsyncValue<GeminiAdvice?>>((ref) {
  return AiAdviceNotifier(ref);
});

class AiAdvisorScreen extends ConsumerWidget {
  const AiAdvisorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(advisorSpendingDataProvider);
    final adviceState = ref.watch(aiAdviceNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Advisor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Giới thiệu',
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      body: SafeArea(
        child: summaryAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Lỗi tải dữ liệu: $e'),
                ElevatedButton(
                  onPressed: () => ref.invalidate(advisorSpendingDataProvider),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          ),
          data: (summary) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Thống kê thực tế (không do AI tạo)
              _StatsCard(summary: summary),
              const SizedBox(height: 16),

              // Phân biệt rõ: dữ liệu thật vs AI
              Card(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.psychology,
                              color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Phân tích AI',
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '⚠ Lời khuyên dưới đây được tạo bởi AI (Gemini) dựa trên dữ liệu bạn cung cấp. '
                        'Chỉ mang tính tham khảo.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Trạng thái AI
                      adviceState.when(
                        loading: () => const Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 8),
                            Text('Gemini đang phân tích...'),
                          ],
                        ),
                        error: (e, _) => _AiError(error: e),
                        data: (advice) => advice == null
                            ? _AiCallToAction(
                                onAnalyze: () => ref
                                    .read(aiAdviceNotifierProvider.notifier)
                                    .analyze(summary),
                              )
                            : _AiAdviceCard(advice: advice, onRefresh: () => ref
                                .read(aiAdviceNotifierProvider.notifier)
                                .analyze(summary)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Về AI Advisor'),
        content: const Text(
          '• AI Advisor sử dụng Google Gemini để phân tích chi tiêu.\n'
          '• Chỉ gửi dữ liệu tổng hợp (không gửi thông tin cá nhân).\n'
          '• Cần kết nối internet để sử dụng.\n'
          '• Lời khuyên chỉ mang tính tham khảo.\n'
          '• Cần cấu hình Gemini API key trong cài đặt.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.summary});
  final SpendingSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bar_chart, color: Colors.blue),
                const SizedBox(width: 8),
                Text('Dữ liệu thống kê thực tế',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            _StatRow(
              label: 'Tổng chi tiêu tháng này:',
              value: CurrencyFormatter.format(summary.totalAmount),
            ),
            _StatRow(
              label: 'Số giao dịch:',
              value: '${summary.transactionCount}',
            ),
            if (summary.changePercentage != null)
              _StatRow(
                label: 'So với tháng trước:',
                value: '${summary.changePercentage! >= 0 ? '+' : ''}'
                    '${summary.changePercentage!.toStringAsFixed(1)}%',
                valueColor: summary.changePercentage! <= 0
                    ? Colors.green
                    : Colors.red,
              ),
            if (summary.categoryBreakdown.isNotEmpty) ...[
              const Divider(),
              Text('Danh mục cần chú ý:',
                  style: theme.textTheme.bodySmall),
              const SizedBox(height: 4),
              ...summary.categoryBreakdown.take(3).map((cat) => _StatRow(
                    label: '${cat.category.displayName}:',
                    value: '${cat.percentage.toStringAsFixed(1)}% '
                        '(${CurrencyFormatter.formatCompact(cat.totalAmount)})',
                  )),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value, this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _AiCallToAction extends StatelessWidget {
  const _AiCallToAction({required this.onAnalyze});
  final VoidCallback onAnalyze;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          Icons.psychology_outlined,
          size: 48,
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
        ),
        const SizedBox(height: 8),
        const Text(
          'Nhấn nút để Gemini phân tích chi tiêu\nvà đưa ra lời khuyên tiết kiệm',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: onAnalyze,
          icon: const Icon(Icons.auto_awesome),
          label: const Text('Phân tích với Gemini'),
        ),
      ],
    );
  }
}

class _AiError extends StatelessWidget {
  const _AiError({required this.error});
  final Object error;

  @override
  Widget build(BuildContext context) {
    final message = switch (error) {
      GeminiException e when e.statusCode == 401 =>
        'API key không hợp lệ. Vui lòng kiểm tra lại trong Cài đặt.',
      GeminiException e when e.statusCode == 429 =>
        'Quá nhiều yêu cầu. Vui lòng đợi một chút.',
      NetworkException _ => 'Không có kết nối internet. Vui lòng kiểm tra mạng.',
      GeminiException e when e.message.contains('chưa được cấu hình') =>
        'Chưa cấu hình Gemini API key.\nVui lòng vào Cài đặt → Cấu hình AI.',
      _ => error.toString(),
    };

    return Column(
      children: [
        Icon(Icons.error_outline,
            color: Theme.of(context).colorScheme.error),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Theme.of(context).colorScheme.error),
        ),
      ],
    );
  }
}

class _AiAdviceCard extends StatelessWidget {
  const _AiAdviceCard({required this.advice, required this.onRefresh});
  final GeminiAdvice advice;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nội dung phân tích
        Text(
          advice.summary,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6),
        ),
        const SizedBox(height: 12),
        Text(
          advice.disclaimer,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontStyle: FontStyle.italic,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 16),
        // Nút phân tích lại
        OutlinedButton.icon(
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('Phân tích lại'),
        ),
      ],
    );
  }
}
