import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/guild_theme.dart';
import 'guild_icons.dart';
import 'ornaments.dart';
import 'pressable.dart';
import 'sketch.dart';
import 'torn_paper.dart';

enum GuildButtonKind {
  primary(GuildColors.brickDeep, GuildColors.cream, GuildColors.brickShade),

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

  static const disabledFill = GuildColors.indigo;
  static const disabledText = Color(0xDBEFE0BC);

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final fill = enabled ? kind.fill : GuildButton.disabledFill;
    final text = enabled ? kind.text : GuildButton.disabledText;
    final border = enabled ? kind.border : GuildColors.chalkLine;

    return GuildPressable(
      semanticEnabled: enabled,
      semanticLabel: label,
      onTap: onPressed,
      haptic: true,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: 56, minWidth: expand ? double.infinity : 0),
        child: SketchBox(
          color: fill,
          borderColor: border,
          shadow: enabled ? GuildShadow.box : null,
          shading: enabled,
          seed: stableSeed(label),
          padding: const EdgeInsets.symmetric(horizontal: GuildSpace.xl, vertical: GuildSpace.md),
          child: Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (glyph != null) ...[
                GuildIcon(glyph!, size: 20, color: text),
                const SizedBox(width: GuildSpace.sm),
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
    );
  }
}

class GuildIconButton extends StatelessWidget {
  const GuildIconButton({
    super.key,
    required this.semanticLabel,
    required this.onTap,
    required this.child,
    this.toggled,
  });

  final String semanticLabel;
  final VoidCallback? onTap;
  final Widget child;
  final bool? toggled;

  @override
  Widget build(BuildContext context) {
    return GuildPressable(
      semanticLabel: semanticLabel,
      toggled: toggled,
      onTap: onTap,
      haptic: true,
      pressedScale: 0.92,
      child: SketchBox(
        color: GuildColors.indigoDeep,
        borderColor: GuildColors.chalkLine,
        seed: 3,
        child: SizedBox.square(dimension: 56, child: Center(child: child)),
      ),
    );
  }
}

class GuildFootnote extends StatelessWidget {
  const GuildFootnote(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Center(
        child: Text(text, textAlign: TextAlign.center, style: GuildText.aside(GuildType.sm)),
      ),
    );
  }
}

class GuildActionBar extends StatelessWidget {
  const GuildActionBar({super.key, required this.main, required this.below, this.leading});

  final Widget? leading;
  final Widget main;
  final Widget below;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(GuildSpace.gutter, GuildSpace.md, GuildSpace.gutter, GuildSpace.xs),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: GuildSpace.md),
              ],
              Expanded(child: main),
            ],
          ),
          const SizedBox(height: GuildSpace.xs),
          below,
        ],
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
                Text(title, textAlign: TextAlign.center, style: GuildText.title(GuildTitle.xl)),
                if (message != null) ...[
                  const SizedBox(height: GuildSpace.sm),
                  Text(message!, textAlign: TextAlign.center, style: GuildText.body(GuildType.md)),
                ],
                if (busy) ...[
                  const SizedBox(height: GuildSpace.lg),
                  const InkDots(),
                ],
                if (action != null) ...[
                  const SizedBox(height: GuildSpace.xl),
                  action!,
                ],
              ],
            ),
          ),
          const Positioned(top: -6, child: Fastener(kind: FastenerKind.pin)),
        ],
      ),
    );
  }
}

class GuildLink extends StatelessWidget {
  const GuildLink({
    super.key,
    required this.label,
    required this.onTap,
    this.color = GuildColors.brickDeep,
    this.size = GuildType.md,
  });

  final String label;
  final VoidCallback onTap;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GuildPressable(
      semanticLabel: label,
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Center(
          child: Text(
            label,
            style: GuildText.body(size, color: color).copyWith(
              decoration: TextDecoration.underline,
              decorationColor: color,
            ),
          ),
        ),
      ),
    );
  }
}

class InkDots extends StatefulWidget {
  const InkDots({super.key});

  @override
  State<InkDots> createState() => _InkDotsState();
}

class _InkDotsState extends State<InkDots> with SingleTickerProviderStateMixin {
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
            Text(title, textAlign: TextAlign.center, style: GuildText.title(GuildTitle.xl)),
            const SizedBox(height: GuildSpace.md),
            Text(message, textAlign: TextAlign.center, style: GuildText.body(GuildType.md)),
            const SizedBox(height: GuildSpace.xxl),
            GuildButton(label: cancelLabel, onPressed: () => Navigator.pop(context, false)),
            const SizedBox(height: GuildSpace.sm),
            GuildLink(label: confirmLabel, onTap: () => Navigator.pop(context, true)),
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
    reverseDuration: GuildMotion.swift,
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
