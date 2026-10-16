import 'package:flutter/material.dart';

class TrainingStatsCard extends StatelessWidget {
  final String title;
  final int completed;
  final int? total;
  final List<Color> gradientColors;

  const TrainingStatsCard({
    super.key,
    required this.title,
    required this.completed,
    this.total,
    required this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 160),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$completed',
                      style: theme.textTheme.displayMedium?.copyWith(
                        color: Colors.white,
                        fontSize: 52,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (total != null)
                      TextSpan(
                        text: '/$total',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                        ),
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
