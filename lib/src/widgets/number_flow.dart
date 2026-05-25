import 'package:flutter/material.dart';
import 'package:flutter_number_flow/flutter_number_flow.dart';
import '../core/diff.dart';
import '../render/glyph_stack.dart';
import '../render/mask.dart';

/// Default animation curve for NumberFlow widgets.
const Curve kNumberFlowDefaultCurve = Curves.easeOutCubic;

/// A Flutter widget that animates number changes with smooth, customizable transitions.
///
/// The [NumberFlow] widget displays numbers with smooth animations when the value changes.
/// It supports multiple animation styles, locale-aware formatting, and performance optimizations.
///
/// Example usage:
/// ```dart
/// NumberFlow(
///   value: 1234.56,
///   format: const NumberFlowFormat(
///     prefix: '\$',
///     minimumFractionDigits: 2,
///   ),
///   textStyle: const TextStyle(fontSize: 32),
///   animationStyle: NumberFlowAnimation.slide,
/// )
/// ```
///
/// The widget only animates digits that actually change, keeping unchanged digits stable
/// for a professional appearance. It uses tabular figures for consistent spacing and
/// caches text metrics for optimal performance.
///
/// See also:
/// * [NumberFlowFormat] for formatting options
/// * [NumberFlowAnimation] for available animation styles
/// * [NumberFlowGroupProvider] for synchronizing multiple widgets
class NumberFlow extends StatefulWidget {
  const NumberFlow({
    super.key,
    required this.value,
    this.previousValue,
    this.textStyle,
    this.duration = const Duration(milliseconds: 600),
    this.curve = kNumberFlowDefaultCurve,
    this.animationStyle = NumberFlowAnimation.slide,
    this.format,
    this.textAlign = TextAlign.center,
    this.groupKey,
    this.scrubProgress,
    this.enableMask = true,
    this.maskConfig = const MaskConfig(),
    this.stagger = false,
    this.staggerFactor = 0.04,
    this.staggerDirection = StaggerDirection.rightToLeft,
  });

  /// Current number value to display
  final num value;

  /// Previous number value for animation (null means no animation)
  final num? previousValue;

  /// Text style for the number display
  final TextStyle? textStyle;

  /// Animation duration
  final Duration duration;

  /// Animation curve
  final Curve curve;

  /// Animation style to use
  final NumberFlowAnimation animationStyle;

  /// Number formatting configuration
  final NumberFlowFormat? format;

  /// Text alignment within the widget
  final TextAlign textAlign;

  /// Group key for synchronized animations (null means no grouping)
  final String? groupKey;

  /// Manual animation progress override (0.0 to 1.0, null means automatic)
  final double? scrubProgress;

  /// Whether to enable edge masking
  final bool enableMask;

  /// Configuration for edge masking
  final MaskConfig maskConfig;

  /// Whether to enable per-digit staggered animations
  final bool stagger;

  /// Factor controlling the stagger delay between digits (0.0 to 1.0).
  /// Higher values increase the delay between each digit's animation start.
  final double staggerFactor;

  /// Direction in which the stagger delay is applied across digits
  final StaggerDirection staggerDirection;

  @override
  State<NumberFlow> createState() => _NumberFlowState();
}

class _NumberFlowState extends State<NumberFlow> with TickerProviderStateMixin {
  late AnimationController _localController;
  late Animation<double> _animation;
  late NumberFormatter _formatter;

  String _currentText = '';
  String _previousText = '';
  List<CharacterDiff> _diffs = [];
  int _direction = 1;
  final List<CurvedAnimation> _staggeredAnimations = [];

  @override
  void initState() {
    super.initState();

    // Initialize local animation controller
    _localController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _localController,
      curve: widget.curve,
    );

    // Initialize formatter
    _formatter = NumberFormatter(widget.format ?? const NumberFlowFormat());
    _formatter.initialize();

    // Compute initial direction from previousValue
    if (widget.previousValue != null) {
      _direction = widget.value > widget.previousValue! ? 1 : -1;
    }

    // Format initial values
    _updateFormattedValues();
    _rebuildDigitAnimations();
  }

  @override
  void didUpdateWidget(NumberFlow oldWidget) {
    super.didUpdateWidget(oldWidget);

    bool shouldAnimate = false;

    // Update animation duration if changed
    if (widget.duration != oldWidget.duration) {
      _localController.duration = widget.duration;
    }

    // Update animation curve if changed
    if (widget.curve != oldWidget.curve) {
      _animation = CurvedAnimation(
        parent: _getEffectiveController(),
        curve: widget.curve,
      );
    }

    // Update formatter if format changed
    if (widget.format != oldWidget.format) {
      _formatter = NumberFormatter(widget.format ?? const NumberFlowFormat());
      _formatter.initialize();
      shouldAnimate = true;
    }

    // Check if value changed - this is the main trigger for animation
    if (widget.value != oldWidget.value) {
      _direction = widget.value > oldWidget.value ? 1 : -1;
      shouldAnimate = true;
    }

    // Trigger animation if needed
    if (shouldAnimate) {
      // Store the old value as previous for animation
      final oldValue = oldWidget.value;
      _updateFormattedValues(oldValue);
      _rebuildDigitAnimations();
      _startAnimation();
    }

    // Rebuild staggered animations if stagger params changed
    if (widget.stagger != oldWidget.stagger ||
        widget.staggerFactor != oldWidget.staggerFactor ||
        widget.staggerDirection != oldWidget.staggerDirection) {
      _rebuildDigitAnimations();
    }
  }

  @override
  void dispose() {
    _disposeStaggeredAnimations();
    _localController.dispose();
    super.dispose();
  }

  void _disposeStaggeredAnimations() {
    for (final anim in _staggeredAnimations) {
      anim.dispose();
    }
    _staggeredAnimations.clear();
  }

  void _rebuildDigitAnimations() {
    _disposeStaggeredAnimations();

    if (!widget.stagger || _diffs.isEmpty) return;

    final controller = _getEffectiveController();
    final totalDiffs = _diffs.length;

    for (int i = 0; i < totalDiffs; i++) {
      final effectiveIndex =
          widget.staggerDirection == StaggerDirection.rightToLeft
              ? (totalDiffs - 1 - i)
              : i;
      final start = (effectiveIndex * widget.staggerFactor).clamp(0.0, 0.7);
      _staggeredAnimations.add(
        CurvedAnimation(
          parent: controller,
          curve: Interval(start, 1.0, curve: widget.curve),
        ),
      );
    }
  }

  /// Get the effective animation controller (group or local)
  AnimationController _getEffectiveController() {
    if (widget.groupKey != null) {
      final group = NumberFlowGroup.findByKey(context, widget.groupKey!);
      return group?.controller ?? _localController;
    }
    return _localController;
  }

  /// Update formatted text values and calculate diffs
  void _updateFormattedValues([num? oldValue]) {
    _previousText = _currentText;
    _currentText = _formatter.formatNumber(widget.value);

    // Use the provided old value, widget.previousValue, or current text as fallback
    if (oldValue != null) {
      _previousText = _formatter.formatNumber(oldValue);
    } else if (widget.previousValue != null) {
      _previousText = _formatter.formatNumber(widget.previousValue!);
    }

    _diffs = StringDiffer.calculateDiff(_previousText, _currentText);
  }

  /// Start the animation
  void _startAnimation() {
    // Don't auto-animate if we're in manual scrub mode
    if (widget.scrubProgress != null) {
      return;
    }

    final controller = _getEffectiveController();
    controller.reset();
    controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveTextStyle = _getEffectiveTextStyle();

    Widget content = AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => _buildNumberDisplay(effectiveTextStyle),
    );

    // Apply text alignment
    content = _applyAlignment(content);

    // Apply edge masking if enabled
    if (widget.enableMask) {
      content = EdgeMask(
        config: widget.maskConfig,
        child: content,
      );
    }

    // Add semantics for accessibility
    return Semantics(
      label: _currentText,
      child: ExcludeSemantics(child: content),
    );
  }

  /// Get effective text style with tabular figures
  TextStyle _getEffectiveTextStyle() {
    final baseStyle = widget.textStyle ?? DefaultTextStyle.of(context).style;
    return baseStyle.copyWith(
      fontFeatures: [
        const FontFeature.tabularFigures(),
        ...?baseStyle.fontFeatures,
      ],
    );
  }

  /// Build the number display using glyph stacks
  Widget _buildNumberDisplay(TextStyle textStyle) {
    final glyphWidgets = <Widget>[];

    for (int i = 0; i < _diffs.length; i++) {
      final diff = _diffs[i];
      final digitAnimation =
          widget.stagger && i < _staggeredAnimations.length
              ? _staggeredAnimations[i]
              : _animation;

      glyphWidgets.add(
        GlyphStack(
          oldGlyph: diff.oldChar,
          newGlyph: diff.newChar,
          textStyle: textStyle,
          animation: digitAnimation,
          animationStyle: widget.animationStyle,
          direction: _direction,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: glyphWidgets,
    );
  }

  /// Apply text alignment to content
  Widget _applyAlignment(Widget content) {
    switch (widget.textAlign) {
      case TextAlign.left:
      case TextAlign.start:
        return Align(alignment: Alignment.centerLeft, child: content);
      case TextAlign.right:
      case TextAlign.end:
        return Align(alignment: Alignment.centerRight, child: content);
      case TextAlign.center:
        return Align(alignment: Alignment.center, child: content);
      case TextAlign.justify:
        return content; // No special alignment for justify
    }
  }
}
