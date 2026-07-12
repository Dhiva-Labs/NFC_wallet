import 'package:flutter/material.dart';

import 'nfc_pulse.dart';

enum _Phase { waiting, success, error }

/// A modal bottom sheet that runs a single NFC [action] (scan or write),
/// showing the pulse while waiting and a success/error state at the end.
///
/// Resolves to the action's result on success, or `null` if cancelled.
class NfcSessionSheet<T> extends StatefulWidget {
  const NfcSessionSheet({
    super.key,
    required this.title,
    required this.hint,
    required this.accent,
    required this.icon,
    required this.action,
    required this.onCancel,
    this.successLabel = 'Done',
  });

  final String title;
  final String hint;
  final Color accent;
  final IconData icon;
  final Future<T> Function() action;
  final Future<void> Function() onCancel;
  final String successLabel;

  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required String hint,
    required Color accent,
    required IconData icon,
    required Future<T> Function() action,
    required Future<void> Function() onCancel,
    String successLabel = 'Done',
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => NfcSessionSheet<T>(
        title: title,
        hint: hint,
        accent: accent,
        icon: icon,
        action: action,
        onCancel: onCancel,
        successLabel: successLabel,
      ),
    );
  }

  @override
  State<NfcSessionSheet<T>> createState() => _NfcSessionSheetState<T>();
}

class _NfcSessionSheetState<T> extends State<NfcSessionSheet<T>> {
  _Phase _phase = _Phase.waiting;
  String _error = '';
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    setState(() {
      _phase = _Phase.waiting;
      _error = '';
    });
    try {
      final result = await widget.action();
      _finished = true;
      if (!mounted) return;
      setState(() => _phase = _Phase.success);
      await Future.delayed(const Duration(milliseconds: 750));
      if (!mounted) return;
      Navigator.of(context).pop(result);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _Phase.error;
        _error = _prettyError(e);
      });
    }
  }

  String _prettyError(Object e) {
    final msg = e.toString().replaceFirst('Exception: ', '');
    if (msg.toLowerCase().contains('cancel')) return 'Session cancelled.';
    return msg.isEmpty ? 'Something went wrong. Try again.' : msg;
  }

  @override
  void dispose() {
    if (!_finished) widget.onCancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (_phase) {
      _Phase.success => const Color(0xFF27AE60),
      _Phase.error => scheme.error,
      _Phase.waiting => widget.accent,
    };
    final icon = switch (_phase) {
      _Phase.success => Icons.check_rounded,
      _Phase.error => Icons.close_rounded,
      _Phase.waiting => widget.icon,
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 28),
          NfcPulse(
            color: color,
            icon: icon,
            active: _phase == _Phase.waiting,
            size: 170,
          ),
          const SizedBox(height: 28),
          Text(
            switch (_phase) {
              _Phase.success => widget.successLabel,
              _Phase.error => 'Couldn’t read the tag',
              _Phase.waiting => widget.title,
            },
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            switch (_phase) {
              _Phase.success => 'You’re all set.',
              _Phase.error => _error,
              _Phase.waiting => widget.hint,
            },
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 28),
          if (_phase == _Phase.waiting)
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          if (_phase == _Phase.error) ...[
            FilledButton.icon(
              onPressed: _run,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ],
      ),
    );
  }
}
