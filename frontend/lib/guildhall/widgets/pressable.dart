import 'package:material_ui/material_ui.dart';
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
    this.semanticLabel,
    this.semanticEnabled,
    this.selected,
    this.toggled,
    this.checked,
  }) : assert(child != null || builder != null);

  final VoidCallback? onTap;
  final Widget? child;

  final Widget Function(BuildContext context, bool pressed)? builder;
  final double pressedScale;
  final bool haptic;

  final String? semanticLabel;
  final bool? semanticEnabled;
  final bool? selected;
  final bool? toggled;
  final bool? checked;

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
    final label = widget.semanticLabel;
    final Widget detector = GestureDetector(
      behavior: HitTestBehavior.opaque,
      excludeFromSemantics: label != null,
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
    if (label == null) return detector;
    return Semantics(
      button: widget.checked == null,
      enabled: widget.semanticEnabled,
      selected: widget.selected,
      toggled: widget.toggled,
      checked: widget.checked,
      label: label,
      onTap: enabled ? _handleTap : null,
      excludeSemantics: true,
      child: detector,
    );
  }
}
