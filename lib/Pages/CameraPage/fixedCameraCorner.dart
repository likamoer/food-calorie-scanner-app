import 'package:flutter/material.dart';

// 固定四角对焦框（无动画、一直显示）
class FixedCornerFocusFrame extends StatelessWidget {
  final double size; // 对焦框整体尺寸
  final double cornerLength; // 每个角的线段长度
  final Color color; // 边框颜色
  final double strokeWidth; // 边框粗细

  const FixedCornerFocusFrame({
    super.key,
    this.size = 200, // 对焦框大小（可按需调整）
    this.cornerLength = 30, // 角部线段长度（可按需调整）
    this.color = Colors.white, // 图片中是白色，可改
    this.strokeWidth = 2, // 边框粗细
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _FixedFocusFramePainter(
          cornerLength: cornerLength,
          color: color,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}

// 绘制逻辑：仅画四个角的线段
class _FixedFocusFramePainter extends CustomPainter {
  final double cornerLength;
  final Color color;
  final double strokeWidth;

  _FixedFocusFramePainter({
    required this.cornerLength,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round; // 线段端点圆润（可选，更美观）

    // 1. 左上角：从左边缘中间 → 左上角 → 上边缘中间
    canvas.drawLine(Offset(0, cornerLength), Offset(0, 0), paint);
    canvas.drawLine(Offset(0, 0), Offset(cornerLength, 0), paint);

    // 2. 右上角：从上边缘中间 → 右上角 → 右边缘中间
    canvas.drawLine(Offset(size.width - cornerLength, 0), Offset(size.width, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, cornerLength), paint);

    // 3. 左下角：从左边缘中间 → 左下角 → 下边缘中间
    canvas.drawLine(Offset(0, size.height - cornerLength), Offset(0, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(cornerLength, size.height), paint);

    // 4. 右下角：从下边缘中间 → 右下角 → 右边缘中间
    canvas.drawLine(Offset(size.width - cornerLength, size.height), Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - cornerLength), paint);
  }

  // 无动画，无需重绘
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}