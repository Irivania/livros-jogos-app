import '../../../core/errors/failure.dart';
import 'story_models.dart';

final class StoryEngine {
  StoryEngine(this.story, {int initialKeys = 0})
      : _state = InvestigationState(
          currentNodeId: story.startNodeId,
          visitedNodeIds: {story.startNodeId},
          evidenceIds: {},
          keys: initialKeys,
          choiceHistory: [],
        );

  final Story story;
  InvestigationState _state;
  InvestigationState get state => _state;

  StoryNode get currentNode {
    final node = story.nodes[_state.currentNodeId];
    if (node == null) throw const DataFailure('Nó de história inexistente.');
    return node;
  }

  void choose(String choiceId) {
    final choice = currentNode.choices.cast<StoryChoice?>().firstWhere(
          (item) => item?.id == choiceId,
          orElse: () => null,
        );
    if (choice == null) {
      throw const RuleFailure('Escolha inválida para o nó atual.');
    }
    if (!choice.requires.every(_state.evidenceIds.contains)) {
      throw const RuleFailure(
          'As provas necessárias ainda não foram reunidas.');
    }
    if (_state.keys < choice.keyCost) {
      throw const RuleFailure(
          'Chaves insuficientes para refazer esta escolha.');
    }
    final nextNodeId = choice.nextNodeId;
    final endingId = choice.endingId;
    if ((nextNodeId == null) == (endingId == null)) {
      throw const RuleFailure(
        'A escolha deve apontar para um nó ou para um final, mas não ambos.',
      );
    }
    if (endingId != null && !story.endings.containsKey(endingId)) {
      throw const DataFailure('Final de história inexistente.');
    }
    final previous = _state;
    final evidence = {..._state.evidenceIds}
      ..addAll(choice.addEvidence)
      ..removeAll(choice.removeEvidence);
    final visited = nextNodeId == null
        ? _state.visitedNodeIds
        : {..._state.visitedNodeIds, nextNodeId};
    _state = _state.copyWith(
      currentNodeId: nextNodeId ?? _state.currentNodeId,
      visitedNodeIds: visited,
      evidenceIds: evidence,
      keys: _state.keys - choice.keyCost,
      choiceHistory: [
        ..._state.choiceHistory,
        ChoiceRecord(
          nodeId: currentNode.id,
          choiceId: choice.id,
          previousState: previous,
        ),
      ],
      endingId: endingId,
    );
  }

  void undoWithKey() {
    if (_state.choiceHistory.isEmpty) {
      throw const RuleFailure('Não há uma escolha anterior para refazer.');
    }
    if (_state.keys < 1) throw const RuleFailure('Chaves insuficientes.');
    final history = [..._state.choiceHistory];
    final previous = history.removeLast().previousState;
    _state = previous.copyWith(
      keys: previous.keys - 1,
      choiceHistory: history,
    );
  }
}
