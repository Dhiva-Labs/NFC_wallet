import 'package:flutter/material.dart';

import '../models/stored_card.dart';
import '../theme/app_theme.dart';

/// The signature gradient "credit card" visual, used in the list and detail.
class WalletCardView extends StatelessWidget {
  const WalletCardView({
    super.key,
    required this.card,
    this.onTap,
    this.heroTag,
    this.revealUid = false,
  });

  final StoredCard card;
  final VoidCallback? onTap;
  final Object? heroTag;

  /// When true, shows the full UID even for protected cards (post-auth).
  final bool revealUid;

  @override
  Widget build(BuildContext context) {
    final gradient = CardPalettes.gradientFor(card.color);
    final dark = card.color.computeLuminance() < 0.55;
    final fg = dark ? Colors.white : const Color(0xFF12151C);
    final fgMuted = fg.withValues(alpha: 0.72);

    Widget content = AspectRatio(
      aspectRatio: 1.6,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          boxShadow: [
            BoxShadow(
              color: card.color.withValues(alpha: 0.35),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative shine
            Positioned(
              right: -40,
              top: -60,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: dark ? 0.08 : 0.18),
                ),
              ),
            ),
            Positioned(
              left: -30,
              bottom: -50,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.06),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(card.type.icon, color: fg, size: 20),
                      ),
                      const Spacer(),
                      if (card.isProtected)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Icon(Icons.lock_rounded,
                              color: fgMuted, size: 18),
                        ),
                      Icon(Icons.contactless_rounded, color: fgMuted, size: 22),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    card.type.label.toUpperCase(),
                    style: TextStyle(
                      color: fgMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    card.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: fg,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    revealUid ? (card.uid ?? '—') : card.maskedUid,
                    style: TextStyle(
                      color: fgMuted,
                      fontSize: 13,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (heroTag != null) {
      content = Hero(tag: heroTag!, child: content);
    }

    if (onTap == null) return content;
    return GestureDetector(onTap: onTap, child: content);
  }
}
