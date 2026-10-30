import 'package:flutter/material.dart';

import '../ui/theme.dart';
import '../ui/widgets.dart';

/// Holds a menu item's place until its phase builds it.
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({super.key, required this.icon, required this.text, required this.phase});
  final IconData icon;
  final String text;
  final int phase;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: SectionCard(
            title: 'Coming in phase $phase',
            child: Column(
              children: [
                Icon(icon, size: 48, color: c.accent),
                const SizedBox(height: 12),
                Text(
                  text,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: c.muted, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
