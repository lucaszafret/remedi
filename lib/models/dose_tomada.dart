class DoseTomada {
  final String medicamentoId;
  final DateTime horarioPrevisto;
  final DateTime horarioTomado;

  DoseTomada({
    required this.medicamentoId,
    required this.horarioPrevisto,
    required this.horarioTomado,
  });

  Map<String, dynamic> toMap() {
    return {
      'medicamentoId': medicamentoId,
      'horarioPrevisto': horarioPrevisto.toIso8601String(),
      'horarioTomado': horarioTomado.toIso8601String(),
    };
  }

  factory DoseTomada.fromMap(Map<String, dynamic> map) {
    return DoseTomada(
      medicamentoId: map['medicamentoId'] as String,
      horarioPrevisto: DateTime.parse(map['horarioPrevisto'] as String),
      horarioTomado: DateTime.parse(map['horarioTomado'] as String),
    );
  }

  String get chave => '${medicamentoId}_${horarioPrevisto.millisecondsSinceEpoch}';
}
