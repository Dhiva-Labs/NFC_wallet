import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/platform_tags.dart';

import '../models/nfc_capture.dart';
import '../models/ndef_record_data.dart';

/// Raised when a clone/write can't be completed.
class NfcWriteException implements Exception {
  const NfcWriteException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Thin wrapper around `nfc_manager` that turns callback-based sessions into
/// awaitable futures and maps raw platform data into our own models.
class NfcService {
  /// Whether NFC hardware is present and enabled.
  Future<bool> isAvailable() => NfcManager.instance.isAvailable();

  /// Read the next tag presented to the device.
  Future<NfcCapture> scan() {
    final completer = Completer<NfcCapture>();
    NfcManager.instance.startSession(
      alertMessage: 'Hold your device near the card',
      onDiscovered: (NfcTag tag) async {
        try {
          final capture = _parse(tag);
          await NfcManager.instance.stopSession();
          if (!completer.isCompleted) completer.complete(capture);
        } catch (e) {
          await NfcManager.instance.stopSession(errorMessage: 'Read failed');
          if (!completer.isCompleted) completer.completeError(e);
        }
      },
      onError: (e) async {
        if (!completer.isCompleted) completer.completeError(e);
      },
    );
    return completer.future;
  }

  /// Write [records] onto the next writable NDEF tag. Returns bytes written.
  Future<int> writeRecords(List<StoredNdefRecord> records) {
    final completer = Completer<int>();
    if (records.isEmpty) {
      return Future.error(
          const NfcWriteException('There is no NDEF data to clone.'));
    }
    NfcManager.instance.startSession(
      alertMessage: 'Hold near a blank writable tag',
      onDiscovered: (NfcTag tag) async {
        try {
          final ndef = Ndef.from(tag);
          if (ndef == null) {
            throw const NfcWriteException(
                'This tag does not support NDEF and cannot be written.');
          }
          if (!ndef.isWritable) {
            throw const NfcWriteException('This tag is locked / read-only.');
          }
          final message =
              NdefMessage(records.map((r) => r.toNdefRecord()).toList());
          if (message.byteLength > ndef.maxSize) {
            throw NfcWriteException(
                'Data (${message.byteLength} B) is larger than this tag’s '
                'capacity (${ndef.maxSize} B).');
          }
          await ndef.write(message);
          await NfcManager.instance.stopSession();
          if (!completer.isCompleted) completer.complete(message.byteLength);
        } catch (e) {
          await NfcManager.instance.stopSession(errorMessage: 'Write failed');
          if (!completer.isCompleted) {
            completer.completeError(
                e is NfcWriteException ? e : NfcWriteException(e.toString()));
          }
        }
      },
      onError: (e) async {
        if (!completer.isCompleted) completer.completeError(e);
      },
    );
    return completer.future;
  }

  /// Cancel any in-flight session (e.g. user backed out of the scan sheet).
  Future<void> cancel() async {
    try {
      await NfcManager.instance.stopSession();
    } catch (_) {
      // no active session
    }
  }

  // --- Parsing -----------------------------------------------------------

  NfcCapture _parse(NfcTag tag) {
    final data = tag.data;

    final uidBytes = _identifierOf(tag);
    final uid = uidBytes == null || uidBytes.isEmpty ? null : _hex(uidBytes);

    final techList = data.keys.map(_friendlyTech).toList()..sort();

    bool isNdef = false;
    bool isWritable = false;
    int? maxSize;
    final records = <StoredNdefRecord>[];
    final ndef = Ndef.from(tag);
    if (ndef != null) {
      isNdef = true;
      isWritable = ndef.isWritable;
      maxSize = ndef.maxSize;
      final msg = ndef.cachedMessage;
      if (msg != null) {
        for (final r in msg.records) {
          records.add(StoredNdefRecord.fromNdefRecord(r));
        }
      }
    }

    final details = <String, String>{};
    if (uid != null) details['Serial (UID)'] = uid;

    final nfca = NfcA.from(tag);
    if (nfca != null) {
      if (nfca.atqa.isNotEmpty) details['ATQA'] = _hex(nfca.atqa);
      details['SAK'] =
          '0x${nfca.sak.toRadixString(16).padLeft(2, '0').toUpperCase()}';
    }
    final mul = MifareUltralight.from(tag);
    if (mul != null) details['Ultralight type'] = _ultralightType(mul.type);
    final mc = MifareClassic.from(tag);
    if (mc != null) {
      details['Classic type'] = _classicType(mc.type);
      details['Memory'] = '${mc.size} B';
      details['Sectors / blocks'] = '${mc.sectorCount} / ${mc.blockCount}';
    }
    final nfcf = NfcF.from(tag);
    if (nfcf != null && nfcf.systemCode.isNotEmpty) {
      details['System code'] = _hex(nfcf.systemCode);
    }
    final nfcb = NfcB.from(tag);
    if (nfcb != null && nfcb.applicationData.isNotEmpty) {
      details['App data'] = _hex(nfcb.applicationData);
    }
    final iso = IsoDep.from(tag);
    if (iso != null &&
        iso.historicalBytes != null &&
        iso.historicalBytes!.isNotEmpty) {
      details['Historical bytes'] = _hex(iso.historicalBytes!);
    }
    if (isNdef) {
      details['NDEF'] = isWritable ? 'Writable' : 'Read-only';
      if (maxSize != null) details['Capacity'] = '$maxSize B';
      details['Records'] = '${records.length}';
    }

    return NfcCapture(
      uid: uid,
      techList: techList,
      isNdef: isNdef,
      isWritable: isWritable,
      maxSize: maxSize,
      records: records,
      details: details,
      rawJson: _prettyRaw(data),
    );
  }

  Uint8List? _identifierOf(NfcTag tag) {
    Uint8List? pick(Uint8List? id) => (id != null && id.isNotEmpty) ? id : null;
    return pick(NfcA.from(tag)?.identifier) ??
        pick(NfcB.from(tag)?.identifier) ??
        pick(NfcF.from(tag)?.identifier) ??
        pick(NfcV.from(tag)?.identifier) ??
        pick(MifareUltralight.from(tag)?.identifier) ??
        pick(MifareClassic.from(tag)?.identifier) ??
        pick(IsoDep.from(tag)?.identifier);
  }

  String _friendlyTech(String key) {
    switch (key.toLowerCase()) {
      case 'nfca':
        return 'NFC-A';
      case 'nfcb':
        return 'NFC-B';
      case 'nfcf':
        return 'NFC-F (FeliCa)';
      case 'nfcv':
        return 'NFC-V (ISO 15693)';
      case 'isodep':
        return 'ISO-DEP';
      case 'ndef':
        return 'NDEF';
      case 'ndefformatable':
        return 'NDEF Formatable';
      case 'mifareclassic':
        return 'MIFARE Classic';
      case 'mifareultralight':
        return 'MIFARE Ultralight';
      default:
        return key.isEmpty
            ? key
            : key[0].toUpperCase() + key.substring(1);
    }
  }

  String _ultralightType(int t) => switch (t) {
        1 => 'Ultralight',
        2 => 'Ultralight C',
        _ => 'Unknown',
      };

  String _classicType(int t) => switch (t) {
        0 => 'Classic',
        1 => 'Plus',
        2 => 'Pro',
        _ => 'Unknown',
      };

  String _hex(Uint8List b) => b
      .map((e) => e.toRadixString(16).padLeft(2, '0'))
      .join(':')
      .toUpperCase();

  String _prettyRaw(Map<String, dynamic> data) {
    try {
      return JsonEncoder.withIndent('  ', (o) => o.toString()).convert(data);
    } catch (_) {
      return data.toString();
    }
  }
}
