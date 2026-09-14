import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class NeonCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final double borderOpacity;
  final double glowOpacity;
  final VoidCallback? onTap;

  const NeonCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 24,
    this.borderOpacity = 0.3,
    this.glowOpacity = 0.12,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: AppTheme.neonCardDecoration(
          borderOpacity: borderOpacity,
          glowOpacity: glowOpacity,
          radius: borderRadius,
        ),
        child: child,
      ),
    );
  }
}

class PulsingNeonBorder extends StatefulWidget {
  final Widget child;
  final double borderRadius;

  const PulsingNeonBorder({
    super.key,
    required this.child,
    this.borderRadius = 24,
  });

  @override
  State<PulsingNeonBorder> createState() => _PulsingNeonBorderState();
}

class _PulsingNeonBorderState extends State<PulsingNeonBorder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.15, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, child) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: [
            BoxShadow(
              color: AppTheme.neonPink.withOpacity(_pulse.value),
              blurRadius: 20,
              spreadRadius: 0,
            ),
          ],
        ),
        child: child,
      ),
      child: widget.child,
    );
  }
}

class NeonText extends StatefulWidget {
  final String text;
  final TextStyle? style;

  const NeonText({super.key, required this.text, this.style});

  @override
  State<NeonText> createState() => _NeonTextState();
}

class _NeonTextState extends State<NeonText> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
    _glow = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glow,
      builder: (_, __) => Text(
        widget.text,
        style: (widget.style ?? const TextStyle()).copyWith(
          shadows: [
            Shadow(
              color: AppTheme.neonPink.withOpacity(_glow.value),
              blurRadius: 12,
            ),
            Shadow(
              color: AppTheme.neonPink.withOpacity(_glow.value * 0.5),
              blurRadius: 24,
            ),
          ],
        ),
      ),
    );
  }
}

class GradientText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Gradient gradient;
  final TextAlign? textAlign;

  const GradientText({
    super.key,
    required this.text,
    this.style,
    this.gradient = AppTheme.neonGradient,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => gradient.createShader(bounds),
      child: Text(text, style: style, textAlign: textAlign),
    );
  }
}
