import 'story_models.dart';

abstract interface class StoryRepository {
  Future<Story> load(String storyId);
}
