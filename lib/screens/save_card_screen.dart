import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/card_type.dart';
import '../models/nfc_capture.dart';
import '../models/stored_card.dart';
import '../providers/wallet_provider.dart';
import '../widgets/editor_fields.dart';
import '../widgets/wallet_card_view.dart';

/// Names and categorises a freshly scanned tag before saving it.
class SaveCardScreen extends StatefulWidget {
  const SaveCardScreen({super.key, required this.capture});

  final NfcCapture capture;

  @override
  State<SaveCardScreen> createState() => _SaveCardScreenState();
}

class _SaveCardScreenState extends State<SaveCardScreen> {
  final _name = TextEditingController();
  final _notes = TextEditingController();

  late CardType _type = widget.capture.guessedType;
  late int _color = _type.defaultColor.toARGB32();
  bool _colorPinned = false;
  bool _protected = false;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _selectType(CardType type) {
    setState(() {
      _type = type;
      if (!_colorPinned) _color = type.defaultColor.toARGB32();
    });
  }

  Future<void> _save() async {
    final card = StoredCard.fromCapture(
      widget.capture,
      name: _name.text.trim(),
      type: _type,
      colorValue: _color,
      notes: _notes.text.trim(),
      isProtected: _protected,
    );
    await context.read<WalletProvider>().add(card);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('“${card.name}” saved to your wallet')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cap = widget.capture;
    final now = DateTime.now();
    final preview = StoredCard(
      id: 'preview',
      name: _name.text.trim().isEmpty ? 'New card' : _name.text.trim(),
      type: _type,
      colorValue: _color,
      uid: cap.uid,
      techList: cap.techList,
      isNdef: cap.isNdef,
      sourceWritable: cap.isWritable,
      maxSize: cap.maxSize,
      records: cap.records,
      details: cap.details,
      rawJson: cap.rawJson,
      notes: '',
      isProtected: _protected,
      createdAt: now,
      updatedAt: now,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Save card')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          WalletCardView(card: preview),
          const SizedBox(height: 20),
          _ScanSummary(capture: cap),
          const SizedBox(height: 24),
          _label(context, 'Name'),
          const SizedBox(height: 8),
          TextField(
            controller: _name,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'e.g. Office door, Metro pass, Car key',
            ),
          ),
          const SizedBox(height: 24),
          _label(context, 'Type'),
          const SizedBox(height: 12),
          TypeTilePicker(selected: _type, onChanged: _selectType),
          const SizedBox(height: 24),
          _label(context, 'Colour'),
          const SizedBox(height: 12),
          ColorSwatchRow(
            selected: _color,
            onChanged: (c) => setState(() {
              _color = c;
              _colorPinned = true;
            }),
          ),
          const SizedBox(height: 24),
          _label(context, 'Notes (optional)'),
          const SizedBox(height: 8),
          TextField(
            controller: _notes,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Anything you want to remember about this card',
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile.adaptive(
            value: _protected,
            onChanged: (v) => setState(() => _protected = v),
            contentPadding: EdgeInsets.zero,
            title: const Text('Protect this card'),
            subtitle: Text(
              'Require fingerprint / PIN to reveal its data',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            secondary: Icon(Icons.lock_rounded, color: scheme.primary),
          ),
        ],
      ),
      bottomSheet: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        padding: EdgeInsets.fromLTRB(
            16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
        child: FilledButton.icon(
          onPressed: _name.text.trim().isEmpty ? null : _save,
          icon: const Icon(Icons.check_rounded),
          label: const Text('Save to wallet'),
        ),
      ),
    );
  }

  Widget _label(BuildContext context, String text) => Text(
        text,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(fontWeight: FontWeight.w700),
      );
}

class _ScanSummary extends StatelessWidget {
  const _ScanSummary({required this.capture});
  final NfcCapture capture;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            capture.isCloneableHint
                ? Icons.check_circle_rounded
                : Icons.info_rounded,
            color:
                capture.isCloneableHint ? const Color(0xFF27AE60) : scheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  capture.techList.isEmpty
                      ? 'Tag read'
                      : capture.techList.join(' · '),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  capture.isCloneableHint
                      ? 'Has NDEF data — can be copied to a blank tag.'
                      : 'Stored for reference. Secure/encrypted tags can’t be copied.',
                  style: TextStyle(
                      color: scheme.onSurfaceVariant, fontSize: 12.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

