import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/medicamento.dart';
import '../services/dose_service.dart';
import '../services/medicamento_service.dart';
import '../services/notificacao_service.dart';
import '../theme.dart';
import '../screens/adicionar_medicamento_screen.dart';
import 'medicamento_detalhes_popup.dart';

class MedicamentoCard extends StatelessWidget {
  final Medicamento medicamento;

  const MedicamentoCard({super.key, required this.medicamento});

  String _formatarTempo(Duration duracao) {
    if (duracao.isNegative) {
      return 'Atrasado';
    }

    final horas = duracao.inHours;
    final minutos = duracao.inMinutes.remainder(60);

    if (horas > 0) {
      return 'em ${horas}h ${minutos}min';
    } else {
      return 'em ${minutos}min';
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
          content: const Text('Dose desmarcada - toque novamente para marcar'),
          backgroundColor: AppColors.textLight,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _editarMedicamento(BuildContext context) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AdicionarMedicamentoScreen(medicamento: medicamento),
      ),
    );

    if (resultado == true && context.mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _removerMedicamento(BuildContext context) async {
    // Mostrar opções: desativar (manter histórico) ou excluir completamente (remover histórico)
    final escolha = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.warning_outlined,
                color: Colors.orange,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Remover medicamento',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'O que deseja fazer com ${medicamento.nome}?',
              style: const TextStyle(color: AppColors.text, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Arquivar mantém o histórico de doses tomadas',
                      style: TextStyle(color: AppColors.text, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: AppColors.textLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => Navigator.pop(context, 'desativar'),
            icon: const Icon(Icons.archive_outlined, size: 18),
            label: const Text('Arquivar'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, 'deletar'),
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Excluir tudo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );

    if (escolha == null) return; // Cancelado

    // Cancelar notificações sempre
    await NotificacaoService().cancelarNotificacoesMedicamento(medicamento.id);

    if (escolha == 'desativar') {
      // Marcar como inativo (manter histórico)
      await MedicamentoService().remover(medicamento.id);
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Medicamento marcado como finalizado. Histórico mantido.',
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else if (escolha == 'deletar') {
      // Deletar histórico e o medicamento
      await DoseService().deletarHistoricoMedicamento(medicamento.id);
      await MedicamentoService().deletar(medicamento.id);
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Medicamento e histórico removidos'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _mostrarDetalhes(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MedicamentoDetalhesPopup(
        medicamento: medicamento,
        onEditar: () => _editarMedicamento(context),
        onRemover: () => _removerMedicamento(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Map>('doses_tomadas').listenable(),
      builder: (context, box, _) {
        final proximaDose = medicamento.proximaDose();
        final tempoRestante = proximaDose?.difference(DateTime.now());
        final foiTomada =
            proximaDose != null &&
            DoseService().foiTomada(medicamento.id, proximaDose);

        return GestureDetector(
          onTap: () => _mostrarDetalhes(context),
          child: Container(
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
                        Icons.medication,
                        color: AppColors.primary,
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
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${medicamento.dosagem} • ${medicamento.quantidadePorDose}x por dose',
                            style: const TextStyle(
                              color: AppColors.textLight,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: AppColors.textLight),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Próxima dose',
                              style: TextStyle(
                                color: AppColors.textLight,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (proximaDose != null) ...[
                              Text(
                                '${proximaDose.hour.toString().padLeft(2, '0')}:${proximaDose.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                  color: AppColors.text,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (tempoRestante != null)
                                Text(
                                  _formatarTempo(tempoRestante),
                                  style: TextStyle(
                                    color: tempoRestante.isNegative
                                        ? AppColors.error
                                        : AppColors.textLight,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                      if (proximaDose != null && !foiTomada)
                        ElevatedButton(
                          onPressed: () =>
                              _marcarComoTomada(context, proximaDose),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Tomei',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        )
                      else if (foiTomada)
                        GestureDetector(
                          onTap: () => _desmarcarDose(context, proximaDose),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Tomado',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
