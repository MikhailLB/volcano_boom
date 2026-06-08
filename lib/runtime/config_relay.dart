import 'dart:convert';

import '../env/runtime_profile.dart';
import '../relay/relay_verdict.dart';
import 'vault_keeper.dart';
import 'wire_client.dart';

/// Sends the attribution body to the backend relay and interprets the verdict.
class ConfigRelay {
  final VaultKeeper _vault;

  ConfigRelay(this._vault);

  Future<RelayVerdict> ask(Map<String, dynamic> body) async {
    if (RuntimeProfile.relayEndpoint.isEmpty) {
      return RelayVerdict.declined('relay-not-set');
    }

    try {
      final res = await wire
          .post(
            Uri.parse(RuntimeProfile.relayEndpoint),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(RuntimeProfile.relayTimeout);

      if (res.statusCode != 200) {
        return RelayVerdict.declined('http-${res.statusCode}');
      }

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final verdict = RelayVerdict.fromMap(json);

      if (verdict.granted && verdict.destination != null) {
        await _vault.writePartnerUrl(verdict.destination!);
        if (verdict.expiresAt != null) {
          await _vault.writePartnerExpiry(verdict.expiresAt!);
        }
      }
      return verdict;
    } catch (e) {
      return RelayVerdict.declined(e.toString());
    }
  }

  /// Last URL we've successfully been given. Used as fallback when the
  /// relay request fails on returning launches.
  Future<String?> cachedDestination() => _vault.readPartnerUrl();
}
