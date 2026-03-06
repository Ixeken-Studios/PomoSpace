import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DigitalClock extends StatefulWidget {
  const DigitalClock({super.key});

  @override
  State<DigitalClock> createState() => _DigitalClockState();
}

class _DigitalClockState extends State<DigitalClock> {
  late String _timeString;
  late String _dateString;
  late DateTime _now;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timeString = _formatTime(_now);
    _dateString = _formatDate(_now);
    _timer = Timer.periodic(
      const Duration(
        milliseconds: 100,
      ), // Faster tick for smooth sweeping seconds
      (Timer t) => _getTime(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _getTime() {
    final DateTime now = DateTime.now();
    if (now.second != _now.second || now.millisecond > 900) {
      final String formattedTime = _formatTime(now);
      final String formattedDate = _formatDate(now);
      setState(() {
        _now = now;
        _timeString = formattedTime;
        _dateString = formattedDate;
      });
    }
  }

  String _formatTime(DateTime dateTime) {
    return DateFormat('hh:mm a').format(dateTime); // Using intl package
  }

  String _formatDate(DateTime dateTime) {
    return DateFormat('EEEE, MMMM d').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;

        // Similar to Pomodoro Timer, reserve some space
        final double maxAllowedHeight = availableHeight - 40.0;
        final double clockSize = maxAllowedHeight.clamp(120.0, 300.0);

        final double timeFontSize = (clockSize * 0.25).clamp(24.0, 64.0);
        final double dateFontSize = (clockSize * 0.08).clamp(12.0, 20.0);

        return Stack(
          alignment: Alignment.center,
          children: [
            // Analog Clock Background
            SizedBox(
              width: clockSize,
              height: clockSize,
              child: CustomPaint(painter: AnalogClockPainter(datetime: _now)),
            ),
            // Digital Clock Foreground
            Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: clockSize * 0.08,
                    vertical: clockSize * 0.03,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Text(
                    _timeString,
                    style: TextStyle(
                      fontSize: timeFontSize,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: clockSize * 0.05),
                Text(
                  _dateString,
                  style: TextStyle(
                    fontSize: dateFontSize,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.7),
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class AnalogClockPainter extends CustomPainter {
  final DateTime datetime;

  AnalogClockPainter({required this.datetime});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2);

    // Aesthetic soft circle background
    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, borderPaint);

    // Draw Tick Marks
    final tickPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 60; i++) {
      final double angle = i * pi / 30; // 6 degrees per tick
      final double startRadius = i % 5 == 0 ? radius - 15 : radius - 8;
      final double startX = center.dx + startRadius * cos(angle);
      final double startY = center.dy + startRadius * sin(angle);
      final double endX = center.dx + radius * cos(angle);
      final double endY = center.dy + radius * sin(angle);

      tickPaint.color = i % 5 == 0
          ? Colors.deepPurpleAccent.withOpacity(0.5)
          : Colors.white.withOpacity(0.1);
      tickPaint.strokeWidth = i % 5 == 0 ? 3 : 1.5;

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), tickPaint);
    }

    // Calculate angles
    // Sweep effect: include milliseconds for seconds, seconds for minutes, etc.
    final secAngle =
        (datetime.second * pi / 30) +
        (datetime.millisecond * pi / 30000) -
        pi / 2;
    final minAngle =
        (datetime.minute * pi / 30) + (datetime.second * pi / 1800) - pi / 2;
    final hourAngle =
        ((datetime.hour % 12) * pi / 6) + (datetime.minute * pi / 360) - pi / 2;

    // Hour Hand
    final hourPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    final hourX = center.dx + (radius * 0.5) * cos(hourAngle);
    final hourY = center.dy + (radius * 0.5) * sin(hourAngle);
    canvas.drawLine(center, Offset(hourX, hourY), hourPaint);

    // Minute Hand
    final minPaint = Paint()
      ..color = Colors.tealAccent.withOpacity(0.8)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final minX = center.dx + (radius * 0.75) * cos(minAngle);
    final minY = center.dy + (radius * 0.75) * sin(minAngle);
    canvas.drawLine(center, Offset(minX, minY), minPaint);

    // Second Hand
    final secPaint = Paint()
      ..color = Colors.deepPurpleAccent
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final secX = center.dx + (radius * 0.85) * cos(secAngle);
    final secY = center.dy + (radius * 0.85) * sin(secAngle);

    // Tail of the second hand
    final secTailX = center.dx - (radius * 0.15) * cos(secAngle);
    final secTailY = center.dy - (radius * 0.15) * sin(secAngle);
    canvas.drawLine(Offset(secTailX, secTailY), Offset(secX, secY), secPaint);

    // Center Dot
    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 6, dotPaint);

    final innerDotPaint = Paint()
      ..color = Colors.deepPurpleAccent
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 3, innerDotPaint);
  }

  @override
  bool shouldRepaint(covariant AnalogClockPainter oldDelegate) {
    return oldDelegate.datetime != datetime;
  }
}
