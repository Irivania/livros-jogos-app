import 'package:flutter_test/flutter_test.dart';
import 'package:livros_jogos/features/story_engine/domain/story_engine.dart';
import 'package:livros_jogos/features/story_engine/domain/story_models.dart';
import 'package:livros_jogos/core/errors/failure.dart';

void main() {
  test('aplica escolha e atualiza o quadro de provas', () {
    final engine = StoryEngine(_story());

    engine.choose('inspect');

    expect(engine.state.currentNodeId, 'start');
    expect(engine.state.evidenceIds, contains('photo'));
    expect(engine.state.endingId, 'truth');
  });

  test('rejeita escolha que exige prova ausente sem mutar o estado', () {
    final engine = StoryEngine(_story());

    expect(
      () => engine.choose('locked'),
      throwsA(isA<RuleFailure>()),
    );
    expect(engine.state.currentNodeId, 'start');
    expect(engine.state.choiceHistory, isEmpty);
  });

  test('desfazer consome uma chave e restaura o snapshot anterior', () {
    final engine = StoryEngine(_storyWithKeys(), initialKeys: 1);

    engine.choose('move');
    engine.undoWithKey();

    expect(engine.state.currentNodeId, 'start');
    expect(engine.state.keys, 0);
    expect(engine.state.choiceHistory, isEmpty);
  });
}

Story _story() => const Story(
      id: 'test',
      version: 1,
      title: 'Test',
      synopsis: 'Test',
      cover: 'cover.webp',
      category: 'suspense',
      startNodeId: 'start',
      nodes: {
        'start': StoryNode(
          id: 'start',
          text: 'Start',
          image: null,
          choices: [
            StoryChoice(
              id: 'inspect',
              label: 'Inspect',
              nextNodeId: null,
              endingId: 'truth',
              requires: {},
              addEvidence: {'photo'},
              removeEvidence: {},
              keyCost: 0,
            ),
            StoryChoice(
              id: 'locked',
              label: 'Locked',
              nextNodeId: 'end',
              endingId: null,
              requires: {'missing'},
              addEvidence: {},
              removeEvidence: {},
              keyCost: 0,
            ),
          ],
        ),
        'end': StoryNode(
          id: 'end',
          text: 'End',
          image: null,
          choices: [],
        ),
      },
      endings: {
        'truth': StoryEnding(
          id: 'truth',
          title: 'Truth',
          text: 'Truth',
          requiredEvidence: {'photo'},
        ),
      },
    );

Story _storyWithKeys() {
  final story = _story();
  return Story(
    id: story.id,
    version: story.version,
    title: story.title,
    synopsis: story.synopsis,
    cover: story.cover,
    category: story.category,
    startNodeId: story.startNodeId,
    nodes: {
      ...story.nodes,
      'start': const StoryNode(
        id: 'start',
        text: 'Start',
        image: null,
        choices: [
          StoryChoice(
            id: 'move',
            label: 'Move',
            nextNodeId: 'end',
            endingId: null,
            requires: {},
            addEvidence: {},
            removeEvidence: {},
            keyCost: 0,
          ),
        ],
      ),
    },
    endings: story.endings,
  );
}
