import 'package:flutter/foundation.dart';

import '../domain/story_engine.dart';
import '../domain/story_models.dart';

final class StorySessionController extends ChangeNotifier {
  StorySessionController(this._engine);

  final StoryEngine _engine;
  InvestigationState get state => _engine.state;
  StoryNode get currentNode => _engine.currentNode;

  void choose(String choiceId) {
    _engine.choose(choiceId);
    notifyListeners();
  }

  void undoWithKey() {
    _engine.undoWithKey();
    notifyListeners();
  }
}
