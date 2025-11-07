class Medicamento {
  final String id;
  final String nome;
  final String dosagem; // Ex: "20mg"
  final int intervaloHoras; // Ex: 8 (de 8 em 8 horas)
  final int quantidadePorDose; // Ex: 1 (comprimido)
  final DateTime horarioPrimeiraDose; // Ex: 08:00
  final bool ativo;
  final int? diasTratamento; // Duração em dias (null = contínuo)
  final int? quantidadeTotal; // Total de comprimidos (null = contínuo)

  Medicamento({
    required this.id,
    required this.nome,
    required this.dosagem,
    required this.intervaloHoras,
    required this.quantidadePorDose,
    required this.horarioPrimeiraDose,
    this.ativo = true,
    this.diasTratamento,
    this.quantidadeTotal,
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
      'diasTratamento': diasTratamento,
      'quantidadeTotal': quantidadeTotal,
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
      diasTratamento: map['diasTratamento'] as int?,
      quantidadeTotal: map['quantidadeTotal'] as int?,
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

  // Calcular horários dos próximos 3 dias
  Map<String, List<DateTime>> horariosProximos3Dias() {
    final hoje = DateTime.now();
    final resultado = <String, List<DateTime>>{};

    for (int dia = 0; dia < 3; dia++) {
      final data = DateTime(hoje.year, hoje.month, hoje.day).add(Duration(days: dia));
      final proximoDia = data.add(const Duration(days: 1));
      final horarios = <DateTime>[];

      DateTime horario = horarioPrimeiraDose;

      // Voltar até antes da data
      while (horario.isAfter(data)) {
        horario = horario.subtract(Duration(hours: intervaloHoras));
      }

      // Avançar até o primeiro horário da data
      while (horario.isBefore(data)) {
        horario = horario.add(Duration(hours: intervaloHoras));
      }

      // Adicionar todos os horários da data
      while (horario.isBefore(proximoDia)) {
        horarios.add(horario);
        horario = horario.add(Duration(hours: intervaloHoras));
      }

      String label;
      if (dia == 0) {
        label = 'Hoje';
      } else if (dia == 1) {
        label = 'Amanhã';
      } else {
        label = 'Depois de amanhã';
      }

      resultado[label] = horarios;
    }

    return resultado;
  }

  // Obter próxima dose (futuro ou atual)
  DateTime? proximaDose() {
    final agora = DateTime.now();
    DateTime horario = horarioPrimeiraDose;

    // Avançar até encontrar um horário futuro ou atual
    while (horario.isBefore(agora)) {
      horario = horario.add(Duration(hours: intervaloHoras));
    }

    return horario;
  }

  // Calcular data final do tratamento
  DateTime? dataFinalTratamento() {
    if (diasTratamento != null) {
      return horarioPrimeiraDose.add(Duration(days: diasTratamento!));
    } else if (quantidadeTotal != null) {
      // Calcular data final baseada na quantidade total
      final totalDoses = (quantidadeTotal! / quantidadePorDose).ceil();
      final horasTotal = (totalDoses - 1) * intervaloHoras; // -1 porque começa da primeira dose
      return horarioPrimeiraDose.add(Duration(hours: horasTotal));
    }
    return null;
  }

  // Calcular total de doses no tratamento
  int? totalDoses() {
    if (diasTratamento != null) {
      final dosesHorasPorDia = 24 / intervaloHoras;
      return (diasTratamento! * dosesHorasPorDia).ceil();
    } else if (quantidadeTotal != null) {
      return (quantidadeTotal! / quantidadePorDose).ceil();
    }
    return null;
  }

  // Calcular total de comprimidos necessários
  int? totalComprimidosNecessarios() {
    if (diasTratamento != null) {
      final doses = totalDoses();
      if (doses == null) return null;
      return doses * quantidadePorDose;
    } else if (quantidadeTotal != null) {
      return quantidadeTotal;
    }
    return null;
  }

  // Calcular dias de tratamento baseado na quantidade total
  int? diasPorQuantidade() {
    if (quantidadeTotal == null) return null;
    final dosesHorasPorDia = 24 / intervaloHoras;
    final totalDeDoses = quantidadeTotal! / quantidadePorDose;
    return (totalDeDoses / dosesHorasPorDia).ceil();
  }

  // Verificar se o tratamento já terminou
  bool tratamentoFinalizado() {
    final dataFinal = dataFinalTratamento();
    if (dataFinal == null) return false;
    return DateTime.now().isAfter(dataFinal);
  }

  // Calcular todas as doses do tratamento desde o início
  List<DateTime> todasDosesTratamento() {
    final doses = <DateTime>[];
    final agora = DateTime.now();

    // SEMPRE começar da primeira dose histórica
    DateTime horario = horarioPrimeiraDose;
    DateTime dataLimite;

    if (diasTratamento != null) {
      // Se tem duração definida em dias:
      // Calcular baseado no número total de doses esperadas
      final dosesHorasPorDia = 24 / intervaloHoras;
      final totalDosesEsperadas = (diasTratamento! * dosesHorasPorDia).ceil();

      // Adicionar todas as doses calculadas
      for (int i = 0; i < totalDosesEsperadas; i++) {
        doses.add(horario);
        horario = horario.add(Duration(hours: intervaloHoras));
      }
    } else if (quantidadeTotal != null) {
      // Se tem quantidade total definida:
      // Calcular o número de doses baseado na quantidade total de comprimidos
      final totalDosesEsperadas = (quantidadeTotal! / quantidadePorDose).ceil();

      // Adicionar todas as doses calculadas
      for (int i = 0; i < totalDosesEsperadas; i++) {
        doses.add(horario);
        horario = horario.add(Duration(hours: intervaloHoras));
      }
    } else {
      // Se não tem data final (uso contínuo):
      // Mostrar desde a primeira dose até hoje + 3 dias
      final hoje = DateTime(agora.year, agora.month, agora.day);
      dataLimite = hoje.add(const Duration(days: 3, hours: 23, minutes: 59));

      // Adicionar todas as doses desde o início até o limite
      while (horario.isBefore(dataLimite) || horario.isAtSameMomentAs(dataLimite)) {
        doses.add(horario);
        horario = horario.add(Duration(hours: intervaloHoras));
      }
    }

    return doses;
  }

  // Calcular quantas doses já foram perdidas (passadas e não tomadas)
  int dosesPerdidas() {
    final agora = DateTime.now();
    int perdidas = 0;

    DateTime horario = horarioPrimeiraDose;
    while (horario.isBefore(agora)) {
      // Aqui precisaríamos acessar DoseService, mas não podemos no modelo
      // Então este método será implementado no widget
      horario = horario.add(Duration(hours: intervaloHoras));
      perdidas++;
    }

    return perdidas;
  }

  // Calcular quantas doses faltam tomar
  int dosesFaltam() {
    final agora = DateTime.now();
    final dataFinal = dataFinalTratamento();

    if (dataFinal == null) {
      // Contínuo - não tem fim
      return -1;
    }

    int faltam = 0;
    DateTime horario = agora;

    while (horario.isBefore(dataFinal)) {
      faltam++;
      horario = horario.add(Duration(hours: intervaloHoras));
    }

    return faltam;
  }

  // Copiar com modificações
  Medicamento copyWith({
    String? nome,
    String? dosagem,
    int? intervaloHoras,
    int? quantidadePorDose,
    DateTime? horarioPrimeiraDose,
    bool? ativo,
    int? diasTratamento,
    int? quantidadeTotal,
  }) {
    return Medicamento(
      id: id,
      nome: nome ?? this.nome,
      dosagem: dosagem ?? this.dosagem,
      intervaloHoras: intervaloHoras ?? this.intervaloHoras,
      quantidadePorDose: quantidadePorDose ?? this.quantidadePorDose,
      horarioPrimeiraDose: horarioPrimeiraDose ?? this.horarioPrimeiraDose,
      ativo: ativo ?? this.ativo,
      diasTratamento: diasTratamento ?? this.diasTratamento,
      quantidadeTotal: quantidadeTotal ?? this.quantidadeTotal,
    );
  }
}
