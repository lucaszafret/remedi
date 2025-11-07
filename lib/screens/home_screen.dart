import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/medicamento_service.dart';
import '../theme.dart';
import '../services/dose_service.dart';
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
  Timer? _minuteTimer;

  @override
  void initState() {
    super.initState();
    _startMinuteTimer();
  }

  void _startMinuteTimer() {
    // Cancela qualquer timer anterior
    _minuteTimer?.cancel();

    // Agendar o primeiro disparo exatamente no próximo limite de minuto
    final now = DateTime.now();
    final nextMinute = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute,
    ).add(const Duration(minutes: 1));
    final firstDelay = nextMinute.difference(now);

    // Primeiro timer único para alinhar ao início do minuto, depois periodic
    _minuteTimer = Timer(firstDelay, () {
      if (!mounted) return;
      setState(() {});
      _minuteTimer = Timer.periodic(const Duration(minutes: 1), (_) {
        if (!mounted) return;
        setState(() {});
      });
    });
  }

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
                  style: TextStyle(fontSize: 16, color: AppColors.textLight),
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

        // Calcular notificações: próximas (<=14min) e perdidas (>30min)
        final now = DateTime.now();
        final doseService = DoseService();
        final upcoming =
            <
              Map<String, dynamic>
            >[]; // {'med': Medicamento, 'horario': DateTime}
        final missed = <Map<String, dynamic>>[];

        for (final med in medicamentos) {
          // Buscar horários de hoje E de amanhã (para cobrir virada de dia)
          final horariosHoje = med.horariosDodia();
          final horariosAmanha = med.horariosAmanha();
          final todosHorarios = [...horariosHoje, ...horariosAmanha];

          for (final horario in todosHorarios) {
            // Ignora se já foi tomada
            if (doseService.foiTomada(med.id, horario)) continue;

            final diffMinutes = horario.difference(now).inMinutes;

            if (diffMinutes >= 0 && diffMinutes <= 14) {
              upcoming.add({'med': med, 'horario': horario});
            } else if (diffMinutes < 0 &&
                now.difference(horario).inMinutes <= 30) {
              missed.add({'med': med, 'horario': horario});
            }
          }
        }

        Widget buildBanner() {
          if (upcoming.isEmpty && missed.isEmpty)
            return const SizedBox.shrink();

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.notifications,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Notificações',
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                if (missed.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ...missed.map((item) {
                    final med = item['med'];
                    final horario = item['horario'] as DateTime;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  med.nome,
                                  style: const TextStyle(
                                    color: AppColors.text,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${horario.hour.toString().padLeft(2, '0')}:${horario.minute.toString().padLeft(2, '0')} • Atrasado',
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              await doseService.marcarComoTomada(
                                med.id,
                                horario,
                              );
                              if (context.mounted) {
                                setState(() {});
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Dose marcada como tomada'),
                                    backgroundColor: Colors.green,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Tomar',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
                if (upcoming.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ...upcoming.map((item) {
                    final med = item['med'];
                    final horario = item['horario'] as DateTime;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.schedule,
                              color: AppColors.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  med.nome,
                                  style: const TextStyle(
                                    color: AppColors.text,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${horario.hour.toString().padLeft(2, '0')}:${horario.minute.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    color: AppColors.textLight,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              await doseService.marcarComoTomada(
                                med.id,
                                horario,
                              );
                              if (context.mounted) {
                                setState(() {});
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Dose marcada como tomada'),
                                    backgroundColor: Colors.green,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Tomar',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ],
            ),
          );
        }

        // Construir lista com banner no topo seguido pelos cartões de medicamento
        final children = <Widget>[];
        final banner = buildBanner();
        if (banner is! SizedBox) children.add(banner);
        children.addAll(
          medicamentos.map((med) => MedicamentoCard(medicamento: med)),
        );

        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: children,
        );
      },
    );
  }

  @override
  void dispose() {
    _minuteTimer?.cancel();
    super.dispose();
  }
}
