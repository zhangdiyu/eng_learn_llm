import 'package:flutter/material.dart';
import '../config/theme.dart';

class XpToast {
  static void show(BuildContext context, int xp) {
    final colors = Theme.of(context).extension<AppColors>();
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 1500),
        onEnd: () => entry.remove(),
        builder: (context, value, child) {
          return Positioned(
            top: MediaQuery.of(context).size.height * 0.3 - (value * 60),
            left: MediaQuery.of(context).size.width / 2 - 50,
            child: Opacity(
              opacity: (1 - value).clamp(0.0, 1.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: (colors?.success ?? Colors.green).withAlpha(230),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  '+$xp XP',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
    overlay.insert(entry);
  }
}
