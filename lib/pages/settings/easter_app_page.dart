import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/translation_service.dart';

enum Biome { forest, mountain, sea, rain }

class EasterAppPage extends StatefulWidget {
  const EasterAppPage({super.key});

  @override
  State<EasterAppPage> createState() => _EasterAppPageState();
}

class _EasterAppPageState extends State<EasterAppPage> with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  final math.Random _random = math.Random();

  // Screen/Sandbox Size
  Size _sandboxSize = Size.zero;
  Duration _lastElapsed = Duration.zero;

  // Multi-touch Tracking
  final Map<int, Offset> _activePointers = {};
  bool _isMovingRight = false;

  // Persistence Key
  static const String _highScoreKey = 'biome_explorer_highscore';

  // ----------------------------------------------------
  // GAME STATES
  // ----------------------------------------------------
  double _worldX = 0.0;
  double _distanceTraveled = 0.0;
  int _score = 0;
  int _highScore = 0;
  double _shield = 100.0;
  int _level = 1;
  int _gemCount = 0;

  // Player Physics
  double _playerY = 0.0;
  double _playerVy = 0.0;
  int _jumpCount = 0;
  double _walkCycle = 0.0;
  double _squashStretch = 1.0;
  double _invincibleTimer = 0.0; 

  // Death Countdown State
  double _deathCountdown = 0.0; 

  // Hyper-Speed Boost
  double _speedBoostTimer = 0.0; 

  // Instructions & Double Tap Sprint
  double _instructionTimer = 10.0;
  // Time of Day Cycle (0.0 to 24.0 hours)
  double _timeOfDay = 8.0; 

  // Lightning Flash Effect
  double _lightningTime = 0.0;
  bool _drawLightningBolt = false;

  // Spawners
  double _lastSpawnedPlatformX = 0.0;
  double _lastSpawnedObstacleX = 0.0;
  double _lastSpawnedGemX = 0.0;
  double _lastSpawnedUndergroundX = 0.0;
  double _lastSpawnedDecoX = 0.0;
  double _lastSpawnedCreatureX = 0.0;
  double _particleSpawnTimer = 0.0;
  double _backAnimalSpawnTimer = 0.0;

  // Screen shake variables
  double _shakeDuration = 0.0;
  double _shakeIntensity = 0.0;
  Offset _shakeOffset = Offset.zero;

  // Game lists
  final List<GamePlatform> _platforms = [];
  final List<Obstacle> _obstacles = [];
  final List<CosmicGem> _gems = [];
  final List<BiomeParticle> _particles = [];
  final List<FloatingText> _floatingTexts = [];
  final List<Offset> _capeTrail = [];
  final List<BackgroundAnimal> _backAnimals = [];
  final List<UndergroundDetail> _undergroundDetails = [];
  final List<SurfaceDeco> _surfaceDecos = [];
  final List<Creature> _creatures = [];

  @override
  void initState() {
    super.initState();
    _loadHighScore();

    // Setup smooth ticker loop
    _ticker = createTicker((elapsed) {
      if (_sandboxSize == Size.zero) return;

      double dt = (elapsed.inMicroseconds - _lastElapsed.inMicroseconds) / 1000000.0;
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

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _highScore = prefs.getInt(_highScoreKey) ?? 0;
    });
  }

  Future<void> _saveHighScore() async {
    if (_score > _highScore) {
      _highScore = _score;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_highScoreKey, _highScore);
    }
  }

  // ----------------------------------------------------
  // BIOME DEFINITIONS & HEIGHT MAP
  // ----------------------------------------------------
  Biome _getBiomeAt(double x) {
    int index = (x ~/ 1200) % Biome.values.length;
    return Biome.values[index];
  }

  // Butter-smooth continuous height function with large high-low variation
  double _getGroundHeight(double x) {
    double base = _sandboxSize.height - 230;

    double hill1 = math.sin(x * 0.0011) * 65.0;
    double hill2 = math.cos(x * 0.00045) * 40.0;
    double hill3 = math.sin(x * 0.003) * 15.0;

    return base - (hill1 + hill2 + hill3);
  }

  // Smooth step ground style interpolation
  GroundStyle _getGroundStyle(double x) {
    double progress = (x / 1200.0);
    int currentIdx = progress.floor() % Biome.values.length;
    int nextIdx = (currentIdx + 1) % Biome.values.length;
    double t = progress - progress.floor();

    double smoothT = t * t * (3.0 - 2.0 * t);

    Biome current = Biome.values[currentIdx];
    Biome next = Biome.values[nextIdx];

    Color currentTop = _getTopColor(current);
    Color nextTop = _getTopColor(next);
    Color top = Color.lerp(currentTop, nextTop, smoothT)!;

    Color currentBottom = _getBottomColor(current);
    Color nextBottom = _getBottomColor(next);
    Color bottom = Color.lerp(currentBottom, nextBottom, smoothT)!;

    Color currentHighlight = _getHighlightColor(current);
    Color nextHighlight = _getHighlightColor(next);
    Color highlight = Color.lerp(currentHighlight, nextHighlight, smoothT)!;

    return GroundStyle(top: top, bottom: bottom, highlight: highlight);
  }

  Color _getTopColor(Biome b) {
    switch (b) {
      case Biome.forest: return const Color(0xFF047857);
      case Biome.mountain: return const Color(0xFF78350F);
      case Biome.sea: return const Color(0xFF0891B2);
      case Biome.rain: return const Color(0xFF334155);
    }
  }

  Color _getBottomColor(Biome b) {
    switch (b) {
      case Biome.forest: return const Color(0xFF0D1712);
      case Biome.mountain: return const Color(0xFF18120F);
      case Biome.sea: return const Color(0xFF051821);
      case Biome.rain: return const Color(0xFF0B0F19);
    }
  }

  Color _getHighlightColor(Biome b) {
    switch (b) {
      case Biome.forest: return Colors.greenAccent;
      case Biome.mountain: return Colors.amberAccent;
      case Biome.sea: return Colors.cyanAccent;
      case Biome.rain: return Colors.blueAccent;
    }
  }

  // Sky Colors blended by Time of Day
  List<Color> _getSkyColors(double time) {
    if (time >= 5.0 && time < 7.0) {
      double t = (time - 5.0) / 2.0;
      return [
        Color.lerp(const Color(0xFF0D0A21), const Color(0xFF7E22CE), t)!,
        Color.lerp(const Color(0xFF1E1E38), const Color(0xFFF59E0B), t)!,
      ];
    } else if (time >= 7.0 && time < 17.0) {
      return [
        const Color(0xFF0F172A),
        const Color(0xFF0284C7),
      ];
    } else if (time >= 17.0 && time < 19.0) {
      double t = (time - 17.0) / 2.0;
      return [
        Color.lerp(const Color(0xFF0F172A), const Color(0xFF881337), t)!,
        Color.lerp(const Color(0xFF0284C7), const Color(0xFFE11D48), t)!,
      ];
    } else {
      double t = 1.0;
      if (time >= 19.0 && time < 21.0) {
        t = (time - 19.0) / 2.0;
      } else if (time >= 3.0 && time < 5.0) {
        t = 1.0 - ((time - 3.0) / 2.0);
      }
      return [
        Color.lerp(const Color(0xFF0F172A), const Color(0xFF020617), t)!,
        Color.lerp(const Color(0xFFE11D48), const Color(0xFF090D16), t)!,
      ];
    }
  }

  // ----------------------------------------------------
  // GAME LOOP & PHYSICS ENGINE
  // ----------------------------------------------------
  void _updatePhysics(double dt) {
    if (_sandboxSize == Size.zero) return;

    // 1. Screen Shake Decay
    if (_shakeDuration > 0) {
      _shakeDuration -= dt;
      double dx = (_random.nextDouble() - 0.5) * 2 * _shakeIntensity;
      double dy = (_random.nextDouble() - 0.5) * 2 * _shakeIntensity;
      _shakeOffset = Offset(dx, dy);
      if (_shakeDuration <= 0) _shakeOffset = Offset.zero;
    }

    // 2. Invincible & Speed Boost Timers decay
    if (_invincibleTimer > 0) {
      _invincibleTimer -= dt;
    }
    if (_speedBoostTimer > 0) {
      _speedBoostTimer -= dt;
      if (_speedBoostTimer <= 0) {
        _floatingTexts.add(FloatingText(
          position: Offset(100, _playerY - 20),
          text: 'BOOST EXPIRED'.tr,
          color: Colors.pinkAccent,
        ));
      }
    }
    if (_instructionTimer > 0) {
      _instructionTimer -= dt;
    }

    // 3. Death Countdown handling
    if (_deathCountdown > 0) {
      setState(() {
        _deathCountdown -= dt;
        // World does NOT move, player does NOT move
        if (_deathCountdown <= 0) {
          _shield = 100.0;
          _invincibleTimer = 2.5;
          _floatingTexts.add(FloatingText(
            position: Offset(100, _playerY - 40),
            text: 'RE-MATERIALIZED'.tr,
            color: Colors.cyanAccent,
          ));
          _triggerSplash(Offset(100, _playerY), Colors.cyanAccent, count: 25);
        }

        // Keep updating particles, floating text, and sky scenery so it stays alive!
        _timeOfDay = (_timeOfDay + dt * 0.15) % 24.0;
        _updateParticles(dt);
        _updateBackgroundAnimals(dt);
        for (int i = _floatingTexts.length - 1; i >= 0; i--) {
          final ft = _floatingTexts[i];
          ft.position = Offset(ft.position.dx, ft.position.dy - 60.0 * dt);
          ft.age += dt;
          if (ft.age >= 0.7) _floatingTexts.removeAt(i);
        }
      });
      return;
    }

    // 4. Advance time of day
    _timeOfDay = (_timeOfDay + dt * 0.15) % 24.0;

    setState(() {
      double playerAbsX = _worldX + 100.0;

      // 5. Speed calculation (boosted or normal/sprint)
      double speed = 0.0;
      if (_speedBoostTimer > 0) {
        speed = 520.0; // Hyper-speed
      } else {
        speed = _isMovingRight ? 480.0 : 180.0;
      }

      // 6. Scroll world
      _worldX += speed * dt;
      _distanceTraveled += speed * dt * 0.04;
      _level = 1 + (_distanceTraveled ~/ 85);

      // 7. Walk Cycle
      if (_playerVy == 0.0) {
        _walkCycle += speed * 0.065 * dt;
      }

      // 8. Player Vertical physics
      _playerVy += 800.0 * dt; 
      _playerY += _playerVy * dt;

      if (_playerVy != 0.0) {
        _squashStretch = lerpDouble(_squashStretch, 1.0 + (_playerVy.abs() * 0.0006), 0.15) ?? 1.0;
      } else {
        _squashStretch = lerpDouble(_squashStretch, 1.0, 0.2) ?? 1.0;
      }

      double groundY = _getGroundHeight(_worldX + 100.0);

      // Ground collision
      if (_playerY >= groundY - 18) {
        _playerY = groundY - 18;
        _playerVy = 0.0;
        _jumpCount = 0;
      }

      // Platform collision
      if (_playerVy >= 0) {
        for (var plat in _platforms) {
          double px = plat.x - _worldX;
          if (100.0 >= px && 100.0 <= px + plat.width) {
            if (_playerY + 18 >= plat.y && _playerY - 10 <= plat.y) {
              _playerY = plat.y - 18;
              _playerVy = 0.0;
              _jumpCount = 0;
              break;
            }
          }
        }
      }

      // Cape Trail
      _capeTrail.add(Offset(100.0, _playerY));
      if (_capeTrail.length > 8) {
        _capeTrail.removeAt(0);
      }

      // Rain Lightning
      Biome currentBiome = _getBiomeAt(_worldX + 100.0);
      if (currentBiome == Biome.rain) {
        _lightningTime -= dt;
        if (_lightningTime <= 0) {
          if (_random.nextDouble() > 0.84) {
            _lightningTime = 0.35;
            _drawLightningBolt = _random.nextDouble() > 0.5;
            _triggerScreenShake(0.2, 8.0);
          } else {
            _lightningTime = 2.0 + _random.nextDouble() * 5.0;
            _drawLightningBolt = false;
          }
        }
      } else {
        _drawLightningBolt = false;
        _lightningTime = 0.0;
      }

      // 9. Spawners
      double rightEdge = _worldX + _sandboxSize.width + 120;

      // Platforms
      if (_lastSpawnedPlatformX < rightEdge - 280) {
        _lastSpawnedPlatformX = rightEdge;
        if (_random.nextDouble() > 0.38) {
          double py = _getGroundHeight(rightEdge) - 75 - _random.nextDouble() * 80;
          _platforms.add(GamePlatform(
            x: rightEdge,
            y: py,
            width: 110 + _random.nextDouble() * 65,
          ));
        }
      }
      _platforms.removeWhere((plat) => plat.x < _worldX - 200);

      // Gems (Normal, Shield, or Hyper Gem)
      if (_lastSpawnedGemX < rightEdge - 180) {
        _lastSpawnedGemX = rightEdge;
        if (_random.nextDouble() > 0.45) {
          int count = 3 + _random.nextInt(3);
          double startY = _getGroundHeight(rightEdge) - 60 - _random.nextDouble() * 80;
          for (int i = 0; i < count; i++) {
            double rng = _random.nextDouble();
            bool isShield = rng > 0.94;
            bool isHyper = !isShield && rng > 0.86; // Hyper-speed powerup bubble
            _gems.add(CosmicGem(
              x: rightEdge + (i * 35),
              y: startY - math.sin((i / count) * math.pi) * 35,
              isShield: isShield,
              isHyper: isHyper,
              size: 6.5,
            ));
          }
        }
      }
      _gems.removeWhere((gem) => gem.x < _worldX - 100);

      // Obstacles (Spikes, Stones, Thorns, Shrooms, Steam Vents)
      if (_lastSpawnedObstacleX < rightEdge - 300) {
        _lastSpawnedObstacleX = rightEdge;
        if (_random.nextDouble() > 0.45) {
          double gY = _getGroundHeight(rightEdge);
          List<String> types = ['spike', 'stone', 'thorn', 'shroom', 'steam_vent'];
          String chosen = types[_random.nextInt(types.length)];
          _obstacles.add(Obstacle(
            x: rightEdge,
            y: gY - 12,
            size: chosen == 'steam_vent' ? 16.0 : 13.0,
            type: chosen,
          ));
        }
      }
      _obstacles.removeWhere((obs) => obs.x < _worldX - 100);

      // Surface Decorations
      if (_lastSpawnedDecoX < rightEdge - 110) {
        _lastSpawnedDecoX = rightEdge;
        if (_random.nextDouble() > 0.2) {
          double gy = _getGroundHeight(rightEdge);
          List<String> types = ['flower', 'mushroom', 'pebble', 'bush'];
          String type = types[_random.nextInt(types.length)];
          _surfaceDecos.add(SurfaceDeco(
            x: rightEdge,
            y: gy,
            type: type,
            size: 8.0 + _random.nextDouble() * 8.0,
          ));
        }
      }
      _surfaceDecos.removeWhere((sd) => sd.x < _worldX - 100);

      // Subterranean Details (Underground Crystals, Fossil, Roots, Gold, Cave Worms)
      if (_lastSpawnedUndergroundX < rightEdge - 200) {
        _lastSpawnedUndergroundX = rightEdge;
        if (_random.nextDouble() > 0.25) {
          double gy = _getGroundHeight(rightEdge);
          double uy = gy + 40 + _random.nextDouble() * 110;
          List<String> types = ['crystals', 'fossil', 'roots', 'mineral', 'gold_ore', 'worm'];
          String type = types[_random.nextInt(types.length)];
          _undergroundDetails.add(UndergroundDetail(
            x: rightEdge,
            y: uy,
            type: type,
            size: 16.0 + _random.nextDouble() * 14.0,
          ));
        }
      }
      _undergroundDetails.removeWhere((ud) => ud.x < _worldX - 100);

      // Erratic Creatures (Rabbit, Eagle, Butterfly)
      if (_lastSpawnedCreatureX < rightEdge - 420) {
        _lastSpawnedCreatureX = rightEdge;
        if (_random.nextDouble() > 0.35) {
          double gy = _getGroundHeight(rightEdge);
          double rand = _random.nextDouble();
          if (rand < 0.35) {
            _creatures.add(Creature(x: rightEdge, y: gy, type: 'rabbit', speed: 85.0));
          } else if (rand < 0.7) {
            _creatures.add(Creature(x: rightEdge, y: gy - 180 - _random.nextDouble() * 40, type: 'eagle', speed: 130.0));
          } else {
            _creatures.add(Creature(x: rightEdge, y: gy - 60 - _random.nextDouble() * 50, type: 'butterfly', speed: 45.0));
          }
        }
      }
      _creatures.removeWhere((c) => c.x < _worldX - 100);

      // 10. Update Peaceful Background Animals
      _backAnimalSpawnTimer += dt;
      if (_backAnimalSpawnTimer >= 5.0) {
        _backAnimalSpawnTimer = 0.0;
        _spawnBackgroundAnimal(currentBiome);
      }
      _updateBackgroundAnimals(dt);

      // 11. Update Particles
      _particleSpawnTimer += dt;
      if (_particleSpawnTimer >= 0.08) {
        _particleSpawnTimer = 0.0;
        _spawnAmbientParticles(currentBiome);
      }
      _updateParticles(dt);

      // Night Fireflies
      if (_timeOfDay > 18.0 || _timeOfDay < 5.0) {
        if (_random.nextDouble() > 0.88) {
          _particles.add(BiomeParticle(
            position: Offset(_random.nextDouble() * _sandboxSize.width, _getGroundHeight(_worldX + 100) - 20 - _random.nextDouble() * 80),
            velocity: Offset(-20 - _random.nextDouble() * 30, (_random.nextDouble() - 0.5) * 20),
            color: Colors.yellowAccent.withValues(alpha: 0.5),
            size: 1.5 + _random.nextDouble() * 2.0,
            type: 'firefly',
          ));
        }
      }

      // Update Floating Texts
      for (int i = _floatingTexts.length - 1; i >= 0; i--) {
        final ft = _floatingTexts[i];
        ft.position = Offset(ft.position.dx, ft.position.dy - 60.0 * dt);
        ft.age += dt;
        if (ft.age >= 0.7) _floatingTexts.removeAt(i);
      }

      // 12. Update Erratic Creatures Animation & AI behavior
      for (var c in _creatures) {
        c.animState += dt * 5.0;
        if (c.type == 'rabbit') {
          c.stateTimer -= dt;
          double currentGroundY = _getGroundHeight(c.x);
          if (c.stateTimer <= 0) {
            c.phase = c.phase == 'idle' ? 'hopping' : 'idle';
            if (c.phase == 'hopping') {
              c.vy = -180.0;
              c.stateTimer = 0.8 + _random.nextDouble() * 1.0;
            } else {
              c.vy = 0.0;
              c.stateTimer = 0.6 + _random.nextDouble() * 0.7;
            }
          }

          if (c.phase == 'hopping') {
            c.vy += 800.0 * dt;
            c.y += c.vy * dt;
            c.x -= c.speed * dt;
            if (c.y >= currentGroundY - 8) {
              c.y = currentGroundY - 8;
              c.vy = 0.0;
            }
          } else {
            c.y = currentGroundY - 8;
            c.x -= 20.0 * dt;
          }
        } else if (c.type == 'eagle') {
          if (c.phase == 'idle') {
            c.phase = 'cruising';
          }
          double dx = c.x - (_worldX + 100.0);
          if (c.phase == 'cruising') {
            c.x -= c.speed * dt;
            if (dx > 0 && dx < 280) {
              c.phase = 'diving';
              c.targetY = _playerY;
            }
          } else if (c.phase == 'diving') {
            c.x -= c.speed * 1.4 * dt;
            c.y += (c.targetY - c.y) * 4.0 * dt;
            if (dx < -40 || (c.targetY - c.y).abs() < 12.0) {
              c.phase = 'climbing';
            }
          } else if (c.phase == 'climbing') {
            c.x -= c.speed * dt;
            c.y -= 95.0 * dt;
          }
        } else if (c.type == 'butterfly') {
          c.x -= c.speed * dt;
          c.y += math.sin(c.animState * 3.8) * 1.4 + math.cos(c.animState * 1.9) * 0.9;
        }
      }

      // 13. Check Collisions: Gems
      for (int i = _gems.length - 1; i >= 0; i--) {
        final gem = _gems[i];
        double dx = gem.x - playerAbsX;
        double dy = gem.y - _playerY;
        double dist = math.sqrt(dx * dx + dy * dy);

        if (dist < 26.0) {
          if (gem.isHyper) {
            _speedBoostTimer = 5.0; // 5 seconds of hyper boost!
            _invincibleTimer = 5.0; // Invincible during boost
            _floatingTexts.add(FloatingText(
              position: Offset(100, _playerY - 20),
              text: 'HYPER BOOST!'.tr,
              color: const Color(0xFFD946EF),
            ));
            _triggerSplash(Offset(100, _playerY), const Color(0xFFD946EF), count: 20);
          } else if (gem.isShield) {
            _shield = math.min(100.0, _shield + 20.0);
            _floatingTexts.add(FloatingText(
              position: Offset(100, _playerY - 20),
              text: '+SHIELD'.tr,
              color: Colors.cyanAccent,
            ));
            _triggerSplash(Offset(100, _playerY), Colors.cyanAccent, count: 12);
          } else {
            _gemCount++;
            int pts = 70 * _level;
            _score += pts;
            if (_score > _highScore) {
              _highScore = _score;
              _saveHighScore();
            }
            _floatingTexts.add(FloatingText(
              position: Offset(100, _playerY - 20),
              text: '+$pts',
              color: Colors.amberAccent,
            ));
            _triggerSplash(Offset(100, _playerY), Colors.amberAccent, count: 8);
          }
          _gems.removeAt(i);
        }
      }

      // 14. Check Collisions: Obstacles
      for (int i = _obstacles.length - 1; i >= 0; i--) {
        final obs = _obstacles[i];
        double dx = obs.x - playerAbsX;
        double dy = obs.y - _playerY;
        double dist = math.sqrt(dx * dx + dy * dy);

        if (dist < (18.0 + obs.size)) {
          // If in Hyper Speed, smash the obstacle!
          if (_speedBoostTimer > 0) {
            _score += 100;
            _floatingTexts.add(FloatingText(
              position: Offset(dx + 100, obs.y),
              text: 'SMASH! +100'.tr,
              color: Colors.orangeAccent,
            ));
            _triggerSplash(Offset(dx + 100, obs.y), Colors.orangeAccent, count: 15);
            _obstacles.removeAt(i);
            continue;
          }

          if (_invincibleTimer <= 0) {
            _triggerScreenShake(0.35, 12.0);
            _shield = math.max(0.0, _shield - 20.0);
            _triggerSplash(Offset(100, _playerY), Colors.redAccent, count: 20);
            _obstacles.removeAt(i);

            // Rebuild/Respawn Sequence (Pauses world locomotion, player stays)
            if (_shield <= 0) {
              _deathCountdown = 3.0; // 3 seconds re-materialize countdown
              _triggerSplash(Offset(100, _playerY), Colors.redAccent, count: 30);
              _score = math.max(0, _score - 150); // Score rebirth deduction
              _saveHighScore();
            }
          }
        }
      }
    });
  }

  // ----------------------------------------------------
  // CONTROLS & EVENT HANDLERS
  // ----------------------------------------------------
  void _jump() {
    if (_jumpCount < 2 && _deathCountdown <= 0) {
      _playerVy = -320.0;
      _jumpCount++;
      _triggerSplash(Offset(100.0, _playerY + 14), Colors.white70, count: 8);
    }
  }

  void _handlePointerDown(PointerDownEvent event) {
    _activePointers[event.pointer] = event.localPosition;
    _evaluatePointers();

    if (event.localPosition.dx <= _sandboxSize.width / 2) {
      _jump();
    }
  }

  void _handlePointerMove(PointerMoveEvent event) {
    _activePointers[event.pointer] = event.localPosition;
    _evaluatePointers();
  }

  void _handlePointerUp(PointerUpEvent event) {
    _activePointers.remove(event.pointer);
    _evaluatePointers();
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    _activePointers.remove(event.pointer);
    _evaluatePointers();
  }

  void _evaluatePointers() {
    bool rightSideHeld = false;
    for (var pos in _activePointers.values) {
      if (pos.dx > _sandboxSize.width / 2) {
        rightSideHeld = true;
      }
    }
    setState(() {
      _isMovingRight = rightSideHeld;
    });
  }

  // ----------------------------------------------------
  // SPAWN AMBIENT PARTICLES
  // ----------------------------------------------------
  void _spawnAmbientParticles(Biome biome) {
    double sx = _sandboxSize.width + 20;

    switch (biome) {
      case Biome.forest:
        _particles.add(BiomeParticle(
          position: Offset(_random.nextDouble() * _sandboxSize.width, -10),
          velocity: Offset(-40 - _random.nextDouble() * 40, 50 + _random.nextDouble() * 30),
          color: Colors.green.withValues(alpha: 0.5),
          size: 4 + _random.nextDouble() * 4,
          type: 'leaf',
        ));
        break;
      case Biome.mountain:
        _particles.add(BiomeParticle(
          position: Offset(sx, _random.nextDouble() * _sandboxSize.height * 0.7),
          velocity: Offset(-100 - _random.nextDouble() * 50, (_random.nextDouble() - 0.5) * 30),
          color: Colors.amberAccent.withValues(alpha: 0.4),
          size: 1.5 + _random.nextDouble() * 2.0,
          type: 'sparkle',
        ));
        break;
      case Biome.sea:
        _particles.add(BiomeParticle(
          position: Offset(_random.nextDouble() * _sandboxSize.width, _sandboxSize.height + 10),
          velocity: Offset((_random.nextDouble() - 0.5) * 20, -70 - _random.nextDouble() * 50),
          color: Colors.cyanAccent.withValues(alpha: 0.35),
          size: 3.0 + _random.nextDouble() * 3.0,
          type: 'bubble',
        ));
        break;
      case Biome.rain:
        _particles.add(BiomeParticle(
          position: Offset(_random.nextDouble() * (_sandboxSize.width + 100) - 50, -10),
          velocity: Offset(-140 - _random.nextDouble() * 70, 480 + _random.nextDouble() * 180),
          color: Colors.blueAccent.withValues(alpha: 0.5),
          size: 1.5 + _random.nextDouble() * 1.5,
          type: 'rain',
        ));
        break;
    }
  }

  void _updateParticles(double dt) {
    for (int i = _particles.length - 1; i >= 0; i--) {
      final p = _particles[i];
      p.position += p.velocity * dt;
      p.age += dt;

      if (p.position.dx < -50 || p.position.dy < -50 || p.position.dy > _sandboxSize.height + 50) {
        _particles.removeAt(i);
      }
    }
  }

  void _triggerSplash(Offset pos, Color color, {int count = 10}) {
    for (int i = 0; i < count; i++) {
      double angle = _random.nextDouble() * 2 * math.pi;
      double speed = 80 + _random.nextDouble() * 140;
      _particles.add(BiomeParticle(
        position: pos,
        velocity: Offset(math.cos(angle) * speed, math.sin(angle) * speed),
        color: color,
        size: 2.0 + _random.nextDouble() * 3.0,
        type: 'splash',
      ));
    }
  }

  void _triggerScreenShake(double duration, double intensity) {
    _shakeDuration = duration;
    _shakeIntensity = intensity;
  }

  // ----------------------------------------------------
  // BACKGROUND PEACEFUL ANIMALS
  // ----------------------------------------------------
  void _spawnBackgroundAnimal(Biome biome) {
    double sx = _sandboxSize.width + 50;

    switch (biome) {
      case Biome.forest:
      case Biome.rain:
        double ay = _getGroundHeight(_worldX + sx) - 10;
        _backAnimals.add(BackgroundAnimal(
          x: _worldX + sx,
          y: ay,
          type: 'deer',
          speed: 25.0,
          size: 20.0,
        ));
        break;
      case Biome.mountain:
        double baseH = 80.0 + _random.nextDouble() * 80.0;
        for (int i = 0; i < 4; i++) {
          _backAnimals.add(BackgroundAnimal(
            x: _worldX + sx + (i * 35),
            y: baseH + (i.isEven ? 18.0 : 0.0),
            type: 'bird_flock',
            speed: 80.0,
            size: 8.0,
          ));
        }
        break;
      case Biome.sea:
        _backAnimals.add(BackgroundAnimal(
          x: _worldX + sx,
          y: _sandboxSize.height - 230 + 40,
          type: 'whale',
          speed: 45.0,
          size: 55.0,
        ));
        break;
    }
  }

  void _updateBackgroundAnimals(double dt) {
    for (int i = _backAnimals.length - 1; i >= 0; i--) {
      final ba = _backAnimals[i];
      ba.animState += dt;

      if (ba.type == 'deer') {
        ba.x += ba.speed * dt;
        ba.y = _getGroundHeight(ba.x) - 10;
      } else if (ba.type == 'bird_flock') {
        ba.x -= ba.speed * dt;
      } else if (ba.type == 'whale') {
        ba.x += ba.speed * dt;
        double progress = (ba.animState % 4.0) / 4.0;
        double angle = progress * math.pi;
        ba.y = (_sandboxSize.height - 230 + 40) - math.sin(angle) * 70.0;
      }

      if (ba.x < _worldX - 150) {
        _backAnimals.removeAt(i);
      }
    }
  }

  double? lerpDouble(double a, double b, double t) {
    return a + (b - a) * t;
  }

  // ----------------------------------------------------
  // WIDGET BUILD
  // ----------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04020d),
      body: Listener(
        onPointerDown: _handlePointerDown,
        onPointerMove: _handlePointerMove,
        onPointerUp: _handlePointerUp,
        onPointerCancel: _handlePointerCancel,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Dynamic Parallax Sky, Sun/Moon, and Mountains
            Transform.translate(
              offset: _shakeOffset,
              child: CustomPaint(
                painter: ParallaxSceneryPainter(
                  worldX: _worldX,
                  timeOfDay: _timeOfDay,
                  skyColors: _getSkyColors(_timeOfDay),
                  getGroundHeight: _getGroundHeight,
                  drawLightningBolt: _drawLightningBolt,
                  lightningTime: _lightningTime,
                  backAnimals: _backAnimals,
                ),
              ),
            ),

            // 2. Active Platformer Game Canvas & Texturing
            LayoutBuilder(
              builder: (context, constraints) {
                final size = Size(constraints.maxWidth, constraints.maxHeight);
                if (_sandboxSize == Size.zero) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    setState(() {
                      _sandboxSize = size;
                      _playerY = _getGroundHeight(100.0) - 18;
                    });
                  });
                }

                return Transform.translate(
                  offset: _shakeOffset,
                  child: CustomPaint(
                    painter: PlatformerCanvasPainter(
                      worldX: _worldX,
                      playerY: _playerY,
                      playerVy: _playerVy,
                      walkCycle: _walkCycle,
                      squashStretch: _squashStretch,
                      isMovingRight: _isMovingRight,
                      platforms: _platforms,
                      obstacles: _obstacles,
                      gems: _gems,
                      particles: _particles,
                      floatingTexts: _floatingTexts,
                      capeTrail: _capeTrail,
                      getGroundHeight: _getGroundHeight,
                      getGroundStyle: _getGroundStyle,
                      undergroundDetails: _undergroundDetails,
                      surfaceDecos: _surfaceDecos,
                      creatures: _creatures,
                      timeOfDay: _timeOfDay,
                      invincibleTimer: _invincibleTimer,
                      speedBoostTimer: _speedBoostTimer,
                      deathCountdown: _deathCountdown,
                    ),
                    size: Size.infinite,
                  ),
                );
              },
            ),

            // 3. Floating Exit Button (Top-Left)
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

            // 4. Game HUD (Top Panel)
            Positioned(
              top: 48,
              right: 20,
              left: 80,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    color: Colors.white.withValues(alpha: 0.03),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Distance HUD
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'EXPLORER'.tr,
                              style: const TextStyle(color: Colors.white30, fontSize: 8, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${_distanceTraveled.toInt()}m',
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),

                        // Center: GLOWING GEMS COUNTER
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.amberAccent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.25), width: 1.5),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.diamond_rounded, color: Colors.amberAccent, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                '$_gemCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Right: Shield HUD
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _speedBoostTimer > 0 ? 'HYPER SPEED'.tr : 'SHIELD'.tr,
                              style: TextStyle(
                                color: _speedBoostTimer > 0 ? const Color(0xFFD946EF) : Colors.white30,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 80,
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.white10,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              alignment: Alignment.centerLeft,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 100),
                                width: 80 * (_shield / 100.0),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: _speedBoostTimer > 0
                                        ? [const Color(0xFFD946EF), Colors.pinkAccent]
                                        : [Colors.redAccent, _isMovingRight ? Colors.amberAccent : Colors.greenAccent],
                                  ),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 5. Bottom Touch Area Overlay Guidelines (Visible for first 10 seconds)
            if (_instructionTimer > 0 && _deathCountdown <= 0)
              Positioned(
                bottom: 30,
                left: 20,
                right: 20,
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: _instructionTimer > 0 ? math.min(1.0, _instructionTimer) : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Left Area: Jump
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: BackdropFilter(
                            filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child: Container(
                              width: 160,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.04),
                                border: Border.all(color: Colors.white10),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.touch_app_rounded, color: Colors.cyanAccent, size: 24),
                                  const SizedBox(height: 6),
                                  Text(
                                    'TAP TO JUMP'.tr,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Tap twice to Double Jump'.tr,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white38,
                                      fontSize: 8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Right Area: Sprint / Super Sprint
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: BackdropFilter(
                            filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child: Container(
                              width: 200,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.04),
                                border: Border.all(color: Colors.white10),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.bolt_rounded, color: Colors.amberAccent, size: 24),
                                  const SizedBox(height: 6),
                                  Text(
                                    'HOLD TO SPRINT'.tr,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Accelerate to maximum speed'.tr,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white38,
                                      fontSize: 8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // 6. Death Countdown Screen Overlay (Keeps ambient loops running)
            if (_deathCountdown > 0)
              Container(
                color: Colors.black.withValues(alpha: 0.45),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.bolt_rounded, color: Colors.redAccent, size: 44),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'SYSTEM DE-MATERIALIZED'.tr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Re-building cosmic explorer in:'.tr,
                        style: const TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        '${_deathCountdown.ceil()}',
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------
// GAME DATA MODELS
// ----------------------------------------------------
class GamePlatform {
  final double x;
  final double y;
  final double width;
  final double height;

  GamePlatform({
    required this.x,
    required this.y,
    required this.width,
    this.height = 16.0,
  });
}

class Obstacle {
  double x;
  double y;
  double vy = 0.0;
  final double size;
  final String type;
  double animState = 0.0;

  Obstacle({
    required this.x,
    required this.y,
    required this.size,
    required this.type,
  });
}

class CosmicGem {
  final double x;
  final double y;
  final bool isShield;
  final bool isHyper;
  final double size;

  CosmicGem({
    required this.x,
    required this.y,
    required this.isShield,
    required this.isHyper,
    required this.size,
  });
}

class BiomeParticle {
  Offset position;
  final Offset velocity;
  final Color color;
  final double size;
  final String type;
  double age = 0.0;
  double maxAge = 5.0;

  BiomeParticle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.size,
    required this.type,
  });
}

class FloatingText {
  Offset position;
  final String text;
  final Color color;
  double age = 0.0;

  FloatingText({
    required this.position,
    required this.text,
    required this.color,
  });
}

class BackgroundAnimal {
  double x;
  double y;
  final String type;
  final double speed;
  final double size;
  double animState = 0.0;

  BackgroundAnimal({
    required this.x,
    required this.y,
    required this.type,
    required this.speed,
    required this.size,
  });
}

class GroundStyle {
  final Color top;
  final Color bottom;
  final Color highlight;

  GroundStyle({required this.top, required this.bottom, required this.highlight});
}

class UndergroundDetail {
  final double x;
  final double y;
  final String type;
  final double size;

  UndergroundDetail({required this.x, required this.y, required this.type, required this.size});
}

class SurfaceDeco {
  final double x;
  final double y;
  final String type;
  final double size;

  SurfaceDeco({required this.x, required this.y, required this.type, required this.size});
}

class Creature {
  double x;
  double y;
  double vy = 0.0;
  final String type;
  double animState = 0.0;
  double speed;
  double targetY = 0.0;
  double stateTimer = 0.0;
  String phase = 'idle';

  Creature({required this.x, required this.y, required this.type, required this.speed});
}

// ----------------------------------------------------
// SCENERY PAINTER (PARALLAX ENVIRONMENT SKY/HILLS)
// ----------------------------------------------------
class ParallaxSceneryPainter extends CustomPainter {
  final double worldX;
  final double timeOfDay;
  final List<Color> skyColors;
  final double Function(double) getGroundHeight;
  final bool drawLightningBolt;
  final double lightningTime;
  final List<BackgroundAnimal> backAnimals;

  ParallaxSceneryPainter({
    required this.worldX,
    required this.timeOfDay,
    required this.skyColors,
    required this.getGroundHeight,
    required this.drawLightningBolt,
    required this.lightningTime,
    required this.backAnimals,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Sky Gradient
    final skyGradient = ui.Gradient.linear(
      Offset(0, size.height * 0.1),
      Offset(0, size.height * 0.9),
      skyColors,
    );
    canvas.drawRect(Offset.zero & size, Paint()..shader = skyGradient);

    // 2. Stars
    double starAlpha = 0.0;
    if (timeOfDay > 19.0) {
      starAlpha = (timeOfDay - 19.0) / 2.0;
    } else if (timeOfDay < 5.0) {
      starAlpha = 1.0;
      if (timeOfDay > 3.0) {
        starAlpha = 1.0 - ((timeOfDay - 3.0) / 2.0);
      }
    }
    if (starAlpha > 0.0) {
      final starPaint = Paint()..color = Colors.white.withValues(alpha: starAlpha * 0.65);
      for (int i = 0; i < 45; i++) {
        double starX = (math.sin(i * 123.4) * 0.5 + 0.5) * size.width;
        double starY = (math.cos(i * 567.8) * 0.5 + 0.5) * (size.height - 230);
        double twinkle = 0.6 + 0.4 * math.sin(timeOfDay * 15.0 + i);
        canvas.drawCircle(Offset(starX, starY), 1.2 * twinkle, starPaint);
      }
    }

    // 3. Sun or Moon
    if (timeOfDay >= 5.0 && timeOfDay < 19.0) {
      double t = (timeOfDay - 5.0) / 14.0;
      double sunAngle = math.pi + t * math.pi;
      double sunX = size.width * 0.5 + math.cos(sunAngle) * (size.width * 0.4);
      double sunY = (size.height - 230) * 0.7 + math.sin(sunAngle) * (size.height * 0.45);

      final sunPaint = Paint()
        ..color = const Color(0xFFFEE2E2).withValues(alpha: 0.95)
        ..style = PaintingStyle.fill;
      final sunGlow = Paint()
        ..color = const Color(0xFFF59E0B).withValues(alpha: 0.25)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(sunX, sunY), 32.0, sunGlow);
      canvas.drawCircle(Offset(sunX, sunY), 20.0, sunPaint);
    }
    if (timeOfDay >= 18.0 || timeOfDay < 6.0) {
      double t = 0.0;
      if (timeOfDay >= 18.0) {
        t = (timeOfDay - 18.0) / 12.0;
      } else {
        t = (timeOfDay + 6.0) / 12.0;
      }
      double moonAngle = math.pi + t * math.pi;
      double moonX = size.width * 0.5 + math.cos(moonAngle) * (size.width * 0.4);
      double moonY = (size.height - 230) * 0.7 + math.sin(moonAngle) * (size.height * 0.45);

      final moonPaint = Paint()
        ..color = const Color(0xFFE2E8F0).withValues(alpha: 0.9)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(moonX, moonY), 18.0, moonPaint);

      final moonShadow = Paint()
        ..color = skyColors[0]
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(moonX - 6.0, moonY - 4.0), 16.0, moonShadow);
    }

    // Lightning flash
    if (lightningTime > 0.0 && lightningTime < 0.28) {
      final flashPaint = Paint()..color = Colors.white.withValues(alpha: 0.15);
      canvas.drawRect(Offset.zero & size, flashPaint);

      if (drawLightningBolt) {
        final boltPaint = Paint()
          ..color = Colors.cyanAccent.withValues(alpha: 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round;

        final boltPath = Path()
          ..moveTo(size.width * 0.45, 0)
          ..lineTo(size.width * 0.38, size.height * 0.25)
          ..lineTo(size.width * 0.48, size.height * 0.2)
          ..lineTo(size.width * 0.4, size.height * 0.52)
          ..lineTo(size.width * 0.46, size.height * 0.48)
          ..lineTo(size.width * 0.35, size.height * 0.72);
        canvas.drawPath(boltPath, boltPaint);
      }
    }

    // 4. Parallax Far Mountain/Forest Layer (Very Slow Scroll)
    final farPath = Path()..moveTo(0, size.height);
    for (double x = 0; x <= size.width; x += 20) {
      double sampleX = worldX * 0.18 + x;
      double y = size.height - 290 + math.sin(sampleX * 0.0035) * 45 + math.cos(sampleX * 0.001) * 20;
      farPath.lineTo(x, y);
    }
    farPath.lineTo(size.width, size.height);
    farPath.close();

    final farPaint = Paint()
      ..color = const Color(0xFF0D0B1C).withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    canvas.drawPath(farPath, farPaint);

    // 5. Parallax Mid Mountain/Forest Layer (Medium Scroll)
    final midPath = Path()..moveTo(0, size.height);
    for (double x = 0; x <= size.width; x += 15) {
      double sampleX = worldX * 0.45 + x;
      double y = size.height - 250 + math.sin(sampleX * 0.0055) * 30 + math.cos(sampleX * 0.0018) * 15;
      midPath.lineTo(x, y);
    }
    midPath.lineTo(size.width, size.height);
    midPath.close();

    final midPaint = Paint()
      ..color = const Color(0xFF0F172A).withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;
    canvas.drawPath(midPath, midPaint);

    // 6. Draw Background Animals
    for (var ba in backAnimals) {
      double drawX = ba.x - worldX;
      if (ba.type == 'deer') {
        final deerPaint = Paint()..color = const Color(0xFF92400E).withValues(alpha: 0.7);
        canvas.drawOval(
          Rect.fromLTWH(drawX - 8, ba.y - 12, 16, 9),
          deerPaint,
        );
        canvas.drawLine(Offset(drawX - 5, ba.y - 4), Offset(drawX - 5, ba.y + 4), deerPaint..strokeWidth = 1.5);
        canvas.drawLine(Offset(drawX + 3, ba.y - 4), Offset(drawX + 3, ba.y + 4), deerPaint..strokeWidth = 1.5);
        canvas.drawLine(Offset(drawX - 6, ba.y - 9), Offset(drawX - 10, ba.y - 18), deerPaint..strokeWidth = 2.0);
        canvas.drawLine(Offset(drawX - 10, ba.y - 18), Offset(drawX - 14, ba.y - 22), deerPaint..strokeWidth = 1.0);
        canvas.drawLine(Offset(drawX - 10, ba.y - 18), Offset(drawX - 8, ba.y - 23), deerPaint..strokeWidth = 1.0);
      } else if (ba.type == 'bird_flock') {
        final birdPaint = Paint()
          ..color = Colors.white70.withValues(alpha: 0.45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        double flap = math.sin(ba.animState * 9.0) * ba.size * 0.6;
        final bPath = Path()
          ..moveTo(drawX - ba.size, ba.y + flap)
          ..lineTo(drawX, ba.y)
          ..lineTo(drawX + ba.size, ba.y + flap);
        canvas.drawPath(bPath, birdPaint);
      } else if (ba.type == 'whale') {
        final whalePaint = Paint()
          ..color = const Color(0xFF475569).withValues(alpha: 0.4)
          ..style = PaintingStyle.fill;
        canvas.drawOval(
          Rect.fromCenter(center: Offset(drawX, ba.y), width: ba.size * 1.5, height: ba.size * 0.7),
          whalePaint,
        );
        final tailPath = Path()
          ..moveTo(drawX + ba.size * 0.7, ba.y)
          ..lineTo(drawX + ba.size * 1.1, ba.y - ba.size * 0.3)
          ..lineTo(drawX + ba.size * 1.1, ba.y + ba.size * 0.3)
          ..close();
        canvas.drawPath(tailPath, whalePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant ParallaxSceneryPainter oldDelegate) => true;
}

// ----------------------------------------------------
// ACTIVE GAMEPLAY CANVAS PAINTER & TEXTURING
// ----------------------------------------------------
class PlatformerCanvasPainter extends CustomPainter {
  final double worldX;
  final double playerY;
  final double playerVy;
  final double walkCycle;
  final double squashStretch;
  final bool isMovingRight;
  final List<GamePlatform> platforms;
  final List<Obstacle> obstacles;
  final List<CosmicGem> gems;
  final List<BiomeParticle> particles;
  final List<FloatingText> floatingTexts;
  final List<Offset> capeTrail;
  final double Function(double) getGroundHeight;
  final GroundStyle Function(double) getGroundStyle;
  final List<UndergroundDetail> undergroundDetails;
  final List<SurfaceDeco> surfaceDecos;
  final List<Creature> creatures;
  final double timeOfDay;
  final double invincibleTimer;
  final double speedBoostTimer;
  final double deathCountdown;

  PlatformerCanvasPainter({
    required this.worldX,
    required this.playerY,
    required this.playerVy,
    required this.walkCycle,
    required this.squashStretch,
    required this.isMovingRight,
    required this.platforms,
    required this.obstacles,
    required this.gems,
    required this.particles,
    required this.floatingTexts,
    required this.capeTrail,
    required this.getGroundHeight,
    required this.getGroundStyle,
    required this.undergroundDetails,
    required this.surfaceDecos,
    required this.creatures,
    required this.timeOfDay,
    required this.invincibleTimer,
    required this.speedBoostTimer,
    required this.deathCountdown,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Biome Ambient Particles (Always floating)
    for (var p in particles) {
      final pPaint = Paint()..color = p.color;
      if (p.type == 'rain') {
        pPaint.strokeWidth = p.size;
        canvas.drawLine(
          p.position,
          Offset(p.position.dx - 12, p.position.dy + 35),
          pPaint,
        );
      } else if (p.type == 'leaf') {
        pPaint.style = PaintingStyle.fill;
        canvas.drawOval(
          Rect.fromCenter(center: p.position, width: p.size * 1.5, height: p.size * 0.7),
          pPaint,
        );
      } else {
        canvas.drawCircle(p.position, p.size, pPaint);
      }
    }

    // 2. Draw Scrolling Ground aligned to fixed world coordinates steps to fully eliminate vibration!
    final groundPath = Path()..moveTo(0, size.height);
    
    // Grid alignment steps of 10.0
    double gridStep = 10.0;
    double startWorldX = (worldX ~/ gridStep) * gridStep;
    double endWorldX = startWorldX + size.width + gridStep * 2;
    
    // Draw initial point projected back to screen coordinates
    double startY = getGroundHeight(startWorldX);
    double startRoughness = math.sin(startWorldX * 0.15) * 2.2 + math.cos(startWorldX * 0.35) * 0.8;
    groundPath.lineTo(startWorldX - worldX, startY + startRoughness);

    for (double wx = startWorldX + gridStep; wx <= endWorldX; wx += gridStep) {
      double screenX = wx - worldX;
      double y = getGroundHeight(wx);
      double roughness = math.sin(wx * 0.15) * 2.2 + math.cos(wx * 0.35) * 0.8;
      groundPath.lineTo(screenX, y + roughness);
    }
    groundPath.lineTo(size.width, size.height);
    groundPath.close();

    final groundStyle = getGroundStyle(worldX + size.width / 2);
    final groundPaint = Paint()..style = PaintingStyle.fill;
    final contourPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    final contourShadowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0;

    final groundGradient = ui.Gradient.linear(
      Offset(0, size.height - 230),
      Offset(0, size.height),
      [groundStyle.top, groundStyle.bottom],
    );
    groundPaint.shader = groundGradient;
    canvas.drawPath(groundPath, groundPaint);

    // Highlight contour aligned to the exact same world grid
    final contourPath = Path();
    contourPath.moveTo(startWorldX - worldX, startY + startRoughness);
    for (double wx = startWorldX + gridStep; wx <= endWorldX; wx += gridStep) {
      double screenX = wx - worldX;
      double y = getGroundHeight(wx);
      double roughness = math.sin(wx * 0.15) * 2.2 + math.cos(wx * 0.35) * 0.8;
      contourPath.lineTo(screenX, y + roughness);
    }

    contourShadowPaint.color = Colors.black.withValues(alpha: 0.35);
    canvas.drawPath(contourPath, contourShadowPaint);

    contourPaint.color = groundStyle.highlight;
    canvas.drawPath(contourPath, contourPaint);

    // 3. Draw Subterranean Details (Below Ground, Scrolling)
    canvas.save();
    canvas.clipPath(groundPath);

    for (var ud in undergroundDetails) {
      double udx = ud.x - worldX;
      final uPos = Offset(udx, ud.y);

      if (ud.type == 'crystals') {
        final cGlow = Paint()
          ..color = Colors.purpleAccent.withValues(alpha: 0.18)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(uPos, ud.size * 1.5, cGlow);

        final cPaint = Paint()
          ..color = Colors.purpleAccent
          ..style = PaintingStyle.fill;
        final cPath = Path()
          ..moveTo(udx - ud.size * 0.5, ud.y + ud.size * 0.5)
          ..lineTo(udx - 2, ud.y - ud.size * 0.8)
          ..lineTo(udx + ud.size * 0.5, ud.y + ud.size * 0.5)
          ..lineTo(udx + 1, ud.y - ud.size * 0.4)
          ..close();
        canvas.drawPath(cPath, cPaint);
      } else if (ud.type == 'fossil') {
        final fPaint = Paint()
          ..color = Colors.white70.withValues(alpha: 0.45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        canvas.drawCircle(uPos, ud.size * 0.5, fPaint);
        canvas.drawLine(Offset(udx - ud.size, ud.y), Offset(udx + ud.size, ud.y), fPaint);
      } else if (ud.type == 'roots') {
        final rPaint = Paint()
          ..color = const Color(0xFF33271E).withValues(alpha: 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0;
        final rPath = Path()
          ..moveTo(udx, ud.y - ud.size)
          ..quadraticBezierTo(udx + 10, ud.y + 15, udx - 5, ud.y + ud.size);
        canvas.drawPath(rPath, rPaint);
      } else if (ud.type == 'gold_ore') {
        // Glowing veins of golden minerals
        final goldPaint = Paint()..color = const Color(0xFFFBBF24)..style = PaintingStyle.fill;
        canvas.drawCircle(uPos, ud.size * 0.45, Paint()..color = const Color(0xFFFBBF24).withValues(alpha: 0.2)..style = PaintingStyle.fill);
        final goldPath = Path()
          ..moveTo(udx - ud.size * 0.5, ud.y - 4)
          ..lineTo(udx + ud.size * 0.3, ud.y + 3)
          ..lineTo(udx + ud.size * 0.6, ud.y - 5);
        canvas.drawPath(goldPath, goldPaint..style = PaintingStyle.stroke..strokeWidth = 3.0);
      } else if (ud.type == 'worm') {
        // Subterranean glowing cave worms slithering
        final wormPaint = Paint()
          ..color = Colors.pinkAccent.withValues(alpha: 0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        double wSway = math.sin(timeOfDay * 15.0 + udx * 0.05) * 4.0;
        final wPath = Path()
          ..moveTo(udx - 10, ud.y + wSway)
          ..lineTo(udx + 10, ud.y - wSway);
        canvas.drawPath(wPath, wormPaint);
      } else {
        final mPaint = Paint()..color = Colors.tealAccent.withValues(alpha: 0.6);
        canvas.drawCircle(uPos, ud.size * 0.4, mPaint);
      }
    }

    canvas.restore();

    // 4. Draw Surface Decorations (Scrolling Grass, Flowers, Mushrooms, Rocks)
    for (var sd in surfaceDecos) {
      double sdx = sd.x - worldX;
      double sy = getGroundHeight(sd.x);

      if (sd.type == 'flower') {
        final stemPaint = Paint()..color = Colors.green..strokeWidth = 1.5;
        canvas.drawLine(Offset(sdx, sy), Offset(sdx, sy - sd.size), stemPaint);
        canvas.drawCircle(Offset(sdx, sy - sd.size), sd.size * 0.4, Paint()..color = Colors.pinkAccent);
      } else if (sd.type == 'mushroom') {
        final stemPaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
        canvas.drawRect(Rect.fromLTWH(sdx - 2, sy - sd.size * 0.5, 4, sd.size * 0.5), stemPaint);
        final capPaint = Paint()..color = Colors.redAccent..style = PaintingStyle.fill;
        canvas.drawOval(Rect.fromLTWH(sdx - sd.size * 0.6, sy - sd.size, sd.size * 1.2, sd.size * 0.7), capPaint);
      } else if (sd.type == 'pebble') {
        final pPaint = Paint()..color = const Color(0xFF6B7280)..style = PaintingStyle.fill;
        canvas.drawOval(Rect.fromLTWH(sdx - sd.size * 0.5, sy - sd.size * 0.4, sd.size, sd.size * 0.5), pPaint);
      } else {
        final bushPaint = Paint()..color = const Color(0xFF065F46)..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(sdx, sy - sd.size * 0.4), sd.size * 0.6, bushPaint);
        canvas.drawCircle(Offset(sdx - sd.size * 0.4, sy - sd.size * 0.3), sd.size * 0.5, bushPaint);
        canvas.drawCircle(Offset(sdx + sd.size * 0.4, sy - sd.size * 0.3), sd.size * 0.5, bushPaint);
      }
    }

    // 5. Draw Platforms
    for (var plat in platforms) {
      double px = plat.x - worldX;
      final platRect = Rect.fromLTWH(px, plat.y, plat.width, plat.height);
      final rrect = RRect.fromRectAndRadius(platRect, const Radius.circular(6));

      final platPaint = Paint()
        ..color = groundStyle.highlight.withValues(alpha: 0.18)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(rrect, platPaint);

      final platBorder = Paint()
        ..color = groundStyle.highlight
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawRRect(rrect, platBorder);
    }

    // 6. Draw Collectible Gems (Including Spinning Hyper Gems)
    for (var gem in gems) {
      double gx = gem.x - worldX;
      final pos = Offset(gx, gem.y);

      Color gColor = Colors.amberAccent;
      if (gem.isShield) gColor = Colors.cyanAccent;
      if (gem.isHyper) gColor = const Color(0xFFD946EF);

      final glowPaint = Paint()
        ..color = gColor.withValues(alpha: 0.22)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, gem.size * 2.8, glowPaint);

      final gemPaint = Paint()
        ..color = gColor
        ..style = PaintingStyle.fill;

      // Draw custom diamond shape
      if (gem.isHyper) {
        // Draw a rotating diamond
        canvas.save();
        canvas.translate(gx, gem.y);
        canvas.rotate(timeOfDay * 15);
        final dPath = Path()
          ..moveTo(0, -gem.size * 1.3)
          ..lineTo(gem.size * 1.3, 0)
          ..lineTo(0, gem.size * 1.3)
          ..lineTo(-gem.size * 1.3, 0)
          ..close();
        canvas.drawPath(dPath, gemPaint);
        canvas.restore();
      } else {
        final dPath = Path()
          ..moveTo(gx, gem.y - gem.size)
          ..lineTo(gx + gem.size, gem.y)
          ..lineTo(gx, gem.y + gem.size)
          ..lineTo(gx - gem.size, gem.y)
          ..close();
        canvas.drawPath(dPath, gemPaint);
      }
    }

    // 7. Draw Obstacles (Spikes, Stones, Thorns, Shrooms, Steam vents)
    for (var obs in obstacles) {
      double ox = obs.x - worldX;

      if (obs.type == 'spike') {
        final spikePaint = Paint()
          ..color = Colors.redAccent
          ..style = PaintingStyle.fill;
        final sPath = Path()
          ..moveTo(ox, obs.y + obs.size)
          ..lineTo(ox - obs.size * 0.7, obs.y + obs.size)
          ..lineTo(ox, obs.y - obs.size)
          ..lineTo(ox + obs.size * 0.7, obs.y + obs.size)
          ..close();
        canvas.drawPath(sPath, spikePaint);
      } else if (obs.type == 'stone') {
        final stonePaint = Paint()..color = const Color(0xFF4B5563)..style = PaintingStyle.fill;
        final sPath = Path()
          ..moveTo(ox - obs.size, obs.y + obs.size)
          ..lineTo(ox, obs.y - obs.size * 0.8)
          ..lineTo(ox + obs.size * 0.6, obs.y + obs.size)
          ..close();
        canvas.drawPath(sPath, stonePaint);
        // Stone details/cracks
        canvas.drawLine(Offset(ox, obs.y), Offset(ox - 3, obs.y + obs.size), Paint()..color = Colors.white24..strokeWidth = 1.5);
      } else if (obs.type == 'thorn') {
        final thornPaint = Paint()
          ..color = const Color(0xFF166534)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0;
        final tPath = Path()
          ..moveTo(ox - obs.size, obs.y + obs.size)
          ..quadraticBezierTo(ox, obs.y - obs.size * 0.4, ox + obs.size, obs.y + obs.size);
        canvas.drawPath(tPath, thornPaint);
        // Thorny spurs
        canvas.drawLine(Offset(ox, obs.y + 4), Offset(ox - 3, obs.y - 3), Paint()..color = Colors.redAccent..strokeWidth = 1.5);
        canvas.drawLine(Offset(ox + 4, obs.y + 5), Offset(ox + 6, obs.y - 1), Paint()..color = Colors.redAccent..strokeWidth = 1.5);
      } else if (obs.type == 'shroom') {
        // Poisonous Mushrooms
        final stemPaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
        canvas.drawRect(Rect.fromLTWH(ox - 3, obs.y - obs.size * 0.4, 6, obs.size * 1.4), stemPaint);
        final capPaint = Paint()..color = Colors.purple..style = PaintingStyle.fill;
        canvas.drawOval(Rect.fromLTWH(ox - obs.size * 0.8, obs.y - obs.size * 0.6, obs.size * 1.6, obs.size), capPaint);
        // Dots
        canvas.drawCircle(Offset(ox - 3, obs.y - obs.size * 0.3), 1.5, Paint()..color = Colors.greenAccent);
        canvas.drawCircle(Offset(ox + 3, obs.y - obs.size * 0.3), 1.5, Paint()..color = Colors.greenAccent);
      } else if (obs.type == 'steam_vent') {
        final ventPaint = Paint()..color = const Color(0xFF374151)..style = PaintingStyle.fill;
        canvas.drawOval(Rect.fromLTWH(ox - obs.size * 0.8, obs.y + obs.size * 0.4, obs.size * 1.6, obs.size * 0.6), ventPaint);
        // Emit steam bubbles
        final steamPaint = Paint()..color = Colors.white.withValues(alpha: 0.3);
        double sSway = math.sin(timeOfDay * 30.0 + ox) * 4.0;
        canvas.drawCircle(Offset(ox + sSway, obs.y - 10), 4.5, steamPaint);
        canvas.drawCircle(Offset(ox - sSway * 0.8, obs.y - 22), 6.0, steamPaint);
      }
    }

    // 8. Draw Erratic Creatures
    for (var c in creatures) {
      double cx = c.x - worldX;

      if (c.type == 'rabbit') {
        final rPaint = Paint()..color = const Color(0xFFF3F4F6)..style = PaintingStyle.fill;
        canvas.drawOval(Rect.fromCenter(center: Offset(cx, c.y), width: 15, height: 10), rPaint);
        canvas.drawCircle(Offset(cx - 6, c.y - 4), 4.5, rPaint);
        canvas.drawOval(Rect.fromLTWH(cx - 7, c.y - 12, 2.5, 6), rPaint);
        canvas.drawCircle(Offset(cx + 7, c.y + 1), 2.5, rPaint);
      } else if (c.type == 'eagle') {
        final ePaint = Paint()..color = const Color(0xFF78350F)..style = PaintingStyle.fill;
        double wingFlap = math.sin(c.animState * 2.0) * 12.0;
        final wPath = Path()
          ..moveTo(cx, c.y)
          ..lineTo(cx - 15, c.y - wingFlap)
          ..lineTo(cx - 5, c.y)
          ..lineTo(cx + 15, c.y - wingFlap)
          ..lineTo(cx + 5, c.y)
          ..close();
        canvas.drawPath(wPath, ePaint);
        canvas.drawCircle(Offset(cx, c.y - 2), 4.0, ePaint);
        canvas.drawCircle(Offset(cx + 3, c.y - 2), 1.5, Paint()..color = Colors.yellowAccent);
      } else if (c.type == 'butterfly') {
        final bPaint = Paint()..color = Colors.pinkAccent..style = PaintingStyle.fill;
        double flap = (math.sin(c.animState * 4.0) * 0.5 + 0.5) * 8.0;
        canvas.drawCircle(Offset(cx, c.y), 1.5, Paint()..color = Colors.black);
        canvas.drawOval(Rect.fromLTWH(cx - flap, c.y - 6, flap, 6), bPaint);
        canvas.drawOval(Rect.fromLTWH(cx, c.y - 6, flap, 6), bPaint);
      }
    }

    // 9. Draw Player (Only if NOT completely dead)
    if (deathCountdown <= 0) {
      _drawPlayer(canvas);
    }

    // 10. Draw Floating Popups
    for (var ft in floatingTexts) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: ft.text,
          style: TextStyle(
            color: ft.color.withValues(alpha: 1.0 - ft.age),
            fontSize: 13 + (5.0 * (1.0 - ft.age)),
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(ft.position.dx - textPainter.width / 2, ft.position.dy),
      );
    }
  }

  void _drawPlayer(Canvas canvas) {
    if (invincibleTimer > 0 && speedBoostTimer <= 0) {
      int flashState = (invincibleTimer * 10).floor();
      if (flashState % 2 == 0) return;
    }

    // Motion trail ghosts
    if ((speedBoostTimer > 0 || isMovingRight) && capeTrail.length > 2) {
      for (int i = 0; i < capeTrail.length - 1; i += 2) {
        double ratio = i / (capeTrail.length - 1);
        double drawX = 100.0 - (capeTrail.length - 1 - i) * 14.0;
        double drawY = capeTrail[i].dy;

        canvas.save();
        canvas.translate(drawX, drawY);

        Color trailColor = speedBoostTimer > 0 ? const Color(0xFFD946EF) : Colors.cyanAccent;

        final trailGlow = Paint()
          ..color = trailColor.withValues(alpha: ratio * 0.35)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset.zero, 11, trailGlow);

        final trailBorder = Paint()
          ..color = Colors.white70.withValues(alpha: ratio * 0.45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        canvas.drawCircle(Offset.zero, 11, trailBorder);

        canvas.restore();
      }
    }

    if (capeTrail.length > 2) {
      final capePath = Path();
      capePath.moveTo(capeTrail.first.dx - 12, capeTrail.first.dy);
      for (int i = 1; i < capeTrail.length; i++) {
        double lagOffset = (capeTrail.length - i) * 2.8;
        capePath.lineTo(capeTrail[i].dx - 12 - lagOffset, capeTrail[i].dy);
      }

      final capePaint = Paint()
        ..color = speedBoostTimer > 0
            ? const Color(0xFFD946EF).withValues(alpha: 0.4)
            : (isMovingRight ? Colors.cyanAccent.withValues(alpha: 0.4) : Colors.pinkAccent.withValues(alpha: 0.35))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(capePath, capePaint);
    }

    canvas.save();
    canvas.translate(100.0, playerY);
    canvas.scale(2.0 - squashStretch, squashStretch);

    // Core body (glowing white)
    final bodyPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, 11, bodyPaint);

    final glowPaint = Paint()
      ..color = speedBoostTimer > 0
          ? const Color(0xFFD946EF)
          : (isMovingRight ? Colors.cyanAccent : Colors.pinkAccent)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (speedBoostTimer > 0 || isMovingRight) ? 3.8 : 2.5;
    canvas.drawCircle(Offset.zero, 11, glowPaint);

    // Visor
    final facePaint = Paint()
      ..color = Colors.cyanAccent
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      const Rect.fromLTWH(2, -5, 8, 7),
      facePaint,
    );

    // Legs
    final legPaint = Paint()
      ..color = speedBoostTimer > 0
          ? const Color(0xFFD946EF)
          : (isMovingRight ? Colors.cyanAccent : Colors.pinkAccent)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    if (playerVy != 0.0) {
      canvas.drawLine(const Offset(-4, 9), const Offset(-6, 15), legPaint);
      canvas.drawLine(const Offset(4, 9), const Offset(6, 15), legPaint);
    } else {
      double leftLegOffset = math.sin(walkCycle) * 7.5;
      double rightLegOffset = math.cos(walkCycle) * 7.5;

      canvas.drawLine(const Offset(-4, 9), Offset(-6, 14 + leftLegOffset), legPaint);
      canvas.drawLine(const Offset(4, 9), Offset(6, 14 + rightLegOffset), legPaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant PlatformerCanvasPainter oldDelegate) => true;
}
