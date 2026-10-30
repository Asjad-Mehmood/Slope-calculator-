// The building blocks every screen is made of.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme.dart';

/// A card with a numbered step and a title. Optional tools fold away until opened.
class SectionCard extends StatefulWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.child,
    this.step,
    this.optional = false,
    this.initiallyOpen = true,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(20, 18, 20, 20),
  });

  final String title;
  final Widget child;
  final int? step;

  /// Shows an "Optional" tag and folds the card when its title is pressed
  final bool optional;
  final bool initiallyOpen;
  final Widget? trailing;
  final EdgeInsets padding;

  @override
  State<SectionCard> createState() => _SectionCardState();
}

class _SectionCardState extends State<SectionCard> {
  late bool _open = widget.initiallyOpen;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final title = Row(
      children: [
        if (widget.step != null) ...[StepBadge(widget.step!), const SizedBox(width: 12)],
        Expanded(
          child: Text(
            widget.title.toUpperCase(),
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1.1, color: c.ink),
          ),
        ),
        if (widget.optional) ...[const Tag('Optional'), const SizedBox(width: 6)],
        if (widget.optional)
          Icon(_open ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: c.muted, semanticLabel: null),
      ],
    );
    // the extra on the right goes under the title when the card is narrow (sooner with larger
    // text), and never takes more than half the width beside it
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final head = widget.trailing == null
        ? title
        : LayoutBuilder(
            builder: (context, box) => box.maxWidth < 560 * scale
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [title, const SizedBox(height: 10), widget.trailing!],
                  )
                : Row(
                    children: [
                      Expanded(child: title),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Align(alignment: Alignment.centerRight, child: widget.trailing),
                      ),
                    ],
                  ),
          );
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.optional)
            Semantics(
              button: true,
              expanded: _open,
              child: InkWell(
                onTap: () => setState(() => _open = !_open),
                child: Padding(
                  padding: widget.padding.copyWith(bottom: _open ? 14 : widget.padding.top),
                  child: head,
                ),
              ),
            )
          else
            Padding(padding: widget.padding.copyWith(bottom: 14), child: head),
          AnimatedSize(
            duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 200),
            alignment: Alignment.topCenter,
            child: _open
                ? Padding(padding: widget.padding.copyWith(top: 0), child: widget.child)
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

/// The gold circle with a step number.
class StepBadge extends StatelessWidget {
  const StepBadge(this.number, {super.key});
  final int number;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle),
      child: Text(
        '$number',
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: c.onAccent),
      ),
    );
  }
}

/// A small rounded label: "Optional", "Rising", "Falling".
class Tag extends StatelessWidget {
  const Tag(this.text, {super.key, this.color, this.textColor, this.icon});
  final String text;
  final Color? color;
  final Color? textColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = textColor ?? c.muted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color ?? c.cardSoft,
        borderRadius: BorderRadius.circular(99),
        border: color == null ? Border.all(color: c.line) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 14, color: fg), const SizedBox(width: 4)],
          Text(
            text.toUpperCase(),
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: fg),
          ),
        ],
      ),
    );
  }
}

/// A number box with its short name (Y1), a label above, the unit and a line under it (the
/// chainage). The whole tile lights up while typing. Enter moves to the next box.
class NumberField extends StatefulWidget {
  const NumberField({
    super.key,
    required this.controller,
    required this.label,
    this.badge,
    this.unit,
    this.helper,
    this.error,
    this.focusNode,
    this.onChanged,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    this.signed = true,
  });

  final TextEditingController controller;
  final String label;
  final String? badge;
  final String? unit;
  final String? helper;
  final String? error;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final bool signed;

  @override
  State<NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<NumberField> {
  FocusNode? _own;
  FocusNode get _focus => widget.focusNode ?? (_own ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _focus.addListener(_repaint);
  }

  @override
  void didUpdateWidget(NumberField old) {
    super.didUpdateWidget(old);
    (old.focusNode ?? _own)?.removeListener(_repaint);
    _focus.addListener(_repaint);
  }

  void _repaint() => setState(() {});

  @override
  void dispose() {
    _focus.removeListener(_repaint);
    _own?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final w = widget;
    final border = w.error != null ? c.fall : (_focus.hasFocus ? c.accent : c.line);
    return Semantics(
      label: w.badge == null ? null : '${w.badge}, ${w.label}',
      child: GestureDetector(
        onTap: _focus.requestFocus,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: EdgeInsets.fromLTRB(w.badge == null ? 14 : 10, 10, 14, 10),
          decoration: BoxDecoration(
            color: c.cardSoft,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border, width: _focus.hasFocus || w.error != null ? 2 : 1),
          ),
          child: Row(
            children: [
              if (w.badge != null) ...[
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: c.heroStart, borderRadius: BorderRadius.circular(11)),
                  child: Text(
                    w.badge!,
                    style: TextStyle(color: c.accent, fontWeight: FontWeight.w800, fontSize: 15.5),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      w.label.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: c.muted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.9),
                    ),
                    TextField(
                      controller: w.controller,
                      focusNode: _focus,
                      onChanged: w.onChanged,
                      onSubmitted: w.onSubmitted,
                      textInputAction: w.textInputAction,
                      keyboardType: TextInputType.numberWithOptions(decimal: true, signed: w.signed),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.+\-\s]'))],
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: c.ink, fontFeatures: tabular),
                      decoration: const InputDecoration(
                        isDense: true,
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.only(top: 4, bottom: 2),
                      ),
                    ),
                    if (w.error != null || w.helper != null)
                      Text(
                        w.error ?? w.helper!,
                        style: TextStyle(
                          color: w.error != null ? c.fall : c.muted,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              if (w.unit != null)
                Text(
                  w.unit!,
                  style: TextStyle(color: c.muted, fontWeight: FontWeight.w600, fontSize: 15),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A pick-one box that looks like a [NumberField]: decimals, units.
class SelectField<T> extends StatelessWidget {
  const SelectField({
    super.key,
    required this.label,
    required this.value,
    required this.values,
    required this.text,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> values;
  final String Function(T) text;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: c.cardSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(color: c.muted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.9),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              isDense: true,
              borderRadius: BorderRadius.circular(12),
              dropdownColor: c.card,
              padding: const EdgeInsets.only(top: 4, bottom: 2),
              style: TextStyle(
                fontFamily: textFont,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: c.ink,
                fontFeatures: tabular,
              ),
              items: [for (final v in values) DropdownMenuItem(value: v, child: Text(text(v)))],
              onChanged: (v) => v == null ? null : onChanged(v),
            ),
          ),
        ],
      ),
    );
  }
}

/// A row of choices that can be pressed: the interval 5 · 10 · 20 · 25 · 50 · 100.
class ChoiceRow<T> extends StatelessWidget {
  const ChoiceRow({
    super.key,
    required this.values,
    required this.selected,
    required this.onSelected,
    required this.label,
    this.semanticLabel,
  });

  final List<T> values;
  final T? selected;
  final ValueChanged<T> onSelected;
  final String Function(T) label;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final v in values)
            ChoiceChip(
              label: Text(label(v)),
              selected: v == selected,
              onSelected: (_) => onSelected(v),
              materialTapTargetSize: MaterialTapTargetSize.padded,
            ),
        ],
      ),
    );
  }
}

/// The big slope % card.
class HeroResult extends StatelessWidget {
  const HeroResult({super.key, required this.label, required this.value, this.tag, this.footer});
  final String label;
  final String value;
  final Widget? tag;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [c.heroStart, c.heroEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFFB9C9E6),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 44,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
                fontFeatures: tabular,
              ),
            ),
          ),
          if (tag != null) ...[const SizedBox(height: 14), tag!],
          if (footer != null) ...[
            const SizedBox(height: 10),
            Text(footer!, style: const TextStyle(color: Color(0xFFB9C9E6), fontSize: 12.5)),
          ],
        ],
      ),
    );
  }
}

/// A smaller result: a label over a value.
class ResultTile extends StatelessWidget {
  const ResultTile({super.key, required this.label, required this.value, this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: c.cardSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.line),
      ),
      // in a tight grid cell the label and value shrink a little rather than overflow
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: c.muted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.9),
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(
                  color: valueColor ?? c.ink,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  fontFeatures: tabular,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum NoticeKind { info, success, warning, problem }

/// A line of guidance, a result sentence or a problem with the input.
class Notice extends StatelessWidget {
  const Notice(this.text, {super.key, this.kind = NoticeKind.info});
  final String text;
  final NoticeKind kind;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final (Color tint, IconData icon) = switch (kind) {
      NoticeKind.info => (c.accent, Icons.info_outline_rounded),
      NoticeKind.success => (c.rise, Icons.check_circle_outline_rounded),
      NoticeKind.warning => (c.accent, Icons.warning_amber_rounded),
      NoticeKind.problem => (c.fall, Icons.error_outline_rounded),
    };
    return Semantics(
      liveRegion: kind == NoticeKind.problem,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: tint.withValues(alpha: dark ? 0.12 : 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: tint.withValues(alpha: 0.45)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: kind == NoticeKind.info || kind == NoticeKind.warning ? c.ink : tint),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(color: c.ink, fontWeight: FontWeight.w500, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A table with a header that stays in view, striped rows, highlighted rows (start and end) and
/// one row that can be brought into view and marked ([focusRow], from "Go to chainage").
class DataGrid extends StatefulWidget {
  const DataGrid({
    super.key,
    required this.columns,
    required this.rows,
    this.numeric = const {},
    this.highlighted = const {},
    this.focusRow,
    this.maxHeight = 420,
  });

  final List<String> columns;
  final List<List<String>> rows;

  /// Columns with numbers: right aligned in table figures
  final Set<int> numeric;

  /// Rows drawn in the accent colour
  final Set<int> highlighted;
  final int? focusRow;
  final double maxHeight;

  static const rowHeight = 40.0;

  @override
  State<DataGrid> createState() => _DataGridState();
}

class _DataGridState extends State<DataGrid> {
  final _scroll = ScrollController();

  @override
  void didUpdateWidget(DataGrid old) {
    super.didUpdateWidget(old);
    final row = widget.focusRow;
    if (row != null && row != old.focusRow) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scroll.hasClients) return;
        final target = (row * DataGrid.rowHeight - widget.maxHeight / 2 + DataGrid.rowHeight / 2).clamp(
          0.0,
          _scroll.position.maxScrollExtent,
        );
        if (MediaQuery.disableAnimationsOf(context)) {
          _scroll.jumpTo(target);
        } else {
          _scroll.animateTo(target, duration: const Duration(milliseconds: 260), curve: Curves.easeOut);
        }
      });
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final w = widget;
    Widget cell(String text, int col, {bool head = false, bool bold = false}) => Expanded(
      flex: col == 0 ? 6 : 5,
      child: Text(
        text,
        textAlign: w.numeric.contains(col) ? TextAlign.right : TextAlign.left,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: head
            ? TextStyle(color: c.muted, fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 0.8)
            : TextStyle(
                color: c.ink,
                fontSize: 14,
                fontWeight: bold || col == 0 ? FontWeight.w600 : FontWeight.w500,
                fontFeatures: tabular,
              ),
      ),
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            color: c.cardSoft,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                for (var i = 0; i < w.columns.length; i++) ...[
                  if (i > 0) const SizedBox(width: 12),
                  cell(w.columns[i].toUpperCase(), i, head: true),
                ],
              ],
            ),
          ),
          Divider(height: 1, color: c.line),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: w.maxHeight),
            child: ListView.builder(
              controller: _scroll,
              shrinkWrap: true,
              itemCount: w.rows.length,
              itemExtent: DataGrid.rowHeight,
              itemBuilder: (context, r) {
                final focus = r == w.focusRow;
                final hot = focus || w.highlighted.contains(r);
                return Container(
                  decoration: BoxDecoration(
                    color: focus
                        ? c.accent.withValues(alpha: 0.32)
                        : hot
                        ? c.accent.withValues(alpha: 0.16)
                        : (r.isOdd ? c.cardSoft.withValues(alpha: 0.6) : null),
                    border: focus ? Border(left: BorderSide(color: c.accent, width: 4)) : null,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      for (var i = 0; i < w.columns.length; i++) ...[
                        if (i > 0) const SizedBox(width: 12),
                        cell(w.rows[r][i], i, bold: hot),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Lays children out side by side on a wide screen and one under the other on a narrow one.
class ResponsiveRow extends StatelessWidget {
  const ResponsiveRow({super.key, required this.children, this.breakpoint = 900, this.flex, this.gap = 16});
  final List<Widget> children;
  final double breakpoint;
  final List<int>? flex;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        if (box.maxWidth < breakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[if (i > 0) SizedBox(height: gap), children[i]],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) SizedBox(width: gap),
              Expanded(flex: flex?[i] ?? 1, child: children[i]),
            ],
          ],
        );
      },
    );
  }
}
