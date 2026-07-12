import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/nfc_capture.dart';
import '../providers/wallet_provider.dart';
import '../services/nfc_service.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_wallet.dart';
import '../widgets/nfc_session_sheet.dart';
import '../widgets/wallet_card_view.dart';
import 'card_detail_screen.dart';
import 'save_card_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _nfc = NfcService();
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _addCard() async {
    final available = await _nfc.isAvailable();
    if (!mounted) return;
    if (!available) {
      _showNfcOffDialog();
      return;
    }
    final capture = await NfcSessionSheet.show<NfcCapture>(
      context,
      title: 'Ready to scan',
      hint: 'Hold your phone against the card, tag or key fob.',
      accent: AppTheme.seed,
      icon: Icons.nfc_rounded,
      action: _nfc.scan,
      onCancel: _nfc.cancel,
      successLabel: 'Tag read',
    );
    if (capture == null || !mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SaveCardScreen(capture: capture)),
    );
  }

  void _showNfcOffDialog() {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('NFC unavailable'),
        content: const Text(
          'NFC is switched off or not supported on this device. '
          'Enable NFC in system settings and try again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: wallet.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _addCard,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add'),
            ),
      body: wallet.isLoading
          ? const Center(child: CircularProgressIndicator())
          : wallet.isEmpty
              ? EmptyWallet(onAdd: _addCard)
              : _WalletBody(
                  searchController: _searchController,
                  scheme: scheme,
                ),
    );
  }
}

class _WalletBody extends StatelessWidget {
  const _WalletBody({required this.searchController, required this.scheme});

  final TextEditingController searchController;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();
    final cards = wallet.visibleCards;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: TextField(
            controller: searchController,
            onChanged: wallet.setQuery,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search cards, keys or UID',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: wallet.query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        searchController.clear();
                        wallet.setQuery('');
                      },
                    ),
            ),
          ),
        ),
        if (wallet.usedTypes.isNotEmpty)
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _FilterChip(
                  label: 'All',
                  count: wallet.totalCount,
                  selected: wallet.typeFilter == null,
                  onTap: () => wallet.setTypeFilter(null),
                ),
                for (final type in wallet.usedTypes)
                  _FilterChip(
                    label: type.label,
                    icon: type.icon,
                    count: wallet.countOf(type),
                    selected: wallet.typeFilter == type,
                    onTap: () => wallet.setTypeFilter(
                        wallet.typeFilter == type ? null : type),
                  ),
              ],
            ),
          ),
        Expanded(
          child: cards.isEmpty
              ? _NoMatches(scheme: scheme)
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  itemCount: cards.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 16),
                  itemBuilder: (context, i) {
                    final card = cards[i];
                    return WalletCardView(
                      card: card,
                      heroTag: 'card_${card.id}',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CardDetailScreen(cardId: card.id),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        avatar: icon == null
            ? null
            : Icon(icon,
                size: 16,
                color: selected ? scheme.onPrimary : scheme.onSurfaceVariant),
        label: Text('$label · $count'),
        labelStyle: TextStyle(
          color: selected ? scheme.onPrimary : scheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        selectedColor: scheme.primary,
        backgroundColor: scheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
    );
  }
}

class _NoMatches extends StatelessWidget {
  const _NoMatches({required this.scheme});
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded,
              size: 48, color: scheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text('No cards match your search',
              style: TextStyle(color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
