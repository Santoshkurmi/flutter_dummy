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
  final List<Particle> _particles = [];
  final math.Random _random = math.Random();
  
  // Settings & Physics parameters
  int _particleCount = 180;
  double _gravityStrength = 4.0;
  double _speedMultiplier = 1.0;
  String _currentTheme = 'Neon Cosmos';
  
  Offset? _touchPosition;
  bool _isSettingsExpanded = false;
  Size _sandboxSize = Size.zero;
  Duration _lastElapsed = Duration.zero;

  // Particle themes
  final Map<String, List<Color>> _themes = {
    'Neon Cosmos': [
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFFEC4899), // Pink
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFF3B82F6), // Blue
      const Color(0xFFF43F5E), // Rose
    ],
    'Acid Rain': [
      const Color(0xFF10B981), // Emerald
      const Color(0xFF10B981), // Green
      const Color(0xFF84CC16), // Lime
      const Color(0xFFF59E0B), // Amber
      const Color(0xFF06B6D4), // Cyan
    ],
    'Fire & Ice': [
      const Color(0xFFEF4444), // Red
      const Color(0xFFF97316), // Orange
      const Color(0xFFF59E0B), // Amber
      const Color(0xFF3B82F6), // Blue
      const Color(0xFF60A5FA), // Light Blue
    ],
    'Matrix Code': [
      const Color(0xFF22C55E), // Green
      const Color(0xFF4ADE80), // Light Green
      const Color(0xFF15803D), // Dark Green
      const Color(0xFF86EFAC), // Pale Green
    ],
  };

  @override
  void initState() {
    super.initState();
    
    // Set up Ticker for smooth 60fps+ rendering loop
    _ticker = createTicker((elapsed) {
      if (_sandboxSize == Size.zero) return;
      
      double dt = (elapsed.inMicroseconds - _lastElapsed.inMicroseconds) / 1000000.0;
      // Clamp dt to avoid physics glitches during lag spikes
      if (dt > 0.1) dt = 0.1;
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
    final colors = _themes[_currentTheme] ?? _themes['Neon Cosmos']!;
    
    for (int i = 0; i < _particleCount; i++) {
      // Spawn in circular orbital ring
      double angle = _random.nextDouble() * 2 * math.pi;
      double radius = 50 + _random.nextDouble() * 120;
      double px = size.width / 2 + math.cos(angle) * radius;
      double py = size.height / 2 + math.sin(angle) * radius;

      // Tangential velocity for orbital motion
      double speed = 30 + _random.nextDouble() * 40;
      double vx = -math.sin(angle) * speed;
      double vy = math.cos(angle) * speed;

      _particles.add(
        Particle(
          position: Offset(px, py),
          velocity: Offset(vx, vy),
          color: colors[_random.nextInt(colors.length)],
          size: 2.0 + _random.nextDouble() * 4.0,
          maxSpeed: 250 + _random.nextDouble() * 150,
        ),
      );
    }
  }

  void _updatePhysics(double dt) {
    if (_sandboxSize == Size.zero) return;

    final targetCount = _particleCount;
    // Keep list size matching setting
    if (_particles.length < targetCount) {
      final colors = _themes[_currentTheme] ?? _themes['Neon Cosmos']!;
      for (int i = _particles.length; i < targetCount; i++) {
        _particles.add(_spawnSingleRandomParticle(colors));
      }
    } else if (_particles.length > targetCount) {
      _particles.removeRange(targetCount, _particles.length);
    }

    setState(() {
      for (var p in _particles) {
        // 1. Apply Gravitational Pull (Towards Touch Position or Center)
        Offset pullTarget = _touchPosition ?? Offset(_sandboxSize.width / 2, _sandboxSize.height / 2);
        Offset direction = pullTarget - p.position;
        double distance = direction.distance;

        if (distance > 2.0) {
          // Force equation: F = G * strength / (dist^1.5 + offset)
          double factor = _touchPosition != null ? 18000 : 8000;
          double force = (_gravityStrength * factor) / (math.pow(distance, 1.4) + 120);
          
          Offset accel = (direction / distance) * force;
          p.velocity += accel * dt * _speedMultiplier;
        }

        // 2. Add dynamic orbital swirl when touched
        if (_touchPosition != null && distance > 5.0) {
          // Tangential vector (perpendicular to gravity)
          Offset swirlVec = Offset(-direction.dy, direction.dx) / distance;
          double swirlForce = (_gravityStrength * 4000) / (distance + 150);
          p.velocity += swirlVec * swirlForce * dt * _speedMultiplier;
        }

        // 3. Position update
        p.position += p.velocity * dt * _speedMultiplier;

        // 4. Drag / Friction to stabilize orbits
        double drag = _touchPosition != null ? 0.995 : 0.988;
        p.velocity *= math.pow(drag, dt * 60.0).toDouble();

        // 5. Speed Cap
        double currentSpeed = p.velocity.distance;
        if (currentSpeed > p.maxSpeed) {
          p.velocity = (p.velocity / currentSpeed) * p.maxSpeed;
        }

        // 6. Border Collision (bounce with energy loss)
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

  Particle _spawnSingleRandomParticle(List<Color> colors) {
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
      color: colors[_random.nextInt(colors.length)],
      size: 2.0 + _random.nextDouble() * 4.0,
      maxSpeed: 250 + _random.nextDouble() * 150,
    );
  }

  void _triggerExplosion(Offset touchPos) {
    final double explosionForce = 700.0;
    setState(() {
      for (var p in _particles) {
        Offset direction = p.position - touchPos;
        double distance = direction.distance;
        if (distance < 5.0) distance = 5.0;
        
        // Closer particles pushed harder
        double force = explosionForce * (200.0 / (distance + 50.0));
        p.velocity += (direction / distance) * force;
      }
    });
  }

  void _changeTheme(String themeName) {
    setState(() {
      _currentTheme = themeName;
      final colors = _themes[_currentTheme]!;
      for (var p in _particles) {
        p.color = colors[_random.nextInt(colors.length)];
      }
    });
  }

  void _resetSimulation() {
    if (_sandboxSize != Size.zero) {
      _initializeParticles(_sandboxSize);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070714),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Background grid/stars aesthetic
          CustomPaint(
            painter: CosmicBackgroundPainter(),
          ),

          // 2. Interactive Physics Particle Sandbox
          LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(constraints.maxWidth, constraints.maxHeight);
              if (_sandboxSize == Size.zero) {
                // Initialize on first layout check
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  setState(() {
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
                onDoubleTapDown: (details) {
                  _triggerExplosion(details.localPosition);
                },
                child: CustomPaint(
                  painter: ParticleSandboxPainter(
                    particles: _particles,
                    touchPosition: _touchPosition,
                  ),
                  size: Size.infinite,
                ),
              );
            },
          ),

          // 3. Top Header Bar (Premium Minimalist Glassmorphism)
          Positioned(
            top: 48,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      color: Colors.white.withValues(alpha: 0.06),
                      child: Row(
                        children: [
                          Icon(Icons.auto_awesome_rounded, color: Colors.cyanAccent.withValues(alpha: 0.9), size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Easter Egg'.tr,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      color: Colors.white.withValues(alpha: 0.06),
                      child: IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 4. Instructions Floating Prompt
          if (_touchPosition == null)
            const Positioned(
              bottom: 240,
              left: 0,
              right: 0,
              child: Center(
                child: IgnorePointer(
                  child: Column(
                    children: [
                      Icon(Icons.touch_app_rounded, color: Colors.white30, size: 28),
                      SizedBox(height: 8),
                      Text(
                        'Touch and Drag to control gravity',
                        style: TextStyle(color: Colors.white38, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Double Tap for shockwave explosion',
                        style: TextStyle(color: Colors.white30, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 5. Collapsible Physics Tuning Glass Console
          Positioned(
            bottom: 24,
            left: 20,
            right: 20,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.fastOutSlowIn,
                  color: const Color(0xFF0F0E26).withValues(alpha: 0.75),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Console Title Row
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          setState(() {
                            _isSettingsExpanded = !_isSettingsExpanded;
                          });
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.tune_rounded, color: Colors.pinkAccent.withValues(alpha: 0.9), size: 20),
                                const SizedBox(width: 10),
                                Text(
                                  'Quantum Sandbox Settings'.tr,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Icon(
                              _isSettingsExpanded ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_up_rounded,
                              color: Colors.white70,
                            ),
                          ],
                        ),
                      ),

                      if (_isSettingsExpanded) ...[
                        const SizedBox(height: 20),
                        // Sliders & Customizations
                        _buildSliderRow(
                          label: 'Cosmos Density'.tr,
                          value: '$_particleCount',
                          slider: Slider(
                            value: _particleCount.toDouble(),
                            min: 50,
                            max: 450,
                            divisions: 8,
                            activeColor: Colors.pinkAccent,
                            inactiveColor: Colors.white10,
                            onChanged: (val) {
                              setState(() {
                                _particleCount = val.round();
                              });
                            },
                          ),
                        ),
                        _buildSliderRow(
                          label: 'Gravity Power'.tr,
                          value: _gravityStrength.toStringAsFixed(1),
                          slider: Slider(
                            value: _gravityStrength,
                            min: 1.0,
                            max: 10.0,
                            activeColor: Colors.cyanAccent,
                            inactiveColor: Colors.white10,
                            onChanged: (val) {
                              setState(() {
                                _gravityStrength = val;
                              });
                            },
                          ),
                        ),
                        _buildSliderRow(
                          label: 'Quantum Speed'.tr,
                          value: '${_speedMultiplier.toStringAsFixed(1)}x',
                          slider: Slider(
                            value: _speedMultiplier,
                            min: 0.2,
                            max: 2.5,
                            activeColor: Colors.amberAccent,
                            inactiveColor: Colors.white10,
                            onChanged: (val) {
                              setState(() {
                                _speedMultiplier = val;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        
                        // Theme Switcher Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Color Spectrum:'.tr,
                              style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            Wrap(
                              spacing: 6,
                              children: _themes.keys.map((themeName) {
                                bool isSelected = _currentTheme == themeName;
                                return ChoiceChip(
                                  label: Text(
                                    themeName.tr,
                                    style: TextStyle(
                                      color: isSelected ? Colors.black : Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  selected: isSelected,
                                  selectedColor: Colors.white,
                                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                                  onSelected: (bool selected) {
                                    if (selected) {
                                      _changeTheme(themeName);
                                    }
                                  },
                                  showCheckmark: false,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Reset & Clear Options
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.refresh_rounded, size: 16),
                                label: Text('Reset Cosmos'.tr),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white24),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: _resetSimulation,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.flash_on_rounded, size: 16),
                                label: Text('Explosion'.tr),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.pinkAccent,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () {
                                  _triggerExplosion(Offset(_sandboxSize.width / 2, _sandboxSize.height / 2));
                                },
                              ),
                            ),
                          ],
                        )
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderRow({required String label, required String value, required Widget slider}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          SizedBox(
            width: 95,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: slider),
          SizedBox(
            width: 35,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
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

class ParticleSandboxPainter extends CustomPainter {
  final List<Particle> particles;
  final Offset? touchPosition;

  ParticleSandboxPainter({required this.particles, this.touchPosition});

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

    // Draw particles with glowing trails
    for (var p in particles) {
      // Glow/Trail effect using drop-shadow-like circles with lower opacity
      paint.color = p.color.withValues(alpha: 0.18);
      canvas.drawCircle(p.position, p.size * 2.2, paint);

      // Core particle
      paint.color = p.color;
      canvas.drawCircle(p.position, p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ParticleSandboxPainter oldDelegate) => true;
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
    final random = math.Random(12345); // Seeded for persistent grid placement
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
