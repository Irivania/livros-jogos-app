import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../core/errors/failure.dart';
import '../domain/story_models.dart';
import '../domain/story_repository.dart';
import '../../stories/data/story_validator.dart';

final class StoryAssetRepository implements StoryRepository {
  const StoryAssetRepository();

  @override
  Future<Story> load(String storyId) async {
    final manifestPath = _manifestPath(storyId);
    return _loadManifest(manifestPath);
  }

  Future<Story> loadAssetPath(String assetPath) {
    return _loadManifest(assetPath);
  }

  Future<Story> _loadManifest(String manifestPath) async {
    try {
      final rawInfo = await rootBundle.loadString(manifestPath);
      final decodedInfo = _decode(rawInfo, manifestPath);
      final infoJson = _object(decodedInfo, 'manifest', manifestPath);

      final chapterFiles = infoJson['chapterFiles'];

      if (chapterFiles == null) {
        return _validatedStory(_parseSingleFile(infoJson, manifestPath));
      }
      if (chapterFiles is! List) {
        _warn(manifestPath, 'chapterFiles',
            'esperado como lista; usando manifesto único');
        return _validatedStory(_parseSingleFile(infoJson, manifestPath));
      }
      if (chapterFiles.isEmpty) {
        return _validatedStory(_parseSingleFile(infoJson, manifestPath));
      }

      final mergedNodes = <String, dynamic>{};
      final mergedEndings = <String, dynamic>{};

      for (var index = 0; index < chapterFiles.length; index++) {
        final fileName = chapterFiles[index];
        if (fileName is! String || fileName.trim().isEmpty) {
          _warn(manifestPath, 'chapterFiles[$index]',
              'nulo ou nome inválido; item ignorado');
          continue;
        }
        final chapterPath = _chapterPath(manifestPath, fileName);
        try {
          final rawChapter = await rootBundle.loadString(chapterPath);
          final chapterJson = _object(
            _decode(rawChapter, chapterPath),
            'chapter',
            chapterPath,
          );
          _mergeMap(mergedNodes, chapterJson['nodes'], chapterPath, 'nodes');
          _mergeMap(
              mergedEndings, chapterJson['endings'], chapterPath, 'endings');
        } on Failure catch (error) {
          _warn(chapterPath, 'chapter', error.message);
        } on Object catch (error) {
          _warn(chapterPath, 'chapter', error);
        }

      }

      final unifiedJson = Map<String, dynamic>.from(infoJson)
        ..['nodes'] = mergedNodes
        ..['endings'] = mergedEndings;
      return _validatedStory(_parseSingleFile(unifiedJson, manifestPath));
    } on Failure {
      rethrow;
    } on Object catch (error) {
      throw DataFailure(
        'Não foi possível carregar "$manifestPath". Detalhe: $error',
      );
    }
  }

  String _manifestPath(String storyId) {
    if (storyId.startsWith('assets/')) return storyId;
    return 'assets/stories/$storyId/story.json';
  }

  String _chapterPath(String manifestPath, String fileName) {
    final separator = manifestPath.lastIndexOf('/');
    if (separator < 0) return fileName;
    return '${manifestPath.substring(0, separator + 1)}$fileName';
  }

  Story _validatedStory(Story story) {
    StoryValidator.validate(story);
    return story;
  }

  Object? _decode(String raw, String source) {
    try {
      return jsonDecode(raw);
    } on FormatException catch (error) {
      _warn(source, '<json>', 'JSON inválido: $error');
      throw DataFailure('JSON inválido em "$source".');
    }
  }

  void _mergeMap(
    Map<String, dynamic> target,
    Object? value,
    String source,
    String field,
  ) {
    final map = _map(value, field, source);
    target.addAll(map);
  }

  Story _parseSingleFile(Map<String, dynamic> json, String source) {
    final nodesJson = _map(json['nodes'], 'nodes', source);
    final endingsJson = _map(json['endings'], 'endings', source);
    final nodes = <String, StoryNode>{};
    final endings = <String, StoryEnding>{};

    nodesJson.forEach((id, value) {
      final node = _parseNode(id, value, source);
      if (node != null) nodes[id] = node;
    });
    endingsJson.forEach((id, value) {
      final ending = _parseEnding(id, value, source);
      if (ending != null) endings[id] = ending;
    });

    return Story(
      id: _string(json, 'id', source),
      version: _positiveInt(json, 'version', source),
      title: _string(json, 'title', source),
      synopsis: _string(json, 'synopsis', source),
      cover: _string(json, 'cover', source),
      category: _string(json, 'category', source),
      startNodeId: _string(json, 'startNodeId', source),
      nodes: nodes,
      endings: endings,
    );
  }

  StoryNode? _parseNode(String id, Object? value, String source) {
    final json = _object(value, 'nodes["$id"]', source);
    if (json.isEmpty) return null;
    final choices = json['choices'];
    if (choices is! List) {
      _warn(source, 'nodes["$id"].choices',
          'nulo ou formato inválido; nó ignorado');
      return null;
    }
    final parsedChoices = <StoryChoice>[];
    for (var index = 0; index < choices.length; index++) {
      final choice =
          _parseChoice(choices[index], 'nodes["$id"].choices[$index]', source);
      if (choice != null) parsedChoices.add(choice);
    }
    if (parsedChoices.isEmpty) {
      _warn(source, 'nodes["$id"].choices',
          'nenhuma escolha válida; nó ignorado');
      return null;
    }
    return StoryNode(
      id: _string(json, 'id', source, fallback: id),
      text: _string(json, 'text', source),
      image: _nullableString(json['image'], source, 'nodes["$id"].image'),
      choices: parsedChoices,
    );
  }

  StoryChoice? _parseChoice(Object? value, String field, String source) {
    final json = _object(value, field, source);
    if (json.isEmpty) return null;
    final id = _string(json, 'id', source);
    final label = _string(json, 'label', source);
    if (id.isEmpty || label.isEmpty) return null;

    return StoryChoice(
      id: id,
      label: label,
      nextNodeId:
          _nullableString(json['nextNodeId'], source, '$field.nextNodeId'),
      endingId: _nullableString(json['endingId'], source, '$field.endingId'),
      requires: _stringSet(json['requires'], '$field.requires', source),
      addEvidence:
          _stringSet(json['addEvidence'], '$field.addEvidence', source),
      removeEvidence:
          _stringSet(json['removeEvidence'], '$field.removeEvidence', source),
      keyCost: _nonNegativeInt(json, 'keyCost', source),
      statChanges: _intMap(json['statChanges'], '$field.statChanges', source),
      requiredStats:
          _intMap(json['requiredStats'], '$field.requiredStats', source),
    );
  }

  StoryEnding? _parseEnding(String id, Object? value, String source) {
    final json = _object(value, 'endings["$id"]', source);
    if (json.isEmpty) return null;
    return StoryEnding(
      id: _string(json, 'id', source, fallback: id),
      title: _string(json, 'title', source),
      text: _string(json, 'text', source),
      requiredEvidence: _stringSet(
        json['requiredEvidence'],
        'endings["$id"].requiredEvidence',
        source,
      ),
    );
  }

  Map<String, dynamic> _map(Object? value, String field, String source) {
    return _object(value, field, source);
  }

  Map<String, dynamic> _object(Object? value, String field, String source) {
    if (value == null) {
      _warn(source, field, 'valor nulo ou ausente; usando mapa vazio');
      return <String, dynamic>{};
    }
    if (value is! Map) {
      _warn(source, field, 'esperado como objeto; usando mapa vazio');
      return <String, dynamic>{};
    }
    final result = <String, dynamic>{};
    value.forEach((key, item) {
      if (key is String) {
        result[key] = item;
      } else {
        _warn(source, '$field[$key]', 'chave não textual; item ignorado');
      }
    });
    return result;
  }

  String _string(
    Map<String, dynamic> json,
    String field,
    String source, {
    String? fallback,
  }) {
    final value = json[field];
    if (value is String && value.isNotEmpty) return value;
    _warn(source, field, 'nulo, ausente ou inválido');
    if (fallback != null && fallback.isNotEmpty) return fallback;
    throw DataFailure('Campo "$field" inválido em "$source".');
  }

  String? _nullableString(Object? value, String source, String field) {
    if (value == null) return null;
    if (value is String) return value;
    _warn(source, field, 'esperado como texto ou null; usando null');
    return null;
  }

  Set<String> _stringSet(Object? value, String field, String source) {
    if (value == null) {
      _warn(source, field, 'nulo ou ausente; usando lista vazia');
      return {};
    }
    if (value is! List) {
      _warn(source, field, 'esperado como lista; usando lista vazia');
      return {};
    }
    final result = <String>{};
    for (var index = 0; index < value.length; index++) {
      final item = value[index];
      if (item is String) {
        result.add(item);
      } else {
        _warn(source, '$field[$index]', 'item não textual; item ignorado');
      }
    }
    return result;
  }

  Map<String, int> _intMap(Object? value, String field, String source) {
    if (value == null) return {};
    if (value is! Map) {
      _warn(source, field, 'esperado como objeto; usando mapa vazio');
      return {};
    }
    final result = <String, int>{};
    value.forEach((key, item) {
      final parsed = item is int ? item : int.tryParse('$item');
      if (key is String && parsed != null) {
        result[key] = parsed;
      } else {
        _warn(source, '$field[$key]', 'chave ou valor inválido; item ignorado');
      }
    });
    return result;
  }

  int _positiveInt(Map<String, dynamic> json, String field, String source) {
    final value = _nonNegativeInt(json, field, source);
    if (value == 0) {
      throw DataFailure('Campo "$field" deve ser positivo em "$source".');
    }
    return value;
  }

  int _nonNegativeInt(
    Map<String, dynamic> json,
    String field,
    String source,
  ) {
    final value = json[field];
    if (value == null) return 0;
    if (value is int && value >= 0) return value;
    _warn(source, field, 'inteiro não negativo esperado; usando 0');
    return 0;
  }

  void _warn(String source, String field, Object detail) {
    debugPrint('StoryAssetRepository [$source] campo "$field": $detail');
  }
}
