import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Simple numeric PIN dialog. When [confirm] is true the user must enter the
/// same PIN twice (used when setting a new PIN). Returns the PIN or null.
class PinDialog extends StatefulWidget {
  const PinDialog({super.key, required this.title, this.confirm = false});

  final String title;
  final bool confirm;

  static Future<String?> show(
    BuildContext context, {
    required String title,
    bool confirm = false,
  }) {
    return showDialog<String>(
      context: context,
      builder: (_) => PinDialog(title: title, confirm: confirm),
    );
  }

  @override
  State<PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<PinDialog> {
  final _pin = TextEditingController();
  final _confirm = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _pin.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    final pin = _pin.text.trim();
    if (pin.length < 4) {
      setState(() => _error = 'Use at least 4 digits.');
      return;
    }
    if (widget.confirm && pin != _confirm.text.trim()) {
      setState(() => _error = 'PINs don’t match.');
      return;
    }
    Navigator.of(context).pop(pin);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _pin,
            autofocus: true,
            obscureText: true,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(8),
            ],
            decoration: const InputDecoration(labelText: 'PIN'),
            onSubmitted: (_) => widget.confirm ? null : _submit(),
          ),
          if (widget.confirm) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _confirm,
              obscureText: true,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(8),
              ],
              decoration: const InputDecoration(labelText: 'Confirm PIN'),
              onSubmitted: (_) => _submit(),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('OK')),
      ],
    );
  }
}
