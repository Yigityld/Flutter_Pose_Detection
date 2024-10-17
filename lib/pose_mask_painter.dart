import 'dart:ui' as ui;
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:body_detection/models/pose.dart';
import 'package:body_detection/models/pose_landmark.dart';
import 'package:body_detection/models/pose_landmark_type.dart';

class PoseMaskPainter extends CustomPainter {
  PoseMaskPainter({
    required this.pose,
    required this.mask,
    required this.imageSize,
  });

  final Pose? pose;
  final ui.Image? mask;
  final Size imageSize;
  final pointPaint = Paint()..color = const Color.fromRGBO(255, 255, 255, 0.8);
  final leftPointPaint = Paint()..color = const Color.fromRGBO(223, 157, 80, 1);
  final rightPointPaint = Paint()
    ..color = const Color.fromRGBO(100, 208, 218, 1);
  final linePaint = Paint()
    ..color = const Color.fromRGBO(255, 0, 0, 0.9)
    ..strokeWidth = 3;
  final maskPaint = Paint()
    ..colorFilter = const ColorFilter.mode(
        Color.fromRGBO(0, 0, 255, 0.5), BlendMode.srcOut);

  @override
  void paint(Canvas canvas, Size size) {
    _paintMask(canvas, size);
    _paintPose(canvas, size);
  }

  void _paintPose(Canvas canvas, Size size) {
    if (pose == null) return;

    final double hRatio =
        imageSize.width == 0 ? 1 : size.width / imageSize.width;
    final double vRatio =
        imageSize.height == 0 ? 1 : size.height / imageSize.height;

    offsetForPart(PoseLandmark part) =>
        Offset(part.position.x * hRatio, part.position.y * vRatio);

    // Landmark connections
    final landmarksByType = {for (final it in pose!.landmarks) it.type: it};

    for (final connection in connections) {
      final point1 = offsetForPart(landmarksByType[connection[0]]!);
      final point2 = offsetForPart(landmarksByType[connection[1]]!);

      canvas.drawLine(point1, point2, linePaint);
      double angleRadians = math.atan2(point2.dy - point1.dy, point2.dx - point1.dx);
      double angleDegrees = (angleRadians * 180 / math.pi) ;
      if (connection[0]==PoseLandmarkType.leftElbow && connection[1]==PoseLandmarkType.leftShoulder) {
        angleDegrees += 90;
        angleDegrees *= -1;
      }else if(connection[0]==PoseLandmarkType.leftWrist && connection[1]==PoseLandmarkType.leftElbow){
        angleDegrees += 90;
        angleDegrees *= -1;
      } else if(connection[0]==PoseLandmarkType.rightWrist && connection[1]==PoseLandmarkType.rightElbow){
        angleDegrees += 90;
      } else {
        angleDegrees -= 90;
      }

      if (angleDegrees < 0) {
        angleDegrees += 360;
      } else if (angleDegrees > 360) {
        angleDegrees -= 360;
      }

      TextSpan angleSpan = TextSpan(
        text: "${angleDegrees.toStringAsFixed(2)}°",
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
      );
      TextPainter angleTp = TextPainter(text: angleSpan, textAlign: TextAlign.left);
      angleTp.textDirection = TextDirection.ltr;
      angleTp.layout();
      angleTp.paint(canvas, Offset((point1.dx + point2.dx) / 2, (point1.dy + point2.dy) / 2));
    }

    for (final part in pose!.landmarks) {
      // Landmark points
      /*canvas.drawCircle(offsetForPart(part), 5, pointPaint);
      if (part.type.isLeftSide) {
        canvas.drawCircle(offsetForPart(part), 3, leftPointPaint);
      } else if (part.type.isRightSide) {
        canvas.drawCircle(offsetForPart(part), 3, rightPointPaint);
      }*/

      // Landmark labels
      TextSpan span = TextSpan(
        text: part.type.toString().substring(16),
        style: const TextStyle(
          color: Color.fromRGBO(0, 128, 255, 1),
          fontSize: 10,
          shadows: [
            ui.Shadow(
              color: Color.fromRGBO(255, 0, 0, 1),
              offset: Offset(1, 1),
              blurRadius: 1,
            ),
          ],
        ),
      );
      TextPainter tp = TextPainter(text: span, textAlign: TextAlign.left);
      tp.textDirection = TextDirection.ltr;
      tp.layout();
      //tp.paint(canvas, offsetForPart(part));
    }
  }

  void _paintMask(Canvas canvas, Size size) {
    if (mask == null) return;

    canvas.drawImageRect(
        mask!,
        Rect.fromLTWH(0, 0, mask!.width.toDouble(), mask!.height.toDouble()),
        Rect.fromLTWH(0, 0, size.width, size.height),
        maskPaint);
  }

  @override
  bool shouldRepaint(PoseMaskPainter oldDelegate) {
    return oldDelegate.pose != pose ||
        oldDelegate.mask != mask ||
        oldDelegate.imageSize != imageSize;
  }

  List<List<PoseLandmarkType>> get connections => [
        [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow],
        [PoseLandmarkType.leftElbow, PoseLandmarkType.leftShoulder],
        [PoseLandmarkType.rightWrist, PoseLandmarkType.rightElbow],
        [PoseLandmarkType.leftWrist, PoseLandmarkType.leftElbow],




  ];
}