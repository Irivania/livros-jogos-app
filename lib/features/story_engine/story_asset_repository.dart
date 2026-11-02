import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class StoryModel {
  final String id;
  final int version;
  final String title;
  final String synopsis;
  final String cover;
  final String category;
  final String startNodeId;
  final List<ActModel> acts; // NOVA LISTA DE ATOS
  final Map<String, SceneNode> nodes;
  final Map<String, EndingModel> endings;

  StoryModel({
    required this.id,
    required this.version,
    required this.title,
    required this.synopsis,
    required this.cover,
    required this.category,
    required this.startNodeId,
    required this.acts,
    required this.nodes,
    required this.endings,
  });

  factory StoryModel.fromJson(Map<String, dynamic> json) {
    final actsList = _mapList(json['acts'], 'acts')
        .map(ActModel.fromJson)
        .toList(growable: false);
    final nodesMap = _objectMap(json['nodes'], 'nodes').map(
      (key, value) => MapEntry(key, SceneNode.fromJson(_object(value, 'nodes.$key'))),
    );
    final endingsMap = _objectMap(json['endings'], 'endings').map(
      (key, value) => MapEntry(key, EndingModel.fromJson(_object(value, 'endings.$key'))),
    );

    return StoryModel(
      id: json['id'] ?? '',
      version: _int(json['version'], 1, 'version'),
      title: _string(json['title'], 'title'),
      synopsis: _string(json['synopsis'], 'synopsis'),
      cover: _string(json['cover'], 'cover'),
      category: _string(json['category'], 'category'),
      startNodeId: _string(json['startNodeId'], 'startNodeId'),
      acts: actsList,
      nodes: nodesMap,
      endings: endingsMap,
    );
  }
}

// NOVO MODELO PARA REPRESENTAR OS ATOS / CAPÍTULOS
class ActModel {
  final String actId;
  final String title;
  final String subtitle;
  final List<String> nodeIds; // Quais cenas pertencem a este ato

  ActModel({
    required this.actId,
    required this.title,
    required this.subtitle,
    required this.nodeIds,
  });

  factory ActModel.fromJson(Map<String, dynamic> json) {
    return ActModel(
      actId: _string(json['actId'], 'actId'),
      title: _string(json['title'], 'title'),
      subtitle: _string(json['subtitle'], 'subtitle'),
      nodeIds: _stringList(json['nodeIds'], 'nodeIds'),
    );
  }
}

class SceneNode {
  final String id;
  final String text;
  final String image;
  final List<ChoiceModel> choices;

  SceneNode({
    required this.id,
    required this.text,
    required this.image,
    required this.choices,
  });

  factory SceneNode.fromJson(Map<String, dynamic> json) {
    final choicesList = _mapList(json['choices'], 'choices')
        .map(ChoiceModel.fromJson)
        .toList(growable: false);

    return SceneNode(
      id: _string(json['id'], 'id'),
      text: _string(json['text'], 'text'),
      image: _string(json['image'], 'image'),
      choices: choicesList,
    );
  }
}

class ChoiceModel {
  final String id;
  final String label;
  final String? nextNodeId;
  final String? endingId;
  final List<String> requires;
  final List<String> addEvidence;
  final List<String> removeEvidence;
  final int keyCost;
  final Map<String, int> statChanges;
  final Map<String, int> requiredStats;

  ChoiceModel({
    required this.id,
    required this.label,
    this.nextNodeId,
    this.endingId,
    required this.requires,
    required this.addEvidence,
    required this.removeEvidence,
    required this.keyCost,
    required this.statChanges,
    required this.requiredStats,
  });

  factory ChoiceModel.fromJson(Map<String, dynamic> json) {
    return ChoiceModel(
      id: _string(json['id'], 'id'),
      label: _string(json['label'], 'label'),
      nextNodeId: _nullableString(json['nextNodeId'], 'nextNodeId'),
      endingId: _nullableString(json['endingId'], 'endingId'),
      requires: _stringList(json['requires'], 'requires'),
      addEvidence: _stringList(json['addEvidence'], 'addEvidence'),
      removeEvidence: _stringList(json['removeEvidence'], 'removeEvidence'),
      keyCost: _int(json['keyCost'], 0, 'keyCost'),
      statChanges: _intMap(json['statChanges'], 'statChanges'),
      requiredStats: _intMap(json['requiredStats'], 'requiredStats'),
    );
  }
}

class EndingModel {
  final String id;
  final String title;
  final String text;
  final List<String> requiredEvidence;

  EndingModel({
    required this.id,
    required this.title,
    required this.text,
    required this.requiredEvidence,
  });

  factory EndingModel.fromJson(Map<String, dynamic> json) {
    return EndingModel(
      id: _string(json['id'], 'id'),
      title: _string(json['title'], 'title'),
      text: _string(json['text'], 'text'),
      requiredEvidence: _stringList(json['requiredEvidence'], 'requiredEvidence'),
    );
  }
}

class StoryAssetRepository {
  Future<StoryModel> loadStory(String assetPath) async {
    try {
      final response = await rootBundle.loadString(assetPath);
      final manifest = _object(json.decode(response), assetPath);
      final chapterFiles = manifest['chapterFiles'];
      if (chapterFiles is List && chapterFiles.isNotEmpty) {
        final merged = Map<String, dynamic>.from(manifest)
          ..['nodes'] = <String, dynamic>{}
          ..['endings'] = <String, dynamic>{};
        for (var index = 0; index < chapterFiles.length; index++) {
          final fileName = chapterFiles[index];
          if (fileName is! String || fileName.isEmpty) {
            _warn(assetPath, 'chapterFiles[$index]', 'nulo ou inválido; ignorado');
            continue;
          }
          final chapterPath = _chapterPath(assetPath, fileName);
          try {
            final chapter = _object(
              json.decode(await rootBundle.loadString(chapterPath)),
              chapterPath,
            );
            _mergeObject(merged['nodes'], chapter['nodes'], chapterPath, 'nodes');
            _mergeObject(merged['endings'], chapter['endings'], chapterPath, 'endings');
          } on Object catch (error) {
            _warn(chapterPath, 'chapter', error);
          }
        }
        return StoryModel.fromJson(merged);
      }
      return StoryModel.fromJson(manifest);
    } on Object catch (error) {
      throw FormatException('História inválida em "$assetPath": $error');
    }
  }
}

Map<String, dynamic> _object(Object? value, String source) {
  if (value is! Map) {
    _warn(source, '<root>', 'nulo ou formato inválido; usando mapa vazio');
    return <String, dynamic>{};
  }
  return value.map<String, dynamic>((key, item) => MapEntry('$key', item));
}

Map<String, dynamic> _objectMap(Object? value, String field) {
  if (value is! Map) {
    _warn(field, field, 'nulo ou formato inválido; usando mapa vazio');
    return <String, dynamic>{};
  }
  return _object(value, field);
}

List<Map<String, dynamic>> _mapList(Object? value, String field) {
  if (value is! List) {
    _warn(field, field, 'nulo ou formato inválido; usando lista vazia');
    return <Map<String, dynamic>>[];
  }
  return value
      .whereType<Map>()
      .map((item) => _object(item, field))
      .toList(growable: false);
}

String _string(Object? value, String field) {
  if (value is String) return value;
  _warn(field, field, 'nulo ou inválido; usando texto vazio');
  return '';
}

String? _nullableString(Object? value, String field) {
  if (value == null || value is String) return value as String?;
  _warn(field, field, 'esperado texto ou null; usando null');
  return null;
}

List<String> _stringList(Object? value, String field) {
  if (value is! List) {
    _warn(field, field, 'nulo ou inválido; usando lista vazia');
    return <String>[];
  }
  return value.whereType<String>().toList(growable: false);
}

Map<String, int> _intMap(Object? value, String field) {
  if (value is! Map) return <String, int>{};
  final result = <String, int>{};
  value.forEach((key, item) {
    final parsed = item is int ? item : int.tryParse('$item');
    if (parsed != null) result['$key'] = parsed;
  });
  return result;
}

int _int(Object? value, int fallback, String field) {
  if (value is int) return value;
  _warn(field, field, 'nulo ou inválido; usando $fallback');
  return fallback;
}

String _chapterPath(String manifestPath, String fileName) {
  final separator = manifestPath.lastIndexOf('/');
  return '${manifestPath.substring(0, separator + 1)}$fileName';
}

void _mergeObject(Object? target, Object? value, String source, String field) {
  if (target is Map && value is Map) {
    target.addAll(_object(value, '$source.$field'));
  } else {
    _warn(source, field, 'nulo ou inválido; mapa ignorado');
  }
}

void _warn(String source, String field, Object detail) {
  debugPrint('StoryAssetRepository [$source] campo "$field": $detail');
}
