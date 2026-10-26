// WeeklyBarChart — biểu đồ cột 7 ngày bằng CustomPainter
// Bắt buộc theo yêu cầu bài tập
//
// Thuật toán chuẩn hóa chiều cao cột:
// barHeight = (value / maxValue) * availableHeight
// Nếu maxValue = 0, tất cả barHeight = 0 (không chia cho 0)
//
// Tọa độ:
// - Origin (0,0): góc trên-trái canvas
// - Trục Y: từ trên xuống (0 = đỉnh, height = đáy)
// - Cột vẽ từ đáy lên: top = bottom - barHeight
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';

class WeeklyBarChart extends StatefulWidget {
  const WeeklyBarChart({
    super.key,
    required this.dailyTotals,
  });

  /// Map từ ngày đến tổng số tiền
  final Map<DateTime, int> dailyTotals;

  @override
  State<WeeklyBarChart> createState() => _WeeklyBarChartState();
}

class _WeeklyBarChartState extends State<WeeklyBarChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int? _selectedDayIndex;

  // 7 ngày gần nhất
  late List<DateTime> _days;
  late List<int> _amounts;

  @override
  void initState() {
    super.initState();
    _prepareDays();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(WeeklyBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dailyTotals != widget.dailyTotals) {
      _prepareDays();
      _controller.reset();
      _controller.forward();
    }
  }

  void _prepareDays() {
    _days = DateFormatter.last7Days();
    _amounts = _days.map((day) {
      // Tìm ngày khớp trong map (so sánh yyyy-MM-dd)
      for (final entry in widget.dailyTotals.entries) {
        if (DateFormatter.isSameDay(entry.key, day)) return entry.value;
      }
      return 0;
    }).toList();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasData = _amounts.any((a) => a > 0);

    if (!hasData) {
      return Card(
        child: SizedBox(
          height: 180,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.bar_chart_outlined,
                  size: 48,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                ),
                const SizedBox(height: 8),
                Text(
                  'Chưa có chi tiêu trong 7 ngày qua',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hiển thị tooltip khi chọn cột
            if (_selectedDayIndex != null)
              _TooltipCard(
                day: _days[_selectedDayIndex!],
                amount: _amounts[_selectedDayIndex!],
              ),
            const SizedBox(height: 8),
            SizedBox(
              height: 160,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return GestureDetector(
                    onTapDown: (details) {
                      final chartWidth = constraints.maxWidth;
                      if (chartWidth > 0) {
                        final barWidth = chartWidth / _days.length;
                        final index =
                            (details.localPosition.dx / barWidth).floor();
                        setState(() {
                          _selectedDayIndex =
                              index.clamp(0, _days.length - 1);
                        });
                      }
                    },
                    child: AnimatedBuilder(
                      animation: _animation,
                      builder: (context, _) {
                        return CustomPaint(
                          size: Size(constraints.maxWidth, 160),
                          painter: _BarChartPainter(
                            days: _days,
                            amounts: _amounts,
                            selectedIndex: _selectedDayIndex,
                            progress: _animation.value,
                            primaryColor: theme.colorScheme.primary,
                            selectedColor: theme.colorScheme.tertiary,
                            labelColor: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                            gridColor: theme.colorScheme.outlineVariant
                                .withValues(alpha: 0.5),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Painter vẽ các cột
class _BarChartPainter extends CustomPainter {
  _BarChartPainter({
    required this.days,
    required this.amounts,
    required this.selectedIndex,
    required this.progress, // 0.0 → 1.0
    required this.primaryColor,
    required this.selectedColor,
    required this.labelColor,
    required this.gridColor,
  });

  final List<DateTime> days;
  final List<int> amounts;
  final int? selectedIndex;
  final double progress;
  final Color primaryColor;
  final Color selectedColor;
  final Color labelColor;
  final Color gridColor;

  // Padding cho nhãn trục
  static const _labelHeight = 28.0;
  static const _topPadding = 8.0;
  static const _barPaddingRatio = 0.25; // Khoảng trống giữa các cột

  @override
  void paint(Canvas canvas, Size size) {
    // Vùng vẽ cột (bỏ phần nhãn bên dưới)
    final chartBottom = size.height - _labelHeight;
    final chartHeight = chartBottom - _topPadding;

    // Chuẩn hóa: tìm giá trị lớn nhất
    // Nếu tất cả = 0, maxValue = 1 — tránh chia cho 0
    final maxValue = amounts.fold(0, math.max);
    final effectiveMax = maxValue > 0 ? maxValue : 1;

    // Vẽ đường lưới ngang
    _drawGrid(canvas, size, chartBottom, chartHeight, effectiveMax);

    // Vẽ từng cột
    final barGroupWidth = size.width / days.length;
    final barWidth = barGroupWidth * (1 - _barPaddingRatio);
    final barPadding = barGroupWidth * _barPaddingRatio / 2;

    for (int i = 0; i < days.length; i++) {
      // Chiều cao cột: chuẩn hóa theo maxValue và animation progress
      final barHeight = (amounts[i] / effectiveMax) * chartHeight * progress;

      final left = i * barGroupWidth + barPadding;
      final top = chartBottom - barHeight;
      final rect = Rect.fromLTWH(left, top, barWidth, barHeight);
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(4));

      // Màu cột: nổi bật khi được chọn
      final isSelected = selectedIndex == i;
      final paint = Paint()
        ..color = isSelected ? selectedColor : primaryColor.withValues(alpha: 0.7);

      canvas.drawRRect(rrect, paint);

      // Nhãn ngày trong tuần (bên dưới cột)
      _drawLabel(
        canvas,
        DateFormatter.weekdayShort(days[i]),
        left + barWidth / 2,
        chartBottom + 6,
        isSelected: isSelected,
      );
    }
  }

  /// Vẽ đường lưới ngang (3 đường: 25%, 50%, 75% và 100%)
  void _drawGrid(
    Canvas canvas,
    Size size,
    double chartBottom,
    double chartHeight,
    int maxValue,
  ) {
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;

    for (final ratio in [0.25, 0.5, 0.75, 1.0]) {
      final y = chartBottom - chartHeight * ratio;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);

      // Nhãn giá trị trục Y
      final value = (maxValue * ratio).round();
      _drawLabel(
        canvas,
        CurrencyFormatter.formatCompact(value),
        -4, // Căn trái canvas
        y - 10,
        textAlign: TextAlign.right,
      );
    }
  }

  void _drawLabel(
    Canvas canvas,
    String text,
    double x,
    double y, {
    bool isSelected = false,
    TextAlign textAlign = TextAlign.center,
  }) {
    final span = TextSpan(
      text: text,
      style: TextStyle(
        color: isSelected ? selectedColor : labelColor,
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
    final painter = TextPainter(
      text: span,
      textDirection: TextDirection.ltr,
      textAlign: textAlign,
    );
    painter.layout(maxWidth: 50);
    painter.paint(
      canvas,
      Offset(x - painter.width / 2, y),
    );
  }

  @override
  bool shouldRepaint(_BarChartPainter old) =>
      old.amounts != amounts ||
      old.selectedIndex != selectedIndex ||
      old.progress != progress;
}

/// Tooltip hiển thị khi chọn cột
class _TooltipCard extends StatelessWidget {
  const _TooltipCard({required this.day, required this.amount});
  final DateTime day;
  final int amount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            DateFormatter.formatFull(day),
            style: TextStyle(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            CurrencyFormatter.format(amount),
            style: TextStyle(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
