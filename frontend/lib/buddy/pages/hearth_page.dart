import 'dart:math';
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../guildhall/widgets/guild_feedback.dart';
import '../../guildhall/widgets/pressable.dart';
import '../data/buddy_repository.dart';
import '../data/models.dart';
import '../state/buddy_controller.dart';
import '../theme/buddy_theme.dart';
import '../widgets/writing_scroll.dart';

/// The Buddy's campfire: Pip lounging on a card with the last thing it said,
/// a horn to call it, and a line to write on.
///
/// Laid out from the Figma frame "Buddy – Idle v4" (393 wide, 762 tall above
/// the tab bar). Every number below is in that frame's units and multiplied
/// by the scale that fits the frame to the screen.
class HearthPage extends StatefulWidget {
  const HearthPage({super.key, required this.controller, this.onOpenGuildHall, this.onOpenMap, this.onHeyPip});

  final BuddyController controller;

  final VoidCallback? onOpenGuildHall;
  final VoidCallback? onOpenMap;

  /// The horn. Voice comes in a later step.
  final VoidCallback? onHeyPip;

  static const greeting = 'Oh, look who finally crawled out of bed. So… dragons or dishes today?';

  @override
  State<HearthPage> createState() => _HearthPageState();
}

class _HearthPageState extends State<HearthPage> with SingleTickerProviderStateMixin {
  static const _frameWidth = 393.0;
  static const _frameHeight = 762.0;

  /// The status bar the frame was drawn with.
  static const _frameTop = 47.0;

  // The scene keeps the height it had before the keyboard came up, so that
  // nothing in it moves or is laid out again while the keyboard slides in.
  double _width = 0;
  double _fullHeight = 0;

  // Writing: a tap on the line slowly unrolls it into a scroll in the place
  // of Pip's card, which fades to make room. The keyboard is only called once
  // the scroll lies open, and on the way back it leaves before the scroll
  // rolls up: the two never animate at once, which stutters on real phones.
  static const _unhurried = Duration(milliseconds: 650);
  static const _keyboardLeaves = Duration(milliseconds: 240);
  final _focus = FocusNode();
  late final AnimationController _writing = AnimationController(vsync: this, duration: _unhurried);
  late final Animation<double> _open = CurvedAnimation(parent: _writing, curve: Curves.easeInOutCubic);

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _writing.duration = MediaQuery.disableAnimationsOf(context) ? Duration.zero : _unhurried;
    _writing.reverseDuration = _writing.duration;
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    _focus.dispose();
    _writing.dispose();
    super.dispose();
  }

  void _startWriting() {
    _writing.forward().whenComplete(() {
      if (mounted && _writing.isCompleted) _focus.requestFocus();
    });
  }

  void _stopWriting() {
    if (_focus.hasFocus) {
      _focus.unfocus(); // and [_onFocus] rolls the scroll up
    } else {
      _writing.reverse();
    }
  }

  void _onFocus() {
    if (_focus.hasFocus) {
      _writing.forward();
      return;
    }
    Future<void>.delayed(_writing.duration == Duration.zero ? Duration.zero : _keyboardLeaves, () {
      if (mounted && !_focus.hasFocus) _writing.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.paddingOf(context).top;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Material(
        color: BuddyColors.night,
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth != _width) {
              _width = constraints.maxWidth;
              _fullHeight = constraints.maxHeight;
            } else if (constraints.maxHeight > _fullHeight) {
              _fullHeight = constraints.maxHeight;
            }
            final byWidth = _width / _frameWidth;
            final byHeight = (_fullHeight - safeTop) / (_frameHeight - _frameTop);
            final s = min(byWidth, byHeight).clamp(0.6, 1.35);
            final frameTop = safeTop - _frameTop * s;
            // Rolled up, the writing line sits at the foot of the page.
            // Unrolled, it hangs from the card's top edge under Pip, as long
            // as a usual keyboard leaves room for (about three fifths of the
            // way down the screen). Nothing here looks at the keyboard: it
            // slides over the foot of the page and the scene does not move.
            final rolledTop = _fullHeight - 66 * s;
            final unrolledTop = frameTop + 250 * s;
            final scrollHeight = 270 * s;

            return GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _stopWriting,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRect(
                    child: OverflowBox(
                      alignment: Alignment.topCenter,
                      minHeight: _fullHeight,
                      maxHeight: _fullHeight,
                      child: _Scene(
                        s: s,
                        top: frameTop,
                        hush: _open,
                        controller: widget.controller,
                        onOpenGuildHall: widget.onOpenGuildHall,
                        onOpenMap: widget.onOpenMap,
                        onHeyPip: widget.onHeyPip,
                      ),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _open,
                    builder: (context, line) => Positioned(
                      left: (_width - _frameWidth * s) / 2 + 24 * s,
                      width: 345 * s,
                      top: lerpDouble(rolledTop, unrolledTop, _open.value),
                      child: line!,
                    ),
                    child: _WritingLine(
                      s: s,
                      controller: widget.controller,
                      focusNode: _focus,
                      open: _open,
                      openHeight: scrollHeight,
                      onStart: _startWriting,
                    ),
                  ),
                  // Pip lies on the card's top edge, paws and tail hanging
                  // over it. Drawn last, so it lies on the open sheet too.
                  Positioned(
                    left: (_width - _frameWidth * s) / 2 + 32 * s,
                    top: frameTop + 78 * s,
                    child: IgnorePointer(
                      child: Image.asset(
                        BuddyAssets.pip,
                        width: 334 * s,
                        semanticLabel: 'Pip, a black cat in a feathered cap',
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Scene extends StatelessWidget {
  const _Scene({
    required this.s,
    required this.top,
    required this.hush,
    required this.controller,
    this.onOpenGuildHall,
    this.onOpenMap,
    this.onHeyPip,
  });

  final double s;

  /// Where the frame's y = 0 falls on the screen: the frame was drawn under a
  /// 47 point status bar, this screen may have another.
  final double top;

  /// 0 while Pip has the floor, 1 while the hero is writing: the card fades
  /// out as this rises.
  final Animation<double> hush;

  final BuddyController controller;
  final VoidCallback? onOpenGuildHall;
  final VoidCallback? onOpenMap;
  final VoidCallback? onHeyPip;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        // The card may grow until it would touch the horn.
        final cardTop = top + 250 * s;
        final hornTop = height - 306 * s;
        final cardRoom = (hornTop - cardTop).clamp(150 * s, double.infinity);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // The forest was painted 90 points taller than the page, down
            // behind the tab bar; keep that so the clearing meets the fire.
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              bottom: -90 * s,
              child: const ExcludeSemantics(
                child: Image(
                  image: AssetImage(BuddyAssets.forest),
                  fit: BoxFit.cover,
                  alignment: Alignment.bottomCenter,
                ),
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: 393 * s,
                height: height,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 32 * s,
                      child: ExcludeSemantics(child: Image.asset(BuddyAssets.campfire, width: 393 * s)),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: top + 56 * s,
                      child: _HistoryHint(s: s),
                    ),
                    Positioned(
                      left: 24 * s,
                      right: 24 * s,
                      top: cardTop,
                      child: AnimatedBuilder(
                        animation: hush,
                        builder: (context, card) => IgnorePointer(
                          ignoring: hush.value > 0.5,
                          child: Opacity(opacity: 1 - hush.value, child: card),
                        ),
                        child: _SpeechCard(
                          s: s,
                          maxHeight: cardRoom,
                          controller: controller,
                          onOpenGuildHall: onOpenGuildHall,
                          onOpenMap: onOpenMap,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 140 * s,
                      child: Center(
                        child: _Horn(s: s, onTap: onHeyPip),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HistoryHint extends StatelessWidget {
  const _HistoryHint({required this.s});

  final double s;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.55,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ExcludeSemantics(child: Image.asset(BuddyAssets.cloud, width: 20 * s)),
          SizedBox(width: 7 * s),
          Flexible(
            child: Text(
              'Old chatter rises with the smoke · pull down',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: BuddyText.hand(14.5 * s, color: BuddyColors.cream, height: 1.2),
            ),
          ),
        ],
      ),
    );
  }
}

/// What Pip has to say right now. Only ever its latest line; older ones are
/// up in the smoke.
class _SpeechCard extends StatelessWidget {
  const _SpeechCard({
    required this.s,
    required this.maxHeight,
    required this.controller,
    this.onOpenGuildHall,
    this.onOpenMap,
  });

  final double s;
  final double maxHeight;
  final BuddyController controller;
  final VoidCallback? onOpenGuildHall;
  final VoidCallback? onOpenMap;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final undelivered = controller.undelivered;
        final latest = controller.latestFromBuddy;

        final String mood;
        final Widget body;
        final Object turn;
        if (controller.replying) {
          mood = 'thinking it over';
          turn = 'thinking';
          body = Padding(
            padding: EdgeInsets.symmetric(vertical: 12 * s),
            child: const Align(alignment: Alignment.centerLeft, child: InkDots()),
          );
        } else if (undelivered != null) {
          mood = 'ears twitching';
          turn = 'lost-${undelivered.id}';
          body = _Lines(
            s: s,
            text: 'The wind ate your words before they reached me.',
            links: [(label: 'Say it again', onTap: () => controller.retry(undelivered.id))],
          );
        } else {
          mood = 'smug as ever';
          turn = latest?.id ?? 'greeting';
          final tile = latest?.newMapTile;
          body = _Lines(
            s: s,
            text: latest?.text ?? HearthPage.greeting,
            links: [
              for (final quest in latest?.updatedQuests ?? const <QuestUpdate>[])
                (label: 'On the board: ${quest.title}', onTap: onOpenGuildHall),
              if (tile != null) (label: 'New on your map: a ${tile.typeLabel} tile', onTap: onOpenMap),
            ],
          );
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: double.infinity,
              constraints: BoxConstraints(minHeight: min(197 * s, maxHeight), maxHeight: maxHeight),
              decoration: BoxDecoration(
                color: BuddyColors.card,
                borderRadius: BorderRadius.circular(26 * s),
                border: Border.all(color: BuddyColors.outline, width: 3 * s),
                boxShadow: [BoxShadow(color: BuddyColors.outline, offset: Offset(0, 6 * s))],
              ),
              padding: EdgeInsets.fromLTRB(27 * s, 44 * s, 27 * s, 14 * s),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        'PIP',
                        style: BuddyText.serif(15 * s, color: BuddyColors.name, spacing: 1.6 * s),
                      ),
                      Flexible(
                        child: Text(
                          '  ·  $mood',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: BuddyText.hand(15 * s, color: BuddyColors.inkFaded, height: 1),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8 * s),
                  Flexible(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      switchInCurve: Curves.easeOut,
                      layoutBuilder: (current, previous) =>
                          Stack(alignment: Alignment.topLeft, children: [...previous, ?current]),
                      child: KeyedSubtree(key: ValueKey(turn), child: body),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: -12 * s,
              bottom: -19 * s,
              child: ExcludeSemantics(child: Image.asset(BuddyAssets.pawSeal, width: 48 * s)),
            ),
          ],
        );
      },
    );
  }
}

typedef _Link = ({String label, VoidCallback? onTap});

/// Pip's words, and under them whatever they led to: a quest on the board, a
/// tile on the map, a way to say it again.
class _Lines extends StatelessWidget {
  const _Lines({required this.s, required this.text, this.links = const []});

  final double s;
  final String text;
  final List<_Link> links;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // A long answer scrolls inside the card and fades out at its foot,
        // so it reads as "there is more" rather than as cut off.
        Flexible(
          child: ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (bounds) => LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: const [Colors.white, Colors.white, Colors.transparent],
              stops: [0, 1 - (10 * s / bounds.height).clamp(0.0, 0.5), 1],
            ).createShader(bounds),
            child: SingleChildScrollView(
              padding: EdgeInsets.only(bottom: 10 * s),
              child: Semantics(liveRegion: true, child: Text(text, style: BuddyText.hand(24 * s, height: 1.32))),
            ),
          ),
        ),
        for (final link in links)
          Semantics(
            button: link.onTap != null,
            child: GuildPressable(
              onTap: link.onTap,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: 30 * s),
                child: Align(
                  alignment: Alignment.centerLeft,
                  widthFactor: 1,
                  heightFactor: 1,
                  child: Text(
                    link.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: BuddyText.hand(
                      17 * s,
                      color: BuddyColors.name,
                      height: 1.2,
                    ).copyWith(decoration: TextDecoration.underline, decorationColor: BuddyColors.name),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// The horn that calls Pip: tap, then speak.
class _Horn extends StatelessWidget {
  const _Horn({required this.s, this.onTap});

  final double s;
  final VoidCallback? onTap;

  // hey_pip_button.svg is 196 x 178.
  static const _width = 176.0;
  static const _k = _width / 196;

  @override
  Widget build(BuildContext context) {
    final k = _k * s;
    return Semantics(
      button: true,
      label: 'Hey Pip! Tap to speak',
      excludeSemantics: true,
      child: GuildPressable(
        onTap: onTap,
        haptic: true,
        child: SizedBox(
          width: 196 * k,
          height: 178 * k,
          child: Stack(
            children: [
              Positioned.fill(child: Image.asset(BuddyAssets.heyPipButton, fit: BoxFit.fill)),
              Positioned(
                left: 0,
                right: 0,
                top: 137 * k,
                child: Text('Hey Pip!', textAlign: TextAlign.center, style: BuddyText.serif(24 * k)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// For when the hero would rather write than speak.
class _WritingLine extends StatefulWidget {
  const _WritingLine({
    required this.s,
    required this.controller,
    required this.focusNode,
    required this.open,
    required this.openHeight,
    required this.onStart,
  });

  final double s;
  final BuddyController controller;
  final FocusNode focusNode;

  /// A tap on the rolled-up line: unroll first, the keyboard comes after.
  final VoidCallback onStart;

  /// 0 rolled up (a one-line pill), 1 unrolled: a scroll [openHeight] tall
  /// and as wide as Pip's card, with the quill resting on its corner.
  final Animation<double> open;
  final double openHeight;

  @override
  State<_WritingLine> createState() => _WritingLineState();
}

class _WritingLineState extends State<_WritingLine> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _send() {
    final text = _text.text;
    if (!widget.controller.canSend(text)) return;
    _text.clear();
    // Put the pen down, so the card comes back with Pip's answer.
    widget.focusNode.unfocus();
    widget.controller.send(text);
  }

  BoxDecoration _box(Color color, double radius) => BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: BuddyColors.outline, width: 3 * widget.s),
    boxShadow: [BoxShadow(color: BuddyColors.outline, offset: Offset(0, 4 * widget.s))],
  );

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final style = BuddyText.hand(20 * s, height: 1.25);
    final quill = ListenableBuilder(
      listenable: Listenable.merge([_text, widget.controller]),
      builder: (context, _) {
        final ready = widget.controller.canSend(_text.text);
        return Semantics(
          button: true,
          enabled: ready,
          label: 'Send',
          excludeSemantics: true,
          child: GuildPressable(
            onTap: ready ? _send : null,
            haptic: true,
            child: Container(
              width: 64 * s,
              height: 58 * s,
              decoration: _box(BuddyColors.leather, 18 * s),
              alignment: Alignment.center,
              child: Image.asset(BuddyAssets.quill, width: 36 * s),
            ),
          ),
        );
      },
    );

    return AnimatedBuilder(
      animation: widget.open,
      builder: (context, _) {
        final t = widget.open.value;
        final rod = WritingScrollPainter.rod(s) * t;
        return SizedBox(
          height: lerpDouble(58 * s, widget.openHeight, t),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Rolled up, the scroll leaves room for the quill beside it;
              // unrolled, it runs the full width and the quill sits on it.
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                right: 76 * s * (1 - t),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: t < 1 ? widget.onStart : widget.focusNode.requestFocus,
                  child: CustomPaint(
                    painter: WritingScrollPainter(t: t, s: s),
                    child: Padding(
                      // Unrolled: clear of the rods, of Pip's paws and tail at the top
                      // and of the quill at the foot.
                      padding: EdgeInsets.fromLTRB(24 * s, rod + 38 * s * t, 24 * s, rod + 50 * s * t),
                      child: IgnorePointer(
                        // Until the scroll lies open a tap only unrolls it.
                        ignoring: t < 1,
                        child: TextField(
                          controller: _text,
                          focusNode: widget.focusNode,
                          style: style,
                          cursorColor: BuddyColors.name,
                          expands: true,
                          maxLines: null,
                          // One centred line when rolled up, a page written from the top when open.
                          textAlignVertical: TextAlignVertical(y: -t),
                          // Plain text keyboard, so that Enter sends instead of starting
                          // a new line; long letters still wrap.
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.send,
                          textCapitalization: TextCapitalization.sentences,
                          inputFormatters: [LengthLimitingTextInputFormatter(BuddyRepository.maxMessageLength)],
                          // An empty line keeps the keyboard up; a written one is sent.
                          onEditingComplete: _send,
                          decoration: InputDecoration(
                            isCollapsed: true,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: lerpDouble(16.5, 6, t)! * s),
                            hintText: 'I feel mute today…',
                            hintStyle: style.copyWith(color: BuddyColors.inkFaded),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(right: 10 * s * t, bottom: (rod + 4 * s) * t, child: quill),
            ],
          ),
        );
      },
    );
  }
}
