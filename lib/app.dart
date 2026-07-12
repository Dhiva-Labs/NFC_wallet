import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/settings_provider.dart';
import 'providers/wallet_provider.dart';
import 'screens/home_screen.dart';
import 'screens/lock_screen.dart';
import 'services/auth_service.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';

class NfcWalletApp extends StatefulWidget {
  const NfcWalletApp({
    super.key,
    required this.storage,
    required this.auth,
  });

  final StorageService storage;
  final AuthService auth;

  @override
  State<NfcWalletApp> createState() => _NfcWalletAppState();
}

class _NfcWalletAppState extends State<NfcWalletApp> {
  late final WalletProvider _wallet = WalletProvider(widget.storage);
  late final SettingsProvider _settings =
      SettingsProvider(widget.storage, widget.auth);
  late final Future<void> _boot = _load();

  Future<void> _load() =>
      Future.wait([_wallet.load(), _settings.load()]).then((_) {});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _wallet),
        ChangeNotifierProvider.value(value: _settings),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) => MaterialApp(
          title: 'NFC Wallet',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: settings.themeMode,
          home: FutureBuilder<void>(
            future: _boot,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const _Splash();
              }
              return const RootGate();
            },
          ),
        ),
      ),
    );
  }
}

/// Decides whether to show the lock screen before the wallet.
class RootGate extends StatefulWidget {
  const RootGate({super.key});

  @override
  State<RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<RootGate> {
  late bool _locked;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _locked = settings.appLockEnabled && settings.canBiometric;
  }

  @override
  Widget build(BuildContext context) {
    if (_locked) {
      return LockScreen(onUnlocked: () => setState(() => _locked = false));
    }
    return const HomeScreen();
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: CardPalettes.gradientFor(AppTheme.seed),
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.contactless_rounded,
                  color: Colors.white, size: 44),
            ),
            const SizedBox(height: 20),
            Text('NFC Wallet',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 24),
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                  strokeWidth: 2.4, color: scheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}
