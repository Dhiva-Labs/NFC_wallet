import 'card_type.dart';
import 'ndef_record_data.dart';

/// The result of a single tag scan, before the user names/saves it.
class NfcCapture {
  NfcCapture({
    required this.uid,
    required this.techList,
    required this.isNdef,
    required this.isWritable,
    required this.maxSize,
    required this.records,
    required this.details,
    required this.rawJson,
  });

  /// Tag serial number as an upper-case hex string (e.g. `04:A2:1B:…`).
  final String? uid;

  /// Friendly technology names present on the tag (e.g. `NDEF`, `MIFARE Ultralight`).
  final List<String> techList;

  final bool isNdef;
  final bool isWritable;
  final int? maxSize;

  final List<StoredNdefRecord> records;

  /// Structured, display-ready facts about the tag (ATQA, SAK, size, …).
  final Map<String, String> details;

  /// Pretty-printed dump of the raw platform payload, for the inspector.
  final String rawJson;

  bool get hasNdefContent => records.any((r) => r.payload.isNotEmpty);

  /// Whether this tag looks copyable to a blank NDEF tag.
  bool get isCloneableHint => isNdef && hasNdefContent;

  /// Best-effort guess of the card type from the tag technologies, used to
  /// pre-select a type on the save screen.
  CardType get guessedType {
    final t = techList.map((e) => e.toLowerCase()).join(' ');
    if (t.contains('felica') || t.contains('iso 15693')) {
      return CardType.transit;
    }
    if (t.contains('isodep') || t.contains('iso-dep') || t.contains('iso7816')) {
      return CardType.payment;
    }
    if (t.contains('ultralight') || t.contains('classic')) {
      return CardType.key;
    }
    return CardType.card;
  }
}
