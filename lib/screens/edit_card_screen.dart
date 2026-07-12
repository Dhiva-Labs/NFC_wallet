import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/card_type.dart';
import '../providers/wallet_provider.dart';
import '../widgets/editor_fields.dart';
import '../widgets/wallet_card_view.dart';

/// Edit an existing card's name, type, colour and notes.
class EditCardScreen extends StatefulWidget {
  const EditCardScreen({super.key, required this.cardId});

  final String cardId;

  @override
  State<EditCardScreen> createState() => _EditCardScreenState();
}

class _EditCardScreenState extends State<EditCardScreen> {
  late final TextEditingController _name;
  late final TextEditingController _notes;
  late CardType _type;
  late int _color;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    final card = context.read<WalletProvider>().byId(widget.cardId);
    _name = TextEditingController(text: card?.name ?? '');
    _notes = TextEditingController(text: card?.notes ?? '');
    _type = card?.type ?? CardType.card;
    _color = card?.colorValue ?? CardType.card.defaultColor.toARGB32();
    _ready = card != null;
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final wallet = context.read<WalletProvider>();
    final card = wallet.byId(widget.cardId);
    if (card == null) return;
    await wallet.update(card.copyWith(
      name: _name.text.trim(),
      type: _type,
      colorValue: _color,
      notes: _notes.text.trim(),
    ));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(body: SizedBox.shrink());
    }
    final card = context.watch<WalletProvider>().byId(widget.cardId);
    if (card == null) {
      return const Scaffold(body: SizedBox.shrink());
    }
    final preview = card.copyWith(
      name: _name.text.trim().isEmpty ? 'Card' : _name.text.trim(),
      type: _type,
      colorValue: _color,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Edit card')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          WalletCardView(card: preview),
          const SizedBox(height: 24),
          _label(context, 'Name'),
          const SizedBox(height: 8),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(hintText: 'Card name'),
          ),
          const SizedBox(height: 24),
          _label(context, 'Type'),
          const SizedBox(height: 12),
          TypeTilePicker(
            selected: _type,
            onChanged: (t) => setState(() => _type = t),
          ),
          const SizedBox(height: 24),
          _label(context, 'Colour'),
          const SizedBox(height: 12),
          ColorSwatchRow(
            selected: _color,
            onChanged: (c) => setState(() => _color = c),
          ),
          const SizedBox(height: 24),
          _label(context, 'Notes'),
          const SizedBox(height: 8),
          TextField(
            controller: _notes,
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'Notes'),
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
          label: const Text('Save changes'),
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
