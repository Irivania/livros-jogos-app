import 'package:flutter_test/flutter_test.dart';
import 'package:livros_jogos/features/stories/presentation/story_cubit.dart';
import 'package:livros_jogos/features/story_engine/domain/story_models.dart';
import 'package:livros_jogos/features/story_engine/domain/story_repository.dart';

void main() {
  test('carrega a história e inicializa o estado', () async {
    final cubit = StoryCubit(
      FakeStoryRepository(_story()),
      localStorage: FakeStoryStorage(),
    );

    await cubit.loadStory('test');

    expect(cubit.state.isLoading, isFalse);
    expect(cubit.state.story?.id, 'test');
    expect(cubit.state.currentNodeId, 'start');
    expect(cubit.state.trust, 50);
    expect(cubit.state.heat, 0);
    cubit.close();
  });

  test('aplica escolha, atributos e evidência', () async {
    final cubit = StoryCubit(
      FakeStoryRepository(_story()),
      localStorage: FakeStoryStorage(),
    );
    await cubit.loadStory('test');

    cubit.makeChoice(_story().nodes['start']!.choices.single);

    expect(cubit.state.currentNodeId, 'next');
    expect(cubit.state.trust, 60);
    expect(cubit.state.heat, 15);
    expect(cubit.state.evidenceInventory, contains('photo'));
    expect(cubit.state.history, hasLength(1));
    cubit.close();
  });

  test('bloqueia escolha sem atributo mínimo', () async {
    final cubit = StoryCubit(
      FakeStoryRepository(_story()),
      localStorage: FakeStoryStorage(),
    );
    await cubit.loadStory('test');

    cubit.makeChoice(_story().nodes['locked']!.choices.single);

    expect(cubit.state.currentNodeId, 'start');
    expect(cubit.state.history, isEmpty);
    cubit.close();
  });

  test('desfaz a última escolha e restaura o snapshot', () async {
    final cubit = StoryCubit(
      FakeStoryRepository(_story()),
      localStorage: FakeStoryStorage(),
    );
    await cubit.loadStory('test');
    cubit.makeChoice(_story().nodes['start']!.choices.single);

    cubit.undoLastChoice();

    expect(cubit.state.currentNodeId, 'start');
    expect(cubit.state.trust, 50);
    expect(cubit.state.heat, 0);
    expect(cubit.state.evidenceInventory, isEmpty);
    expect(cubit.state.history, isEmpty);
    cubit.close();
  });
}

final class FakeStoryRepository implements StoryRepository {
  FakeStoryRepository(this.story);

  final Story story;

  @override
  Future<Story> load(String storyId) async => story;
}

final class FakeStoryStorage extends StoryLocalStorage {
  @override
  Future<void> saveProgress({
    required String storyId,
    required String currentNodeId,
    required int trust,
    required int heat,
    required List<String> evidenceInventory,
  }) async {}

  @override
  Future<Map<String, dynamic>?> loadProgress(String storyId) async => null;
}

Story _story() => const Story(
      id: 'test',
      version: 1,
      title: 'Test',
      synopsis: 'Test story',
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
              id: 'continue',
              label: 'Continue',
              nextNodeId: 'next',
              endingId: null,
              requires: {},
              addEvidence: {'photo'},
              removeEvidence: {},
              keyCost: 0,
              statChanges: {'trust': 10, 'heat': 15},
            ),
          ],
        ),
        'locked': StoryNode(
          id: 'locked',
          text: 'Locked',
          image: null,
          choices: [
            StoryChoice(
              id: 'locked-choice',
              label: 'Locked',
              nextNodeId: 'next',
              endingId: null,
              requires: {},
              addEvidence: {},
              removeEvidence: {},
              keyCost: 0,
              requiredStats: {'trust': 80},
            ),
          ],
        ),
        'next': StoryNode(
          id: 'next',
          text: 'Next',
          image: null,
          choices: [],
        ),
      },
      endings: {},
    );
