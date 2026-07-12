import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';
import '../widgets/pin_dialog.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _setAppLock(BuildContext context, bool value) async {
    final settings = context.read<SettingsProvider>();
    if (value && !settings.canBiometric && !settings.hasPin) {
      final pin =
          await PinDialog.show(context, title: 'Set a PIN', confirm: true);
      if (pin == null) return;
      await settings.setPin(pin);
    }
    await settings.setAppLock(value);
  }

  Future<void> _setPin(BuildContext context) async {
    final settings = context.read<SettingsProvider>();
    final pin = await PinDialog.show(
      context,
      title: settings.hasPin ? 'Change PIN' : 'Set PIN',
      confirm: true,
    );
    if (pin == null) return;
    await settings.setPin(pin);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('PIN saved')));
    }
  }

  Future<void> _removePin(BuildContext context) async {
    final settings = context.read<SettingsProvider>();
    await settings.setPin(null);
    if (!settings.canBiometric) await settings.setAppLock(false);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('PIN removed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _GroupLabel('Appearance'),
          _Group(
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(Icons.palette_outlined, color: scheme.primary),
                    const SizedBox(width: 14),
                    const Text('Theme'),
                    const Spacer(),
                    SegmentedButton<ThemeMode>(
                      showSelectedIcon: false,
                      style: const ButtonStyle(
                        visualDensity: VisualDensity.compact,
                      ),
                      segments: const [
                        ButtonSegment(
                            value: ThemeMode.system, label: Text('Auto')),
                        ButtonSegment(
                            value: ThemeMode.light,
                            icon: Icon(Icons.light_mode_rounded, size: 18)),
                        ButtonSegment(
                            value: ThemeMode.dark,
                            icon: Icon(Icons.dark_mode_rounded, size: 18)),
                      ],
                      selected: {settings.themeMode},
                      onSelectionChanged: (s) =>
                          settings.setThemeMode(s.first),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _GroupLabel('Security'),
          _Group(
            children: [
              SwitchListTile.adaptive(
                value: settings.appLockEnabled,
                onChanged: (v) => _setAppLock(context, v),
                secondary: Icon(Icons.lock_outline_rounded,
                    color: scheme.primary),
                title: const Text('App lock'),
                subtitle: Text(
                  'Require authentication to open the app',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ),
              Divider(height: 1, color: scheme.outlineVariant),
              ListTile(
                leading: Icon(Icons.pin_rounded, color: scheme.primary),
                title: Text(settings.hasPin ? 'Change PIN' : 'Set PIN'),
                subtitle: Text(
                  settings.canBiometric
                      ? 'Fallback when biometrics are unavailable'
                      : 'Used to lock the app and protected cards',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
                onTap: () => _setPin(context),
              ),
              if (settings.hasPin) ...[
                Divider(height: 1, color: scheme.outlineVariant),
                ListTile(
                  leading: Icon(Icons.no_encryption_gmailerrorred_rounded,
                      color: scheme.error),
                  title: const Text('Remove PIN'),
                  onTap: () => _removePin(context),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),
          _GroupLabel('About'),
          _Group(
            children: [
              ListTile(
                leading: Icon(Icons.contactless_rounded,
                    color: scheme.primary),
                title: const Text('NFC Wallet'),
                subtitle: Text('Version 1.0.0 · by DhivaLabs',
                    style: TextStyle(color: scheme.onSurfaceVariant)),
              ),
              Divider(height: 1, color: scheme.outlineVariant),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoLine(
                      icon: Icons.smartphone_rounded,
                      text: 'Every card is stored only on this device. '
                          'Nothing is uploaded anywhere.',
                    ),
                    const SizedBox(height: 12),
                    _InfoLine(
                      icon: Icons.info_outline_rounded,
                      text: 'Cloning copies NDEF data onto blank writable '
                          'tags. Bank cards and encrypted access cards use '
                          'cryptography that cannot be duplicated.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: scheme.onSurfaceVariant),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: TextStyle(
                  color: scheme.onSurfaceVariant, fontSize: 13, height: 1.4)),
        ),
      ],
    );
  }
}
