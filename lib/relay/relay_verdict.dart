/// Verdict returned by the backend config endpoint.
///
/// The contract is intentionally minimal:
///   `ok`      — bool, granted or declined
///   `url`     — string?, content to load when granted
///   `expires` — int?, unix timestamp after which the URL must be refreshed
///   `message` — string?, optional human-readable note
class RelayVerdict {
  final bool granted;
  final String? destination;
  final int? expiresAt;
  final String? note;

  const RelayVerdict({
    required this.granted,
    this.destination,
    this.expiresAt,
    this.note,
  });

  factory RelayVerdict.fromMap(Map<String, dynamic> map) {
    return RelayVerdict(
      granted: map['ok'] == true,
      destination: map['url'] as String?,
      expiresAt: (map['expires'] is int) ? map['expires'] as int : null,
      note: map['message'] as String?,
    );
  }

  factory RelayVerdict.declined(String reason) =>
      RelayVerdict(granted: false, note: reason);
}
