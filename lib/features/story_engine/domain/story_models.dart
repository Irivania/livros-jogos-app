typedef EvidenceId = String;

final class Story {
  const Story({
    required this.id,
    required this.version,
    required this.title,
    required this.synopsis,
    required this.cover,
    required this.category,
    required this.startNodeId,
    required this.nodes,
    required this.endings,
  });

  final String id;
  final int version;
  final String title;
  final String synopsis;
  final String cover;
  final String category;
  final String startNodeId;
  final Map<String, StoryNode> nodes;
  final Map<String, StoryEnding> endings;
}

final class StoryNode {
  const StoryNode({
    required this.id,
    required this.text,
    required this.image,
    required this.choices,
  });

  final String id;
  final String text;
  final String? image;
  final List<StoryChoice> choices;
}

final class StoryChoice {
  const StoryChoice({
    required this.id,
    required this.label,
    required this.nextNodeId,
    required this.endingId,
    required this.requires,
    required this.addEvidence,
    required this.removeEvidence,
    required this.keyCost,
    this.statChanges = const {},
    this.requiredStats = const {},
  });

  final String id;
  final String label;
  final String? nextNodeId;
  final String? endingId;
  final Set<EvidenceId> requires;
  final Set<EvidenceId> addEvidence;
  final Set<EvidenceId> removeEvidence;
  final int keyCost;
  final Map<String, int> statChanges;
  final Map<String, int> requiredStats;
}

final class StoryEnding {
  const StoryEnding({
    required this.id,
    required this.title,
    required this.text,
    required this.requiredEvidence,
  });

  final String id;
  final String title;
  final String text;
  final Set<EvidenceId> requiredEvidence;
}

final class InvestigationState {
  const InvestigationState({
    required this.currentNodeId,
    required this.visitedNodeIds,
    required this.evidenceIds,
    required this.keys,
    required this.choiceHistory,
    this.endingId,
  });

  final String currentNodeId;
  final Set<String> visitedNodeIds;
  final Set<EvidenceId> evidenceIds;
  final int keys;
  final List<ChoiceRecord> choiceHistory;
  final String? endingId;

  InvestigationState copyWith({
    String? currentNodeId,
    Set<String>? visitedNodeIds,
    Set<EvidenceId>? evidenceIds,
    int? keys,
    List<ChoiceRecord>? choiceHistory,
    String? endingId,
  }) =>
      InvestigationState(
        currentNodeId: currentNodeId ?? this.currentNodeId,
        visitedNodeIds: visitedNodeIds ?? this.visitedNodeIds,
        evidenceIds: evidenceIds ?? this.evidenceIds,
        keys: keys ?? this.keys,
        choiceHistory: choiceHistory ?? this.choiceHistory,
        endingId: endingId ?? this.endingId,
      );
}

final class ChoiceRecord {
  const ChoiceRecord({
    required this.nodeId,
    required this.choiceId,
    required this.previousState,
  });

  final String nodeId;
  final String choiceId;
  final InvestigationState previousState;
}
