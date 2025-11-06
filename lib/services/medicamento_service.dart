import 'package:hive_flutter/hive_flutter.dart';
import '../models/medicamento.dart';

class MedicamentoService {
  static const String _boxName = 'medicamentos';

  // Obter a box do Hive
  Box<Map> get _box => Hive.box<Map>(_boxName);

  // Listar todos os medicamentos ativos
  List<Medicamento> listarTodos() {
    return _box.values
        .map((map) => Medicamento.fromMap(Map<String, dynamic>.from(map)))
        .where((med) => med.ativo)
        .toList();
  }

  // Adicionar novo medicamento
  Future<void> adicionar(Medicamento medicamento) async {
    await _box.put(medicamento.id, medicamento.toMap());
  }

  // Atualizar medicamento existente
  Future<void> atualizar(Medicamento medicamento) async {
    await _box.put(medicamento.id, medicamento.toMap());
  }

  // Remover medicamento (marca como inativo)
  Future<void> remover(String id) async {
    final map = _box.get(id);
    if (map != null) {
      final medicamento = Medicamento.fromMap(Map<String, dynamic>.from(map));
      await _box.put(id, medicamento.copyWith(ativo: false).toMap());
    }
  }

  // Deletar permanentemente
  Future<void> deletar(String id) async {
    await _box.delete(id);
  }

  // Buscar medicamento por ID
  Medicamento? buscarPorId(String id) {
    final map = _box.get(id);
    if (map != null) {
      return Medicamento.fromMap(Map<String, dynamic>.from(map));
    }
    return null;
  }

  // Stream para observar mudanças
  Stream<List<Medicamento>> observarMedicamentos() {
    return _box.watch().map((_) => listarTodos());
  }
}
