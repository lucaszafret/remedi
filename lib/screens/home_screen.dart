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

        // Calcular notificações: próximas (<=30min) e perdidas (>30min)
        final now = DateTime.now();
        final doseService = DoseService();
        final upcoming =
            <
              Map<String, dynamic>
            >[]; // {'med': Medicamento, 'horario': DateTime}
        final missed = <Map<String, dynamic>>[];

        for (final med in medicamentos) {
          final horarios = med.horariosDodia();
          for (final horario in horarios) {
            // Ignora se já foi tomada
            if (doseService.foiTomada(med.id, horario)) continue;

            final diffMinutes = horario.difference(now).inMinutes;
            if (diffMinutes >= 0 && diffMinutes <= 30) {
              upcoming.add({'med': med, 'horario': horario});
            } else if (diffMinutes < 0 &&
                now.difference(horario).inMinutes >= 30) {
              missed.add({'med': med, 'horario': horario});
            }
          }
        }

        Widget buildBanner() {
          if (upcoming.isEmpty && missed.isEmpty)
            return const SizedBox.shrink();

          return Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.notifications, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Notificações',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (missed.isNotEmpty) ...[
                  Text(
                    '${missed.length} dose(s) perdida(s)',
                    style: TextStyle(color: AppColors.text),
                  ),
                  const SizedBox(height: 6),
                  ...missed.map((item) {
                    final med = item['med'];
                    final horario = item['horario'] as DateTime;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.error_outline,
                        color: Colors.redAccent,
                      ),
                      title: Text(
                        med.nome,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${horario.hour.toString().padLeft(2, '0')}:${horario.minute.toString().padLeft(2, '0')} — Atrasado',
                      ),
                      trailing: ElevatedButton(
                        onPressed: () async {
                          await doseService.marcarComoTomada(med.id, horario);
                          if (context.mounted) {
                            setState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Dose marcada como tomada'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                        child: const Text('Tomar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                        ),
                      ),
                    );
                  }).toList(),
                  const Divider(),
                ],
                if (upcoming.isNotEmpty) ...[
                  Text(
                    '${upcoming.length} dose(s) para os próximos 30 minutos',
                    style: TextStyle(color: AppColors.text),
                  ),
                  const SizedBox(height: 6),
                  ...upcoming.map((item) {
                    final med = item['med'];
                    final horario = item['horario'] as DateTime;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.schedule, color: AppColors.primary),
                      title: Text(
                        med.nome,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${horario.hour.toString().padLeft(2, '0')}:${horario.minute.toString().padLeft(2, '0')}',
                      ),
                      trailing: ElevatedButton(
                        onPressed: () async {
                          await doseService.marcarComoTomada(med.id, horario);
                          if (context.mounted) {
                            setState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Dose marcada como tomada'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                        child: const Text('Tomar'),
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
