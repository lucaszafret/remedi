import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/medicamento.dart';
import '../services/dose_service.dart';
import '../theme.dart';

class MedicamentoDetalhesPopup extends StatelessWidget {
  final Medicamento medicamento;
  final VoidCallback onEditar;
  final VoidCallback onRemover;

  const MedicamentoDetalhesPopup({
    super.key,
    required this.medicamento,
    required this.onEditar,
    required this.onRemover,
  });

  String _formatarData(DateTime data) {
    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);
    final amanha = hoje.add(const Duration(days: 1));
    final depoisAmanha = hoje.add(const Duration(days: 2));

    final dataComparacao = DateTime(data.year, data.month, data.day);

    if (dataComparacao == hoje) {
      return 'Hoje';
    } else if (dataComparacao == amanha) {
      return 'Amanhã';
    } else if (dataComparacao == depoisAmanha) {
      return 'Depois de amanhã';
    } else {
      return '${data.day}/${data.month}';
    }
  }

  Future<void> _marcarComoTomada(BuildContext context, DateTime horario) async {
    await DoseService().marcarComoTomada(medicamento.id, horario);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Dose marcada como tomada'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _desmarcarDose(BuildContext context, DateTime horario) async {
    await DoseService().desmarcarDose(medicamento.id, horario);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Dose desmarcada'),
          backgroundColor: AppColors.textLight,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Map>('doses_tomadas').listenable(),
      builder: (context, box, _) {
        final horariosMap = medicamento.horariosProximos3Dias();
        final todasDoses = <DateTime>[];
        horariosMap.forEach((_, doses) => todasDoses.addAll(doses));
        todasDoses.sort();

        // Filtrar doses: remover doses passadas que já foram tomadas
        final agora = DateTime.now();
        final dosesParaMostrar = todasDoses.where((horario) {
          final isPast = horario.isBefore(agora);
          final foiTomada = DoseService().foiTomada(medicamento.id, horario);

          // Se é passado e foi tomada, não mostrar
          if (isPast && foiTomada) {
            return false;
          }

          // Mostrar todos os outros casos:
          // - Doses futuras (tomadas ou não)
          // - Doses passadas que NÃO foram tomadas (perdidas)
          return true;
        }).toList();

        return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textLight.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.medication,
                    color: AppColors.primary,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medicamento.nome,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${medicamento.dosagem} • A cada ${medicamento.intervaloHoras}h',
                        style: const TextStyle(
                          color: AppColors.textLight,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Próximas doses',
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: dosesParaMostrar.length,
                    itemBuilder: (context, index) {
                      final horario = dosesParaMostrar[index];
                      final foiTomada = DoseService().foiTomada(medicamento.id, horario);
                      final isPast = horario.isBefore(DateTime.now());
                      final isMissed = isPast && !foiTomada;

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: foiTomada
                                    ? Colors.green
                                    : isPast
                                        ? AppColors.error
                                        : AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _formatarData(horario),
                                    style: const TextStyle(
                                      color: AppColors.textLight,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    '${horario.hour.toString().padLeft(2, '0')}:${horario.minute.toString().padLeft(2, '0')}',
                                    style: TextStyle(
                                      color: AppColors.text,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      decoration: foiTomada && isPast ? TextDecoration.lineThrough : null,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (foiTomada)
                              GestureDetector(
                                onTap: () => _desmarcarDose(context, horario),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Tomado',
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else if (isMissed)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.error.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.error_outline,
                                          color: AppColors.error,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Perdido',
                                          style: TextStyle(
                                            color: AppColors.error,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: () => _marcarComoTomada(context, horario),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      minimumSize: Size.zero,
                                    ),
                                    child: const Text(
                                      'Marcar',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            else
                              ElevatedButton(
                                onPressed: () => _marcarComoTomada(context, horario),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  minimumSize: Size.zero,
                                ),
                                child: const Text(
                                  'Marcar',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEditar,
                    icon: const Icon(Icons.edit),
                    label: const Text('Editar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onRemover,
                    icon: const Icon(Icons.delete),
                    label: const Text('Remover'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
        );
      },
    );
  }
}
