import 'package:flutter/material.dart';
import '../story_asset_repository.dart';
import '../data/secure_progress_store.dart';
import '../data/sound_manager.dart';
import 'murder_board_screen.dart';
import 'typewriter_text.dart';

class StoryReaderScreen extends StatefulWidget {
  final String storyAssetPath;

  const StoryReaderScreen({super.key, required this.storyAssetPath});

  @override
  State<StoryReaderScreen> createState() => _StoryReaderScreenState();
}

class _StoryReaderScreenState extends State<StoryReaderScreen> {
  late Future<StoryModel> _storyFuture;
  StoryModel? _story;
  String? currentSceneId;
  String? currentEndingId;
  final List<String> collectedEvidence = [];
  int playerKeys = 3;

  // Controlo rigoroso para exibir as escolhas apenas quando a máquina terminar
  bool _isTypingFinished = false;
  String? _lastProcessedSceneId; // Para detetar mudança de cena com precisão

  // Estado dinâmico do jogador (Atributos ocultos/visíveis)
  Map<String, int> playerStats = {
    'trust': 50, // Confiança (0 a 100)
    'heat': 10, // Suspeita policial (0 a 100)
  };

  final SecureProgressStore _progressStore = SecureProgressStore();
  bool _isLoadingProgress = true;

  @override
  void initState() {
    super.initState();
    _storyFuture = StoryAssetRepository().loadStory(widget.storyAssetPath);
    _loadSavedGame();
    SoundManager.playAmbientRain();
  }

  @override
  void dispose() {
    SoundManager.stopAll();
    super.dispose();
  }

  Future<void> _loadSavedGame() async {
    final progress = await _progressStore.loadProgress();
    if (progress != null) {
      setState(() {
        currentSceneId = progress['sceneId'];
        collectedEvidence.addAll(List<String>.from(progress['evidence']));
        if (progress['stats'] != null) {
          playerStats = Map<String, int>.from(progress['stats']);
        }
      });
    }
    setState(() {
      _isLoadingProgress = false;
    });
  }

  bool _isChoiceUnlocked(ChoiceModel choice) {
    for (var req in choice.requires) {
      if (!collectedEvidence.contains(req)) return false;
    }
    if (playerKeys < choice.keyCost) return false;

    for (var entry in choice.requiredStats.entries) {
      final statName = entry.key;
      final requiredMin = entry.value;
      final currentVal = playerStats[statName] ?? 0;
      if (currentVal < requiredMin) return false;
    }

    return true;
  }

  Future<void> _makeChoice(ChoiceModel choice) async {
    if (!_isChoiceUnlocked(choice)) return;

    SoundManager.playClickEffect();

    setState(() {
      playerKeys -= choice.keyCost;

      for (var ev in choice.addEvidence) {
        if (!collectedEvidence.contains(ev)) collectedEvidence.add(ev);
      }
      for (var ev in choice.removeEvidence) {
        collectedEvidence.remove(ev);
      }

      choice.statChanges.forEach((stat, change) {
        final current = playerStats[stat] ?? 50;
        playerStats[stat] = (current + change).clamp(0, 100).toInt();
      });

      // IMPORTANTE: Oculta imediatamente as opções ao avançar de escolha
      _isTypingFinished = false;

      if (choice.endingId != null) {
        currentEndingId = choice.endingId;
        currentSceneId = null;
      } else if (choice.nextNodeId != null) {
        currentSceneId = choice.nextNodeId;
      }
    });

    if (currentSceneId != null) {
      await _progressStore.saveProgress(
        sceneId: currentSceneId!,
        evidence: collectedEvidence,
        stats: playerStats,
      );
    } else {
      await _progressStore.clearProgress();
    }
  }

  Future<void> _resetProgress() async {
    await _progressStore.clearProgress();
    setState(() {
      currentSceneId = _story?.startNodeId;
      currentEndingId = null;
      collectedEvidence.clear();
      playerKeys = 3;
      playerStats = {'trust': 50, 'heat': 10};
      _isTypingFinished = false;
      _lastProcessedSceneId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingProgress) {
      return Scaffold(
        appBar: AppBar(backgroundColor: const Color(0xFF1F1F1F)),
        body: const Center(
            child: CircularProgressIndicator(color: Colors.redAccent)),
      );
    }

    return FutureBuilder<StoryModel>(
      future: _storyFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(backgroundColor: const Color(0xFF1F1F1F)),
            body: const Center(
                child: CircularProgressIndicator(color: Colors.redAccent)),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(backgroundColor: const Color(0xFF1F1F1F)),
            body: Center(
                child: Text('Erro: ${snapshot.error}',
                    style: const TextStyle(color: Colors.white))),
          );
        } else if (snapshot.hasData) {
          _story ??= snapshot.data;
          currentSceneId ??= _story!.startNodeId;

          // Se mudou de cena, garante que as opções começam ocultas
          if (_lastProcessedSceneId != currentSceneId) {
            _lastProcessedSceneId = currentSceneId;
            _isTypingFinished = false;
          }

          if (currentEndingId != null) {
            final ending = _story!.endings[currentEndingId];
            return Scaffold(
              appBar: AppBar(
                title: const Text('Veredito da Investigação'),
                backgroundColor: const Color(0xFF1F1F1F),
                automaticallyImplyLeading: false,
              ),
              body: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.gavel, color: Colors.redAccent, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      ending?.title ?? 'Fim do Caso',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Text(
                          ending?.text ??
                              'A investigação chegou ao seu desfecho.',
                          style: const TextStyle(
                              fontSize: 16, color: Colors.white70, height: 1.6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2C2C2C),
                          foregroundColor: Colors.amber,
                          padding: const EdgeInsets.all(16)),
                      icon: const Icon(Icons.dashboard),
                      label: Text(
                          'Ver Quadro de Provas (${collectedEvidence.length} evidências)'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => MurderBoardScreen(
                                  collectedEvidence: collectedEvidence)),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(16)),
                      onPressed: _resetProgress,
                      child: const Text('Jogar Novamente',
                          style: TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Voltar ao Catálogo',
                          style: TextStyle(color: Colors.grey)),
                    ),
                  ],
                ),
              ),
            );
          }

          final scene = _story!.nodes[currentSceneId];

          if (scene == null) {
            return Scaffold(
              appBar: AppBar(
                  title: const Text('Fim da Investigação'),
                  backgroundColor: const Color(0xFF1F1F1F)),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Cena não encontrada.',
                        style: TextStyle(color: Colors.white, fontSize: 18)),
                    const SizedBox(height: 20),
                    ElevatedButton(
                        onPressed: _resetProgress,
                        child: const Text('Reiniciar Caso')),
                  ],
                ),
              ),
            );
          }

          return Scaffold(
            appBar: AppBar(
              title: Text(_story!.title),
              backgroundColor: const Color(0xFF1F1F1F),
              actions: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0),
                    child: Row(
                      children: [
                        const Icon(Icons.handshake,
                            color: Colors.blueAccent, size: 16),
                        const SizedBox(width: 4),
                        Text('${playerStats['trust']}%',
                            style: const TextStyle(
                                color: Colors.blueAccent,
                                fontSize: 13,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0),
                    child: Row(
                      children: [
                        const Icon(Icons.local_fire_department,
                            color: Colors.orangeAccent, size: 16),
                        const SizedBox(width: 4),
                        Text('${playerStats['heat']}%',
                            style: const TextStyle(
                                color: Colors.orangeAccent,
                                fontSize: 13,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      children: [
                        const Icon(Icons.key, color: Colors.amber, size: 16),
                        const SizedBox(width: 2),
                        Text('$playerKeys',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.dashboard,
                      color: Colors.amber, size: 20),
                  tooltip: 'Quadro de Investigação',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => MurderBoardScreen(
                              collectedEvidence: collectedEvidence)),
                    );
                  },
                ),
              ],
            ),
            body: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: TypewriterText(
                        key: ValueKey<String>(scene.id),
                        text: scene.text,
                        characterDelay: const Duration(milliseconds: 15),
                        onFinished: () {
                          // Garante que só liberta os botões após a última letra aparecer
                          setState(() {
                            _isTypingFinished = true;
                          });
                        },
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white70,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ),

                  // AS OPÇÕES SÓ APARECEM SE _isTypingFinished FOR VERDADEIRO
                  if (_isTypingFinished) ...[
                    const SizedBox(height: 20),
                    const Divider(color: Colors.grey),
                    const SizedBox(height: 10),
                    const Text(
                      "O que você faz?",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...scene.choices.map((choice) {
                      final bool isUnlocked = _isChoiceUnlocked(choice);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isUnlocked
                                ? const Color(0xFF2C2C2C)
                                : Colors.grey[900],
                            foregroundColor:
                                isUnlocked ? Colors.white : Colors.grey,
                            padding: const EdgeInsets.all(16),
                            alignment: Alignment.centerLeft,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: isUnlocked
                                    ? Colors.white24
                                    : Colors.red.withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                          onPressed:
                              isUnlocked ? () => _makeChoice(choice) : null,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  choice.label,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: isUnlocked
                                        ? Colors.white
                                        : Colors.grey[600],
                                  ),
                                ),
                              ),
                              if (!isUnlocked)
                                const Icon(Icons.lock,
                                    color: Colors.redAccent, size: 18),
                              if (choice.keyCost > 0 && isUnlocked)
                                Row(
                                  children: [
                                    const SizedBox(width: 8),
                                    const Icon(Icons.key,
                                        color: Colors.amber, size: 14),
                                    Text(' ${choice.keyCost}',
                                        style: const TextStyle(
                                            color: Colors.amber, fontSize: 12)),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
