import 'package:flutter/material.dart';

class FlyingHero {
  final BuildContext shuttleContext;
  final BuildContext pageContext;
  final VoidCallback onTap;

  FlyingHero({
    required this.shuttleContext,
    required this.pageContext,
    required this.onTap,
  });
}

class FlyingHeroTracker {
  static final List<FlyingHero> _activeHeroes = [];
  static DateTime? _lastTriggerTime;

  static void register(BuildContext shuttleContext, BuildContext pageContext, VoidCallback onTap) {
    _activeHeroes.add(FlyingHero(
      shuttleContext: shuttleContext,
      pageContext: pageContext,
      onTap: onTap,
    ));
  }

  static void unregister(BuildContext shuttleContext) {
    _activeHeroes.removeWhere((h) => h.shuttleContext == shuttleContext);
  }

  static bool checkTap(Offset globalPosition) {
    final now = DateTime.now();
    if (_lastTriggerTime != null && now.difference(_lastTriggerTime!) < const Duration(milliseconds: 400)) {
      return false;
    }

    for (final hero in List.from(_activeHeroes)) {
      if (hero.shuttleContext.mounted && hero.pageContext.mounted) {
        final renderBox = hero.shuttleContext.findRenderObject() as RenderBox?;
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
  final BuildContext pageContext;

  const FlyingShuttleWrapper({
    super.key,
    required this.child,
    required this.onTap,
    required this.pageContext,
  });

  @override
  State<FlyingShuttleWrapper> createState() => _FlyingShuttleWrapperState();
}

class _FlyingShuttleWrapperState extends State<FlyingShuttleWrapper> {
  @override
  void initState() {
    super.initState();
    FlyingHeroTracker.register(context, widget.pageContext, widget.onTap);
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
