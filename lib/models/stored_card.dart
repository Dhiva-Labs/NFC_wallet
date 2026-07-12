import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'card_type.dart';
import 'nfc_capture.dart';
import 'ndef_record_data.dart';

const _uuid = Uuid();

/// A card/key the user has saved to their wallet.
class StoredCard {
  StoredCard({
    required this.id,
    required this.name,
    required this.type,
    required this.colorValue,
    required this.uid,
    required this.techList,
    required this.isNdef,
    required this.sourceWritable,
    required this.maxSize,
    required this.records,
    required this.details,
    required this.rawJson,
    required this.notes,
    required this.isProtected,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  String name;
  CardType type;

  /// Base colour (ARGB) the gradient is derived from.
  int colorValue;

  final String? uid;
  final List<String> techList;
  final bool isNdef;
  final bool sourceWritable;
  final int? maxSize;
  final List<StoredNdefRecord> records;
  final Map<String, String> details;
  final String rawJson;

  String notes;

  /// When true, revealing this card's data requires device authentication.
  bool isProtected;

  final DateTime createdAt;
  DateTime updatedAt;

  Color get color => Color(colorValue);

  /// Only NDEF tags carrying at least one non-empty record can be copied
  /// onto a blank tag. Everything else is stored for reference only.
  bool get isCloneable => isNdef && records.any((r) => r.payload.isNotEmpty);

  /// UID shown partially masked for protected cards.
  String get maskedUid {
    final u = uid;
    if (u == null || u.isEmpty) return '—';
    if (!isProtected) return u;
    final parts = u.split(':');
    if (parts.length <= 2) return '••';
    return '${parts.first}:••:••:${parts.last}';
  }

  factory StoredCard.fromCapture(
    NfcCapture cap, {
    required String name,
    required CardType type,
    required int colorValue,
    String notes = '',
    bool isProtected = false,
  }) {
    final now = DateTime.now();
    return StoredCard(
      id: _uuid.v4(),
      name: name,
      type: type,
      colorValue: colorValue,
      uid: cap.uid,
      techList: cap.techList,
      isNdef: cap.isNdef,
      sourceWritable: cap.isWritable,
      maxSize: cap.maxSize,
      records: cap.records,
      details: cap.details,
      rawJson: cap.rawJson,
      notes: notes,
      isProtected: isProtected,
      createdAt: now,
      updatedAt: now,
    );
  }

  StoredCard copyWith({
    String? name,
    CardType? type,
    int? colorValue,
    String? notes,
    bool? isProtected,
  }) {
    return StoredCard(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      colorValue: colorValue ?? this.colorValue,
      uid: uid,
      techList: techList,
      isNdef: isNdef,
      sourceWritable: sourceWritable,
      maxSize: maxSize,
      records: records,
      details: details,
      rawJson: rawJson,
      notes: notes ?? this.notes,
      isProtected: isProtected ?? this.isProtected,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.id,
        'color': colorValue,
        'uid': uid,
        'tech': techList,
        'isNdef': isNdef,
        'sourceWritable': sourceWritable,
        'maxSize': maxSize,
        'records': records.map((r) => r.toJson()).toList(),
        'details': details,
        'rawJson': rawJson,
        'notes': notes,
        'protected': isProtected,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory StoredCard.fromJson(Map<String, dynamic> j) => StoredCard(
        id: j['id'] as String,
        name: j['name'] as String? ?? 'Untitled',
        type: CardType.fromId(j['type'] as String?),
        colorValue: j['color'] as int? ?? CardType.card.defaultColor.toARGB32(),
        uid: j['uid'] as String?,
        techList:
            (j['tech'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        isNdef: j['isNdef'] as bool? ?? false,
        sourceWritable: j['sourceWritable'] as bool? ?? false,
        maxSize: j['maxSize'] as int?,
        records: (j['records'] as List?)
                ?.map((e) =>
                    StoredNdefRecord.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            const [],
        details: (j['details'] as Map?)?.map(
              (k, v) => MapEntry(k.toString(), v.toString()),
            ) ??
            const {},
        rawJson: j['rawJson'] as String? ?? '',
        notes: j['notes'] as String? ?? '',
        isProtected: j['protected'] as bool? ?? false,
        createdAt:
            DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
        updatedAt:
            DateTime.tryParse(j['updatedAt'] as String? ?? '') ?? DateTime.now(),
      );
}
