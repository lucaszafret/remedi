import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/medicamento_service.dart';
import '../theme.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../widgets/medicamento_card.dart';
import 'adicionar_medicamento_screen.dart';
import 'historico_screen.dart';
import 'configuracoes_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _service = MedicamentoService();
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(),
      body: _buildBody(),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildMedicamentosLista();
      case 1:
        return AdicionarMedicamentoScreen(
          onSaved: () {
            // Volta para a tela inicial após salvar
            setState(() {
              _currentIndex = 0;
            });
          },
        );
      case 2:
        return const HistoricoScreen();
      case 3:
        return const ConfiguracoesScreen();
      default:
        return _buildMedicamentosLista();
    }
  }

  Widget _buildMedicamentosLista() {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Map>('medicamentos').listenable(),
      builder: (context, Box<Map> box, _) {
        final medicamentos = _service.listarTodos();

        if (medicamentos.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.medication_outlined,
                  size: 80,
                  color: AppColors.textLight.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'Nenhum medicamento cadastrado',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textLight,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Toque no + para adicionar',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textLight.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: medicamentos.length,
          itemBuilder: (context, index) {
            final medicamento = medicamentos[index];
            return MedicamentoCard(medicamento: medicamento);
          },
        );
      },
    );
  }
}
