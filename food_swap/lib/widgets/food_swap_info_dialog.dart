import 'package:flutter/material.dart';

Future<void> showFoodSwapInfoDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) => const _FoodSwapInfoDialog(),
  );
}

class _FoodSwapInfoDialog extends StatelessWidget {
  const _FoodSwapInfoDialog();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('About FoodSwap'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoSection(
              title: 'What FoodSwap is',
              child: Text(
                'FoodSwap helps you compare packaged foods and discover '
                'potentially better alternatives using available nutritional '
                'information.',
                style: TextStyle(color: colors.onSurfaceVariant, height: 1.4),
              ),
            ),
            const SizedBox(height: 20),
            _InfoSection(
              title: 'FoodSwap Score',
              child: Text(
                'The FoodSwap Score is the app’s own comparative score. It '
                'uses the nutritional factors implemented by FoodSwap to '
                'help compare products. It is not an official health rating.',
                style: TextStyle(color: colors.onSurfaceVariant, height: 1.4),
              ),
            ),
            const SizedBox(height: 20),
            _InfoSection(
              title: 'Nutri-Score A–E',
              child: Column(
                children: const [
                  _GradeRow(
                    grade: 'A',
                    description: 'Generally more favorable',
                  ),
                  _GradeRow(grade: 'B', description: 'Generally favorable'),
                  _GradeRow(grade: 'C', description: 'Intermediate'),
                  _GradeRow(
                    grade: 'D',
                    description: 'Generally less favorable',
                  ),
                  _GradeRow(
                    grade: 'E',
                    description: 'Generally least favorable',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Nutri-Score is a nutritional grading system based on the '
              'available product data. It does not determine whether a food '
              'is healthy or unhealthy.',
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'FoodSwap is intended to help compare packaged foods using '
                'available nutritional data. It is not medical or dietary '
                'advice.',
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _InfoSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _GradeRow extends StatelessWidget {
  final String grade;
  final String description;

  const _GradeRow({required this.grade, required this.description});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final gradeColor = switch (grade) {
      'A' => const Color(0xFF16854A),
      'B' => const Color(0xFF76B852),
      'C' => const Color(0xFFF0B323),
      'D' => const Color(0xFFE27C2F),
      _ => const Color(0xFFD75242),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: gradeColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              grade,
              style: TextStyle(
                color: colors.onPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              description,
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
