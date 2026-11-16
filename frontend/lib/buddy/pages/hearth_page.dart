import 'dart:math';
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../guildhall/widgets/guild_feedback.dart';
import '../../guildhall/widgets/pressable.dart';
import '../data/buddy_ears.dart';
import '../data/buddy_repository.dart';
import '../data/models.dart';
import '../state/buddy_controller.dart';
import '../state/hearing_controller.dart';
import '../theme/buddy_theme.dart';
import '../widgets/hearth_life.dart';
import '../widgets/pip_cat.dart';
import '../widgets/sky.dart';
import '../widgets/smoke_puff.dart';
import '../widgets/writing_scroll.dart';

/// The Buddy's campfire: Pip lounging on a card with the last thing it said,
/// a horn to call it, and a line to write on.
///
/// Laid out from the Figma frame "Buddy – Idle v4" (393 wide, 762 tall above
/// the tab bar). Every number below is in that frame's units and multiplied
/// by the scale that fits the frame to the screen.
class HearthPage extends StatefulWidget {
  const HearthPage({super.key, required this.controller, required this.ears, this.onOpenGuildHall, this.onOpenMap});

  final BuddyController controller;

  /// What the horn listens with.
  final BuddyEars ears;

  final VoidCallback? onOpenGuildHall;
  final VoidCallback? onOpenMap;

  static const greeting = 'Oh, look who finally crawled out of bed. So… dragons or dishes today?';

  @override
  State<HearthPage> createState() => _HearthPageState();
}

class _HearthPageState extends State<HearthPage> with TickerProviderStateMixin {
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
  // rolls up: one thing moves at a time.
  static const _unhurried = Duration(milliseconds: 650);
  static const _keyboardLeaves = Duration(milliseconds: 240);
  final _focus = FocusNode();
  late final AnimationController _writing = AnimationController(vsync: this, duration: _unhurried);
  late final Animation<double> _open = CurvedAnimation(parent: _writing, curve: Curves.easeInOutCubic);

  // What is on the writing line, typed or heard.
  final _text = TextEditingController();
  final _line = GlobalKey<_WritingLineState>();

  // The horn: tap it and the same scroll unrolls, with no keyboard, and
  // fills with what is heard; tap it again and that is sent.
  late final HearingController _hearing = HearingController(widget.ears, onHeard: _onHeard);
  bool _scrollIsForVoice = false;
  bool _heardAndSent = false;

  // The sky: pulling the scene down climbs above the trees, to where the old
  // messages hang in the smoke. [_climb] is how far up the view is.
  final _sky = ScrollController();
  final _climb = ValueNotifier<double>(0);

  // One clock, in seconds, for everything that moves by itself. It feeds
  // [_time] (the sky: stars, smoke) only while the view is off the ground,
  // and [_hearthTime] (the fire, the fireflies, Pip) only while the ground
  // is in view, so nothing is repainted where no one is looking. It stops
  // altogether while another tab is showing.
  final _time = ValueNotifier<double>(0);
  final _hearthTime = ValueNotifier<double>(0);
  late final Ticker _clock = createTicker(_tick);
  double _clockBase = 0;
  double _now = 0;
  bool _still = false;

  void _tick(Duration elapsed) {
    _now = _clockBase + elapsed.inMicroseconds / 1e6;
    final climb = _climb.value;
    if (climb > 1) _time.value = _now;
    if (climb < _fullHeight) _hearthTime.value = _now;
  }

  void _runClock(bool run) {
    if (run == _clock.isActive) return;
    if (run) {
      _clock.start();
    } else {
      _clockBase = _now;
      _clock.stop();
    }
  }

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
    _hearing.addListener(_onHearing);
    widget.controller.addListener(_onTalk);
    _sky.addListener(_onClimb);
    // The sky cannot be pulled while the scroll is out for writing.
    _writing.addStatusListener((_) => setState(() {}));
  }

  void _onClimb() => _climb.value = _sky.offset;

  void _backToTheFire() {
    if (!_sky.hasClients) return;
    final far = _sky.offset;
    _sky.animateTo(
      0,
      duration: Duration(milliseconds: (350 + far / 6).clamp(350, 1400).round()),
      curve: Curves.easeInOutCubic,
    );
  }

  /// Let go just above the ground and the view settles back onto it.
  bool _onSettled(ScrollEndNotification end) {
    final offset = end.metrics.pixels;
    if (end.depth == 0 && offset > 0 && offset < _fullHeight * 0.22) {
      Future<void>.microtask(_backToTheFire);
    }
    return false;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _still = MediaQuery.disableAnimationsOf(context);
    _runClock(!_still && Visibility.of(context));
    _writing.duration = _still ? Duration.zero : _unhurried;
    _writing.reverseDuration = _writing.duration;
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    widget.controller.removeListener(_onTalk);
    _hearing.dispose();
    _text.dispose();
    _focus.dispose();
    _writing.dispose();
    _clock.dispose();
    _sky.dispose();
    _climb.dispose();
    _time.dispose();
    _hearthTime.dispose();
    super.dispose();
  }

  void _startWriting() {
    if (_hearing.active) return;
    _writing.forward().whenComplete(() {
      if (mounted && _writing.isCompleted) _focus.requestFocus();
    });
  }

  void _onHearing() {
    if (_hearing.active) {
      // The scroll comes out for the words, and shows them as they come.
      if (!_scrollIsForVoice) {
        _scrollIsForVoice = true;
        _focus.unfocus();
        _writing.forward();
      }
      final words = _hearing.words;
      if (_text.text != words) {
        _text.value = TextEditingValue(
          text: words,
          selection: TextSelection.collapsed(offset: words.length),
        );
      }
      return;
    }
    if (!_scrollIsForVoice) return;
    _scrollIsForVoice = false;
    if (_heardAndSent) {
      _heardAndSent = false; // the line is rolling itself up with the words on it
    } else {
      // Cancelled, nothing heard, or the microphone would not start.
      _text.clear();
      _writing.reverse();
    }
  }

  /// The hero has finished speaking: send it as if it had been written.
  void _onHeard(String words) {
    _text.text = words;
    _heardAndSent = _line.currentState?._send() ?? false;
  }

  /// Once a message is on its way, an old "I could not hear you" is stale.
  void _onTalk() {
    if (widget.controller.replying) _hearing.clearTrouble();
  }

  void _stopWriting() {
    if (_hearing.active) {
      _hearing.cancel(); // and [_onHearing] rolls the scroll up
      return;
    }
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

            final ground = GestureDetector(
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
                        hearing: _hearing,
                        time: _hearthTime,
                      ),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _open,
                    builder: (context, line) => Positioned(
                      left: (_width - _frameWidth * s) / 2 + 24 * s,
                      width: 345 * s,
                      top: lerpDouble(rolledTop, unrolledTop, _open.value),
                      // Typing repaints the scroll alone, not the forest behind it.
                      child: RepaintBoundary(child: line),
                    ),
                    child: _WritingLine(
                      key: _line,
                      text: _text,
                      hearing: _hearing,
                      s: s,
                      controller: widget.controller,
                      focusNode: _focus,
                      open: _open,
                      openHeight: scrollHeight,
                      onStart: _startWriting,
                      onDone: _stopWriting,
                    ),
                  ),
                  // Pip lies on the card's top edge, paws and tail hanging
                  // over it. Drawn last, so it lies on the open sheet too.
                  Positioned(
                    left: (_width - _frameWidth * s) / 2 + 32 * s,
                    top: frameTop + 78 * s,
                    child: IgnorePointer(
                      child: RepaintBoundary(
                        child: ListenableBuilder(
                          listenable: Listenable.merge([widget.controller, _hearing]),
                          builder: (context, _) => PipCat(
                            time: _hearthTime,
                            s: s,
                            mood: _hearing.active
                                ? PipMood.listening
                                : (widget.controller.replying ? PipMood.thinking : PipMood.idle),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );

            return NotificationListener<ScrollEndNotification>(
              onNotification: _onSettled,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  RepaintBoundary(
                    child: CustomPaint(
                      painter: SkyPainter(climb: _climb, time: _time, s: s),
                    ),
                  ),
                  // Bottom up: the ground, the treetops, then the messages,
                  // newest lowest. Pulling down climbs.
                  ListenableBuilder(
                    listenable: widget.controller,
                    builder: (context, _) {
                      final messages = widget.controller.messages;
                      return ListView.builder(
                        controller: _sky,
                        reverse: true,
                        padding: EdgeInsets.zero,
                        physics: _writing.isDismissed
                            ? const ClampingScrollPhysics()
                            : const NeverScrollableScrollPhysics(),
                        itemCount: messages.length + 3,
                        itemBuilder: (context, i) {
                          if (i == 0) {
                            return _KeptAlive(
                              child: SizedBox(height: _fullHeight, child: ground),
                            );
                          }
                          if (i == 1) {
                            return SizedBox(
                              height: 130 * s,
                              child: CustomPaint(painter: TreetopsPainter(s: s)),
                            );
                          }
                          if (i == messages.length + 2) {
                            return _SkyNote(
                              s: s,
                              height: _fullHeight * 0.5,
                              text: messages.isEmpty
                                  ? 'Nothing has gone up in smoke yet. Go and tell Pip something.'
                                  : 'This is where the smoke began.',
                            );
                          }
                          final message = messages[messages.length + 1 - i];
                          return Center(
                            child: SizedBox(
                              width: _frameWidth * s,
                              child: SmokePuff(
                                key: ValueKey(message.id),
                                message: message,
                                time: _time,
                                s: s,
                                onOpenGuildHall: widget.onOpenGuildHall,
                                onOpenMap: widget.onOpenMap,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  ValueListenableBuilder<double>(
                    valueListenable: _climb,
                    builder: (context, climb, button) {
                      final aloft = climb > _fullHeight * 0.5;
                      return Positioned(
                        left: 0,
                        right: 0,
                        bottom: 14 * s,
                        child: IgnorePointer(
                          ignoring: !aloft,
                          child: AnimatedOpacity(
                            opacity: aloft ? 1 : 0,
                            duration: const Duration(milliseconds: 220),
                            child: button,
                          ),
                        ),
                      );
                    },
                    child: Center(
                      child: _BackToTheFire(s: s, onTap: _backToTheFire),
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

/// The ground stays built while the view is far above it, so that what the
/// hero was writing is still there on the way back down.
class _KeptAlive extends StatefulWidget {
  const _KeptAlive({required this.child});

  final Widget child;

  @override
  State<_KeptAlive> createState() => _KeptAliveState();
}

class _KeptAliveState extends State<_KeptAlive> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

/// A line written on the sky itself, above the oldest message.
class _SkyNote extends StatelessWidget {
  const _SkyNote({required this.s, required this.height, required this.text});

  final double s;
  final double height;
  final String text;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Align(
        alignment: const Alignment(0, 0.5),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 40 * s),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: BuddyText.hand(17 * s, color: BuddyColors.cream.withValues(alpha: 0.6)),
          ),
        ),
      ),
    );
  }
}

class _BackToTheFire extends StatelessWidget {
  const _BackToTheFire({required this.s, required this.onTap});

  final double s;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Back to the fire',
      excludeSemantics: true,
      child: GuildPressable(
        onTap: onTap,
        haptic: true,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20 * s, vertical: 10 * s),
          decoration: BoxDecoration(
            color: BuddyColors.card,
            borderRadius: BorderRadius.circular(24 * s),
            border: Border.all(color: BuddyColors.outline, width: 3 * s),
            boxShadow: [BoxShadow(color: BuddyColors.outline, offset: Offset(0, 4 * s))],
          ),
          child: Text('Back to the fire', style: BuddyText.hand(18 * s, height: 1.1)),
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
    required this.hearing,
    required this.time,
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
  final HearingController hearing;

  /// Seconds, for the embers and the fireflies.
  final ValueListenable<double> time;

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
                    // Life around the fire, painted over the still artwork:
                    // fireflies among the trunks, and the embers themselves.
                    Positioned.fill(
                      child: IgnorePointer(
                        child: RepaintBoundary(
                          child: CustomPaint(
                            painter: FirefliesPainter(time: time, s: s, top: top),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 32 * s,
                      height: (226 + EmbersPainter.headroom) * s,
                      child: IgnorePointer(
                        child: RepaintBoundary(
                          child: CustomPaint(
                            painter: EmbersPainter(time: time, s: s),
                          ),
                        ),
                      ),
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
                          hearing: hearing,
                          maxHeight: cardRoom,
                          controller: controller,
                          onOpenGuildHall: onOpenGuildHall,
                          onOpenMap: onOpenMap,
                        ),
                      ),
                    ),
                    // With the scroll out, the horn steps down into the room the rolled-up
                    // line has left, so the two never overlap.
                    AnimatedBuilder(
                      animation: Listenable.merge([hush, controller]),
                      builder: (context, _) => Positioned(
                        left: 0,
                        right: 0,
                        bottom: lerpDouble(140, 74, hush.value)! * s,
                        child: Center(
                          // One thing at a time: no calling Pip while it is answering.
                          child: _Horn(s: s, hearing: hearing, enabled: !controller.replying),
                        ),
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
    required this.hearing,
    this.onOpenGuildHall,
    this.onOpenMap,
  });

  final double s;
  final double maxHeight;
  final BuddyController controller;
  final HearingController hearing;
  final VoidCallback? onOpenGuildHall;
  final VoidCallback? onOpenMap;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([controller, hearing]),
      builder: (context, _) {
        final undelivered = controller.undelivered;
        final trouble = hearing.trouble;
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
        } else if (trouble != null) {
          mood = 'ears flat';
          turn = 'deaf';
          body = _Lines(s: s, text: trouble);
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

/// The horn that calls Pip: tap, speak, tap again.
class _Horn extends StatefulWidget {
  const _Horn({required this.s, required this.hearing, required this.enabled});

  final double s;
  final HearingController hearing;
  final bool enabled;

  @override
  State<_Horn> createState() => _HornState();
}

class _HornState extends State<_Horn> with SingleTickerProviderStateMixin {
  // hey_pip_button.svg is 196 x 178.
  static const _width = 176.0;
  static const _k = _width / 196;

  // Rings of sound going out from the horn while it listens.
  late final AnimationController _rings = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  @override
  void initState() {
    super.initState();
    widget.hearing.addListener(_onHearing);
  }

  @override
  void dispose() {
    widget.hearing.removeListener(_onHearing);
    _rings.dispose();
    super.dispose();
  }

  void _onHearing() {
    final listening = widget.hearing.state == Hearing.listening;
    if (listening && !_rings.isAnimating && !MediaQuery.disableAnimationsOf(context)) {
      _rings.repeat();
    } else if (!listening && _rings.isAnimating) {
      _rings.stop();
      _rings.value = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final k = _k * widget.s;
    final hearing = widget.hearing;
    return AnimatedBuilder(
      animation: hearing,
      builder: (context, _) {
        final (ribbon, said) = switch (hearing.state) {
          Hearing.idle => ('Hey Pip!', 'Hey Pip! Tap to speak'),
          Hearing.waking => ('One moment', 'Waking the horn'),
          Hearing.listening => ('I’m listening', 'Listening. Tap to send'),
          Hearing.finishing => ('Got it', 'Sending what you said'),
        };
        final size = ribbon.length > 9 ? 18.5 : 24.0;
        return Semantics(
          button: true,
          enabled: widget.enabled,
          label: said,
          excludeSemantics: true,
          child: GuildPressable(
            onTap: widget.enabled ? hearing.toggle : null,
            haptic: true,
            child: Opacity(
              opacity: widget.enabled ? 1 : 0.6,
              child: SizedBox(
                width: 196 * k,
                height: 178 * k,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    if (hearing.state == Hearing.listening)
                      Positioned.fill(child: CustomPaint(painter: _RingsPainter(_rings, k))),
                    Positioned.fill(child: Image.asset(BuddyAssets.heyPipButton, fit: BoxFit.fill)),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: (133 + (24 - size) / 2) * k,
                      child: Text(ribbon, textAlign: TextAlign.center, style: BuddyText.serif(size * k)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RingsPainter extends CustomPainter {
  _RingsPainter(this.progress, this.k) : super(repaint: progress);

  final Animation<double> progress;
  final double k;

  @override
  void paint(Canvas canvas, Size size) {
    // The shield's centre and radius within hey_pip_button.svg.
    final centre = Offset(98 * k, 84 * k);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * k;
    for (final lag in [0.0, 0.5]) {
      final t = (progress.value + lag) % 1;
      paint.color = BuddyColors.cream.withValues(alpha: 0.55 * (1 - t));
      canvas.drawCircle(centre, (86 + 34 * t) * k, paint);
    }
  }

  @override
  bool shouldRepaint(_RingsPainter old) => old.k != k;
}

/// For when the hero would rather write than speak.
class _WritingLine extends StatefulWidget {
  const _WritingLine({
    super.key,
    required this.s,
    required this.controller,
    required this.text,
    required this.hearing,
    required this.focusNode,
    required this.open,
    required this.openHeight,
    required this.onStart,
    required this.onDone,
  });

  final double s;
  final BuddyController controller;

  /// What is on the line. The page owns it, because the horn writes here too.
  final TextEditingController text;
  final HearingController hearing;
  final FocusNode focusNode;

  /// A tap on the rolled-up line: unroll first, the keyboard comes after.
  final VoidCallback onStart;

  /// The letter is sent: put the pen down and roll the scroll up.
  final VoidCallback onDone;

  /// 0 rolled up (a one-line pill), 1 unrolled: a scroll [openHeight] tall
  /// and as wide as Pip's card, with the quill resting on its corner.
  final Animation<double> open;
  final double openHeight;

  @override
  State<_WritingLine> createState() => _WritingLineState();
}

class _WritingLineState extends State<_WritingLine> {
  TextEditingController get _text => widget.text;

  // Keeps the newest words in view while they are being heard.
  final _reading = ScrollController();

  // A sent letter is not wiped off the page: it stays on the scroll and
  // fades as the scroll rolls up around it. Only then is the line cleared.
  bool _sent = false;

  @override
  void initState() {
    super.initState();
    widget.open.addStatusListener(_onRolled);
    widget.hearing.addListener(_followWords);
  }

  @override
  void dispose() {
    widget.open.removeStatusListener(_onRolled);
    widget.hearing.removeListener(_followWords);
    _reading.dispose();
    super.dispose();
  }

  void _onRolled(AnimationStatus status) {
    if (!_sent || status == AnimationStatus.reverse) return;
    // Rolled up, or opened again before it got that far: a fresh line.
    _text.clear();
    setState(() => _sent = false);
  }

  void _followWords() {
    if (!widget.hearing.active) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _reading.hasClients) _reading.jumpTo(_reading.position.maxScrollExtent);
    });
  }

  /// Sends what is on the line. False if it could not be sent just now.
  bool _send() {
    final text = _text.text;
    if (_sent || !widget.controller.canSend(text)) return false;
    widget.controller.send(text);
    if (widget.open.isDismissed) {
      _text.clear();
      return true;
    }
    setState(() => _sent = true);
    // Put the pen down, so the card comes back with Pip's answer.
    widget.onDone();
    return true;
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
      listenable: Listenable.merge([_text, widget.controller, widget.hearing]),
      builder: (context, _) {
        // While the horn is listening the quill ends it too: done, send.
        final listening = widget.hearing.state == Hearing.listening;
        final ready = listening || (!widget.hearing.active && widget.controller.canSend(_text.text));
        return Semantics(
          button: true,
          enabled: ready,
          label: 'Send',
          excludeSemantics: true,
          child: GuildPressable(
            onTap: !ready ? null : (listening ? widget.hearing.finish : _send),
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
      animation: Listenable.merge([widget.open, widget.hearing]),
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
                  onTap: widget.hearing.active ? null : (t < 1 ? widget.onStart : widget.focusNode.requestFocus),
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
                          readOnly: _sent || widget.hearing.active,
                          scrollController: _reading,
                          style: _sent ? style.copyWith(color: BuddyColors.ink.withValues(alpha: t)) : style,
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
                            // The invitation is gone the moment the line is tapped.
                            hintText: t == 0
                                ? 'I feel mute today…'
                                : (widget.hearing.active ? 'Go on, I’m listening…' : null),
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
