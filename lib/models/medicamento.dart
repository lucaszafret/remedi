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
    final horarios = <DateTime>[];

    // Primeira dose do dia com a hora especificada
    DateTime horario = DateTime(
      hoje.year,
      hoje.month,
      hoje.day,
      horarioPrimeiraDose.hour,
      horarioPrimeiraDose.minute,
    );

    // Adicionar todos os horários do dia (24 horas)
    while (horario.day == hoje.day) {
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
