import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/guild_theme.dart';

class NoticeRoute<T> extends PageRouteBuilder<T> {
  NoticeRoute({required WidgetBuilder builder, Rect? origin, double tilt = 0})
      : super(
          transitionDuration: GuildMotion.page,
          reverseTransitionDuration: GuildMotion.pageBack,
          pageBuilder: (context, _, _) => EdgeSwipeBack(child: builder(context)),
          transitionsBuilder: (context, animation, _, child) {
            if (origin == null || MediaQuery.disableAnimationsOf(context)) {
              return FadeTransition(opacity: animation, child: child);
            }
            final size = MediaQuery.sizeOf(context);
            final alignment = Alignment(
              (origin.center.dx / size.width) * 2 - 1,
              (origin.center.dy / size.height) * 2 - 1,
            );
            final ease = CurveTween(curve: Curves.easeOutCubic);
            final startScale = (origin.width / size.width).clamp(0.3, 0.9);
            return FadeTransition(
              opacity: animation.drive(CurveTween(curve: const Interval(0, 0.35))),
              child: ScaleTransition(
                alignment: alignment,
                scale: animation.drive(Tween(begin: startScale, end: 1.0).chain(ease)),
                child: RotationTransition(
                  alignment: alignment,
                  turns: animation.drive(Tween(begin: tilt / (2 * pi), end: 0.0).chain(ease)),
                  child: child,
                ),
              ),
            );
          },
        );
}

class PlaqueRoute<T> extends PageRouteBuilder<T> {
  PlaqueRoute({required WidgetBuilder builder, Rect? origin})
      : super(
          transitionDuration: GuildMotion.page,
          reverseTransitionDuration: GuildMotion.pageBack,
          pageBuilder: (context, _, _) => EdgeSwipeBack(child: builder(context)),
          transitionsBuilder: (context, animation, _, child) {
            if (origin == null || MediaQuery.disableAnimationsOf(context)) {
              return FadeTransition(opacity: animation, child: child);
            }
            final size = MediaQuery.sizeOf(context);
            final alignment = Alignment(
              (origin.center.dx / size.width) * 2 - 1,
              (origin.center.dy / size.height) * 2 - 1,
            );
            return FadeTransition(
              opacity: animation.drive(CurveTween(curve: const Interval(0, 0.5, curve: Curves.easeOut))),
              child: ScaleTransition(
                alignment: alignment,
                scale: animation.drive(
                  Tween(begin: 0.97, end: 1.0).chain(CurveTween(curve: GuildMotion.easeOut)),
                ),
                child: child,
              ),
            );
          },
        );
}

class EdgeSwipeBack extends StatefulWidget {
  const EdgeSwipeBack({super.key, required this.child});

  final Widget child;

  @override
  State<EdgeSwipeBack> createState() => _EdgeSwipeBackState();
}

class _EdgeSwipeBackState extends State<EdgeSwipeBack> {
  double _dragged = 0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: 22,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragStart: (_) => _dragged = 0,
            onHorizontalDragUpdate: (d) => _dragged += d.delta.dx,
            onHorizontalDragEnd: (d) {
              if (_dragged > 70 || (d.primaryVelocity ?? 0) > 500) {
                Navigator.of(context).maybePop();
              }
            },
          ),
        ),
      ],
    );
  }
}

typedef OpenQuest = Future<void> Function(String questId, {Rect? origin, double tilt});

typedef OpenJourney = void Function(String journeyId, {Rect? origin});

Rect? globalRectOf(BuildContext context) {
  final box = context.findRenderObject();
  if (box is! RenderBox || !box.hasSize) return null;
  return box.localToGlobal(Offset.zero) & box.size;
}
