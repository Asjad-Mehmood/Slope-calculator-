// Settings: how the app looks and what a new calculation starts with.
import 'package:flutter/material.dart';

import '../brand.dart';
import '../calc/calc.dart';
import '../ui/settings.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.settings});
  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final c = context.colors;
        final s = settings;
        Widget row(String title, String text, Widget control) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: LayoutBuilder(
            builder: (context, box) {
              final words = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontWeight: FontWeight.w700, color: c.ink, fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(text, style: TextStyle(color: c.muted, fontSize: 13, height: 1.4)),
                ],
              );
              if (box.maxWidth < 620) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [words, const SizedBox(height: 10), control],
                );
              }
              return Row(
                children: [
                  Expanded(child: words),
                  const SizedBox(width: 20),
                  control,
                ],
              );
            },
          ),
        );

        return LayoutBuilder(
          builder: (context, box) {
            final pad = box.maxWidth < 720 ? 14.0 : 28.0;
            return SingleChildScrollView(
              padding: EdgeInsets.all(pad),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 860),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SectionCard(
                        title: 'Display',
                        child: Column(
                          children: [
                            row(
                              'Theme',
                              'Follow the computer, or always light or dark.',
                              SegmentedButton<ThemeMode>(
                                segments: const [
                                  ButtonSegment(value: ThemeMode.system, label: Text('Computer')),
                                  ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                                  ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                                ],
                                selected: {s.themeMode},
                                onSelectionChanged: (v) => s.themeMode = v.first,
                              ),
                            ),
                            Divider(color: c.line),
                            row(
                              'Text size',
                              'Makes everything larger or smaller, from 85 % to 130 %.',
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton.outlined(
                                    tooltip: 'Smaller text',
                                    onPressed: s.canShrinkText ? s.shrinkText : null,
                                    icon: const Icon(Icons.remove_rounded),
                                  ),
                                  SizedBox(
                                    width: 64,
                                    child: Text(
                                      '${(s.textScale * 100).round()} %',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontFeatures: tabular),
                                    ),
                                  ),
                                  IconButton.outlined(
                                    tooltip: 'Larger text',
                                    onPressed: s.canGrowText ? s.growText : null,
                                    icon: const Icon(Icons.add_rounded),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SectionCard(
                        title: 'Calculations',
                        child: Column(
                          children: [
                            row(
                              'Stations',
                              s.spacing == StationSpacing.roundChainages
                                  ? 'On round chainages: from 1+013 every 20 m gives 1+013, 1+020, 1+040 …'
                                  : 'Counted from the start: from 1+013 every 20 m gives 1+013, 1+033, 1+053 …',
                              SegmentedButton<StationSpacing>(
                                segments: const [
                                  ButtonSegment(value: StationSpacing.roundChainages, label: Text('Round chainages')),
                                  ButtonSegment(value: StationSpacing.fromStart, label: Text('From the start')),
                                ],
                                selected: {s.spacing},
                                onSelectionChanged: (v) => s.spacing = v.first,
                              ),
                            ),
                            Divider(color: c.line),
                            row(
                              'Decimals',
                              'For levels in a new calculation, tables and reports.',
                              SizedBox(
                                width: 140,
                                child: SelectField<int>(
                                  label: 'Places',
                                  value: s.decimals,
                                  values: const [1, 2, 3, 4, 5],
                                  text: (d) => '$d',
                                  onChanged: (d) => s.decimals = d,
                                ),
                              ),
                            ),
                            Divider(color: c.line),
                            row(
                              'Interval',
                              'The chainage interval a new calculation starts with.',
                              SizedBox(
                                width: 140,
                                child: SelectField<double>(
                                  label: 'Metres',
                                  value: const [5.0, 10.0, 20.0, 25.0, 50.0, 100.0].contains(s.interval)
                                      ? s.interval
                                      : 20.0,
                                  values: const [5.0, 10.0, 20.0, 25.0, 50.0, 100.0],
                                  text: (v) => v.toStringAsFixed(0),
                                  onChanged: (v) => s.interval = v,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SectionCard(
                        title: 'Levelling',
                        child: row(
                          'Allowable misclosure',
                          'C in C√K mm, with K the length of the run in km. 12 is common for '
                              'ordinary levelling; your specification may ask for less.',
                          SizedBox(
                            width: 140,
                            child: SelectField<double>(
                              label: 'C (mm)',
                              value: const [4.0, 6.0, 8.0, 10.0, 12.0, 20.0, 24.0].contains(s.allowableC)
                                  ? s.allowableC
                                  : 12.0,
                              values: const [4.0, 6.0, 8.0, 10.0, 12.0, 20.0, 24.0],
                              text: (v) => v.toStringAsFixed(0),
                              onChanged: (v) => s.allowableC = v,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SectionCard(
                        title: 'About',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$appName $appVersion',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: c.ink),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$appTagline. By $appPublisher, ${websiteUrl.replaceFirst('https://', '')}',
                              style: TextStyle(color: c.muted),
                            ),
                            const SizedBox(height: 14),
                            const Notice(
                              'Check results against an approved example before using them for construction.',
                              kind: NoticeKind.warning,
                            ),
                            const SizedBox(height: 14),
                            OutlinedButton.icon(
                              onPressed: () {
                                s.reset();
                                ScaffoldMessenger.of(
                                  context,
                                ).showSnackBar(const SnackBar(content: Text('Settings are back to how they started')));
                              },
                              icon: const Icon(Icons.restart_alt_rounded),
                              label: const Text('Reset settings'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
