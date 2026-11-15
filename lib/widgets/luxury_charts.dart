import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DonutChartWidget extends StatelessWidget {
  final List> items;
  final double totalExpense;

  const DonutChartWidget({
    super.key,
    required this.items,
    required this.totalExpense,
  });

  @override
  Widget build(BuildContext context) {
    final activeItems = items.where((e) => (e['spent'] as double) > 0).toList();

    return SizedBox(
      height: 210,
      width: 210,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(210, 210),
            painter: _DonutPainter(
              items: activeItems,
              total: totalExpense,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'TOTAL KELUAR',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppFormatters.compactRupiah(totalExpense),
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List> items;
  final double total;

  _DonutPainter({required this.items, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 16;
    const strokeWidth = 22.0;

    final bgPaint = Paint()
      ..color = AppTheme.cardElevated
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, bgPaint);

    if (total <= 0 || items.isEmpty) return;

    double startAngle = -pi / 2;
    for (final item in items) {
      final spent = (item['spent'] as num).toDouble();
      final sweepAngle = (spent / total) * 2 * pi;
      final colorHex = item['color_hex'] as int? ?? 0xFFF59E0B;

      final paint = Paint()
        ..color = Color(colorHex)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle > 0.04 ? sweepAngle - 0.03 : sweepAngle,
        false,
        paint,
      );
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => true;
}
