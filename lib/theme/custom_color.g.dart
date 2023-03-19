import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';

const xanthous = Color(0xFFFFC248);


CustomColors lightCustomColors = const CustomColors(
  sourceXanthous: Color(0xFFFFC248),
  xanthous: Color(0xFF7C5800),
  onXanthous: Color(0xFFFFFFFF),
  xanthousContainer: Color(0xFFFFDEA7),
  onXanthousContainer: Color(0xFF271900),
);

CustomColors darkCustomColors = const CustomColors(
  sourceXanthous: Color(0xFFFFC248),
  xanthous: Color(0xFFF9BC43),
  onXanthous: Color(0xFF412D00),
  xanthousContainer: Color(0xFF5E4200),
  onXanthousContainer: Color(0xFFFFDEA7),
);



/// Defines a set of custom colors, each comprised of 4 complementary tones.
///
/// See also:
///   * <https://m3.material.io/styles/color/the-color-system/custom-colors>
@immutable
class CustomColors extends ThemeExtension<CustomColors> {
  const CustomColors({
    required this.sourceXanthous,
    required this.xanthous,
    required this.onXanthous,
    required this.xanthousContainer,
    required this.onXanthousContainer,
  });

  final Color? sourceXanthous;
  final Color? xanthous;
  final Color? onXanthous;
  final Color? xanthousContainer;
  final Color? onXanthousContainer;

  @override
  CustomColors copyWith({
    Color? sourceXanthous,
    Color? xanthous,
    Color? onXanthous,
    Color? xanthousContainer,
    Color? onXanthousContainer,
  }) {
    return CustomColors(
      sourceXanthous: sourceXanthous ?? this.sourceXanthous,
      xanthous: xanthous ?? this.xanthous,
      onXanthous: onXanthous ?? this.onXanthous,
      xanthousContainer: xanthousContainer ?? this.xanthousContainer,
      onXanthousContainer: onXanthousContainer ?? this.onXanthousContainer,
    );
  }

  @override
  CustomColors lerp(ThemeExtension<CustomColors>? other, double t) {
    if (other is! CustomColors) {
      return this;
    }
    return CustomColors(
      sourceXanthous: Color.lerp(sourceXanthous, other.sourceXanthous, t),
      xanthous: Color.lerp(xanthous, other.xanthous, t),
      onXanthous: Color.lerp(onXanthous, other.onXanthous, t),
      xanthousContainer: Color.lerp(xanthousContainer, other.xanthousContainer, t),
      onXanthousContainer: Color.lerp(onXanthousContainer, other.onXanthousContainer, t),
    );
  }

  /// Returns an instance of [CustomColors] in which the following custom
  /// colors are harmonized with [dynamic]'s [ColorScheme.primary].
  ///   * [CustomColors.sourceXanthous]
  ///   * [CustomColors.xanthous]
  ///   * [CustomColors.onXanthous]
  ///   * [CustomColors.xanthousContainer]
  ///   * [CustomColors.onXanthousContainer]
  ///
  /// See also:
  ///   * <https://m3.material.io/styles/color/the-color-system/custom-colors#harmonization>
  CustomColors harmonized(ColorScheme dynamic) {
    return copyWith(
      sourceXanthous: sourceXanthous!.harmonizeWith(dynamic.primary),
      xanthous: xanthous!.harmonizeWith(dynamic.primary),
      onXanthous: onXanthous!.harmonizeWith(dynamic.primary),
      xanthousContainer: xanthousContainer!.harmonizeWith(dynamic.primary),
      onXanthousContainer: onXanthousContainer!.harmonizeWith(dynamic.primary),
    );
  }
}