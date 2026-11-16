import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gnu_clacks_core/gnu_clacks_core.dart';

import 'localizations.dart';
import 'theme.dart';

/// Original local tower animation. No network activity.
///
/// With a [message], each character travels tower to tower from left to right,
/// shown in the nine-lamp [ClacksLampCode]; as it reaches the last tower it is
/// printed, respelling the message. Without one, a symbolic pulse is shown.
///
/// Pauses with reduced motion, inactive app, TickerMode, viewport clipping or
/// [active]=false. Hosts hiding content outside normal paint/scroll lifecycles
/// should also set [active] false. A static equivalent always retains semantics.
class ClacksSignal extends StatefulWidget {
  const ClacksSignal({
    super.key,
    this.message,
    this.animate = true,
    this.active = true,
  });

  /// Text relayed across the towers, such as a memorial's display name.
  final String? message;
  final bool animate;
  final bool active;
  @override
  State<ClacksSignal> createState() => _ClacksSignalState();
}

class _ClacksSignalState extends State<ClacksSignal>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final _paintKey = GlobalKey();
  AnimationController? _controller;
  final _positions = <ScrollPosition>[];
  bool _paused = false;
  bool _visible = false;
  bool _scheduled = false;
  bool _foreground = true;
  bool _allowed = false;
  late _Relay? _relay = _Relay.of(widget.message);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _foreground = lifecycle == null || lifecycle == AppLifecycleState.resumed;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final position in _positions) {
      position.removeListener(_scheduleCheck);
    }
    _positions.clear();
    // Register all scrolling ancestors, including nested outer viewports.
    Scrollable.maybeOf(context);
    context.visitAncestorElements((element) {
      if (element is StatefulElement && element.state is ScrollableState) {
        final position = (element.state as ScrollableState).position;
        if (!_positions.contains(position)) {
          _positions.add(position);
          position.addListener(_scheduleCheck);
        }
      }
      return true;
    });
    // Reduced motion is the only platform signal that stops the animation.
    // accessibleNavigation is not used: on Android it turns on whenever any
    // accessibility service (password managers, device-link apps) reads the
    // screen. Screen readers already get one static label below.
    _allowed =
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled;
    _scheduleCheck();
  }

  @override
  void didUpdateWidget(ClacksSignal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message != widget.message) {
      _relay = _Relay.of(widget.message);
      // Restart so the repeat period matches the new message length.
      _controller?.stop();
    }
    _scheduleCheck();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) {
      WidgetsBinding.instance.scheduleFrame();
    } else {
      _controller?.stop();
    }
    _scheduleCheck();
  }

  void _scheduleCheck() {
    if (_scheduled || !mounted) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (mounted) _checkVisibility();
    });
  }

  void _checkVisibility() {
    if (!mounted) return;
    final box = _paintKey.currentContext?.findRenderObject();
    var visible = box is RenderBox && box.attached && box.hasSize;
    if (visible) {
      final bounds = MatrixUtils.transformRect(
        box.getTransformTo(null),
        Offset.zero & box.size,
      );
      var clip = Offset.zero & MediaQuery.sizeOf(context);
      RenderObject? ancestor = box.parent;
      while (ancestor != null) {
        if (ancestor is RenderOffstage && ancestor.offstage) visible = false;
        if (ancestor is RenderOpacity && ancestor.opacity == 0) visible = false;
        if (ancestor is RenderAnimatedOpacity && ancestor.opacity.value == 0) {
          visible = false;
        }
        if (ancestor is RenderClipRect && ancestor.hasSize) {
          final localClip =
              ancestor.clipper?.getClip(ancestor.size) ??
              (Offset.zero & ancestor.size);
          clip = clip.intersect(
            MatrixUtils.transformRect(ancestor.getTransformTo(null), localClip),
          );
        }

        final viewport = ancestor is RenderBox ? ancestor : null;
        if (ancestor is RenderAbstractViewport &&
            viewport != null &&
            viewport.hasSize) {
          clip = clip.intersect(
            MatrixUtils.transformRect(
              viewport.getTransformTo(null),
              Offset.zero & viewport.size,
            ),
          );
        }
        ancestor = ancestor.parent;
      }
      visible = visible && bounds.overlaps(clip) && !clip.isEmpty;
    }
    _visible = visible;
    final shouldRun =
        _visible &&
        _allowed &&
        widget.active &&
        widget.animate &&
        !_paused &&
        _foreground;
    if (shouldRun) {
      _controller ??= AnimationController(vsync: this)
        ..addListener(_checkVisibility);
      final period = ClacksTheme.of(context).signalPeriod;
      final safePeriod = period.inMilliseconds >= 1000
          ? period
          : const Duration(seconds: 4);
      _controller!.duration = _relay?.cycle(safePeriod) ?? safePeriod;
      if (!_controller!.isAnimating) {
        _controller!.repeat();
        setState(() {});
      }
    } else if (_controller?.isAnimating ?? false) {
      _controller!.stop();
      setState(() {});
    }
  }

  @override
  void dispose() {
    for (final position in _positions) {
      position.removeListener(_scheduleCheck);
    }
    _controller?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = ClacksLocalizations.of(context);
    final theme = ClacksTheme.of(context);
    final animation = _controller;
    final relay = _relay;
    final colour = theme.accentOn(theme.surface);

    Widget painted(double progress) => CustomPaint(
      painter: relay == null
          ? TowerPainter(colour, progress)
          : _RelayPainter(
              colour,
              relay,
              animation == null ? null : relay.frame(progress),
            ),
    );

    final towers = _PaintProbe(
      onPaint: _scheduleCheck,
      child: SizedBox(
        key: _paintKey,
        height: 112,
        width: double.infinity,
        child: animation == null
            ? painted(0)
            : AnimatedBuilder(
                animation: animation,
                builder: (context, child) => painted(animation.value),
              ),
      ),
    );

    return ColoredBox(
      color: theme.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            label: relay == null
                ? strings.symbolicSignal
                : strings.relaySignal(widget.message!),
            child: ExcludeSemantics(
              child: relay == null
                  ? towers
                  : _RelayLayout(
                      relay: relay,
                      animation: animation,
                      towers: towers,
                      ink: theme.ink(theme.surface),
                      accent: colour,
                    ),
            ),
          ),
          if (widget.animate && _allowed)
            TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: theme.ink(theme.surface),
                minimumSize: const Size(48, 48),
              ),
              onPressed: () {
                setState(() => _paused = !_paused);
                _scheduleCheck();
              },
              icon: Icon(_paused ? Icons.play_arrow : Icons.pause),
              label: Text(_paused ? strings.resume : strings.pause),
            ),
        ],
      ),
    );
  }
}

/// Timeline for relaying a message across [towers] towers.
///
/// At step `s`, tower `k` shows character `s - k`, so several characters are in
/// flight at once. A character is printed when it reaches the last tower. After
/// the final character the whole message is held for [hold] steps.
class _Relay {
  _Relay(this.characters)
    : patterns = [
        for (final c in characters) ClacksLampCode.encode(c),
        ClacksLampCode.end,
      ];

  static _Relay? of(String? message) {
    final characters = message?.trim().characters.toList() ?? const [];
    return characters.isEmpty ? null : _Relay(characters);
  }

  static const towers = 3;
  static const hold = 3;
  static const _minimumStep = Duration(milliseconds: 400);

  /// The message's characters; the END signal follows as one extra token.
  final List<String> characters;

  /// Lamp pattern per token: one per character, then [ClacksLampCode.end].
  final List<int?> patterns;

  int get tokens => patterns.length;

  int get steps => tokens + towers - 1 + hold;

  /// One cycle; [period] is the time a character takes to cross every tower.
  Duration cycle(Duration period) {
    var step = period ~/ towers;
    if (step < _minimumStep) step = _minimumStep;
    return step * steps;
  }

  _RelayFrame frame(double progress) {
    final position = progress.clamp(0.0, 1.0) * steps;
    final step = math.min(position.floor(), steps - 1);
    return _RelayFrame(
      step: step,
      phase: position - step,
      towers: [
        for (var k = 0; k < towers; k++)
          step - k >= 0 && step - k < tokens ? step - k : null,
      ],
      printed: (step - towers + 2).clamp(0, tokens),
      sending: step < tokens ? step : null,
    );
  }

  /// At rest: the message fully respelled and the towers dark.
  _RelayFrame get rest => _RelayFrame(
    step: steps - 1,
    phase: 0,
    towers: const [null, null, null],
    printed: tokens,
    sending: null,
  );
}

class _RelayFrame {
  const _RelayFrame({
    required this.step,
    required this.phase,
    required this.towers,
    required this.printed,
    required this.sending,
  });
  final int step;
  final double phase;

  /// Index of the character shown on each tower, left to right.
  final List<int?> towers;

  /// How many characters have arrived at the last tower.
  final int printed;

  /// Index of the character entering the first tower, if any.
  final int? sending;
}

/// Name on the left, towers in the middle, respelled name on the right.
/// Stacks vertically when there is not enough width.
class _RelayLayout extends StatelessWidget {
  const _RelayLayout({
    required this.relay,
    required this.animation,
    required this.towers,
    required this.ink,
    required this.accent,
  });
  final _Relay relay;
  final Animation<double>? animation;
  final Widget towers;
  final Color ink;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.titleMedium?.copyWith(color: ink);
    final end = ClacksLocalizations.of(context).endSignal;
    final endStyle = TextStyle(
      fontSize: (style?.fontSize ?? 16) * .75,
      letterSpacing: 1.5,
      fontWeight: FontWeight.w600,
    );

    Widget text(bool source) {
      TextStyle? stateOf(_RelayFrame frame, int i) => source
          ? (i == frame.sending
                ? TextStyle(color: accent, fontWeight: FontWeight.bold)
                : null)
          // Unprinted tokens keep their space, so the respelled name does
          // not shift as it grows.
          : (i < frame.printed
                ? null
                : const TextStyle(color: Color(0x00000000)));

      Widget build(_RelayFrame frame) => Text.rich(
        TextSpan(
          children: [
            for (var i = 0; i < relay.tokens; i++)
              i < relay.characters.length
                  ? TextSpan(
                      text: relay.characters[i],
                      style: stateOf(frame, i),
                    )
                  // END follows a no-break space, so it never wraps alone,
                  // and is set small and letter-spaced as a signal.
                  : TextSpan(
                      text: '\u00a0$end',
                      style: endStyle.merge(stateOf(frame, i)),
                    ),
          ],
        ),
        style: style,
        textAlign: source ? TextAlign.start : TextAlign.end,
        key: ValueKey(source ? 'clacks-source' : 'clacks-received'),
      );
      final controller = animation;
      return controller == null
          ? build(relay.rest)
          : AnimatedBuilder(
              animation: controller,
              builder: (context, _) => build(relay.frame(controller.value)),
            );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 560) {
          return Row(
            children: [
              Expanded(flex: 2, child: text(true)),
              const SizedBox(width: 12),
              Expanded(flex: 5, child: towers),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: text(false)),
            ],
          );
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: text(true),
            ),
            towers,
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: text(false),
            ),
          ],
        );
      },
    );
  }
}

/// Original towers, each with a three-by-three lamp panel.
class _RelayPainter extends CustomPainter {
  const _RelayPainter(this.colour, this.relay, this.frame);
  final Color colour;
  final _Relay relay;

  /// `null` paints the towers at rest with every lamp dark.
  final _RelayFrame? frame;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = colour
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final scale = math.min(size.width / 320, size.height / 110);
    canvas.save();
    canvas.translate(
      (size.width - 320 * scale) / 2,
      (size.height - 110 * scale) / 2,
    );
    canvas.scale(scale);
    final current = frame;
    // Lamps settle quickly at the start of each step, then hold steady.
    final settle = current == null
        ? 1.0
        : Curves.easeOut.transform(math.min(1, current.phase * 4));
    for (var i = 0; i < _Relay.towers; i++) {
      final x = 52.0 + i * 108;
      stroke.color = colour;
      canvas.drawLine(Offset(x - 16, 98), Offset(x - 12, 56), stroke);
      canvas.drawLine(Offset(x + 16, 98), Offset(x + 12, 56), stroke);
      canvas.drawLine(Offset(x - 12, 74), Offset(x + 12, 74), stroke);
      canvas.drawLine(Offset(x - 14, 90), Offset(x + 14, 90), stroke);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(x - 24, 6, x + 24, 56),
          const Radius.circular(3),
        ),
        stroke,
      );
      final index = current?.towers[i];
      final pattern = index == null ? null : relay.patterns[index];
      for (var lamp = 0; lamp < ClacksLampCode.lampCount; lamp++) {
        final centre = Offset(
          x + (lamp % ClacksLampCode.columns - 1) * 14,
          17.0 + (lamp ~/ ClacksLampCode.columns) * 14,
        );
        // The centre lamp is reserved for END, so its rim is fainter.
        final reserved = lamp == ClacksLampCode.centre;
        final lit = pattern != null && ClacksLampCode.isLit(pattern, lamp);
        canvas.drawCircle(
          centre,
          5,
          Paint()
            ..color = colour.withValues(alpha: lit ? .15 + .85 * settle : .12),
        );
        canvas.drawCircle(
          centre,
          5,
          Paint()
            ..color = colour.withValues(alpha: reserved ? .3 : .55)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      }
      if (i < _Relay.towers - 1) {
        final from = x + 26;
        final to = x + 108 - 26;
        canvas.drawLine(
          Offset(from, 31),
          Offset(to, 31),
          stroke..color = colour.withValues(alpha: .35),
        );
        // A small pulse travels on towards the next tower.
        if (current != null && index != null) {
          canvas.drawCircle(
            Offset(from + (to - from) * current.phase, 31),
            2.5,
            Paint()..color = colour.withValues(alpha: .8),
          );
        }
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RelayPainter oldDelegate) =>
      oldDelegate.colour != colour ||
      oldDelegate.relay != relay ||
      oldDelegate.frame?.step != frame?.step ||
      oldDelegate.frame?.phase != frame?.phase;
}

// Paint notification resumes a stopped signal when it becomes visible again.
class _PaintProbe extends SingleChildRenderObjectWidget {
  const _PaintProbe({required this.onPaint, required super.child});
  final VoidCallback onPaint;
  @override
  RenderObject createRenderObject(BuildContext context) =>
      _ProbeRender(onPaint);
  @override
  void updateRenderObject(
    BuildContext context,
    covariant _ProbeRender renderObject,
  ) => renderObject.onPaint = onPaint;
}

class _ProbeRender extends RenderProxyBox {
  _ProbeRender(this.onPaint);
  VoidCallback onPaint;
  @override
  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset);
    onPaint();
  }
}

/// Original geometric tower drawing, shared by static local placeholders.
class TowerPainter extends CustomPainter {
  const TowerPainter(this.colour, this.progress);
  final Color colour;
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = colour
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final scale = math.min(size.width / 320, size.height / 110);
    canvas.save();
    canvas.translate(
      (size.width - 320 * scale) / 2,
      (size.height - 110 * scale) / 2,
    );
    canvas.scale(scale);
    for (var i = 0; i < 3; i++) {
      final x = 52.0 + i * 108;
      canvas.drawLine(Offset(x - 15, 96), Offset(x - 11, 48), paint);
      canvas.drawLine(Offset(x + 15, 96), Offset(x + 11, 48), paint);
      canvas.drawLine(Offset(x - 12, 68), Offset(x + 12, 68), paint);
      canvas.drawLine(Offset(x - 14, 86), Offset(x + 14, 86), paint);
      canvas.drawRect(
        Rect.fromCenter(center: Offset(x, 36), width: 38, height: 27),
        paint,
      );
      canvas.drawPath(
        Path()
          ..moveTo(x - 24, 22)
          ..lineTo(x, 9)
          ..lineTo(x + 24, 22),
        paint,
      );
      for (var shutter = 0; shutter < 3; shutter++) {
        final glow =
            .45 +
            .5 *
                (math.sin(progress * math.pi * 2 - i * 1.3 + shutter * .5) +
                    1) /
                2;
        canvas.drawRect(
          Rect.fromLTWH(x - 13 + shutter * 10, 29, 6, 14),
          Paint()..color = colour.withValues(alpha: glow),
        );
      }
      if (i < 2) {
        canvas.drawLine(
          Offset(x + 23, 36),
          Offset(x + 85, 36),
          paint..color = colour.withValues(alpha: .35),
        );
      }
      paint.color = colour;
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(TowerPainter oldDelegate) =>
      oldDelegate.colour != colour || oldDelegate.progress != progress;
}
