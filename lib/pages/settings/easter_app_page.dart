import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../services/translation_service.dart';

class EasterAppPage extends StatefulWidget {
  const EasterAppPage({super.key});

  @override
  State<EasterAppPage> createState() => _EasterAppPageState();
}

class _EasterAppPageState extends State<EasterAppPage> with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  final math.Random _random = math.Random();

  Size _sandboxSize = Size.zero;
  Duration _lastElapsed = Duration.zero;
  Offset? _touchPosition;

  // Maximum capability variables for intense particle physics
  final int _particleCount = 450;
  final double _gravityStrength = 10.0;
  final double _speedMultiplier = 2.0;

  final List<Particle> _particles = [];

  // Default premium Neon Cosmos color palette
  final List<Color> _colors = [
    const Color(0xFF06B6D4), // Cyan
    const Color(0xFFEC4899), // Pink
    const Color(0xFF8B5CF6), // Purple
    const Color(0xFF3B82F6), // Blue
    const Color(0xFFF43F5E), // Rose
  ];

  @override
  void initState() {
    super.initState();

    // Set up Ticker for smooth 60fps+ rendering loop
    _ticker = createTicker((elapsed) {
      if (_sandboxSize == Size.zero) return;

      double dt = (elapsed.inMicroseconds - _lastElapsed.inMicroseconds) / 1000000.0;
      if (dt > 0.1) dt = 0.1; // Clamp to prevent physical calculation glitches
      _lastElapsed = elapsed;

      _updatePhysics(dt);
    });
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _initializeParticles(Size size) {
    _sandboxSize = size;
    _particles.clear();

    for (int i = 0; i < _particleCount; i++) {
      double angle = _random.nextDouble() * 2 * math.pi;
      double radius = 50 + _random.nextDouble() * 120;
      double px = size.width / 2 + math.cos(angle) * radius;
      double py = size.height / 2 + math.sin(angle) * radius;

      double speed = 30 + _random.nextDouble() * 40;
      double vx = -math.sin(angle) * speed;
      double vy = math.cos(angle) * speed;

      _particles.add(
        Particle(
          position: Offset(px, py),
          velocity: Offset(vx, vy),
          color: _colors[_random.nextInt(_colors.length)],
          size: 2.0 + _random.nextDouble() * 4.0,
          maxSpeed: 250 + _random.nextDouble() * 150,
        ),
      );
    }
  }

  Particle _spawnSingleRandomParticle() {
    double angle = _random.nextDouble() * 2 * math.pi;
    double radius = 20 + _random.nextDouble() * 200;
    double px = _sandboxSize.width / 2 + math.cos(angle) * radius;
    double py = _sandboxSize.height / 2 + math.sin(angle) * radius;

    double speed = 10 + _random.nextDouble() * 50;
    double vx = -math.sin(angle) * speed;
    double vy = math.cos(angle) * speed;

    return Particle(
      position: Offset(px, py),
      velocity: Offset(vx, vy),
      color: _colors[_random.nextInt(_colors.length)],
      size: 2.0 + _random.nextDouble() * 4.0,
      maxSpeed: 250 + _random.nextDouble() * 150,
    );
  }

  void _updatePhysics(double dt) {
    if (_sandboxSize == Size.zero) return;

    if (_particles.length < _particleCount) {
      for (int i = _particles.length; i < _particleCount; i++) {
        _particles.add(_spawnSingleRandomParticle());
      }
    } else if (_particles.length > _particleCount) {
      _particles.removeRange(_particleCount, _particles.length);
    }

    setState(() {
      for (var p in _particles) {
        Offset pullTarget = _touchPosition ?? Offset(_sandboxSize.width / 2, _sandboxSize.height / 2);
        Offset direction = pullTarget - p.position;
        double distance = direction.distance;

        if (distance > 2.0) {
          double factor = _touchPosition != null ? 18000 : 8000;
          double force = (_gravityStrength * factor) / (math.pow(distance, 1.4) + 120);
          Offset accel = (direction / distance) * force;
          p.velocity += accel * dt * _speedMultiplier;
        }

        if (_touchPosition != null && distance > 5.0) {
          Offset swirlVec = Offset(-direction.dy, direction.dx) / distance;
          double swirlForce = (_gravityStrength * 4000) / (distance + 150);
          p.velocity += swirlVec * swirlForce * dt * _speedMultiplier;
        }

        p.position += p.velocity * dt * _speedMultiplier;

        double drag = _touchPosition != null ? 0.995 : 0.988;
        p.velocity *= math.pow(drag, dt * 60.0).toDouble();

        double currentSpeed = p.velocity.distance;
        if (currentSpeed > p.maxSpeed) {
          p.velocity = (p.velocity / currentSpeed) * p.maxSpeed;
        }

        if (p.position.dx < 0) {
          p.position = Offset(0, p.position.dy);
          p.velocity = Offset(-p.velocity.dx * 0.6, p.velocity.dy);
        } else if (p.position.dx > _sandboxSize.width) {
          p.position = Offset(_sandboxSize.width, p.position.dy);
          p.velocity = Offset(-p.velocity.dx * 0.6, p.velocity.dy);
        }

        if (p.position.dy < 0) {
          p.position = Offset(p.position.dx, 0);
          p.velocity = Offset(p.velocity.dx, -p.velocity.dy * 0.6);
        } else if (p.position.dy > _sandboxSize.height) {
          p.position = Offset(p.position.dx, _sandboxSize.height);
          p.velocity = Offset(p.velocity.dx, -p.velocity.dy * 0.6);
        }
      }
    });
  }

  void _triggerExplosion(Offset touchPos) {
    final double explosionForce = 700.0;
    setState(() {
      for (var p in _particles) {
        Offset direction = p.position - touchPos;
        double distance = direction.distance;
        if (distance < 5.0) distance = 5.0;

        double force = explosionForce * (200.0 / (distance + 50.0));
        p.velocity += (direction / distance) * force;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070714),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Cosmic Background Stars & Grids
          CustomPaint(
            painter: CosmicBackgroundPainter(),
          ),

          // 2. Interactive Physics Particle Canvas
          LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(constraints.maxWidth, constraints.maxHeight);
              if (_sandboxSize == Size.zero) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  setState(() {
                    _sandboxSize = size;
                    _initializeParticles(size);
                  });
                });
              }

              return GestureDetector(
                onPanStart: (details) {
                  setState(() {
                    _touchPosition = details.localPosition;
                  });
                },
                onPanUpdate: (details) {
                  setState(() {
                    _touchPosition = details.localPosition;
                  });
                },
                onPanEnd: (_) {
                  setState(() {
                    _touchPosition = null;
                  });
                },
                onTapDown: (details) {
                  setState(() {
                    _touchPosition = details.localPosition;
                  });
                },
                onTapUp: (_) {
                  setState(() {
                    _touchPosition = null;
                  });
                },
                onDoubleTap: () {
                  if (_touchPosition != null) {
                    _triggerExplosion(_touchPosition!);
                  } else {
                    _triggerExplosion(Offset(_sandboxSize.width / 2, _sandboxSize.height / 2));
                  }
                },
                child: CustomPaint(
                  painter: CosmicCanvasPainter(
                    particles: _particles,
                    touchPosition: _touchPosition,
                  ),
                  size: Size.infinite,
                ),
              );
            },
          ),

          // 3. Floating Subtle Exit Button (Top-Left)
          Positioned(
            top: 48,
            left: 20,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: Colors.white.withValues(alpha: 0.05),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 16),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ),
          ),

          // 4. Interactive Floating Instructions
          if (_touchPosition == null)
            Positioned(
              bottom: 48,
              left: 0,
              right: 0,
              child: Center(
                child: IgnorePointer(
                  child: Column(
                    children: [
                      const Icon(Icons.touch_app_rounded, color: Colors.white24, size: 28),
                      const SizedBox(height: 8),
                      Text(
                        'Touch and Drag to bend gravity'.tr,
                        style: const TextStyle(color: Colors.white30, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Double Tap to release shockwave'.tr,
                        style: const TextStyle(color: Colors.white24, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class Particle {
  Offset position;
  Offset velocity;
  Color color;
  final double size;
  final double maxSpeed;

  Particle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.size,
    required this.maxSpeed,
  });
}

class CosmicCanvasPainter extends CustomPainter {
  final List<Particle> particles;
  final Offset? touchPosition;

  CosmicCanvasPainter({
    required this.particles,
    this.touchPosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    // Draw gravity well visual feedback
    if (touchPosition != null) {
      final pulsePaint = Paint()
        ..color = Colors.cyanAccent.withValues(alpha: 0.15)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(touchPosition!, 24, pulsePaint);

      final ringPaint = Paint()
        ..color = Colors.cyanAccent.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawCircle(touchPosition!, 40, ringPaint);
    }

    // Draw sandbox particles
    for (var p in particles) {
      paint.color = p.color.withValues(alpha: 0.18);
      canvas.drawCircle(p.position, p.size * 2.2, paint);

      paint.color = p.color;
      canvas.drawCircle(p.position, p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CosmicCanvasPainter oldDelegate) => true;
}

class CosmicBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Background radial glowing gradient
    final gradient = ui.Gradient.radial(
      Offset(size.width / 2, size.height / 2),
      size.width,
      [
        const Color(0xFF140F30),
        const Color(0xFF070714),
      ],
    );

    final bgPaint = Paint()..shader = gradient;
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Dynamic grid aesthetic
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.02)
      ..strokeWidth = 0.8;

    double step = 55.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Static ambient stars
    final starPaint = Paint()..color = Colors.white24;
    final random = math.Random(12345);
    for (int i = 0; i < 40; i++) {
      double sx = random.nextDouble() * size.width;
      double sy = random.nextDouble() * size.height;
      double sz = 0.6 + random.nextDouble() * 1.2;
      canvas.drawCircle(Offset(sx, sy), sz, starPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CosmicBackgroundPainter oldDelegate) => false;
}
