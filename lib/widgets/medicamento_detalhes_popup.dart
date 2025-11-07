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
    final ontem = hoje.subtract(const Duration(days: 1));
    final amanha = hoje.add(const Duration(days: 1));
    final depoisAmanha = hoje.add(const Duration(days: 2));

    final dataComparacao = DateTime(data.year, data.month, data.day);

    if (dataComparacao == hoje) {
      return 'Hoje';
    } else if (dataComparacao == ontem) {
      return 'Ontem';
    } else if (dataComparacao == amanha) {
      return 'Amanhã';
    } else if (dataComparacao == depoisAmanha) {
      return 'Depois de amanhã';
    } else {
      // Para datas mais antigas ou futuras, mostrar dia da semana completo
      final diasSemana = ['Domingo', 'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado'];
      final diaSemana = diasSemana[data.weekday % 7];
      return '$diaSemana ${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
    }
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textLight,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppColors.primary,
          size: 14,
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            color: AppColors.text,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textLight,
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
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
        // Obter todas as doses do tratamento (da primeira até a última)
        final todasDoses = medicamento.todasDosesTratamento();

        // Filtrar apenas doses fora do período de tratamento
        final dataFinal = medicamento.dataFinalTratamento();

        final dosesParaMostrar = todasDoses.where((horario) {
          // Se há data final e a dose é depois dela, não mostrar
          if (dataFinal != null && horario.isAfter(dataFinal)) {
            return false;
          }

          // Mostrar todas as outras doses (tomadas, perdidas, futuras)
          return true;
        }).toList();

        return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // HANDLE BAR
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textLight.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // HEADER COMPACTO
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.medication_rounded,
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
                            medicamento.nome,
                            style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${medicamento.dosagem} • A cada ${medicamento.intervaloHoras}h',
                            style: TextStyle(
                              color: AppColors.textLight,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // STATISTICS COMPACTAS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Builder(
              builder: (context) {
                final agora = DateTime.now();
                int tomadas = 0;
                int perdidas = 0;
                int futuras = 0;

                for (var horario in dosesParaMostrar) {
                  if (horario.isBefore(agora)) {
                    if (DoseService().foiTomada(medicamento.id, horario)) {
                      tomadas++;
                    } else {
                      perdidas++;
                    }
                  } else {
                    futuras++;
                  }
                }

                return Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildStatCard(
                      icon: Icons.check_circle_rounded,
                      label: 'tomadas',
                      value: tomadas.toString(),
                      color: const Color(0xFF4CAF50),
                      backgroundColor: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                    ),
                    _buildStatCard(
                      icon: Icons.error_rounded,
                      label: 'perdidas',
                      value: perdidas.toString(),
                      color: AppColors.error,
                      backgroundColor: AppColors.error.withValues(alpha: 0.1),
                    ),
                    _buildStatCard(
                      icon: Icons.schedule_rounded,
                      label: 'futuras',
                      value: futuras.toString(),
                      color: AppColors.primary,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    ),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // TREATMENT INFO COMPACTO
          if (medicamento.diasTratamento != null || medicamento.quantidadeTotal != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    if (medicamento.quantidadeTotal != null) ...[
                      Expanded(
                        child: _buildInfoItem(
                          icon: Icons.inventory_2,
                          label: 'Total',
                          value: '${medicamento.quantidadeTotal}',
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 20,
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                      Expanded(
                        child: _buildInfoItem(
                          icon: Icons.calendar_today,
                          label: 'Duração',
                          value: '~${medicamento.diasPorQuantidade()}d',
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 20,
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                      Expanded(
                        child: _buildInfoItem(
                          icon: Icons.event_available,
                          label: 'Término',
                          value: '${medicamento.dataFinalTratamento()!.day}/${medicamento.dataFinalTratamento()!.month}',
                        ),
                      ),
                    ] else if (medicamento.diasTratamento != null) ...[
                      Expanded(
                        child: _buildInfoItem(
                          icon: Icons.calendar_today,
                          label: 'Duração',
                          value: '${medicamento.diasTratamento}d',
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 20,
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                      Expanded(
                        child: _buildInfoItem(
                          icon: Icons.medication,
                          label: 'Total',
                          value: '${medicamento.totalComprimidosNecessarios()}',
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 20,
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                      Expanded(
                        child: _buildInfoItem(
                          icon: Icons.event_available,
                          label: 'Término',
                          value: '${medicamento.dataFinalTratamento()!.day}/${medicamento.dataFinalTratamento()!.month}',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

          // DOSES LIST COMPACTA
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Histórico de Doses (${dosesParaMostrar.length})',
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: dosesParaMostrar.length,
                    itemBuilder: (context, index) {
                      final horario = dosesParaMostrar[index];
                      final foiTomada = DoseService().foiTomada(medicamento.id, horario);
                      final isPast = horario.isBefore(DateTime.now());
                      final isMissed = isPast && !foiTomada;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: foiTomada
                              ? const Color(0xFF4CAF50).withValues(alpha: 0.08)
                              : isMissed
                                  ? AppColors.error.withValues(alpha: 0.08)
                                  : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: foiTomada
                                ? const Color(0xFF4CAF50).withValues(alpha: 0.3)
                                : isMissed
                                    ? AppColors.error.withValues(alpha: 0.3)
                                    : AppColors.primary.withValues(alpha: 0.15),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              foiTomada
                                  ? Icons.check_circle
                                  : isMissed
                                      ? Icons.error_outline
                                      : Icons.schedule,
                              color: foiTomada
                                  ? const Color(0xFF4CAF50)
                                  : isMissed
                                      ? AppColors.error
                                      : AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        '${horario.hour.toString().padLeft(2, '0')}:${horario.minute.toString().padLeft(2, '0')}',
                                        style: TextStyle(
                                          color: AppColors.text,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _formatarData(horario),
                                        style: TextStyle(
                                          color: AppColors.textLight,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (foiTomada)
                              InkWell(
                                onTap: () => _desmarcarDose(context, horario),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Tomado',
                                    style: TextStyle(
                                      color: Color(0xFF4CAF50),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              )
                            else if (isPast)
                              InkWell(
                                onTap: () => _marcarComoTomada(context, horario),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Marcar',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onEditar,
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    label: const Text('Editar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onRemover,
                    icon: const Icon(Icons.delete_rounded, size: 18),
                    label: const Text('Remover'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(color: AppColors.error, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
        );
      },
    );
  }
}
