import 'package:flutter/material.dart';

class MurderBoardScreen extends StatelessWidget {
  final List<String> collectedEvidence;

  const MurderBoardScreen({super.key, required this.collectedEvidence});

  Map<String, String> getEvidenceDetails(String evidenceId) {
    switch (evidenceId) {
      case 'maleta_escondida':
        return {
          'title': 'Maleta de Documentos',
          'category': 'Provas Físicas',
          'description':
              'Escondida no armário. Contém registos financeiros e papéis rasgados.',
          'icon': 'folder_special',
        };
      case 'notebook_escritorio':
        return {
          'title': 'Notebook de Helena',
          'category': 'Digital / Informática',
          'description':
              'Exibe contrato de transferência bancária de R\$ 500 mil para Marcos.',
          'icon': 'laptop_mac',
        };
      case 'testemunho_falso_marcos':
        return {
          'title': 'Dossiê do Sócio (Marcos)',
          'category': 'Suspeitos',
          'description':
              'Bilhetes de amor e desvios financeiros comprovam chantagem.',
          'icon': 'person_search',
        };
      case 'confissao_gravada':
        return {
          'title': 'Áudio de Confissão',
          'category': 'Provas Críticas',
          'description':
              'Gravação oculta obtida atrás da cortina no escritório.',
          'icon': 'mic',
        };
      default:
        return {
          'title': evidenceId,
          'category': 'Evidência Desconhecida',
          'description': 'Item recolhido durante a investigação em campo.',
          'icon': 'help_outline',
        };
    }
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'folder_special':
        return Icons.folder_special;
      case 'laptop_mac':
        return Icons.laptop_mac;
      case 'person_search':
        return Icons.person_search;
      case 'mic':
        return Icons.mic;
      default:
        return Icons.sticky_note_2;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1B18),
      appBar: AppBar(
        title: const Text('Mural Tático de Investigação'),
        backgroundColor: const Color(0xFF141210),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.push_pin, color: Colors.redAccent, size: 20),
                SizedBox(width: 8),
                Text(
                  'EVIDÊNCIAS & PONTOS LIGADOS',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: collectedEvidence.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.folder_open,
                              color: Colors.white24, size: 60),
                          SizedBox(height: 12),
                          Text(
                            'Nenhuma evidência recolhida ainda.\nInvestigue os cenários com cautela.',
                            textAlign: TextAlign.center,
                            style:
                                TextStyle(color: Colors.white54, fontSize: 15),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: collectedEvidence.length,
                      itemBuilder: (context, index) {
                        final details =
                            getEvidenceDetails(collectedEvidence[index]);
                        return Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF9C4),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.4),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Icon(
                                    _getIconData(details['icon']!),
                                    color: Colors.red[900],
                                    size: 24,
                                  ),
                                  const Icon(Icons.push_pin,
                                      color: Colors.red, size: 16),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black12,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: Text(
                                  details['category']!,
                                  style: TextStyle(
                                    color: Colors.grey[800],
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                details['title']!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Expanded(
                                child: Text(
                                  details['description']!,
                                  style: TextStyle(
                                    color: Colors.grey[900],
                                    fontSize: 11,
                                    height: 1.3,
                                  ),
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
