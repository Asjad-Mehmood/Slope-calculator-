// The project plate: the job's details for the top of every report. A dialog on a computer, a
// full page on a phone.
import 'package:flutter/material.dart';

import '../state/project_plate.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';

Future<void> openProjectPlate(BuildContext context, ProjectPlate plate) {
  final wide = MediaQuery.sizeOf(context).width >= 720;
  if (wide) {
    return showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920, maxHeight: 820),
          child: ProjectPlateForm(plate: plate),
        ),
      ),
    );
  }
  return Navigator.of(context)
      .push(MaterialPageRoute<void>(fullscreenDialog: true, builder: (_) => ProjectPlateForm(plate: plate)));
}

class ProjectPlateForm extends StatefulWidget {
  const ProjectPlateForm({super.key, required this.plate});
  final ProjectPlate plate;

  @override
  State<ProjectPlateForm> createState() => _ProjectPlateFormState();
}

class _ProjectPlateFormState extends State<ProjectPlateForm> {
  late final Map<String, TextEditingController> _boxes = {
    for (final f in plateFields) f.key: TextEditingController(text: widget.plate[f.key]),
  };

  @override
  void dispose() {
    for (final c in _boxes.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    widget.plate.save({for (final e in _boxes.entries) e.key: e.value.text});
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Project plate saved')));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.card,
      appBar: AppBar(
        backgroundColor: c.card,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        titleSpacing: 24,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Project plate', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
            Text(
              'Printed at the top of the Excel and PDF reports. Fill in only what your job needs.',
              style: TextStyle(color: c.muted, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        toolbarHeight: 76,
        actions: [
          IconButton(
            tooltip: 'Close without saving',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, box) {
          final columns = box.maxWidth >= 760 ? 3 : (box.maxWidth >= 520 ? 2 : 1);
          const gap = 14.0;
          final cell = (box.maxWidth - 48 - gap * (columns - 1)) / columns;
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final f in plateFields)
                  SizedBox(
                    width: f.full ? box.maxWidth - 48 : (f.wide && columns > 1 ? cell * 2 + gap : cell),
                    child: TextField(
                      controller: _boxes[f.key],
                      autofocus: f == plateFields.first,
                      maxLines: f.multiline ? 3 : 1,
                      minLines: 1,
                      textInputAction: f.multiline ? TextInputAction.newline : TextInputAction.next,
                      decoration: InputDecoration(labelText: f.label, hintText: f.hint),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: c.line)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Kept on this device. With an account (phase 6) it is saved with each calculation.',
                  style: TextStyle(color: c.muted, fontSize: 12.5),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
              const SizedBox(width: 10),
              FilledButton.icon(onPressed: _save, icon: const Icon(Icons.check_rounded), label: const Text('Save')),
            ],
          ),
        ),
      ),
    );
  }
}

/// The header button: "Project plate", with how many details are filled in.
class ProjectPlateButton extends StatelessWidget {
  const ProjectPlateButton({super.key, required this.plate});
  final ProjectPlate plate;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: plate,
      builder: (context, _) => MediaQuery.sizeOf(context).width < 720
          ? IconButton(
              tooltip: plate.isEmpty ? 'Project plate' : 'Project plate: ${plate.projectName}',
              onPressed: () => openProjectPlate(context, plate),
              icon: Badge(
                isLabelVisible: !plate.isEmpty,
                label: Text('${plate.filled}'),
                child: const Icon(Icons.badge_outlined),
              ),
            )
          : OutlinedButton.icon(
              onPressed: () => openProjectPlate(context, plate),
              icon: const Icon(Icons.badge_outlined, size: 19),
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(plate.isEmpty ? 'Project plate' : _short(plate.projectName)),
                  if (!plate.isEmpty) ...[const SizedBox(width: 8), Tag('${plate.filled}')],
                ],
              ),
            ),
    );
  }

  static String _short(String name) {
    if (name.isEmpty) return 'Project plate';
    return name.length > 24 ? '${name.substring(0, 23)}…' : name;
  }
}
