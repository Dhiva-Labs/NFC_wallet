import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/ndef_record_data.dart';
import '../models/stored_card.dart';
import '../providers/settings_provider.dart';
import '../providers/wallet_provider.dart';
import '../services/nfc_service.dart';
import '../widgets/nfc_session_sheet.dart';
import '../widgets/pin_dialog.dart';
import '../widgets/wallet_card_view.dart';
import 'edit_card_screen.dart';
import 'raw_data_screen.dart';

class CardDetailScreen extends StatefulWidget {
  const CardDetailScreen({super.key, required this.cardId});

  final String cardId;

  @override
  State<CardDetailScreen> createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends State<CardDetailScreen> {
  final _nfc = NfcService();
  bool _revealed = false;

  Future<bool> _authenticate(String reason) async {
    final settings = context.read<SettingsProvider>();
    if (settings.canBiometric) {
      return settings.auth.authenticate(reason);
    }
    if (settings.hasPin) {
      final pin = await PinDialog.show(context, title: 'Enter your PIN');
      if (pin == null) return false;
      return settings.verifyPin(pin);
    }
    return true;
  }

  Future<void> _reveal(StoredCard card) async {
    if (await _authenticate('Reveal “${card.name}”')) {
      if (mounted) setState(() => _revealed = true);
    }
  }

  Future<void> _toggleProtect(StoredCard card) async {
    final wallet = context.read<WalletProvider>();
    if (card.isProtected) {
      if (!await _authenticate('Unlock “${card.name}”')) return;
      await wallet.update(card.copyWith(isProtected: false));
      if (mounted) setState(() => _revealed = true);
    } else {
      await wallet.update(card.copyWith(isProtected: true));
      if (mounted) setState(() => _revealed = false);
    }
  }

  Future<void> _clone(StoredCard card) async {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clone to a blank tag'),
        content: const Text(
          'This copies the stored NDEF data onto a blank, writable NFC tag '
          '(such as an NTAG213/215 sticker). It does not copy the original '
          'serial number, and secure/encrypted cards cannot be duplicated.\n\n'
          'Have a writable tag ready and continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (proceed != true || !mounted) return;

    if (!await _nfc.isAvailable()) {
      if (mounted) _snack('NFC is switched off or unavailable.');
      return;
    }
    if (!mounted) return;
    final bytes = await NfcSessionSheet.show<int>(
      context,
      title: 'Ready to write',
      hint: 'Hold your phone against a blank, writable NFC tag.',
      accent: card.color,
      icon: Icons.edit_rounded,
      action: () => _nfc.writeRecords(card.records),
      onCancel: _nfc.cancel,
      successLabel: 'Clone written',
    );
    if (bytes != null && mounted) {
      _snack('Copied $bytes bytes onto the tag.');
    }
  }

  Future<void> _delete(StoredCard card) async {
    final wallet = context.read<WalletProvider>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete card?'),
        content: Text('“${card.name}” will be permanently removed from this '
            'device. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await wallet.delete(card.id);
      if (mounted) Navigator.of(context).pop();
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final card = context.watch<WalletProvider>().byId(widget.cardId);
    if (card == null) {
      return const Scaffold(body: SizedBox.shrink());
    }
    final scheme = Theme.of(context).colorScheme;
    final revealed = !card.isProtected || _revealed;

    return Scaffold(
      appBar: AppBar(
        title: Text(card.name, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => EditCardScreen(cardId: card.id)),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          WalletCardView(
            card: card,
            heroTag: 'card_${card.id}',
            revealUid: revealed,
          ),
          const SizedBox(height: 20),
          _ActionBar(
            card: card,
            onClone: () => _clone(card),
            onToggleProtect: () => _toggleProtect(card),
            onDelete: () => _delete(card),
          ),
          const SizedBox(height: 24),
          _CloneBanner(card: card),
          if (card.notes.trim().isNotEmpty) ...[
            const SizedBox(height: 24),
            _SectionTitle('Notes'),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(card.notes),
            ),
          ],
          const SizedBox(height: 24),
          _SectionTitle('Tag details'),
          const SizedBox(height: 8),
          if (!revealed)
            _LockedPanel(onReveal: () => _reveal(card))
          else ...[
            _DetailsCard(card: card),
            if (card.records.isNotEmpty) ...[
              const SizedBox(height: 24),
              _SectionTitle('NDEF records (${card.records.length})'),
              const SizedBox(height: 8),
              for (var i = 0; i < card.records.length; i++)
                _RecordTile(index: i, record: card.records[i]),
            ],
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => RawDataScreen(card: card)),
              ),
              icon: const Icon(Icons.data_object_rounded),
              label: const Text('View raw data'),
            ),
          ],
          const SizedBox(height: 24),
          Text(
            'Added ${_formatDate(card.createdAt)}',
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12.5),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.card,
    required this.onClone,
    required this.onToggleProtect,
    required this.onDelete,
  });

  final StoredCard card;
  final VoidCallback onClone;
  final VoidCallback onToggleProtect;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: Icons.content_copy_rounded,
            label: 'Clone',
            color: scheme.primary,
            enabled: card.isCloneable,
            disabledHint: 'This tag can’t be copied',
            onTap: onClone,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionButton(
            icon: card.isProtected
                ? Icons.lock_open_rounded
                : Icons.lock_rounded,
            label: card.isProtected ? 'Unlock' : 'Secure',
            color: scheme.secondary,
            onTap: onToggleProtect,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionButton(
            icon: Icons.delete_outline_rounded,
            label: 'Delete',
            color: scheme.error,
            onTap: onDelete,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.enabled = true,
    this.disabledHint,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool enabled;
  final String? disabledHint;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = enabled ? color : scheme.onSurfaceVariant.withValues(alpha: 0.5);
    return Tooltip(
      message: enabled ? '' : (disabledHint ?? ''),
      triggerMode:
          enabled ? TooltipTriggerMode.manual : TooltipTriggerMode.tap,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: enabled
            ? onTap
            : () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(disabledHint ?? 'Unavailable')),
                ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: c.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(icon, color: c),
              const SizedBox(height: 6),
              Text(label,
                  style:
                      TextStyle(color: c, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CloneBanner extends StatelessWidget {
  const _CloneBanner({required this.card});
  final StoredCard card;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cloneable = card.isCloneable;
    final color = cloneable ? const Color(0xFF27AE60) : scheme.tertiary;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(cloneable ? Icons.verified_rounded : Icons.shield_rounded,
              color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              cloneable
                  ? 'This tag’s NDEF data can be copied onto a blank writable '
                      'tag using Clone.'
                  : 'Stored for reference. Its serial number and any encrypted '
                      'data can’t be duplicated by design.',
              style: TextStyle(
                  color: scheme.onSurface, fontSize: 13, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.card});
  final StoredCard card;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final entries = <MapEntry<String, String>>[
      MapEntry('Type', card.type.label),
      if (card.techList.isNotEmpty)
        MapEntry('Technologies', card.techList.join(', ')),
      ...card.details.entries,
    ];
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            if (i > 0)
              Divider(height: 1, color: scheme.outlineVariant),
            _DetailRow(label: entries[i].key, value: entries[i].value),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: value));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$label copied')),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(label,
                  style: TextStyle(color: scheme.onSurfaceVariant)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontFeatures: [FontFeature.tabularFigures()],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordTile extends StatelessWidget {
  const _RecordTile({required this.index, required this.record});
  final int index;
  final StoredNdefRecord record;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('#${index + 1} · ${record.kindLabel}',
                    style: TextStyle(
                        color: scheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ),
              if (record.mimeType.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(record.mimeType,
                    style: TextStyle(
                        color: scheme.onSurfaceVariant, fontSize: 12)),
              ],
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            record.preview.isEmpty ? '(empty)' : record.preview,
            style: const TextStyle(
                fontFamily: 'monospace', fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _LockedPanel extends StatelessWidget {
  const _LockedPanel({required this.onReveal});
  final VoidCallback onReveal;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(Icons.lock_rounded, color: scheme.onSurfaceVariant, size: 34),
          const SizedBox(height: 12),
          Text('This card is protected',
              style: TextStyle(
                  color: scheme.onSurface, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Authenticate to reveal its details.',
              style: TextStyle(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onReveal,
            icon: const Icon(Icons.fingerprint_rounded),
            label: const Text('Reveal'),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}
