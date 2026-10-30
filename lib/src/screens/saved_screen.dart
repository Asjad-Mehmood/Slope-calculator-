// Saved: sign in with the Excel to KML account, then keep calculations in it and open them on any
// device: the Windows program, the web app or a phone.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../account/account.dart';
import '../account/api.dart';
import '../calc/calc.dart';
import '../state/calculation.dart';
import '../state/project_plate.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';

class SavedScreen extends StatelessWidget {
  const SavedScreen({
    super.key,
    required this.account,
    required this.calculation,
    required this.plate,
    required this.onOpened,
  });
  final Account account;
  final Calculation calculation;
  final ProjectPlate plate;

  /// Called after a saved calculation is opened, to show the calculator
  final VoidCallback onOpened;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: account,
      builder: (context, _) => LayoutBuilder(
        builder: (context, box) {
          final pad = box.maxWidth < 720 ? 14.0 : 28.0;
          return SingleChildScrollView(
            padding: EdgeInsets.all(pad),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: account.signedIn
                    ? _SavedList(account: account, calculation: calculation, plate: plate, onOpened: onOpened)
                    : SignInCard(account: account),
              ),
            ),
          );
        },
      ),
    );
  }
}

String _when(String iso) {
  final t = DateTime.tryParse(iso)?.toLocal();
  if (t == null) return '';
  String two(int n) => n.toString().padLeft(2, '0');
  return '${t.year}-${two(t.month)}-${two(t.day)} ${two(t.hour)}:${two(t.minute)}';
}

class _SavedList extends StatefulWidget {
  const _SavedList({required this.account, required this.calculation, required this.plate, required this.onOpened});
  final Account account;
  final Calculation calculation;
  final ProjectPlate plate;
  final VoidCallback onOpened;

  @override
  State<_SavedList> createState() => _SavedListState();
}

class _SavedListState extends State<_SavedList> {
  bool _saving = false;

  void _toast(String s) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(s)));

  Future<void> _saveCurrent() async {
    final r = widget.calculation.result;
    if (r == null) {
      _toast('Fix the line on the Calculator first: ${widget.calculation.problem}');
      return;
    }
    final suggested = widget.plate.projectName.isNotEmpty
        ? widget.plate.projectName
        : '${formatChainage(r.startChainage)} to ${formatChainage(r.endChainage)}';
    final name = await _askName(context, suggested);
    if (name == null || name.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await widget.account.save(
        name: name.trim(),
        data: {'version': 1, 'calculation': widget.calculation.toJson(), 'plate': widget.plate.values},
        summary: {
          'percent': r.percent,
          'rise': r.rise,
          'length': r.length,
          'start': r.startChainage,
          'end': r.endChainage,
          'stations': r.stations.length,
        },
      );
      _toast('Saved to your account: ${name.trim()}');
    } on ApiError catch (e) {
      _toast(e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _open(SavedCalculation s) {
    final calc = s.data['calculation'];
    final plate = s.data['plate'];
    if (calc is Map<String, Object?>) widget.calculation.loadJson(calc);
    if (plate is Map<String, Object?>) {
      widget.plate.save({
        for (final e in plate.entries)
          if (e.value is String) e.key: e.value! as String,
      });
    }
    widget.onOpened();
    _toast('Opened: ${s.name}');
  }

  Future<void> _delete(SavedCalculation s) async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this calculation?'),
        content: Text('"${s.name}" is removed from your account on every device.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (sure != true) return;
    try {
      await widget.account.delete(s.id);
      _toast('Deleted: ${s.name}');
    } on ApiError catch (e) {
      _toast(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final a = widget.account;
    final user = a.user!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionCard(
          title: 'Your account',
          trailing: OutlinedButton.icon(
            onPressed: a.signOut,
            icon: const Icon(Icons.logout_rounded, size: 19),
            label: const Text('Sign out'),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: c.accent,
                child: Text(
                  user.display.characters.first.toUpperCase(),
                  style: TextStyle(color: c.onAccent, fontWeight: FontWeight.w800, fontSize: 18),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.display,
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: c.ink),
                    ),
                    Text(user.email, style: TextStyle(color: c.muted)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          step: 7,
          title: 'Saved calculations',
          trailing: Wrap(
            spacing: 8,
            children: [
              IconButton(
                tooltip: 'Refresh',
                onPressed: a.loading ? null : a.refresh,
                icon: const Icon(Icons.refresh_rounded),
              ),
              FilledButton.icon(
                onPressed: _saving ? null : _saveCurrent,
                icon: const Icon(Icons.cloud_upload_outlined, size: 19),
                label: const Text('Save the current calculation'),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (a.problem != null) ...[Notice(a.problem!, kind: NoticeKind.problem), const SizedBox(height: 12)],
              if (a.loading && a.saved.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (a.saved.isEmpty)
                const Notice(
                  'Nothing saved yet. Press "Save the current calculation" to keep the line, the settings '
                  'and the project plate in your account, ready to open on any device.',
                )
              else
                for (final s in a.saved) ...[
                  _SavedTile(saved: s, onOpen: () => _open(s), onDelete: () => _delete(s)),
                  const SizedBox(height: 10),
                ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SavedTile extends StatelessWidget {
  const _SavedTile({required this.saved, required this.onOpen, required this.onDelete});
  final SavedCalculation saved;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = saved.summary;
    double? n(String k) => (s[k] as num?)?.toDouble();
    final parts = [
      if (n('percent') != null) '${signed(n('percent')!, 3)} %',
      if (n('start') != null && n('end') != null) '${formatChainage(n('start')!)} to ${formatChainage(n('end')!)}',
      if (n('stations') != null) '${n('stations')!.round()} stations',
      _when(saved.updated),
    ].where((p) => p.isNotEmpty);
    return Material(
      color: c.cardSoft,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onOpen,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.line),
          ),
          child: Row(
            children: [
              Icon(Icons.show_chart_rounded, color: c.accent),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      saved.name,
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: c.ink),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      parts.join('  ·  '),
                      style: TextStyle(color: c.muted, fontSize: 13, fontFeatures: tabular),
                    ),
                  ],
                ),
              ),
              TextButton(onPressed: onOpen, child: const Text('Open')),
              IconButton(tooltip: 'Delete', onPressed: onDelete, icon: const Icon(Icons.delete_outline_rounded)),
            ],
          ),
        ),
      ),
    );
  }
}

Future<String?> _askName(BuildContext context, String suggested) =>
    showDialog<String>(context: context, builder: (_) => _NameDialog(suggested));

/// Asks for the saved calculation's name. Owns its text box, so the box lives until the dialog
/// has finished closing.
class _NameDialog extends StatefulWidget {
  const _NameDialog(this.suggested);
  final String suggested;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final _box = TextEditingController(text: widget.suggested);

  @override
  void dispose() {
    _box.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Save to your account'),
    content: SizedBox(
      width: 420,
      child: TextField(
        controller: _box,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Name'),
        onSubmitted: (v) => Navigator.pop(context, v),
      ),
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      FilledButton(onPressed: () => Navigator.pop(context, _box.text), child: const Text('Save')),
    ],
  );
}

/// Sign in, create an account, or sign in through the browser.
class SignInCard extends StatefulWidget {
  const SignInCard({super.key, required this.account});
  final Account account;

  @override
  State<SignInCard> createState() => _SignInCardState();
}

enum _Step { signIn, register, code, browser }

class _SignInCardState extends State<SignInCard> {
  _Step _step = _Step.signIn;
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _company = TextEditingController();
  final _code = TextEditingController();
  EmailCode? _challenge;
  BrowserSignIn? _browser;
  Timer? _poll;
  bool _busy = false;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _poll?.cancel();
    for (final c in [_name, _email, _password, _company, _code]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _run(Future<void> Function() work) async {
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      await work();
    } on ApiError catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _needCode(EmailCode? c) {
    if (c == null) return;
    _challenge = c;
    _code.clear();
    setState(() => _step = _Step.code);
  }

  Future<void> _startBrowser() => _run(() async {
    final s = await widget.account.startBrowserSignIn();
    setState(() {
      _browser = s;
      _step = _Step.browser;
    });
    await launchUrl(Uri.parse(s.url), mode: LaunchMode.externalApplication);
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(seconds: 3), (_) async {
      try {
        if (await widget.account.checkBrowserSignIn(s)) _poll?.cancel();
      } on ApiError catch (e) {
        _poll?.cancel();
        if (mounted) setState(() => _error = e.message);
      }
    });
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final a = widget.account;
    Widget field(TextEditingController ctl, String label, {bool secret = false, TextInputType? type, String? hint}) =>
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextField(
            controller: ctl,
            obscureText: secret,
            keyboardType: type,
            autocorrect: false,
            enableSuggestions: !secret,
            decoration: InputDecoration(labelText: label, hintText: hint),
          ),
        );

    final body = switch (_step) {
      _Step.signIn || _Step.register => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<_Step>(
            segments: const [
              ButtonSegment(value: _Step.signIn, label: Text('Sign in')),
              ButtonSegment(value: _Step.register, label: Text('Create an account')),
            ],
            selected: {_step},
            onSelectionChanged: (v) => setState(() {
              _step = v.first;
              _error = null;
            }),
          ),
          const SizedBox(height: 16),
          if (_step == _Step.register) field(_name, 'Your name'),
          field(_email, 'Email', type: TextInputType.emailAddress, hint: 'name@company.com'),
          field(_password, 'Password', secret: true, hint: _step == _Step.register ? 'At least 8 characters' : null),
          if (_step == _Step.register) field(_company, 'Company (optional)'),
          FilledButton(
            onPressed: _busy
                ? null
                : () => _run(() async {
                    final code = _step == _Step.signIn
                        ? await a.signIn(_email.text, _password.text)
                        : await a.register(
                            name: _name.text,
                            email: _email.text,
                            password: _password.text,
                            company: _company.text,
                          );
                    _needCode(code);
                  }),
            child: Text(_step == _Step.signIn ? 'Sign in' : 'Create the account'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _busy ? null : _startBrowser,
            icon: const Icon(Icons.open_in_browser_rounded),
            label: const Text('Sign in with the browser (Google)'),
          ),
          if (_step == _Step.signIn)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: _busy
                    ? null
                    : () => _run(() async {
                        if (_email.text.trim().isEmpty) throw ApiError('Type your email first.');
                        await a.forgotPassword(_email.text);
                        setState(
                          () => _info = 'If that email has an account, a link to set a new password is on its way.',
                        );
                      }),
                child: const Text('Forgot the password?'),
              ),
            ),
        ],
      ),
      _Step.code => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'We sent a 6-digit code to ${_challenge?.sentTo}. Type it here to confirm your email. '
            'Not there? Look in Spam.',
            style: TextStyle(color: c.ink, height: 1.45),
          ),
          const SizedBox(height: 14),
          field(_code, 'Code', type: TextInputType.number, hint: '123456'),
          FilledButton(
            onPressed: _busy ? null : () => _run(() => a.confirmEmail(_challenge!, _code.text)),
            child: const Text('Confirm'),
          ),
          Row(
            children: [
              TextButton(
                onPressed: _busy
                    ? null
                    : () => _run(() async {
                        _challenge = await a.resendCode(_challenge!);
                        setState(() => _info = 'A new code is on its way to ${_challenge!.sentTo}.');
                      }),
                child: const Text('Send a new code'),
              ),
              TextButton(onPressed: () => setState(() => _step = _Step.signIn), child: const Text('Back')),
            ],
          ),
        ],
      ),
      _Step.browser => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Your browser is open at exceltokml.com. Sign in there (Google works), then confirm this code:',
            style: TextStyle(color: c.ink, height: 1.45),
          ),
          const SizedBox(height: 14),
          Center(
            child: SelectableText(
              _browser?.code ?? '',
              style: TextStyle(
                fontFamily: readingFont,
                fontSize: 34,
                fontWeight: FontWeight.w700,
                letterSpacing: 4,
                color: c.ink,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4))),
          const SizedBox(height: 8),
          Center(
            child: Text('Waiting for the browser…', style: TextStyle(color: c.muted)),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: _browser == null
                    ? null
                    : () => launchUrl(Uri.parse(_browser!.url), mode: LaunchMode.externalApplication),
                child: const Text('Open the browser again'),
              ),
              TextButton(
                onPressed: () {
                  _poll?.cancel();
                  setState(() => _step = _Step.signIn);
                },
                child: const Text('Cancel'),
              ),
            ],
          ),
        ],
      ),
    };

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: SectionCard(
        title: 'Your Excel to KML account',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Sign in to keep calculations in your account and open them on any device. The same '
              'account as Excel to KML and Traverse & Level. The calculator works without signing in.',
              style: TextStyle(color: c.muted, height: 1.45),
            ),
            const SizedBox(height: 16),
            body,
            if (_error != null) ...[const SizedBox(height: 12), Notice(_error!, kind: NoticeKind.problem)],
            if (_info != null) ...[const SizedBox(height: 12), Notice(_info!, kind: NoticeKind.success)],
          ],
        ),
      ),
    );
  }
}
