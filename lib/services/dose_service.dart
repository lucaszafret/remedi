import 'package:hive_flutter/hive_flutter.dart';
import '../models/dose_tomada.dart';

class DoseService {
  static const String _boxName = 'doses_tomadas';

  Box<Map> get _box => Hive.box<Map>(_boxName);

  // Marcar dose como tomada
  Future<void> marcarComoTomada(String medicamentoId, DateTime horarioPrevisto) async {
    final dose = DoseTomada(
      medicamentoId: medicamentoId,
      horarioPrevisto: horarioPrevisto,
      horarioTomado: DateTime.now(),
    );
    await _box.put(dose.chave, dose.toMap());
  }

  // Verificar se dose foi tomada
  bool foiTomada(String medicamentoId, DateTime horarioPrevisto) {
    final chave = '${medicamentoId}_${horarioPrevisto.millisecondsSinceEpoch}';
    return _box.containsKey(chave);
  }

  // Desmarcar dose
  Future<void> desmarcarDose(String medicamentoId, DateTime horarioPrevisto) async {
    final chave = '${medicamentoId}_${horarioPrevisto.millisecondsSinceEpoch}';
    await _box.delete(chave);
  }

  // Obter todas as doses tomadas de um medicamento
  List<DoseTomada> obterDosesTomadas([String? medicamentoId]) {
    final doses = _box.values
        .map((map) => DoseTomada.fromMap(Map<String, dynamic>.from(map)))
        .toList();

    if (medicamentoId != null) {
      return doses.where((dose) => dose.medicamentoId == medicamentoId).toList();
    }

    return doses;
  }
}
