/// Flutter Number Flow - A Flutter widget that animates number changes with smooth transitions.
///
/// This library provides widgets and utilities for creating smooth number animations
/// with various animation styles (slide, spin, crossFade) and locale-aware formatting.
/// Perfect for displaying animated counters, currency values, statistics, and more.
library flutter_number_flow;

export 'src/widgets/number_flow.dart';
export 'src/core/formatter.dart';
export 'src/widgets/number_flow_group.dart';

/// Animation styles available for NumberFlow widget
enum NumberFlowAnimation {
  /// Slides digits vertically during transitions
  slide,

  /// Cross-fades between old and new digits
  crossFade,

  /// Combines slide and fade for a smooth transition
  slideFade,

  /// Spins/rolls through intermediate digits like an odometer
  spin,
}

/// Number notation styles for formatting
enum NumberNotation {
  /// Standard notation (e.g., 1,234.56)
  standard,

  /// Compact notation (e.g., 1.2K, 1.2M)
  compact,
}

/// Direction for per-digit staggered animations
enum StaggerDirection {
  /// Stagger from left digit to right digit
  leftToRight,

  /// Stagger from right digit to left digit
  rightToLeft,
}
