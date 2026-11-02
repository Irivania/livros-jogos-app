import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../errors/failure.dart';

/// Persiste apenas um cache protegido. O backend continua sendo a autoridade
/// para moedas, compras, chaves e recompensas.
final class SecureProgressStore {
  SecureProgressStore(this._storage);

  static const _keyName = 'livros_jogos_progress_key_v1';
  static const _payloadName = 'livros_jogos_progress_payload_v1';
  final FlutterSecureStorage _storage;

  Future<void> write(Map<String, Object?> progress) async {
    final key = await _getOrCreateKey();
    final payload = utf8.encode(jsonEncode(progress));
    final mac = Hmac(sha256, key).convert(payload).bytes;
    await _storage.write(
      key: _payloadName,
      value: jsonEncode(<String, Object?>{
        'version': 1,
        'payload': base64UrlEncode(payload),
        'mac': base64UrlEncode(mac),
      }),
    );
  }

  Future<Map<String, Object?>?> read() async {
    final raw = await _storage.read(key: _payloadName);
    if (raw == null) return null;

    try {
      final envelope = jsonDecode(raw) as Map<String, dynamic>;
      if (envelope['version'] != 1) {
        throw const IntegrityFailure('Versão de progresso não suportada.');
      }
      final payload = base64Url.decode(envelope['payload'] as String);
      final receivedMac = base64Url.decode(envelope['mac'] as String);
      final expectedMac =
          Hmac(sha256, await _getOrCreateKey()).convert(payload).bytes;
      if (!_constantTimeEquals(receivedMac, expectedMac)) {
        throw const IntegrityFailure('Integridade do progresso inválida.');
      }
      return (jsonDecode(utf8.decode(payload)) as Map).cast<String, Object?>();
    } on IntegrityFailure {
      rethrow;
    } on Object {
      throw const DataFailure('Progresso local corrompido.');
    }
  }

  Future<List<int>> _getOrCreateKey() async {
    final existing = await _storage.read(key: _keyName);
    if (existing != null) return base64Url.decode(existing);
    final key = Uint8List.fromList(
      List<int>.generate(32, (_) => Random.secure().nextInt(256)),
    );
    await _storage.write(key: _keyName, value: base64UrlEncode(key));
    return key;
  }

  bool _constantTimeEquals(List<int> left, List<int> right) {
    if (left.length != right.length) return false;
    var result = 0;
    for (var index = 0; index < left.length; index++) {
      result |= left[index] ^ right[index];
    }
    return result == 0;
  }
}
