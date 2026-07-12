import 'dart:convert';
import 'dart:typed_data';

import 'package:nfc_manager/nfc_manager.dart';

/// A serialisable snapshot of a single NDEF record.
///
/// Stores the four raw NDEF fields (base64-encoded) so a record can be
/// persisted and later re-written onto a blank tag verbatim ("clone").
class StoredNdefRecord {
  StoredNdefRecord({
    required this.tnf,
    required this.type,
    required this.identifier,
    required this.payload,
  });

  /// Type-Name-Format, as the index of [NdefTypeNameFormat].
  final int tnf;
  final Uint8List type;
  final Uint8List identifier;
  final Uint8List payload;

  factory StoredNdefRecord.fromNdefRecord(NdefRecord r) => StoredNdefRecord(
        tnf: r.typeNameFormat.index,
        type: r.type,
        identifier: r.identifier,
        payload: r.payload,
      );

  /// Rebuild a live [NdefRecord] for writing back to a tag.
  NdefRecord toNdefRecord() {
    final format = NdefTypeNameFormat
        .values[tnf.clamp(0, NdefTypeNameFormat.values.length - 1)];
    return NdefRecord(
      typeNameFormat: format,
      type: type,
      identifier: identifier,
      payload: payload,
    );
  }

  // --- Human-friendly decoding -------------------------------------------

  bool get _isWellKnown => tnf == NdefTypeNameFormat.nfcWellknown.index;

  bool get isText => _isWellKnown && _typeEquals(0x54); // 'T'
  bool get isUri => _isWellKnown && _typeEquals(0x55); // 'U'

  bool _typeEquals(int b) => type.length == 1 && type[0] == b;

  String get kindLabel {
    if (isText) return 'Text';
    if (isUri) return 'URI';
    switch (NdefTypeNameFormat.values[tnf]) {
      case NdefTypeNameFormat.media:
        return 'MIME';
      case NdefTypeNameFormat.absoluteUri:
        return 'Absolute URI';
      case NdefTypeNameFormat.nfcExternal:
        return 'External';
      case NdefTypeNameFormat.empty:
        return 'Empty';
      case NdefTypeNameFormat.unknown:
        return 'Unknown';
      case NdefTypeNameFormat.unchanged:
        return 'Chunk';
      case NdefTypeNameFormat.nfcWellknown:
        return 'Well-known';
    }
  }

  /// A short, readable representation of the payload for the UI.
  String get preview {
    try {
      if (isText) {
        if (payload.isEmpty) return '';
        final status = payload[0];
        final langLen = status & 0x3F;
        return utf8.decode(payload.sublist(1 + langLen), allowMalformed: true);
      }
      if (isUri) {
        if (payload.isEmpty) return '';
        final prefix = payload[0] < NdefRecord.URI_PREFIX_LIST.length
            ? NdefRecord.URI_PREFIX_LIST[payload[0]]
            : '';
        return prefix + utf8.decode(payload.sublist(1), allowMalformed: true);
      }
      if (tnf == NdefTypeNameFormat.media.index) {
        return utf8.decode(payload, allowMalformed: true);
      }
    } catch (_) {
      // fall through to hex
    }
    return _hex(payload);
  }

  String get mimeType =>
      tnf == NdefTypeNameFormat.media.index ? ascii.decode(type) : '';

  Map<String, dynamic> toJson() => {
        'tnf': tnf,
        'type': base64.encode(type),
        'id': base64.encode(identifier),
        'payload': base64.encode(payload),
      };

  factory StoredNdefRecord.fromJson(Map<String, dynamic> j) =>
      StoredNdefRecord(
        tnf: j['tnf'] as int,
        type: _decode(j['type']),
        identifier: _decode(j['id']),
        payload: _decode(j['payload']),
      );

  static Uint8List _decode(dynamic v) =>
      v == null ? Uint8List(0) : base64.decode(v as String);

  static String _hex(Uint8List b) =>
      b.map((e) => e.toRadixString(16).padLeft(2, '0')).join(' ').toUpperCase();
}
