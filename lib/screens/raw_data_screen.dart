import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/stored_card.dart';

/// Read-only inspector for the raw platform payload captured from a tag.
class RawDataScreen extends StatelessWidget {
  const RawDataScreen({super.key, required this.card});

  final StoredCard card;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = card.rawJson.isEmpty ? '{ }' : card.rawJson;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Raw data'),
        actions: [
          IconButton(
            tooltip: 'Copy',
            icon: const Icon(Icons.copy_rounded),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: text));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Raw data copied')),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Exactly what the phone reported for this tag. Handy for debugging '
            'or verifying a clone.',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
            ),
            child: SelectableText(
              text,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12.5,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
