import 'package:flutter/material.dart';

/// Neumorphic design system for Sendy
/// Soft UI with embossed/debossed shadows on a light background
class NeuColors {
  static const Color background = Color(0xFFE8ECF1);
  static const Color surface = Color(0xFFE8ECF1);
  static const Color lightShadow = Color(0xFFFFFFFF);
  static const Color darkShadow = Color(0xFFA3B1C6);
  static const Color accent = Color(0xFFFF5722);
  static const Color accentLight = Color(0xFFFF7043);
  static const Color textPrimary = Color(0xFF2D3436);
  static const Color textSecondary = Color(0xFF636E72);
  static const Color textHint = Color(0xFFB2BEC3);
  static const Color success = Color(0xFF00B894);
  static const Color error = Color(0xFFD63031);
  static const Color promoGreen = Color(0xFF00B894);
}

class NeuDecoration {
  /// Raised/embossed container (card-like)
  static BoxDecoration raised({
    double radius = 16,
    Color color = NeuColors.background,
    double intensity = 1.0,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: NeuColors.lightShadow.withOpacity(0.8 * intensity),
          offset: Offset(-4 * intensity, -4 * intensity),
          blurRadius: 8 * intensity,
          spreadRadius: 1,
        ),
        BoxShadow(
          color: NeuColors.darkShadow.withOpacity(0.25 * intensity),
          offset: Offset(4 * intensity, 4 * intensity),
          blurRadius: 8 * intensity,
          spreadRadius: 1,
        ),
      ],
    );
  }

  /// Pressed/inset container (input fields, selected states)
  static BoxDecoration pressed({
    double radius = 16,
    Color color = NeuColors.background,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: NeuColors.darkShadow.withOpacity(0.15),
          offset: const Offset(2, 2),
          blurRadius: 4,
        ),
        BoxShadow(
          color: NeuColors.lightShadow.withOpacity(0.7),
          offset: const Offset(-2, -2),
          blurRadius: 4,
        ),
      ],
    );
  }

  /// Flat container (subtle)
  static BoxDecoration flat({
    double radius = 16,
    Color color = NeuColors.background,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
    );
  }

  /// Accent raised button
  static BoxDecoration accentRaised({double radius = 16}) {
    return BoxDecoration(
      gradient: const LinearGradient(
        colors: [NeuColors.accent, NeuColors.accentLight],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: NeuColors.accent.withOpacity(0.3),
          offset: const Offset(0, 4),
          blurRadius: 10,
        ),
        BoxShadow(
          color: NeuColors.lightShadow.withOpacity(0.3),
          offset: const Offset(-2, -2),
          blurRadius: 6,
        ),
      ],
    );
  }
}

/// Neumorphic card widget
class NeuCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final bool isPressed;
  final VoidCallback? onTap;
  final Color? color;

  const NeuCard({
    Key? key,
    required this.child,
    this.padding,
    this.margin,
    this.radius = 16,
    this.isPressed = false,
    this.onTap,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 16),
      decoration: isPressed
          ? NeuDecoration.pressed(radius: radius, color: color ?? NeuColors.background)
          : NeuDecoration.raised(radius: radius, color: color ?? NeuColors.background),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Neumorphic text field
class NeuTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;

  const NeuTextField({
    Key? key,
    this.controller,
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.onChanged,
    this.keyboardType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: NeuDecoration.pressed(radius: 14),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        onChanged: onChanged,
        keyboardType: keyboardType,
        style: const TextStyle(color: NeuColors.textPrimary),
        decoration: InputDecoration(
          hintText: hintText,
          labelText: labelText,
          hintStyle: const TextStyle(color: NeuColors.textHint),
          labelStyle: const TextStyle(color: NeuColors.textSecondary),
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: NeuColors.accent, width: 1.5),
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

/// Neumorphic button
class NeuButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool isAccent;
  final double radius;
  final EdgeInsetsGeometry? padding;

  const NeuButton({
    Key? key,
    this.onPressed,
    required this.child,
    this.isAccent = true,
    this.radius = 14,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isAccent) {
      return GestureDetector(
        onTap: onPressed,
        child: Container(
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: NeuDecoration.accentRaised(radius: radius),
          child: DefaultTextStyle(
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            child: child,
          ),
        ),
      );
    }
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: NeuDecoration.raised(radius: radius),
        child: child,
      ),
    );
  }
}

/// Neumorphic chip (for categories, filters)
class NeuChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final Widget? avatar;

  const NeuChip({
    Key? key,
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.avatar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: isSelected
            ? NeuDecoration.accentRaised(radius: 20)
            : NeuDecoration.raised(radius: 20, intensity: 0.6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (avatar != null) ...[
              avatar!,
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : NeuColors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Neumorphic AppBar theme
class NeuAppBar {
  static AppBar build({
    required String title,
    List<Widget>? actions,
    Widget? leading,
    PreferredSizeWidget? bottom,
  }) {
    return AppBar(
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: 20,
        ),
      ),
      backgroundColor: NeuColors.accent,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: actions,
      leading: leading,
      bottom: bottom,
    );
  }
}

/// Neumorphic bottom navigation bar decoration
BoxDecoration neuBottomNavDecoration() {
  return BoxDecoration(
    color: NeuColors.background,
    boxShadow: [
      BoxShadow(
        color: NeuColors.darkShadow.withOpacity(0.2),
        offset: const Offset(0, -4),
        blurRadius: 10,
      ),
      BoxShadow(
        color: NeuColors.lightShadow.withOpacity(0.8),
        offset: const Offset(0, -1),
        blurRadius: 4,
      ),
    ],
  );
}
