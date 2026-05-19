import 'package:flutter/material.dart';

/// Lightweight fade + subtle x-slide transition.
/// 250ms forward, 200ms reverse — fast enough to not feel sluggish,
/// slow enough to communicate navigation direction.
class FadeSlideRoute<T> extends PageRouteBuilder<T> {
  FadeSlideRoute({required WidgetBuilder builder})
      : super(
          pageBuilder: (ctx, _, __) => builder(ctx),
          transitionDuration: const Duration(milliseconds: 250),
          reverseTransitionDuration: const Duration(milliseconds: 200),
          transitionsBuilder: (_, animation, __, child) => SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.04, 0),
              end: Offset.zero,
            ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: FadeTransition(opacity: animation, child: child),
          ),
        );
}
