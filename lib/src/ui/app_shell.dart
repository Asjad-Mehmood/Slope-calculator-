// The frame round every screen: a menu down the left on a wide screen, a rail on a tablet and a
// bar along the bottom on a phone; a header with the page title, text size and light/dark.
import 'package:flutter/material.dart';

import '../brand.dart';
import 'settings.dart';
import 'theme.dart';

class Destination {
  const Destination({required this.label, required this.icon, required this.title, required this.subtitle});
  final String label;
  final IconData icon;
  final String title;
  final String subtitle;
}

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.destinations,
    required this.selected,
    required this.onSelect,
    required this.settings,
    required this.child,
    this.headerActions = const [],
  });

  final List<Destination> destinations;
  final int selected;
  final ValueChanged<int> onSelect;
  final AppSettings settings;
  final Widget child;

  /// Buttons for this page, shown in the header (Project plate, Copy …)
  final List<Widget> headerActions;

  static const wide = 1100.0;
  static const medium = 720.0;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final page = destinations[selected];
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(page: page, settings: settings, compact: width < medium, actions: headerActions),
        Expanded(child: child),
      ],
    );

    if (width >= wide) {
      return Scaffold(
        body: Row(
          children: [
            _Sidebar(destinations: destinations, selected: selected, onSelect: onSelect),
            Expanded(child: body),
          ],
        ),
      );
    }
    if (width >= medium) {
      final c = context.colors;
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              backgroundColor: c.card,
              selectedIndex: selected,
              onDestinationSelected: onSelect,
              labelType: NavigationRailLabelType.all,
              leading: const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: _Logo(size: 40)),
              indicatorColor: c.accent.withValues(alpha: 0.25),
              destinations: [
                for (final d in destinations) NavigationRailDestination(icon: Icon(d.icon), label: Text(d.label)),
              ],
            ),
            VerticalDivider(width: 1, color: c.line),
            Expanded(child: body),
          ],
        ),
      );
    }
    final c = context.colors;
    return Scaffold(
      body: SafeArea(bottom: false, child: body),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected,
        onDestinationSelected: onSelect,
        backgroundColor: c.card,
        indicatorColor: c.accent.withValues(alpha: 0.28),
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [for (final d in destinations) NavigationDestination(icon: Icon(d.icon), label: d.label)],
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({this.size = 36});
  final double size;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(size * 0.22),
    child: Image.asset('assets/brand/icon-512.png', width: size, height: size, excludeFromSemantics: true),
  );
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.destinations, required this.selected, required this.onSelect});
  final List<Destination> destinations;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: 252,
      decoration: BoxDecoration(
        color: c.card,
        border: Border(right: BorderSide(color: c.line)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
              child: Row(
                children: [
                  const _Logo(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: c.ink,
                            letterSpacing: -0.2,
                          ),
                        ),
                        Text(
                          'by $appPublisher',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: c.line),
            const SizedBox(height: 10),
            for (var i = 0; i < destinations.length; i++)
              _SideItem(destination: destinations[i], selected: i == selected, onTap: () => onSelect(i)),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: OutlinedButton.icon(
                onPressed: () =>
                    ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(content: Text('Sign in with Excel to KML comes in phase 6.'))),
                icon: const Icon(Icons.account_circle_outlined),
                label: const Text('Sign in'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
              child: Text(
                'Version $appVersion',
                style: TextStyle(fontSize: 12, color: c.muted, fontFeatures: tabular),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SideItem extends StatelessWidget {
  const _SideItem({required this.destination, required this.selected, required this.onTap});
  final Destination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: selected ? c.accent.withValues(alpha: 0.18) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Semantics(
            selected: selected,
            button: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              child: Row(
                children: [
                  Icon(destination.icon, size: 21, color: selected ? c.ink : c.muted),
                  const SizedBox(width: 12),
                  Text(
                    destination.label,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      color: selected ? c.ink : c.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.page, required this.settings, required this.compact, required this.actions});
  final Destination page;
  final AppSettings settings;
  final bool compact;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final brightness = Theme.of(context).brightness;
    final themeLabel = brightness == Brightness.light ? 'Dark mode' : 'Light mode';
    return Container(
      padding: EdgeInsets.fromLTRB(compact ? 16 : 28, compact ? 10 : 18, compact ? 8 : 24, compact ? 10 : 16),
      decoration: BoxDecoration(
        color: c.background,
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      child: Row(
        children: [
          if (compact) ...[const _Logo(size: 32), const SizedBox(width: 10)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  compact ? page.label : page.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: compact ? 19 : 24),
                ),
                if (!compact)
                  Text(
                    page.subtitle,
                    style: TextStyle(color: c.muted, fontSize: 13.5, fontWeight: FontWeight.w500),
                  ),
              ],
            ),
          ),
          ...actions,
          if (!compact) const SizedBox(width: 8),
          ListenableBuilder(
            listenable: settings,
            builder: (context, _) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!compact) ...[
                  IconButton(
                    tooltip: 'Smaller text',
                    onPressed: settings.canShrinkText ? settings.shrinkText : null,
                    icon: const Icon(Icons.text_decrease_rounded),
                  ),
                  IconButton(
                    tooltip: 'Larger text',
                    onPressed: settings.canGrowText ? settings.growText : null,
                    icon: const Icon(Icons.text_increase_rounded),
                  ),
                ],
                IconButton(
                  tooltip: themeLabel,
                  onPressed: () => settings.cycleTheme(brightness),
                  icon: Icon(brightness == Brightness.light ? Icons.dark_mode_outlined : Icons.light_mode_outlined),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
