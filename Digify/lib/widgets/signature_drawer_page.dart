// lib/pages/signature_editor_page.dart
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:path_provider/path_provider.dart';

class SignatureEditorPage extends StatefulWidget {
  const SignatureEditorPage({Key? key}) : super(key: key);

  @override
  State<SignatureEditorPage> createState() => _SignatureEditorPageState();
}

class _SignatureEditorPageState extends State<SignatureEditorPage> {
  // RepaintBoundary key for exporting the strokes-only layer (transparent)
  final GlobalKey _exportKey = GlobalKey();

  // Strokes storage for undo/redo
  final List<_Stroke> _strokes = [];
  final List<_Stroke> _redoStack = [];

  // Current stroke being drawn
  _Stroke? _currentStroke;

  // Tool state
  bool _isEraser = false;
  double _strokeWidth = 4.0;
  Color _strokeColor = const Color(0xFF121212);

  // Preset colors
  static const List<Color> _presets = [
    Color(0xFF6B46C1), // purple
    Color(0xFFFF6B00), // orange
    Color(0xFFE91E63), // pink
    Colors.black,
  ];

  // ---------- Gesture handlers (use details.localPosition now) ----------
  void _handlePanStart(DragStartDetails details, BuildContext ctx) {
    // clear redo stack on new stroke
    _redoStack.clear();

    // local position inside the strokes area
    final RenderBox box = ctx.findRenderObject() as RenderBox;
    final local = box.globalToLocal(details.globalPosition);

    final paint = _buildPaint(
        isEraser: _isEraser, width: _strokeWidth, color: _strokeColor);
    final p = Path()..moveTo(local.dx, local.dy);
    _currentStroke = _Stroke(path: p, paint: paint);
    setState(() => _strokes.add(_currentStroke!));
  }

  void _handlePanUpdate(DragUpdateDetails details, BuildContext ctx) {
    final RenderBox box = ctx.findRenderObject() as RenderBox;
    final local = box.globalToLocal(details.globalPosition);
    setState(() {
      _currentStroke?.path.lineTo(local.dx, local.dy);
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    _currentStroke = null;
  }

  Paint _buildPaint(
      {required bool isEraser, required double width, required Color color}) {
    final paint = Paint()
      ..isAntiAlias = true
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    if (isEraser) {
      paint
        ..blendMode = BlendMode.clear
        ..color = Colors.transparent;
    } else {
      paint
        ..blendMode = BlendMode.srcOver
        ..color = color;
    }
    return paint;
  }

  // ---------- Commands ----------
  void _undo() {
    if (_strokes.isNotEmpty) {
      setState(() {
        _redoStack.add(_strokes.removeLast());
      });
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Nothing to undo')));
    }
  }

  void _redo() {
    if (_redoStack.isNotEmpty) {
      setState(() {
        _strokes.add(_redoStack.removeLast());
      });
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Nothing to redo')));
    }
  }

  void _clearAll() {
    setState(() {
      _strokes.clear();
      _redoStack.clear();
      _currentStroke = null;
    });
  }

  void _cut() {
    // placeholder
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Cut tool coming soon')));
  }

  void _copy() {
    // placeholder
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Copy tool coming soon')));
  }

  // color picker dialog
  Future<void> _pickAnyColor() async {
    Color temp = _strokeColor;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pick a color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: temp,
            onColorChanged: (c) => temp = c,
            enableAlpha: false,
            labelTypes: const [],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _strokeColor = temp;
                _isEraser = false;
              });
              Navigator.pop(ctx);
            },
            child: const Text('Select'),
          ),
        ],
      ),
    );
  }

  // Export transparent PNG and pop File via Navigator.pop(file)
  Future<void> _saveAndReturnFile() async {
    if (_strokes.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Nothing to save')));
      return;
    }

    try {
      // find the boundary of the strokes-only RepaintBoundary
      final boundary = _exportKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Export failed')));
        return;
      }

      // increase pixelRatio for sharpness
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/signature_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(pngBytes, flush: true);

      if (!mounted) return;
      Navigator.of(context).pop<File>(file);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Save error: $e')));
    }
  }

  // ---------- Build UI ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),
      appBar: AppBar(
        title: const Text('Direct signature'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () => Navigator.maybePop(context),
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.content_cut),
              tooltip: 'Cut',
              onPressed: _cut),
          IconButton(
              icon: const Icon(Icons.copy), tooltip: 'Copy', onPressed: _copy),
          IconButton(
              icon: const Icon(Icons.undo), tooltip: 'Undo', onPressed: _undo),
          IconButton(
              icon: const Icon(Icons.redo), tooltip: 'Redo', onPressed: _redo),
          IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Clear',
              onPressed: _clearAll),
          IconButton(
              icon: const Icon(Icons.check),
              tooltip: 'Save',
              onPressed: _saveAndReturnFile),
          const SizedBox(width: 6),
        ],
      ),

      // Canvas takes all flexible space between appBar and bottom controls
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Canvas container (centered, with rounded card and shadow like your screenshot)
            Expanded(
              child: Center(
                child: Container(
                  // Let it expand but set max width for comfortable look on large screens
                  constraints:
                      const BoxConstraints(minWidth: 320, maxWidth: 1100),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                        color: Colors.black.withOpacity(0.08),
                      ),
                    ],
                  ),
                  child: AspectRatio(
                    // Aspect ratio keeps shape; since this is Expanded, it will grow vertically on small screens.
                    aspectRatio: 16 / 9,
                    child: Stack(
                      children: [
                        // Grid + border painter (display only)
                        CustomPaint(
                          size: Size.infinite,
                          painter: _GridAndBorderPainter(),
                        ),

                        // Strokes layer inside a RepaintBoundary (transparent) -> export this only
                        RepaintBoundary(
                          key: _exportKey,
                          child: CustomPaint(
                            size: Size.infinite,
                            painter: _StrokesPainter(strokes: _strokes),
                          ),
                        ),

                        // Gesture area on top to capture touch events.
                        // Use LayoutBuilder to provide a context whose RenderBox we use (localPosition)
                        LayoutBuilder(
                          builder: (ctx, bc) {
                            return GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onPanStart: (d) => _handlePanStart(d, ctx),
                              onPanUpdate: (d) => _handlePanUpdate(d, ctx),
                              onPanEnd: _handlePanEnd,
                              child: Container(color: Colors.transparent),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Bottom toolbar container - fixed at bottom, no overflow
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                    color: Colors.black.withOpacity(0.05),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // First row: tools + colors
                  Row(
                    children: [
                      _ToolChip(
                        icon: Icons.brush,
                        label: '',
                        selected: !_isEraser,
                        onTap: () => setState(() => _isEraser = false),
                      ),
                      const SizedBox(width: 8),
                      _ToolChip(
                        icon: Icons.auto_fix_off,
                        label: '',
                        selected: _isEraser,
                        onTap: () => setState(() => _isEraser = true),
                      ),
                      const SizedBox(width: 12),
                      // color dots - put in flexible Row to prevent overflow
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (final c in _presets) _colorDot(c),
                              IconButton(
                                tooltip: 'Pick any color',
                                onPressed: _pickAnyColor,
                                icon: const Icon(Icons.add_circle_outline),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Second row: stroke slider - uses Flexible to avoid overflow
                  Row(
                    children: [
                      const Icon(Icons.tune, size: 20),
                      const SizedBox(width: 8),
                      const Text('Stroke'),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Slider(
                          value: _strokeWidth,
                          min: 1,
                          max: 28,
                          onChanged: (v) => setState(() => _strokeWidth = v),
                        ),
                      ),
                      SizedBox(
                        width: 48,
                        child: Text(
                          '${_strokeWidth.toStringAsFixed(0)} px',
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // small helper to build a color dot
  Widget _colorDot(Color c) {
    final selected = !_isEraser && c.value == _strokeColor.value;
    return InkWell(
      onTap: () => setState(() {
        _isEraser = false;
        _strokeColor = c;
      }),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            width: selected ? 3 : 1.2,
            color: selected ? Colors.black : Colors.grey.shade400,
          ),
        ),
        child: ClipOval(
          child: Container(width: 28, height: 28, color: c),
        ),
      ),
    );
  }
}

// ===== Models and Painters =====

class _Stroke {
  final Path path;
  final Paint paint;
  _Stroke({required this.path, required this.paint});
}

// Painter that draws strokes and handles eraser by saving layer
class _StrokesPainter extends CustomPainter {
  final List<_Stroke> strokes;
  const _StrokesPainter({required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    // Use saveLayer so BlendMode.clear (eraser) works properly
    final Paint layerPaint = Paint();
    canvas.saveLayer(Offset.zero & size, layerPaint);

    for (final s in strokes) {
      canvas.drawPath(s.path, s.paint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _GridAndBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Soft white background for display only (not exported)
    final Paint bg = Paint()..color = Colors.white;
    canvas.drawRect(Offset.zero & size, bg);

    // Subtle grid lines
    final Paint grid = Paint()
      ..color = Colors.black.withOpacity(0.04)
      ..strokeWidth = 1;
    const double gap = 24.0;
    for (double x = 0; x <= size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y <= size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    // Rounded border
    final Paint border = Paint()
      ..color = Colors.black.withOpacity(0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final RRect rrect =
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(8));
    canvas.drawRRect(rrect, border);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ToolChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ToolChip({
    Key? key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bg = selected ? Colors.black : Colors.white;
    final fg = selected ? Colors.white : Colors.black;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? Colors.black : Colors.grey.shade400,
              width: 1.0),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: fg),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: fg, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
