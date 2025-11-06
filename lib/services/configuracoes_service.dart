import 'package:hive_flutter/hive_flutter.dart';
import '../models/configuracoes.dart';

class ConfiguracoesService {
  static const String _boxName = 'configuracoes';
  static const String _key = 'app_config';

  Future<Box<Map>> _getBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      return await Hive.openBox<Map>(_boxName);
    }
    return Hive.box<Map>(_boxName);
  }

  Future<Configuracoes> obterConfiguracoes() async {
    final box = await _getBox();
    final map = box.get(_key);

    if (map == null) {
      return Configuracoes();
    }

    return Configuracoes.fromMap(Map<String, dynamic>.from(map));
  }

  Future<void> salvarConfiguracoes(Configuracoes config) async {
    final box = await _getBox();
    await box.put(_key, config.toMap());
  }
}
