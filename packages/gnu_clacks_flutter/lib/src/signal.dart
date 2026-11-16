import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'localizations.dart';
import 'theme.dart';

/// Original, symbolic local animation. No alphabet encoding or network activity.
///
/// Pauses with reduced motion, inactive app, TickerMode, viewport clipping or
/// [active]=false. Hosts hiding content outside normal paint/scroll lifecycles
/// should also set [active] false. A static equivalent always retains semantics.
class ClacksSignal extends StatefulWidget {
  const ClacksSignal({super.key, this.animate = true, this.active = true});
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
    _allowed =
        !MediaQuery.disableAnimationsOf(context) &&
        !MediaQuery.accessibleNavigationOf(context) &&
        TickerMode.valuesOf(context).enabled;
    _scheduleCheck();
  }

  @override
  void didUpdateWidget(ClacksSignal oldWidget) {
    super.didUpdateWidget(oldWidget);
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
      final duration = ClacksTheme.of(context).signalPeriod;
      _controller!.duration = duration.inMilliseconds >= 1000
          ? duration
          : const Duration(seconds: 4);
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
    return ColoredBox(
      color: theme.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            label: strings.symbolicSignal,
            child: ExcludeSemantics(
              child: _PaintProbe(
                onPaint: _scheduleCheck,
                child: SizedBox(
                  key: _paintKey,
                  height: 112,
                  width: double.infinity,
                  child: animation == null
                      ? CustomPaint(
                          painter: TowerPainter(
                            theme.accentOn(theme.surface),
                            0,
                          ),
                        )
                      : AnimatedBuilder(
                          animation: animation,
                          builder: (context, child) => CustomPaint(
                            painter: TowerPainter(
                              theme.accentOn(theme.surface),
                              animation.value,
                            ),
                          ),
                        ),
                ),
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
