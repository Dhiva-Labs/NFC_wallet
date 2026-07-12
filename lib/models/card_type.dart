import 'package:flutter/material.dart';

/// The kind of thing an NFC entry represents. Drives the icon, default colour
/// and copy shown throughout the UI.
enum CardType {
  card,
  key,
  access,
  transit,
  payment,
  loyalty,
  identity,
  business,
  other;

  /// Stable string used in persistence (never localise this).
  String get id => name;

  static CardType fromId(String? id) => CardType.values.firstWhere(
        (t) => t.name == id,
        orElse: () => CardType.card,
      );

  String get label => switch (this) {
        CardType.card => 'Card',
        CardType.key => 'Key / Fob',
        CardType.access => 'Access',
        CardType.transit => 'Transit',
        CardType.payment => 'Payment',
        CardType.loyalty => 'Loyalty',
        CardType.identity => 'ID / Badge',
        CardType.business => 'Business',
        CardType.other => 'Other',
      };

  String get description => switch (this) {
        CardType.card => 'A generic smart card or NFC card.',
        CardType.key => 'A key fob, door tag or car key.',
        CardType.access => 'Office / building access credential.',
        CardType.transit => 'Metro, bus or transit pass.',
        CardType.payment => 'Bank or payment card (reference only).',
        CardType.loyalty => 'Store loyalty or membership card.',
        CardType.identity => 'ID card, badge or passport tag.',
        CardType.business => 'Business card / contact tag.',
        CardType.other => 'Anything else with an NFC chip.',
      };

  IconData get icon => switch (this) {
        CardType.card => Icons.credit_card_rounded,
        CardType.key => Icons.vpn_key_rounded,
        CardType.access => Icons.meeting_room_rounded,
        CardType.transit => Icons.directions_transit_rounded,
        CardType.payment => Icons.payments_rounded,
        CardType.loyalty => Icons.loyalty_rounded,
        CardType.identity => Icons.badge_rounded,
        CardType.business => Icons.contact_page_rounded,
        CardType.other => Icons.nfc_rounded,
      };

  Color get defaultColor => switch (this) {
        CardType.card => const Color(0xFF6D5DF6),
        CardType.key => const Color(0xFFF5A623),
        CardType.access => const Color(0xFF16C79A),
        CardType.transit => const Color(0xFF2D9CDB),
        CardType.payment => const Color(0xFF27AE60),
        CardType.loyalty => const Color(0xFFEB5AA0),
        CardType.identity => const Color(0xFF9B51E0),
        CardType.business => const Color(0xFF5B7089),
        CardType.other => const Color(0xFF00B8D9),
      };
}
