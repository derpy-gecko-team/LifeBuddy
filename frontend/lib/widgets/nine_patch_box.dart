import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

/// Draws [asset] as a nine-patch frame behind [child].
///
/// Corners keep their shape; only the edges and the middle stretch, so one
/// hand-drawn PNG fits any width and height. Reuse it for any framed thing
/// (text fields, quest cards, signs).
///
/// Unlike Flutter's `DecorationImage.centerSlice`, the slice is computed from
/// the image's real size at runtime, so a wrong pixel guess can no longer
/// leave the border unstretched. Tune [slice] and [imageScale] by eye.
class NinePatchBox extends StatefulWidget {
  const NinePatchBox({
    super.key,
    required this.asset,
    required this.child,
    this.slice,
    this.imageScale = 3,
    this.padding = EdgeInsets.zero,
  });

  final String asset;
  final Widget child;

  /// Width of the band that must NOT stretch (the corner artwork), measured in
  /// IMAGE pixels. null = 40% of the image height on every side.
  final EdgeInsets? slice;

  /// Image pixels per logical pixel. Higher = smaller, thinner border.
  /// 3 is crisp on most phones.
  final double imageScale;

  final EdgeInsetsGeometry padding;

  @override
  State<NinePatchBox> createState() => _NinePatchBoxState();
}

class _NinePatchBoxState extends State<NinePatchBox> {
  ImageStream? _stream;
  ImageInfo? _info;
  late final ImageStreamListener _listener = ImageStreamListener(_onImage);

  void _onImage(ImageInfo info, bool synchronousCall) {
    final previous = _info;
    _info = info.clone();
    previous?.dispose();
    // A synchronous call happens during didChangeDependencies, right before
    // build, so no setState is needed.
    if (!synchronousCall && mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _subscribe();
  }

  @override
  void didUpdateWidget(NinePatchBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.asset != widget.asset) _subscribe();
  }

  void _subscribe() {
    final next = AssetImage(
      widget.asset,
    ).resolve(createLocalImageConfiguration(context));
    if (next.key == _stream?.key) return;
    _stream?.removeListener(_listener);
    _stream = next..addListener(_listener);
  }

  @override
  void dispose() {
    _stream?.removeListener(_listener);
    _info?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final info = _info;
    return CustomPaint(
      painter: info == null
          ? null
          : _NinePatchPainter(
              image: info.image,
              slice: widget.slice,
              scale: widget.imageScale,
            ),
      child: Padding(padding: widget.padding, child: widget.child),
    );
  }
}

class _NinePatchPainter extends CustomPainter {
  const _NinePatchPainter({
    required this.image,
    required this.slice,
    required this.scale,
  });

  final ui.Image image;
  final EdgeInsets? slice;
  final double scale;

  double _clamp(double v, double length) =>
      v.clamp(1.0, length / 2 - 1).toDouble();

  @override
  void paint(Canvas canvas, Size size) {
    final w = image.width.toDouble();
    final h = image.height.toDouble();
    final s = slice ?? EdgeInsets.all(h * 0.4);

    final center = Rect.fromLTRB(
      _clamp(s.left, w),
      _clamp(s.top, h),
      w - _clamp(s.right, w),
      h - _clamp(s.bottom, h),
    );

    // Work in image pixels: shrink the canvas by [scale] and draw into a
    // destination that is [scale] times larger.
    canvas
      ..save()
      ..scale(1 / scale)
      ..drawImageNine(
        image,
        center,
        Offset.zero & (size * scale),
        Paint()..filterQuality = FilterQuality.medium,
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_NinePatchPainter old) =>
      old.image != image || old.slice != slice || old.scale != scale;
}
