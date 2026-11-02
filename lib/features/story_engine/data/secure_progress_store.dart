import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureProgressStore {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String _keySceneId = 'saved_story_scene_id';
  static const String _keyEvidence = 'saved_story_evidence';
  static const String _keyStats = 'saved_story_stats';

  Future<void> saveProgress({
    required String sceneId,
    required List<String> evidence,
    required Map<String, int> stats,
  }) async {
    await _storage.write(key: _keySceneId, value: sceneId);
    await _storage.write(key: _keyEvidence, value: json.encode(evidence));
    await _storage.write(key: _keyStats, value: json.encode(stats));
  }

  Future<Map<String, dynamic>?> loadProgress() async {
    final String? sceneId = await _storage.read(key: _keySceneId);
    final String? evidenceJson = await _storage.read(key: _keyEvidence);
    final String? statsJson = await _storage.read(key: _keyStats);

    if (sceneId == null) return null;

    List<String> evidence = [];
    if (evidenceJson != null) {
      evidence = List<String>.from(json.decode(evidenceJson));
    }

    Map<String, int> stats = {'trust': 50, 'heat': 10};
    if (statsJson != null) {
      stats = Map<String, int>.from(json.decode(statsJson));
    }

    return <String, dynamic>{
      'sceneId': sceneId,
      'evidence': evidence,
      'stats': stats,
    };
  }

  Future<void> clearProgress() async {
    await _storage.delete(key: _keySceneId);
    await _storage.delete(key: _keyEvidence);
    await _storage.delete(key: _keyStats);
  }
}
