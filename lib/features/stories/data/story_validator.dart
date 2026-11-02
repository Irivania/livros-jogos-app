import '../../story_engine/domain/story_models.dart';

final class StoryValidator {
  const StoryValidator._();

  /// Valida toda a estrutura da história unificada (manifesto + capítulos)
  static void validate(Story story) {
    final nodeIds = story.nodes.keys.toSet();
    final endingIds = story.endings.keys.toSet();

    // 1. Valida se o nó inicial (startNodeId) existe
    if (!nodeIds.contains(story.startNodeId)) {
      throw FormatException(
        'Erro de Validação: O nó inicial "${story.startNodeId}" não foi encontrado na história "${story.id}".',
      );
    }

    // 2. Valida cada nó e as respetivas escolhas
    story.nodes.forEach((nodeId, node) {
      if (node.choices.isEmpty) {
        throw FormatException(
          'Erro de Validação: O nó "$nodeId" não possui nenhuma escolha cadastrada.',
        );
      }

      for (final choice in node.choices) {
        // Valida se o próximo nó existe (caso a escolha aponte para um nó)
        if (choice.nextNodeId != null && !nodeIds.contains(choice.nextNodeId)) {
          throw FormatException(
            'Erro de Validação no nó "$nodeId" (Escolha "${choice.id}"): '
            'O nextNodeId "${choice.nextNodeId}" não existe.',
          );
        }

        // Valida se o final existe (caso a escolha encerre a história com um final)
        if (choice.endingId != null && !endingIds.contains(choice.endingId)) {
          throw FormatException(
            'Erro de Validação no nó "$nodeId" (Escolha "${choice.id}"): '
            'O endingId "${choice.endingId}" não existe nos finais declarados.',
          );
        }
      }
    });
  }
}
