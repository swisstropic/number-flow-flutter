import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter_number_flow/flutter_number_flow.dart';
import '../core/metrics_cache.dart';

/// Animated presenter for individual glyphs with different animation styles
class GlyphStack extends StatefulWidget {
  const GlyphStack({
    super.key,
    required this.oldGlyph,
    required this.newGlyph,
    required this.textStyle,
    required this.animation,
    required this.animationStyle,
    this.direction = 1,
  });

  /// Previous glyph (null if this is a new glyph)
  final String? oldGlyph;

  /// Current glyph (null if this glyph was removed)
  final String? newGlyph;

  /// Text style to apply to the glyph
  final TextStyle textStyle;

  /// Animation controller driving the transition
  final Animation<double> animation;

  /// Style of animation to use
  final NumberFlowAnimation animationStyle;

  /// Direction of the animation: 1 = increase (slide up), -1 = decrease (slide down)
  final int direction;

  @override
  State<GlyphStack> createState() => _GlyphStackState();
}

class _GlyphStackState extends State<GlyphStack> {
  late final TextMetricsCache _metricsCache;

  // Cached reference height per text style
  TextStyle? _cachedStyle;
  double _referenceHeight = 0;

  @override
  void initState() {
    super.initState();
    _metricsCache = TextMetricsCache();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: widget.animation,
        builder: (context, child) => _buildAnimatedGlyph(),
      );

  // --- Height consistency ---

  /// Returns a stable line height derived from the font metrics, so that all
  /// glyph containers share the same height regardless of which character is
  /// being rendered. This prevents the parent Row from changing height when
  /// transitioning between characters of different sizes (e.g. digit → comma).
  double _getReferenceHeight() {
    if (_cachedStyle == widget.textStyle && _referenceHeight > 0) {
      return _referenceHeight;
    }
    _cachedStyle = widget.textStyle;
    final painter = TextPainter(
      text: TextSpan(text: '0', style: widget.textStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    _referenceHeight = painter.preferredLineHeight;
    return _referenceHeight;
  }

  // --- Helpers ---

  TextStyle _withOpacity(TextStyle style, double opacity) {
    final baseColor = style.color ?? Colors.black;
    return style.copyWith(
      color: baseColor.withAlpha((opacity.clamp(0.0, 1.0) * 255).round()),
    );
  }

  double _calculateAnimatedWidth() {
    final progress = widget.animation.value;
    final oldW =
        widget.oldGlyph != null ? _getGlyphWidth(widget.oldGlyph!) : 0.0;
    final newW =
        widget.newGlyph != null ? _getGlyphWidth(widget.newGlyph!) : 0.0;
    return lerpDouble(oldW, newW, progress)!;
  }

  bool _isDigit(String? char) {
    if (char == null || char.length != 1) return false;
    return char.codeUnitAt(0) >= 48 && char.codeUnitAt(0) <= 57;
  }

  List<int> _generateSpinSequence(int oldDigit, int newDigit, int direction) {
    final sequence = <int>[];
    if (direction >= 0) {
      int current = oldDigit;
      while (current != newDigit) {
        sequence.add(current);
        current = (current + 1) % 10;
      }
      sequence.add(newDigit);
    } else {
      int current = oldDigit;
      while (current != newDigit) {
        sequence.add(current);
        current = (current - 1 + 10) % 10;
      }
      sequence.add(newDigit);
    }
    return sequence;
  }

  // --- Shared builders ---

  Widget _buildStaticGlyph(String glyph) => SizedBox(
        width: _getGlyphWidth(glyph),
        height: _getReferenceHeight(),
        child: Align(
          alignment: Alignment.center,
          child: Text(glyph, style: widget.textStyle),
        ),
      );

  Widget _buildDeletionAnimation(String oldGlyph) {
    final progress = widget.animation.value;
    final width = lerpDouble(_getGlyphWidth(oldGlyph), 0.0, progress)!;
    final height = _getReferenceHeight();
    final opacity = 1.0 - progress;

    return SizedBox(
      width: width,
      height: height,
      child: ClipRect(
        child: Center(
          child: Text(
            oldGlyph,
            style: _withOpacity(widget.textStyle, opacity),
          ),
        ),
      ),
    );
  }

  Widget _buildInsertionAnimation(String newGlyph) {
    final progress = widget.animation.value;
    final width = lerpDouble(0.0, _getGlyphWidth(newGlyph), progress)!;
    final height = _getReferenceHeight();
    final opacity = progress;

    return SizedBox(
      width: width,
      height: height,
      child: ClipRect(
        child: Center(
          child: Text(
            newGlyph,
            style: _withOpacity(widget.textStyle, opacity),
          ),
        ),
      ),
    );
  }

  // --- Animation builders ---

  Widget _buildAnimatedGlyph() {
    switch (widget.animationStyle) {
      case NumberFlowAnimation.slide:
        return _buildSlideAnimation();
      case NumberFlowAnimation.crossFade:
        return _buildCrossFadeAnimation();
      case NumberFlowAnimation.slideFade:
        return _buildSlideFadeAnimation();
      case NumberFlowAnimation.spin:
        return _buildSpinAnimation();
    }
  }

  Widget _buildSlideAnimation() {
    final String? oldGlyph = widget.oldGlyph;
    final String? newGlyph = widget.newGlyph;

    if (newGlyph == null && oldGlyph != null) {
      return _buildDeletionAnimation(oldGlyph);
    }
    if (newGlyph == null) return const SizedBox.shrink();
    if (oldGlyph == null) return _buildInsertionAnimation(newGlyph);
    if (oldGlyph == newGlyph) return _buildStaticGlyph(newGlyph);

    final width = _calculateAnimatedWidth();
    final height = _getReferenceHeight();
    final progress = widget.animation.value;
    final dir = widget.direction.toDouble();

    return SizedBox(
      width: width,
      height: height,
      child: ClipRect(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Transform.translate(
              offset: Offset(0, -height * progress * dir),
              child: Text(oldGlyph, style: widget.textStyle),
            ),
            Transform.translate(
              offset: Offset(0, height * (1 - progress) * dir),
              child: Text(newGlyph, style: widget.textStyle),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCrossFadeAnimation() {
    final String? oldGlyph = widget.oldGlyph;
    final String? newGlyph = widget.newGlyph;

    if (newGlyph == null && oldGlyph != null) {
      return _buildDeletionAnimation(oldGlyph);
    }
    if (newGlyph == null) return const SizedBox.shrink();
    if (oldGlyph == null) return _buildInsertionAnimation(newGlyph);
    if (oldGlyph == newGlyph) return _buildStaticGlyph(newGlyph);

    final width = _calculateAnimatedWidth();
    final height = _getReferenceHeight();
    final progress = widget.animation.value;

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            oldGlyph,
            style: _withOpacity(widget.textStyle, 1.0 - progress),
          ),
          Text(
            newGlyph,
            style: _withOpacity(widget.textStyle, progress),
          ),
        ],
      ),
    );
  }

  Widget _buildSlideFadeAnimation() {
    final String? oldGlyph = widget.oldGlyph;
    final String? newGlyph = widget.newGlyph;

    if (newGlyph == null && oldGlyph != null) {
      return _buildDeletionAnimation(oldGlyph);
    }
    if (newGlyph == null) return const SizedBox.shrink();
    if (oldGlyph == null) return _buildInsertionAnimation(newGlyph);
    if (oldGlyph == newGlyph) return _buildStaticGlyph(newGlyph);

    final width = _calculateAnimatedWidth();
    final height = _getReferenceHeight();
    final progress = widget.animation.value;
    final dir = widget.direction.toDouble();

    return SizedBox(
      width: width,
      height: height,
      child: ClipRect(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Transform.translate(
              offset: Offset(0, -height * progress * dir),
              child: Text(
                oldGlyph,
                style: _withOpacity(widget.textStyle, 1.0 - progress),
              ),
            ),
            Transform.translate(
              offset: Offset(0, height * (1 - progress) * dir),
              child: Text(
                newGlyph,
                style: _withOpacity(widget.textStyle, progress),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpinAnimation() {
    final String? oldGlyph = widget.oldGlyph;
    final String? newGlyph = widget.newGlyph;

    if (newGlyph == null && oldGlyph != null) {
      return _buildDeletionAnimation(oldGlyph);
    }
    if (newGlyph == null) return const SizedBox.shrink();
    if (oldGlyph == null) return _buildInsertionAnimation(newGlyph);
    if (oldGlyph == newGlyph) return _buildStaticGlyph(newGlyph);

    // Non-digit characters fall back to slide
    if (!_isDigit(oldGlyph) || !_isDigit(newGlyph)) {
      return _buildSlideAnimation();
    }

    final oldDigit = int.parse(oldGlyph);
    final newDigit = int.parse(newGlyph);
    final sequence =
        _generateSpinSequence(oldDigit, newDigit, widget.direction);

    final width = _calculateAnimatedWidth();
    final height = _getReferenceHeight();
    final progress = widget.animation.value;
    final baseOffset = -progress * (height * (sequence.length - 1));

    // Use Stack + Transform.translate (paint-only offsets) to avoid layout
    // overflow errors that a Column would produce.
    return SizedBox(
      width: width,
      height: height,
      child: ClipRect(
        child: Stack(
          children: [
            for (int i = 0; i < sequence.length; i++)
              Transform.translate(
                offset: Offset(0, baseOffset + i * height),
                child: SizedBox(
                  width: width,
                  height: height,
                  child: Center(
                    child: Text(
                      sequence[i].toString(),
                      style: widget.textStyle,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // --- Metrics ---

  Size _getGlyphSize(String glyph) {
    final metrics = _metricsCache.getMetrics(glyph, widget.textStyle);
    return metrics.size;
  }

  double _getGlyphWidth(String glyph) => _getGlyphSize(glyph).width;
}
