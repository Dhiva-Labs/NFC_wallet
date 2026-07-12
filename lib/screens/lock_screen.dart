import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/pin_dialog.dart';

/// Full-screen gate shown when app-lock is enabled.
class LockScreen extends StatefulWidget {
  const LockScreen({super.key, required this.onUnlocked});

  final VoidCallback onUnlocked;

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  Future<void> _unlock() async {
    if (_busy) return;
    setState(() => _busy = true);
    final settings = context.read<SettingsProvider>();
    final ok = await settings.auth.authenticate('Unlock your NFC Wallet');
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) widget.onUnlocked();
  }

  Future<void> _usePin() async {
    final settings = context.read<SettingsProvider>();
    final pin = await PinDialog.show(context, title: 'Enter your PIN');
    if (pin == null || !mounted) return;
    if (await settings.verifyPin(pin)) {
      widget.onUnlocked();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incorrect PIN')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasPin = context.watch<SettingsProvider>().hasPin;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: CardPalettes.gradientFor(AppTheme.seed)),
                  borderRadius: BorderRadius.circular(28),
                ),
                child:
                    const Icon(Icons.lock_rounded, color: Colors.white, size: 44),
              ),
              const SizedBox(height: 28),
              Text('Wallet locked',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(
                'Authenticate to view your cards.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _busy ? null : _unlock,
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.fingerprint_rounded),
                label: const Text('Unlock'),
                style: FilledButton.styleFrom(minimumSize: const Size(220, 52)),
              ),
              if (hasPin) ...[
                const SizedBox(height: 12),
                TextButton(onPressed: _usePin, child: const Text('Use PIN')),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
