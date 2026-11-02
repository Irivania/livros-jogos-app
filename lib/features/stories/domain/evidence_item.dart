class EvidenceItem {
  final String id;
  final String title;
  final String description;
  final String imagePath; // Caminho para a foto policial ou documento
  final bool isUnlocked;

  const EvidenceItem({
    required this.id,
    required this.title,
    required this.description,
    required this.imagePath,
    this.isUnlocked = false,
  });

  // Catálogo de todas as evidências da minissérie
  static const Map<String, EvidenceItem> catalog = {
    'celular_helena_silencioso': EvidenceItem(
      id: 'celular_helena_silencioso',
      title: 'Telemóvel Corporativo de Helena',
      description: 'Encontrado sob os livros. Contém transferências suspeitas.',
      imagePath: 'assets/images/evidence/phone.webp',
    ),
    'alibi_contraditorio_daniel': EvidenceItem(
      id: 'alibi_contraditorio_daniel',
      title: 'Fios no Punho de Daniel',
      description: 'Fios de tecido azul-marinho idênticos ao lenço do crime.',
      imagePath: 'assets/images/evidence/threads.webp',
    ),
    'telemovel_corporativo_helena': EvidenceItem(
      id: 'telemovel_corporativo_helena',
      title: 'Extrato Bancário (R$ 85k)',
      description: 'Pix enviado para Marcos nas vésperas do assassinato.',
      imagePath: 'assets/images/evidence/bank_statement.webp',
    ),
    'relatorio_financeiro_lumen': EvidenceItem(
      id: 'relatorio_financeiro_lumen',
      title: 'Auditoria da Lumen Design',
      description: 'Aponta rombo financeiro e desvios geridos por Helena.',
      imagePath: 'assets/images/evidence/audit.webp',
    ),
    'pen_drive_segredo_preservado': EvidenceItem(
      id: 'pen_drive_segredo_preservado',
      title: 'Pen Drive Criptografado',
      description: 'Contém gravações de voz e provas do esquema de Marcos.',
      imagePath: 'assets/images/evidence/usb.webp',
    ),
  };
}