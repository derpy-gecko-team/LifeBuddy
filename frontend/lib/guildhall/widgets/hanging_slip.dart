import 'package:material_ui/material_ui.dart';

import '../theme/guild_theme.dart';
import 'sketch.dart';

class HangingSlip extends StatelessWidget {
  const HangingSlip({
    super.key,
    required this.child,
    this.hanging = true,
    this.padding = const EdgeInsets.fromLTRB(16, 13, 16, 13),
  });

  static const threadHeight = 16.0;

  final Widget child;
  final bool hanging;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _HangingSlipPainter(hanging: hanging),
      child: Padding(
        padding: padding.add(EdgeInsets.only(top: hanging ? threadHeight : 0)),
        child: child,
      ),
    );
  }
}

class _HangingSlipPainter extends CustomPainter {
  _HangingSlipPainter({required this.hanging});
  final bool hanging;

  @override
  void paint(Canvas canvas, Size size) {
    final top = hanging ? HangingSlip.threadHeight : 0.0;
    final rect = Rect.fromLTRB(0, top, size.width, size.height);
    final holes = [size.width * 0.14, size.width * 0.86];

    if (hanging) {
      final thread = Sketch.pen(GuildColors.chalk, 2);
      for (final x in holes) {
        canvas.drawLine(Offset(x, 3), Offset(x, top + 1), thread);
        canvas.drawCircle(Offset(x, 3), 3, Paint()..color = GuildColors.chalk);
      }
    }

    canvas.save();
    canvas.translate(0, top);
    final slip = Sketch.of(Sketch.box(rect.size, inset: 0.75), 5);
    slip.paintFill(canvas, GuildColors.parchment, shadow: GuildShadow.box);
    slip.paintBorder(canvas, color: GuildColors.pencil, width: 1.3);
    canvas.restore();

    canvas.drawRect(rect.deflate(5), Sketch.pen(GuildColors.tan, 2.4));
    canvas.drawRect(rect.deflate(9), Sketch.pen(GuildColors.tan, 1));
  }

  @override
  bool shouldRepaint(_HangingSlipPainter old) => old.hanging != hanging;
}
