import 'package:flutter/material.dart';

/// Friendly empty state shown when the wallet has no cards yet.
class EmptyWallet extends StatelessWidget {
  const EmptyWallet({super.key, required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 160,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Transform.rotate(
                    angle: -0.14,
                    child: _ghostCard(scheme, 0.35),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -10),
                    child: Transform.rotate(
                      angle: 0.06,
                      child: _ghostCard(scheme, 1),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    child: Icon(Icons.contactless_rounded,
                        size: 34, color: scheme.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Your wallet is empty',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Scan a card, key or tag to add it here. '
              'Everything is stored only on this device.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.4,
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Scan a card'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(200, 52),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ghostCard(ColorScheme scheme, double opacity) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: 130,
        height: 82,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: scheme.primary, width: 2),
          color: scheme.primary.withValues(alpha: 0.06),
        ),
      ),
    );
  }
}
