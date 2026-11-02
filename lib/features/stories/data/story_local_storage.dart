import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StoryLocalStorage {
  static const String _keyPrefix = 'story_progress_';

  /// Guarda o estado atual da história
  Future<void> saveProgress({
    required String storyId,
    required String currentNodeId,
    required int trust,
    required int heat,
    required List<String> evidenceInventory,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'currentNodeId': currentNodeId,
      'trust': trust,
      'heat': heat,
      'evidenceInventory': evidenceInventory,
      'savedAt': DateTime.now().toIso8601String(),
    };
    await prefs.setString('$_keyPrefix$storyId', jsonEncode(data));
  }

  /// Recupera o progresso salvo de uma história
  Future<Map<String, dynamic>?> loadProgress(String storyId) async {
    final prefs = await SharedPreferences.getInstance();
    final rawData = prefs.getString('$_keyPrefix$storyId');
    if (rawData == null) return null;

    try {
      final decoded = jsonDecode(rawData);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      // Ignora dados corrompidos
    }
    return null;
  }

  /// Apaga o progresso salvo (útil ao reiniciar a história)
  Future<void> clearProgress(String storyId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_keyPrefix$storyId');
  }
}
