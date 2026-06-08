import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Full-screen themed background: a volcano energy image, darkened, with a
/// vertical gradient so foreground UI stays readable.
class AppBackground extends StatelessWidget {
  final String image;
  final Widget child;
  final double darken;
  const AppBackground({super.key, required this.image, required this.child, this.darken = 0.55});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(image, fit: BoxFit.cover, gaplessPlayback: true),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: darken * 0.7),
                Colors.black.withValues(alpha: darken),
                Colors.black.withValues(alpha: (darken + 0.2).clamp(0.0, 1.0)),
              ],
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// A frosted, rounded panel used throughout the menus.
class GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? border;
  final double radius;
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.border,
    this.radius = 22,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: color ?? AppColors.bgPanel.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: border ?? Colors.white.withValues(alpha: 0.08), width: 1.2),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// A button that scales down while pressed for tactile feedback.
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  const Pressable({super.key, required this.child, this.onTap, this.scale = 0.94});

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.onTap != null;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _down = true) : null,
      onTapUp: enabled ? (_) => setState(() => _down = false) : null,
      onTapCancel: enabled ? () => setState(() => _down = false) : null,
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? widget.scale : 1.0,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        child: Opacity(opacity: enabled ? 1 : 0.5, child: widget.child),
      ),
    );
  }
}

/// A glossy gradient call-to-action button.
class GradientButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final Gradient gradient;
  final double height;
  final double fontSize;
  const GradientButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.gradient = AppColors.lavaGradient,
    this.height = 60,
    this.fontSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(height / 2),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.last.withValues(alpha: 0.5),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: Colors.white, size: fontSize + 4),
                const SizedBox(width: 10),
              ],
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.display(fontSize, color: Colors.white).copyWith(
                    shadows: [const Shadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2))],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small round icon button (for back, settings, etc).
class CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final Color? color;
  const CircleIconButton({super.key, required this.icon, this.onTap, this.size = 46, this.color});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.bgPanel.withValues(alpha: 0.8),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Icon(icon, color: color ?? AppColors.textPrimary, size: size * 0.5),
      ),
    );
  }
}

/// A pill showing a currency value with an icon.
class CurrencyPill extends StatelessWidget {
  final IconData icon;
  final String value;
  final Gradient gradient;
  final Color iconColor;
  const CurrencyPill({
    super.key,
    required this.icon,
    required this.value,
    this.gradient = AppColors.lavaGradient,
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 5, 16, 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(gradient: gradient, shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 8),
          Text(value, style: AppText.display(18)),
        ],
      ),
    );
  }
}

/// Section header with a glowing accent bar.
class SectionTitle extends StatelessWidget {
  final String text;
  final Color accent;
  const SectionTitle(this.text, {super.key, this.accent = AppColors.lava});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 5, height: 22, decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 10),
        Text(text, style: AppText.display(22)),
      ],
    );
  }
}
