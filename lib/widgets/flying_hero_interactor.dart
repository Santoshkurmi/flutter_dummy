import 'package:flutter/material.dart';

class FlyingHero {
  final BuildContext context;
  final VoidCallback onTap;

  FlyingHero({
    required this.context,
    required this.onTap,
  });
}

class FlyingHeroTracker {
  static final List<FlyingHero> _activeHeroes = [];
  static DateTime? _lastTriggerTime;

  static void register(BuildContext context, VoidCallback onTap) {
    _activeHeroes.add(FlyingHero(context: context, onTap: onTap));
  }

  static void unregister(BuildContext context) {
    _activeHeroes.removeWhere((h) => h.context == context);
  }

  static bool checkTap(Offset globalPosition) {
    final now = DateTime.now();
    if (_lastTriggerTime != null && now.difference(_lastTriggerTime!) < const Duration(milliseconds: 400)) {
      return false;
    }

    for (final hero in List.from(_activeHeroes)) {
      if (hero.context.mounted) {
        final renderBox = hero.context.findRenderObject() as RenderBox?;
        if (renderBox != null && renderBox.hasSize) {
          final position = renderBox.localToGlobal(Offset.zero);
          final size = renderBox.size;
          final rect = position & size;
          if (rect.contains(globalPosition)) {
            _lastTriggerTime = now;
            // Execute onTap outside of current build/layout cycle to prevent any framework warnings.
            Future.microtask(() => hero.onTap());
            return true;
          }
        }
      }
    }
    return false;
  }
}

class FlyingShuttleWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const FlyingShuttleWrapper({
    super.key,
    required this.child,
    required this.onTap,
  });

  @override
  State<FlyingShuttleWrapper> createState() => _FlyingShuttleWrapperState();
}

class _FlyingShuttleWrapperState extends State<FlyingShuttleWrapper> {
  @override
  void initState() {
    super.initState();
    FlyingHeroTracker.register(context, widget.onTap);
  }

  @override
  void dispose() {
    FlyingHeroTracker.unregister(context);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
