import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/dose_tomada.dart';
import '../services/medicamento_service.dart';
import '../services/dose_service.dart';
import '../theme.dart';

class HistoricoScreen extends StatelessWidget {
  const HistoricoScreen({super.key});

  String _formatarData(DateTime data) {
    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);
    final ontem = hoje.subtract(const Duration(days: 1));
    final dataComparacao = DateTime(data.year, data.month, data.day);

    if (dataComparacao == hoje) {
      return 'Hoje';
    } else if (dataComparacao == ontem) {
      return 'Ontem';
    } else {
      final diasAtras = hoje.difference(dataComparacao).inDays;
      if (diasAtras < 7) {
        return 'Há $diasAtras dias';
      } else {
        return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Map>('doses_tomadas').listenable(),
        builder: (context, box, _) {
          final dosesTomadas = DoseService().obterDosesTomadas();

          if (dosesTomadas.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 80,
                    color: AppColors.textLight.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhuma dose tomada ainda',
                    style: TextStyle(
                      color: AppColors.textLight,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          dosesTomadas.sort((a, b) => b.horarioTomado.compareTo(a.horarioTomado));

          final dosesAgrupadas = <String, List<DoseTomada>>{};
          for (final dose in dosesTomadas) {
            final dataKey = _formatarData(dose.horarioTomado);
            dosesAgrupadas.putIfAbsent(dataKey, () => []).add(dose);
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 16),
            itemCount: dosesAgrupadas.length,
            itemBuilder: (context, index) {
              final grupo = dosesAgrupadas.keys.elementAt(index);
              final doses = dosesAgrupadas[grupo]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Text(
                      grupo,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ...doses.map((dose) {
                    final medicamento = MedicamentoService().buscarPorId(dose.medicamentoId);
                    if (medicamento == null) return const SizedBox.shrink();

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  medicamento.nome,
                                  style: const TextStyle(
                                    color: AppColors.text,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  medicamento.dosagem,
                                  style: const TextStyle(
                                    color: AppColors.textLight,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${dose.horarioTomado.hour.toString().padLeft(2, '0')}:${dose.horarioTomado.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                  color: AppColors.text,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Tomado',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
