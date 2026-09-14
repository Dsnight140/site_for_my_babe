import 'dart:math' as math;
import 'package:flutter/material.dart';

class Particle {
  double x;
  double y;
  double vx;
  double vy;
  double size;
  double opacity;
  double rotation;
  double rotationSpeed;
  String emoji;
  bool rising;

  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.opacity,
    required this.rotation,
    required this.rotationSpeed,
    required this.emoji,
    required this.rising,
  });
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double animValue;

  ParticlePainter(this.particles, this.animValue);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      canvas.save();
      canvas.translate(p.x * size.width, p.y * size.height);
      canvas.rotate(p.rotation);

      final textPainter = TextPainter(
        text: TextSpan(
          text: p.emoji,
          style: TextStyle(fontSize: p.size),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => true;
}

class ParticleBackground extends StatefulWidget {
  final List<String> emojis;
  final int particleCount;

  const ParticleBackground({
    super.key,
    this.emojis = const ['💕', '✨', '🌸', '⭐', '💫'],
    this.particleCount = 18,
  });

  @override
  State<ParticleBackground> createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<ParticleBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Particle> _particles;
  final math.Random _rng = math.Random();

  @override
  void initState() {
    super.initState();
    _spawnParticles();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 50),
    )..addListener(_update)..repeat();
  }

  void _spawnParticles() {
    _particles = List.generate(widget.particleCount, (_) => _newParticle());
  }

  Particle _newParticle({bool fromBottom = false}) {
    return Particle(
      x: _rng.nextDouble(),
      y: fromBottom ? 1.1 : _rng.nextDouble(),
      vx: (_rng.nextDouble() - 0.5) * 0.0008,
      vy: -(_rng.nextDouble() * 0.0015 + 0.0005),
      size: _rng.nextDouble() * 14 + 8,
      opacity: _rng.nextDouble() * 0.5 + 0.2,
      rotation: _rng.nextDouble() * math.pi * 2,
      rotationSpeed: (_rng.nextDouble() - 0.5) * 0.05,
      emoji: widget.emojis[_rng.nextInt(widget.emojis.length)],
      rising: true,
    );
  }

  void _update() {
    if (!mounted) return;
    setState(() {
      for (int i = 0; i < _particles.length; i++) {
        final p = _particles[i];
        p.x += p.vx;
        p.y += p.vy;
        p.rotation += p.rotationSpeed;
        // fade in then out
        if (p.y < 0.8) {
          p.opacity = (p.opacity + 0.005).clamp(0.0, 0.6);
        } else {
          p.opacity = (p.opacity - 0.003).clamp(0.0, 1.0);
        }
        if (p.y < -0.1 || p.opacity <= 0) {
          _particles[i] = _newParticle(fromBottom: true);
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: ParticlePainter(_particles, _controller.value),
        size: Size.infinite,
      ),
    );
  }
}
