import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../theme/guild_theme.dart';
import 'guild_icons.dart';
import 'pressable.dart';
import 'sketch.dart';
import 'torn_paper.dart';

enum GuildButtonKind {
  primary(GuildColors.brick, GuildColors.cream, GuildColors.brickDeep),

  reward(GuildColors.gold, GuildColors.ink, GuildColors.bronze),

  quiet(GuildColors.indigoDeep, GuildColors.cream, GuildColors.chalkLine);

  const GuildButtonKind(this.fill, this.text, this.border);
  final Color fill;
  final Color text;
  final Color border;
}

class GuildButton extends StatelessWidget {
  const GuildButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.kind = GuildButtonKind.primary,
    this.glyph,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final GuildButtonKind kind;
  final GuildGlyph? glyph;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final fill = enabled ? kind.fill : GuildColors.indigoDeep;
    final text = enabled ? kind.text : GuildColors.cream.withValues(alpha: 0.72);
    final border = enabled ? kind.border : GuildColors.chalkLine;

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: GuildPressable(
        onTap: onPressed,
        haptic: true,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: 56, minWidth: expand ? double.infinity : 0),
          child: SketchBox(
            color: fill,
            borderColor: border,
            shadow: enabled ? const Offset(2, 3) : null,
            seed: stableSeed(label),
            padding: const EdgeInsets.symmetric(horizontal: 20.5, vertical: 12.5),
            child: Row(
              mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (glyph != null) ...[
                  GuildIcon(glyph!, size: 20, color: text),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: GuildText.label(GuildType.md, color: text, spacing: 1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GuildNote extends StatelessWidget {
  const GuildNote({
    super.key,
    required this.title,
    this.message,
    this.action,
    this.busy = false,
  });

  final String title;
  final String? message;
  final Widget? action;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          TornPaper(
            seed: 11,
            padding: const EdgeInsets.fromLTRB(24, 30, 24, 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, textAlign: TextAlign.center, style: GuildText.title(GuildType.xl)),
                if (message != null) ...[
                  const SizedBox(height: 8),
                  Text(message!, textAlign: TextAlign.center, style: GuildText.body(GuildType.md)),
                ],
                if (busy) ...[
                  const SizedBox(height: 16),
                  const _InkDots(),
                ],
                if (action != null) ...[
                  const SizedBox(height: 20),
                  action!,
                ],
              ],
            ),
          ),
          const Positioned(top: -6, child: _Nail()),
        ],
      ),
    );
  }
}

class _Nail extends StatelessWidget {
  const _Nail();

  @override
  Widget build(BuildContext context) => Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: GuildColors.brick,
          border: Border.all(color: GuildColors.brickDeep, width: 1),
          boxShadow: [BoxShadow(color: GuildColors.shadow.withValues(alpha: 0.45), offset: const Offset(1, 2))],
        ),
      );
}

class _InkDots extends StatefulWidget {
  const _InkDots();

  @override
  State<_InkDots> createState() => _InkDotsState();
}

class _InkDotsState extends State<_InkDots> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading',
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: GuildColors.ink.withValues(
                    alpha: 0.25 + 0.75 * (1 - ((_c.value * 3 - i).abs().clamp(0, 1))),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

Future<bool> showGuildConfirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  required String cancelLabel,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierColor: GuildColors.shadow.withValues(alpha: 0.7),
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(28),
      child: TornPaper(
        seed: 23,
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, textAlign: TextAlign.center, style: GuildText.title(GuildType.xl)),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center, style: GuildText.body(GuildType.md)),
            const SizedBox(height: 22),
            GuildButton(label: cancelLabel, onPressed: () => Navigator.pop(context, false)),
            const SizedBox(height: 6),
            Semantics(
              button: true,
              label: confirmLabel,
              excludeSemantics: true,
              child: GuildPressable(
                onTap: () => Navigator.pop(context, true),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Center(
                    child: Text(
                      confirmLabel,
                      style: GuildText.body(GuildType.md, color: GuildColors.brickDeep).copyWith(
                        decoration: TextDecoration.underline,
                        decorationColor: GuildColors.brickDeep,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  return result ?? false;
}

OverlayEntry? _currentToast;

void showGuildToast(BuildContext context, String message) {
  _currentToast?.remove();
  _currentToast = null;

  final overlay = Overlay.of(context, rootOverlay: true);
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _GuildToast(
      message: message,
      onDone: () {
        if (_currentToast == entry) {
          _currentToast = null;
          entry.remove();
        }
      },
    ),
  );
  _currentToast = entry;
  overlay.insert(entry);
}

class _GuildToast extends StatefulWidget {
  const _GuildToast({required this.message, required this.onDone});

  final String message;
  final VoidCallback onDone;

  @override
  State<_GuildToast> createState() => _GuildToastState();
}

class _GuildToastState extends State<_GuildToast> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: GuildMotion.quick,
    reverseDuration: const Duration(milliseconds: 160),
  );
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _c.forward();
    _timer = Timer(const Duration(milliseconds: 3500), _dismiss);
  }

  Future<void> _dismiss() async {
    _timer?.cancel();
    if (!mounted) return;
    await _c.reverse();
    if (mounted) widget.onDone();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    final slide = _c.drive(
      Tween(begin: reduced ? Offset.zero : const Offset(0, -1.2), end: Offset.zero)
          .chain(CurveTween(curve: Curves.easeOutCubic)),
    );
    return Positioned(
      top: MediaQuery.paddingOf(context).top + 8,
      left: 16,
      right: 16,
      child: Material(
        type: MaterialType.transparency,
        child: SlideTransition(
          position: slide,
          child: FadeTransition(
            opacity: _c,
            child: Semantics(
              liveRegion: true,
              child: GestureDetector(
                onTap: _dismiss,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: TornPaper(
                      color: GuildColors.mist,
                      seed: 5,
                      tear: 4,
                      tearBottom: 8,
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                      child: Text(
                        widget.message,
                        textAlign: TextAlign.center,
                        style: GuildText.body(GuildType.md, color: GuildColors.ink),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
