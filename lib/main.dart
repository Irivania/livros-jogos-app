import 'package:flutter/material.dart';
import 'features/story_engine/presentation/catalog_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LivrosJogosApp());
}

class LivrosJogosApp extends StatelessWidget {
  const LivrosJogosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Livros-Jogos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        primarySwatch: Colors.red,
        fontFamily: 'Roboto',
      ),
      home: const CatalogHomeScreen(),
    );
  }
}
