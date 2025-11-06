class Medicamento {
  final String id;
  final String nome;
  final String dosagem; // Ex: "20mg"
  final int intervaloHoras; // Ex: 8 (de 8 em 8 horas)
  final int quantidadePorDose; // Ex: 1 (comprimido)
  final DateTime horarioPrimeiraDose; // Ex: 08:00
  final bool ativo;

  Medicamento({
    required this.id,
    required this.nome,
    required this.dosagem,
    required this.intervaloHoras,
    required this.quantidadePorDose,
    required this.horarioPrimeiraDose,
    this.ativo = true,
  });

  // Converter para Map para salvar no Hive
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'dosagem': dosagem,
      'intervaloHoras': intervaloHoras,
      'quantidadePorDose': quantidadePorDose,
      'horarioPrimeiraDose': horarioPrimeiraDose.toIso8601String(),
      'ativo': ativo,
    };
  }

  // Criar Medicamento a partir de Map
  factory Medicamento.fromMap(Map<String, dynamic> map) {
    return Medicamento(
      id: map['id'] as String,
      nome: map['nome'] as String,
      dosagem: map['dosagem'] as String,
      intervaloHoras: map['intervaloHoras'] as int,
      quantidadePorDose: map['quantidadePorDose'] as int,
      horarioPrimeiraDose: DateTime.parse(map['horarioPrimeiraDose'] as String),
      ativo: map['ativo'] as bool? ?? true,
    );
  }

  // Calcular próximos horários do dia
  List<DateTime> horariosDodia() {
    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);
    final fimDodia = hoje.add(const Duration(days: 1));
    final horarios = <DateTime>[];

    // Começar da primeira dose e ir adicionando intervalos
    DateTime horario = horarioPrimeiraDose;

    // Voltar até encontrar um horário antes de hoje
    while (horario.isAfter(hoje)) {
      horario = horario.subtract(Duration(hours: intervaloHoras));
    }

    // Avançar até o primeiro horário de hoje
    while (horario.isBefore(hoje)) {
      horario = horario.add(Duration(hours: intervaloHoras));
    }

    // Adicionar todos os horários de hoje
    while (horario.isBefore(fimDodia)) {
      horarios.add(horario);
      horario = horario.add(Duration(hours: intervaloHoras));
    }

    return horarios;
  }

  // Calcular horários de amanhã
  List<DateTime> horariosAmanha() {
    final agora = DateTime.now();
    final amanha = DateTime(agora.year, agora.month, agora.day).add(const Duration(days: 1));
    final fimAmanha = amanha.add(const Duration(days: 1));
    final horarios = <DateTime>[];

    // Começar da primeira dose e ir adicionando intervalos
    DateTime horario = horarioPrimeiraDose;

    // Voltar até encontrar um horário antes de amanhã
    while (horario.isAfter(amanha)) {
      horario = horario.subtract(Duration(hours: intervaloHoras));
    }

    // Avançar até o primeiro horário de amanhã
    while (horario.isBefore(amanha)) {
      horario = horario.add(Duration(hours: intervaloHoras));
    }

    // Adicionar todos os horários de amanhã
    while (horario.isBefore(fimAmanha)) {
      horarios.add(horario);
      horario = horario.add(Duration(hours: intervaloHoras));
    }

    return horarios;
  }

  // Copiar com modificações
  Medicamento copyWith({
    String? nome,
    String? dosagem,
    int? intervaloHoras,
    int? quantidadePorDose,
    DateTime? horarioPrimeiraDose,
    bool? ativo,
  }) {
    return Medicamento(
      id: id,
      nome: nome ?? this.nome,
      dosagem: dosagem ?? this.dosagem,
      intervaloHoras: intervaloHoras ?? this.intervaloHoras,
      quantidadePorDose: quantidadePorDose ?? this.quantidadePorDose,
      horarioPrimeiraDose: horarioPrimeiraDose ?? this.horarioPrimeiraDose,
      ativo: ativo ?? this.ativo,
    );
  }
}
