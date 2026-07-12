import 'package:flutter/material.dart';

import '../models/card_type.dart';
import '../theme/app_theme.dart';

/// A wrap of selectable type tiles, shared by the save and edit screens.
class TypeTilePicker extends StatelessWidget {
  const TypeTilePicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final CardType selected;
  final ValueChanged<CardType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final type in CardType.values)
          _TypeTile(
            type: type,
            selected: selected == type,
            onTap: () => onChanged(type),
          ),
      ],
    );
  }
}

class _TypeTile extends StatelessWidget {
  const _TypeTile({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final CardType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? type.defaultColor.withValues(alpha: 0.16)
              : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? type.defaultColor : scheme.outlineVariant,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(type.icon,
                size: 18,
                color: selected ? type.defaultColor : scheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Text(
              type.label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal row of colour swatches.
class ColorSwatchRow extends StatelessWidget {
  const ColorSwatchRow({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: CardPalettes.swatches.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final color = CardPalettes.swatches[i];
          final isSel = color.toARGB32() == selected;
          return GestureDetector(
            onTap: () => onChanged(color.toARGB32()),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient:
                    LinearGradient(colors: CardPalettes.gradientFor(color)),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSel ? Colors.white : Colors.transparent,
                  width: 3,
                ),
                boxShadow: [
                  if (isSel)
                    BoxShadow(
                      color: color.withValues(alpha: 0.5),
                      blurRadius: 10,
                    ),
                ],
              ),
              child: isSel
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 20)
                  : null,
            ),
          );
        },
      ),
    );
  }
}
