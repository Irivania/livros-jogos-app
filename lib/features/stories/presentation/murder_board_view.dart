import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../domain/evidence_item.dart';
import 'story_cubit.dart';

class MurderBoardView extends StatelessWidget {
  const MurderBoardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1412), // Fundo de cortiça escura / estilo noir
      appBar: AppBar(
        backgroundColor: const Color(0xFF0d0a09),
        title: const Text(
          'QUADRO DE INVESTIGAÇÃO',
          style: TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: BlocBuilder<StoryCubit, StoryState>(
        builder: (context, state) {
          final unlockedEvidenceIds = state.evidenceInventory;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'EVIDÊNCIAS RECOLHIDAS',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    letterSpacing: 1.5,
                  ),
                ),
                const Divider(color: Colors.redAccent, thickness: 1.5),
                const SizedBox(height: 10),
                Expanded(
                  child: unlockedEvidenceIds.isEmpty
                      ? const Center(
                          child: Text(
                            'Nenhuma evidência descoberta ainda.\nInvestigue com atenção nas escolhas dos capítulos.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white38, fontSize: 16),
                          ),
                        )
                      : GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.85,
                          ),
                          itemCount: unlockedEvidenceIds.length,
                          itemBuilder: (context, index) {
                            final evidenceId = unlockedEvidenceIds.elementAt(index);
                            final evidence = EvidenceItem.catalog[evidenceId] ??
                                EvidenceItem(
                                  id: evidenceId,
                                  title: evidenceId,
                                  description: 'Evidência recolhida no caso.',
                                  imagePath: '',
                                );

                            return _buildPolaroidCard(evidence);
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPolaroidCard(EvidenceItem evidence) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFf4f1ea), // Cor de papel polaroid antigo
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Espaço para a foto / miniatura da evidência
          Expanded(
            child: Container(
              color: Colors.black87,
              child: const Center(
                child: Icon(
                  Icons.fingerprint,
                  color: Colors.redAccent,
                  size: 40,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            evidence.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            evidence.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}