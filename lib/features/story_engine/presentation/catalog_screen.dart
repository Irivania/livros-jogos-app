import 'package:flutter/material.dart';
import 'story_reader_screen.dart';
import 'fade_page_route.dart';

class StoryCatalogItem {
  final String title;
  final String synopsis;
  final String assetPath;
  final String difficulty;
  final String genre; // Ex: 'Assassinato', 'Drama', 'Suspense'
  final String bannerColorHex; // Cor temática para o card (simulando capa)

  const StoryCatalogItem({
    required this.title,
    required this.synopsis,
    required this.assetPath,
    required this.difficulty,
    required this.genre,
    required this.bannerColorHex,
  });
}

class CatalogHomeScreen extends StatelessWidget {
  const CatalogHomeScreen({super.key});

  // Base de dados local de casos divididos por géneros (estilo Netflix/Globoplay)
  final List<StoryCatalogItem> availableStories = const [
    StoryCatalogItem(
      title: 'Até que a Morte nos Separe',
      synopsis:
          'Uma noite chuvosa em Perdizes, um corpo no estúdio e segredos ocultos entre os suspeitos.',
      assetPath: 'assets/stories/ate_que_a_morte.json',
      difficulty: 'Moderado',
      genre: 'Assassinato & Mistério',
      bannerColorHex: '0xFF8B0000', // Vermelho escuro/Noir
    ),
    StoryCatalogItem(
      title: 'Chuva Negra',
      synopsis:
          'Um mistério corporativo nas margens da represa Billings que esconde uma conspiração perigosa.',
      assetPath: 'assets/stories/black-rain/story.json',
      difficulty: 'Difícil',
      genre: 'Drama & Conspiração',
      bannerColorHex: '0xFF1C3B57', // Azul corporativo sombrio
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Agrupar histórias por género dinamicamente
    final Map<String, List<StoryCatalogItem>> groupedStories = {};
    for (var story in availableStories) {
      groupedStories.putIfAbsent(story.genre, () => []).add(story);
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Fundo estilo streaming
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.movie_filter, color: Colors.redAccent),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'LIVROS-JOGOS+',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF181818),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white70),
            onPressed: () {
              // Futura barra de pesquisa de histórias
            },
          ),
          IconButton(
            tooltip: 'Perfil',
            icon: const Icon(Icons.person, color: Colors.redAccent),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // DESTAQUE PRINCIPAL (BANNER HERO - ESTILO NETFLIX)
            _buildHeroBanner(context, availableStories.first),

            const SizedBox(height: 24),

            // PRATELEIRAS POR CATEGORIA (GENERO)
            ...groupedStories.entries.map((entry) {
              final genre = entry.key;
              final storiesInCategory = entry.value;

              return Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        genre,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 210,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        itemCount: storiesInCategory.length,
                        itemBuilder: (context, index) {
                          final story = storiesInCategory[index];
                          return _buildStoryCard(context, story);
                        },
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // Widget para o Banner Principal em Destaque no topo
  Widget _buildHeroBanner(
      BuildContext context, StoryCatalogItem featuredStory) {
    return Container(
      width: double.infinity,
      height: 280,
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(int.parse(featuredStory.bannerColorHex)),
            const Color(0xFF1E1E1E),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.redAccent),
              ),
              child: Text(
                'DESTAQUE • ${featuredStory.difficulty.toUpperCase()}',
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              featuredStory.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              featuredStory.synopsis,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.play_arrow, color: Colors.black),
              label: const Text('Assistir / Investigar',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.push(
                  context,
                  FadePageRoute(
                    child: StoryReaderScreen(
                        storyAssetPath: featuredStory.assetPath),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Widget para os Cards Individuais nas Prateleiras Horizontais
  Widget _buildStoryCard(BuildContext context, StoryCatalogItem story) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          FadePageRoute(
            child: StoryReaderScreen(storyAssetPath: story.assetPath),
          ),
        );
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: const Color(0xFF252525),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white12),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(int.parse(story.bannerColorHex)),
                    const Color(0xFF222222),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  const Center(
                    child: Icon(Icons.local_library,
                        color: Colors.white24, size: 40),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        story.difficulty,
                        style:
                            const TextStyle(color: Colors.white70, fontSize: 9),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              story.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            Text(
              story.genre,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
