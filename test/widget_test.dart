import 'package:flutter_test/flutter_test.dart';
import 'package:livros_jogos/main.dart';

void main() {
  testWidgets('exibe o catálogo inicial', (tester) async {
    await tester.pumpWidget(const LivrosJogosApp());

    expect(find.text('LIVROS-JOGOS+'), findsOneWidget);
    expect(find.text('Assassinato & Mistério'), findsNWidgets(2));
  });
}
