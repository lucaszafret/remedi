import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'theme.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Hive
  await Hive.initFlutter();

  // Abrir a box de medicamentos
  await Hive.openBox<Map>('medicamentos');

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Remedi',
      theme: AppTheme.theme,
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}
