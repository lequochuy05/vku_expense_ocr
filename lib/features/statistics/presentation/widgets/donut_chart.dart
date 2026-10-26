// DonutChart — vẽ biểu đồ donut bằng CustomPainter
// Bắt buộc theo yêu cầu bài tập — không dùng thư viện biểu đồ sẵn có
//
// Thuật toán:
// - StartAngle: -pi/2 (bắt đầu từ trên đỉnh)
// - SweepAngle của mỗi danh mục = (số tiền / tổng) * 2*pi
// - Vẽ bằng canvas.drawArc với style stroke để tạo hiệu ứng donut
// - Animation: AnimatedBuilder từ 0.0 đến 1.0, nhân sweepAngle
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../../../domain/models/spending_summary.dart';

class DonutChart extends StatefulWidget {
  const DonutChart({
    super.key,
    required this.categories,
    required this.totalAmount,
  });

  final List<CategorySummary> categories;
  final int totalAmount;

  @override
  State<DonutChart> createState() => _DonutChartState();
}

class _DonutChartState extends State<DonutChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // Animation từ 0 đến 1 trong 800ms — easeInOut cho trải nghiệm mượt
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(DonutChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset animation khi dữ liệu thay đổi
    if (oldWidget.categories != widget.categories) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.totalAmount == 0) {
      return const _EmptyDonut();
    }

    return Column(
      children: [
        // Vùng biểu đồ
        Semantics(
          label: 'Biểu đồ donut phân bổ chi tiêu '
              'Tổng: ${CurrencyFormatter.format(widget.totalAmount)}',
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, _) {
              return SizedBox(
                height: 220,
                child: CustomPaint(
                  painter: _DonutPainter(
                    categories: widget.categories,
                    totalAmount: widget.totalAmount,
                    progress: _animation.value,
                    isDark:
                        Theme.of(context).brightness == Brightness.dark,
                  ),
                  child: Center(
                    child: _CenterLabel(totalAmount: widget.totalAmount),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        // Legend danh mục
        _DonutLegend(categories: widget.categories, totalAmount: widget.totalAmount),
      ],
    );
  }
}

/// Custom painter vẽ donut
class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.categories,
    required this.totalAmount,
    required this.progress, // 0.0 → 1.0 cho animation
    required this.isDark,
  });

  final List<CategorySummary> categories;
  final int totalAmount;
  final double progress;
  final bool isDark;

  // Độ dày của donut (stroke width)
  static const _strokeWidth = 36.0;
  // Khoảng trống giữa các cung (radians) — tạo hiệu ứng separated
  static const _gapAngle = 0.02;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) / 2) - _strokeWidth / 2 - 4;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Bắt đầu từ đỉnh (trừ pi/2 vì Flutter đo góc theo chiều kim đồng hồ từ bên phải)
    double startAngle = -math.pi / 2;

    for (int i = 0; i < categories.length; i++) {
      final cat = categories[i];
      if (cat.totalAmount <= 0) continue;

      // Tính sweepAngle: tỷ lệ của danh mục * 2*pi * progress (animation)
      final sweepAngle =
          (cat.totalAmount / totalAmount) * 2 * math.pi * progress;

      // Tạo Paint cho danh mục này
      final paint = Paint()
        ..color = cat.category.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = _strokeWidth
        ..strokeCap = StrokeCap.butt; // Không bo đầu để tránh chồng lấp

      // Vẽ cung tròn
      canvas.drawArc(
        rect,
        startAngle + _gapAngle / 2, // Trừ gap ở đầu
        sweepAngle - _gapAngle, // Trừ gap ở cuối
        false, // useCenter = false → chỉ vẽ cung, không kết nối tâm
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  // shouldRepaint: chỉ vẽ lại khi dữ liệu hoặc progress thay đổi
  bool shouldRepaint(_DonutPainter old) =>
      old.categories != categories ||
      old.totalAmount != totalAmount ||
      old.progress != progress ||
      old.isDark != isDark;
}

/// Nhãn tổng tiền ở giữa donut
class _CenterLabel extends StatelessWidget {
  const _CenterLabel({required this.totalAmount});
  final int totalAmount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Tổng',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        Text(
          CurrencyFormatter.formatCompact(totalAmount),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}

/// Legend hiển thị bên dưới biểu đồ
class _DonutLegend extends StatelessWidget {
  const _DonutLegend({
    required this.categories,
    required this.totalAmount,
  });

  final List<CategorySummary> categories;
  final int totalAmount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: categories.map((cat) {
        // Đảm bảo phần trăm không vượt 100% do sai số
        final pct = totalAmount > 0
            ? (cat.totalAmount / totalAmount * 100).clamp(0.0, 100.0)
            : 0.0;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              // Ô màu
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: cat.category.color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 8),
              // Tên danh mục + icon
              Icon(cat.category.icon, size: 14, color: cat.category.color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  cat.category.displayName,
                  style: theme.textTheme.bodySmall,
                ),
              ),
              // Phần trăm
              Text(
                '${pct.toStringAsFixed(1)}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(width: 8),
              // Số tiền
              Text(
                CurrencyFormatter.formatCompact(cat.totalAmount),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// Trạng thái khi totalAmount = 0
class _EmptyDonut extends StatelessWidget {
  const _EmptyDonut();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.donut_large_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 8),
          Text(
            'Chưa có dữ liệu',
            style: TextStyle(
              color:
                  Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}
