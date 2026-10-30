// The Level page: the digital level run and the optical level trainer, one tab each.
import 'package:flutter/material.dart';

import '../state/calculation.dart';
import '../state/level_run_state.dart';
import '../state/store.dart';
import '../ui/settings.dart';
import '../ui/theme.dart';
import 'digital_level_screen.dart';
import 'optical_trainer_screen.dart';

class LevelScreen extends StatelessWidget {
  const LevelScreen({
    super.key,
    required this.calculation,
    required this.settings,
    required this.store,
    required this.levelRun,
  });
  final LevelRunState levelRun;
  final Calculation calculation;
  final AppSettings settings;
  final Store store;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Material(
            color: c.background,
            child: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              indicatorColor: c.accent,
              indicatorWeight: 3,
              labelColor: c.ink,
              unselectedLabelColor: c.muted,
              labelStyle: const TextStyle(fontFamily: textFont, fontWeight: FontWeight.w700, fontSize: 14.5),
              dividerColor: c.line,
              tabs: const [
                Tab(icon: Icon(Icons.qr_code_2_rounded, size: 20), iconMargin: EdgeInsets.zero, text: 'Digital level'),
                Tab(
                  icon: Icon(Icons.visibility_outlined, size: 20),
                  iconMargin: EdgeInsets.zero,
                  text: 'Optical trainer',
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                DigitalLevelScreen(calculation: calculation, settings: settings, store: store, levelRun: levelRun),
                const OpticalTrainerScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
