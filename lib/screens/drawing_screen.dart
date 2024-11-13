import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class DrawingScreen extends StatefulWidget {
  final String? initialDrawing;
  final bool isFromHomeScreen;

  DrawingScreen({this.initialDrawing, this.isFromHomeScreen = false});

  @override
  _DrawingScreenState createState() => _DrawingScreenState();
}

class _DrawingScreenState extends State<DrawingScreen> {
  List<DrawingPoint?> points = [];
  Color selectedColor = Colors.white;
  double strokeWidth = 3.0;
  DrawingTool currentTool = DrawingTool.pen;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            if (widget.isFromHomeScreen) {
              Navigator.pop(context);
              Navigator.pop(context);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.undo),
            onPressed: points.isEmpty ? null : _undo,
          ),
          IconButton(
            icon: Icon(Icons.redo),
            onPressed: null, // Implement redo functionality
          ),
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveDrawing,
          ),
        ],
      ),
      body: Container(
        // color: Colors.white,
        child: Stack(
          children: [
            GestureDetector(
              onPanStart: (details) {
                setState(() {
                  points.add(
                    DrawingPoint(
                      offset: details.localPosition,
                      paint: Paint()
                        ..color = selectedColor
                        ..isAntiAlias = true
                        ..strokeWidth = strokeWidth
                        ..strokeCap = StrokeCap.round,
                    ),
                  );
                });
              },
              onPanUpdate: (details) {
                setState(() {
                  points.add(
                    DrawingPoint(
                      offset: details.localPosition,
                      paint: Paint()
                        ..color = selectedColor
                        ..isAntiAlias = true
                        ..strokeWidth = strokeWidth
                        ..strokeCap = StrokeCap.round,
                    ),
                  );
                });
              },
              onPanEnd: (details) {
                setState(() {
                  points.add(null);
                });
              },
              child: CustomPaint(
                painter: DrawingPainter(points: points),
                size: Size.infinite,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: Icon(Icons.crop_square_outlined),
                      onPressed: () =>
                          setState(() => currentTool = DrawingTool.select),
                      color: currentTool == DrawingTool.select
                          ? Colors.blue
                          : null,
                    ),
                    IconButton(
                      icon: Icon(Icons.edit_outlined),
                      onPressed: () =>
                          setState(() => currentTool = DrawingTool.pen),
                      color:
                          currentTool == DrawingTool.pen ? Colors.blue : null,
                    ),
                    IconButton(
                      icon: Icon(Icons.brush),
                      onPressed: () =>
                          setState(() => currentTool = DrawingTool.brush),
                      color:
                          currentTool == DrawingTool.brush ? Colors.blue : null,
                    ),
                    IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () =>
                          setState(() => currentTool = DrawingTool.marker),
                      color: currentTool == DrawingTool.marker
                          ? Colors.blue
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _undo() {
    setState(() {
      final lastNull = points.lastIndexOf(null);
      if (lastNull != -1) {
        points.removeRange(lastNull, points.length);
      } else {
        points.clear();
      }
    });
  }

  Future<void> _saveDrawing() async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final painter = DrawingPainter(points: points);
      painter.paint(
          canvas,
          Size(MediaQuery.of(context).size.width,
              MediaQuery.of(context).size.height));
      final picture = recorder.endRecording();
      final img = await picture.toImage(
        MediaQuery.of(context).size.width.toInt(),
        MediaQuery.of(context).size.height.toInt(),
      );
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      final buffer = byteData!.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = File(
          '${tempDir.path}/drawing_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(buffer);

      Navigator.pop(context, file.path);
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save drawing')),
      );
    }
  }
}

enum DrawingTool { select, pen, brush, marker }

class DrawingPoint {
  final Offset offset;
  final Paint paint;

  DrawingPoint({
    required this.offset,
    required this.paint,
  });
}

class DrawingPainter extends CustomPainter {
  final List<DrawingPoint?> points;

  DrawingPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(
            points[i]!.offset, points[i + 1]!.offset, points[i]!.paint);
      } else if (points[i] != null && points[i + 1] == null) {
        canvas.drawPoints(
          ui.PointMode.points,
          [points[i]!.offset],
          points[i]!.paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
