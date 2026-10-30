// The Export menu: Excel report, PDF report, Print and the chainage levels as CSV.
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../state/calculation.dart';
import '../state/level_run_state.dart';
import '../state/project_plate.dart';
import '../state/store.dart';
import 'csv_export.dart';
import 'excel_report.dart';
import 'pdf_report.dart';
import 'report_data.dart';
import 'save_file.dart';

enum ExportKind { excel, pdf, print, csv }

class Exporter {
  Exporter({required this.calculation, required this.plate, required this.store, required this.levelRun});
  final Calculation calculation;
  final ProjectPlate plate;
  final Store store;
  final LevelRunState levelRun;

  ReportData? data() {
    final slope = calculation.result;
    if (slope == null) return null;
    return ReportData(
      slope: slope,
      plate: ReportData.plateOf(plate),
      crossfall: CrossfallData.fromStore(store),
      run: levelRun.run,
      book: levelRun.book,
      method: levelRun.method,
    );
  }

  /// Makes and saves (or prints) the file; returns what to tell the user
  Future<String> export(ExportKind kind) async {
    final d = data();
    if (d == null) return 'Fix the line on the Calculator first: ${calculation.problem}';
    switch (kind) {
      case ExportKind.excel:
        final bytes = buildExcelReport(d);
        final saved = await saveFile(
          '${d.fileName('Slope_Report')}.xlsx',
          Uint8List.fromList(bytes),
          mime: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          extension: 'xlsx',
        );
        return saved == null ? 'Not saved' : 'Excel report saved: $saved';
      case ExportKind.pdf:
        final saved = await saveFile(
          '${d.fileName('Slope_Report')}.pdf',
          await buildPdfReport(d),
          mime: 'application/pdf',
          extension: 'pdf',
        );
        return saved == null ? 'Not saved' : 'PDF report saved: $saved';
      case ExportKind.print:
        final ok = await Printing.layoutPdf(name: d.fileName('Slope_Report'), onLayout: (_) => buildPdfReport(d));
        return ok ? 'Sent to the printer' : 'Printing cancelled';
      case ExportKind.csv:
        final saved = await saveFile(
          '${d.fileName('Chainage_Levels')}.csv',
          Uint8List.fromList(chainageLevelsCsv(d.slope)),
          mime: 'text/csv',
          extension: 'csv',
        );
        return saved == null ? 'Not saved' : 'Chainage levels saved: $saved';
    }
  }
}

class ExportButton extends StatefulWidget {
  const ExportButton({super.key, required this.exporter});
  final Exporter exporter;

  @override
  State<ExportButton> createState() => _ExportButtonState();
}

class _ExportButtonState extends State<ExportButton> {
  bool _busy = false;

  Future<void> _run(ExportKind kind) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    String message;
    try {
      message = await widget.exporter.export(kind);
    } catch (e) {
      message = 'Could not make the file: $e';
    }
    if (!mounted) return;
    setState(() => _busy = false);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 720;
    final items = [
      (ExportKind.excel, Icons.grid_on_rounded, 'Excel report (.xlsx)'),
      (ExportKind.pdf, Icons.picture_as_pdf_outlined, 'PDF report'),
      (ExportKind.print, Icons.print_outlined, 'Print'),
      (ExportKind.csv, Icons.table_rows_outlined, 'Chainage levels (.csv)'),
    ];
    return MenuAnchor(
      menuChildren: [
        for (final (kind, icon, label) in items)
          MenuItemButton(leadingIcon: Icon(icon), onPressed: _busy ? null : () => _run(kind), child: Text(label)),
      ],
      builder: (context, menu, _) {
        void toggle() => menu.isOpen ? menu.close() : menu.open();
        final icon = _busy
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2))
            : const Icon(Icons.ios_share_rounded, size: 19);
        if (compact) return IconButton(tooltip: 'Export', onPressed: toggle, icon: icon);
        return FilledButton.icon(onPressed: toggle, icon: icon, label: const Text('Export'));
      },
    );
  }
}
