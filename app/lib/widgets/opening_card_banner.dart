import 'package:flutter/material.dart';

import '../models/opening_experience.dart';

class OpeningCardBanner extends StatelessWidget {
  const OpeningCardBanner({
    super.key,
    required this.card,
    required this.onPressed,
  });

  final OpeningCardData card;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = _toneColors(theme, card.tone);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            card.title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            card.body,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withAlpha(230),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: colors.first,
            ),
            child: Text(card.ctaLabel),
          ),
        ],
      ),
    );
  }

  List<Color> _toneColors(ThemeData theme, String tone) {
    switch (tone) {
      case 'warning':
        return const [Color(0xFF8A5A00), Color(0xFFCA8A04)];
      case 'success':
        return const [Color(0xFF0F766E), Color(0xFF14B8A6)];
      case 'celebration':
        return const [Color(0xFFB45309), Color(0xFFF59E0B)];
      case 'supportive':
        return const [Color(0xFF1D4ED8), Color(0xFF60A5FA)];
      default:
        return [
          theme.colorScheme.primary,
          theme.colorScheme.primaryContainer.withAlpha(220),
        ];
    }
  }
}
