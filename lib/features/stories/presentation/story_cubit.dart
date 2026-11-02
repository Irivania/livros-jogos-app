import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../story_engine/domain/story_models.dart';
import '../../story_engine/domain/story_repository.dart';

// --- SERVIÇO DE PERSISTÊNCIA LOCAL ---
class StoryLocalStorage {
  static const String _keyPrefix = 'story_progress_';

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

  Future<Map<String, dynamic>?> loadProgress(String storyId) async {
    final prefs = await SharedPreferences.getInstance();
    final rawData = prefs.getString('$_keyPrefix$storyId');
    if (rawData == null) return null;

    try {
      final decoded = jsonDecode(rawData);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {}
    return null;
  }

  Future<void> clearProgress(String storyId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_keyPrefix$storyId');
  }
}

// --- ESTADO DO JOGO ---
class StoryState {
  final Story? story;
  final String? currentNodeId;
  final String? currentEndingId;
  final int trust;
  final int heat;
  final Set<String> evidenceInventory;
  final List<StoryStateSnapshot> history;
  final bool isLoading;
  final String? errorMessage;

  const StoryState({
    this.story,
    this.currentNodeId,
    this.currentEndingId,
    this.trust = 50,
    this.heat = 0,
    this.evidenceInventory = const {},
    this.history = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  StoryState copyWith({
    Story? story,
    String? currentNodeId,
    String? currentEndingId,
    int? trust,
    int? heat,
    Set<String>? evidenceInventory,
    List<StoryStateSnapshot>? history,
    bool? isLoading,
    String? errorMessage,
  }) {
    return StoryState(
      story: story ?? this.story,
      currentNodeId: currentNodeId ?? this.currentNodeId,
      currentEndingId: currentEndingId ?? this.currentEndingId,
      trust: trust ?? this.trust,
      heat: heat ?? this.heat,
      evidenceInventory: evidenceInventory ?? this.evidenceInventory,
      history: history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// Snapshot para o histórico (permite a funcionalidade de Desfazer)
class StoryStateSnapshot {
  final String nodeId;
  final int trust;
  final int heat;
  final Set<String> evidenceInventory;

  const StoryStateSnapshot({
    required this.nodeId,
    required this.trust,
    required this.heat,
    required this.evidenceInventory,
  });
}

// --- CUBIT DE CONTROLO ---
class StoryCubit extends Cubit<StoryState> {
  final StoryRepository repository;
  final StoryLocalStorage localStorage;

  StoryCubit(this.repository, {StoryLocalStorage? localStorage})
      : localStorage = localStorage ?? StoryLocalStorage(),
        super(const StoryState());

  Future<void> loadStory(String storyId) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final story = await repository.load(storyId);

      // Tenta carregar o progresso salvo anteriormente no dispositivo
      final savedProgress = await localStorage.loadProgress(storyId);

      if (savedProgress != null) {
        emit(state.copyWith(
          story: story,
          currentNodeId:
              savedProgress['currentNodeId'] as String? ?? story.startNodeId,
          trust: savedProgress['trust'] as int? ?? 50,
          heat: savedProgress['heat'] as int? ?? 0,
          evidenceInventory:
              Set<String>.from(savedProgress['evidenceInventory'] ?? []),
          isLoading: false,
          history: [],
        ));
      } else {
        emit(state.copyWith(
          story: story,
          currentNodeId: story.startNodeId,
          isLoading: false,
          trust: 50,
          heat: 0,
          evidenceInventory: {},
          history: [],
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Erro ao carregar a história: $e',
      ));
    }
  }

  /// Executa uma escolha selecionada pelo utilizador
  void makeChoice(StoryChoice choice) {
    final story = state.story;
    if (story == null) return;

    // 1. Valida se cumpre os requisitos de atributos (requiredStats)
    for (var entry in choice.requiredStats.entries) {
      final statName = entry.key;
      final requiredValue = entry.value;

      if (statName == 'trust' && state.trust < requiredValue) return;
      if (statName == 'heat' && state.heat < requiredValue) return;
    }

    // 2. Guarda um snapshot atual no histórico antes de alterar o estado (para o Undo)
    final currentSnapshot = StoryStateSnapshot(
      nodeId: state.currentNodeId ?? story.startNodeId,
      trust: state.trust,
      heat: state.heat,
      evidenceInventory: Set.from(state.evidenceInventory),
    );
    final newHistory = List<StoryStateSnapshot>.from(state.history)
      ..add(currentSnapshot);

    // 3. Processa alterações de atributos (statChanges)
    int newTrust = state.trust;
    int newHeat = state.heat;

    choice.statChanges.forEach((stat, delta) {
      if (stat == 'trust') {
        newTrust = (newTrust + delta).clamp(0, 100).toInt();
      } else if (stat == 'heat') {
        newHeat = (newHeat + delta).clamp(0, 100).toInt();
      }
    });

    // 4. Atualiza o inventário de evidências (addEvidence / removeEvidence)
    final newEvidence = Set<String>.from(state.evidenceInventory)
      ..addAll(choice.addEvidence)
      ..removeAll(choice.removeEvidence);

    // 5. Verifica se a escolha leva a um final (endingId) ou a um próximo nó (nextNodeId)
    if (choice.endingId != null) {
      emit(state.copyWith(
        currentEndingId: choice.endingId,
        trust: newTrust,
        heat: newHeat,
        evidenceInventory: newEvidence,
        history: newHistory,
      ));
    } else if (choice.nextNodeId != null) {
      emit(state.copyWith(
        currentNodeId: choice.nextNodeId,
        trust: newTrust,
        heat: newHeat,
        evidenceInventory: newEvidence,
        history: newHistory,
      ));
    }

    // 6. Salva automaticamente o progresso no dispositivo
    if (state.story != null && state.currentNodeId != null) {
      localStorage.saveProgress(
        storyId: state.story!.id,
        currentNodeId: state.currentNodeId!,
        trust: newTrust,
        heat: newHeat,
        evidenceInventory: newEvidence.toList(),
      );
    }
  }

  /// Permite desfazer a última decisão (Undo)
  void undoLastChoice() {
    if (state.history.isEmpty) return;

    final lastState = state.history.last;
    final updatedHistory = List<StoryStateSnapshot>.from(state.history)
      ..removeLast();

    emit(state.copyWith(
      currentNodeId: lastState.nodeId,
      currentEndingId: null,
      trust: lastState.trust,
      heat: lastState.heat,
      evidenceInventory: lastState.evidenceInventory,
      history: updatedHistory,
    ));

    // Atualiza a persistência local após o Undo
    if (state.story != null && state.currentNodeId != null) {
      localStorage.saveProgress(
        storyId: state.story!.id,
        currentNodeId: lastState.nodeId,
        trust: lastState.trust,
        heat: lastState.heat,
        evidenceInventory: lastState.evidenceInventory.toList(),
      );
    }
  }

  /// Reinicia a história limpando os dados salvos
  Future<void> restartStory() async {
    final story = state.story;
    if (story == null) return;

    await localStorage.clearProgress(story.id);

    emit(state.copyWith(
      currentNodeId: story.startNodeId,
      currentEndingId: null,
      trust: 50,
      heat: 0,
      evidenceInventory: {},
      history: [],
    ));
  }
}
