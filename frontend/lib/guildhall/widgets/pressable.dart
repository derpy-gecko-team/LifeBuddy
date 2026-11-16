import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/guild_theme.dart';

class GuildPressable extends StatefulWidget {
  const GuildPressable({
    super.key,
    required this.onTap,
    this.child,
    this.builder,
    this.pressedScale = 0.96,
    this.haptic = false,
  }) : assert(child != null || builder != null);

  final VoidCallback? onTap;
  final Widget? child;

  final Widget Function(BuildContext context, bool pressed)? builder;
  final double pressedScale;
  final bool haptic;

  @override
  State<GuildPressable> createState() => _GuildPressableState();
}

class _GuildPressableState extends State<GuildPressable> {
  bool _pressed = false;

  void _set(bool v) {
    if (mounted && _pressed != v) setState(() => _pressed = v);
  }

  void _handleTap() {
    _set(true);
    Future<void>.delayed(GuildMotion.press, () => _set(false));
    if (widget.haptic) HapticFeedback.selectionClick();
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final pressed = enabled && _pressed;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => _set(true) : null,
      onTapCancel: enabled ? () => _set(false) : null,
      onTap: enabled ? _handleTap : null,
      child: AnimatedScale(
        scale: pressed ? widget.pressedScale : 1,
        duration: GuildMotion.press,
        curve: Curves.easeOut,
        child: widget.builder?.call(context, pressed) ?? widget.child,
      ),
    );
  }
}
