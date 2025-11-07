import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/medicamento_service.dart';
import '../services/dose_service.dart';
import '../theme.dart';
import '../models/medicamento.dart';

class ArquivadosScreen extends StatelessWidget {
  const ArquivadosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = MedicamentoService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Arquivados'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      backgroundColor: AppColors.background,
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Map>('medicamentos').listenable(),
        builder: (context, Box<Map> box, _) {
          final meds = box.values
              .map((m) => Medicamento.fromMap(Map<String, dynamic>.from(m)))
              .where((m) => !m.ativo)
              .toList();

          if (meds.isEmpty) {
            return Center(
              child: Text(
                'Nenhum medicamento arquivado',
                style: TextStyle(color: AppColors.textLight),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: meds.length,
            itemBuilder: (context, index) {
              final med = meds[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                            med.nome,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            med.dosagem,
                            style: TextStyle(color: AppColors.textLight),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        // Restaurar
                        final restored = med.copyWith(ativo: true);
                        await service.atualizar(restored);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Medicamento restaurado'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                      child: const Text('Restaurar'),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () async {
                        final confirmar = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Excluir permanentemente'),
                            content: Text(
                              'Deseja excluir ${med.nome} e seu histórico? Esta ação não pode ser desfeita.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancelar'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.error,
                                ),
                                child: const Text('Excluir'),
                              ),
                            ],
                          ),
                        );

                        if (confirmar == true) {
                          await DoseService().deletarHistoricoMedicamento(
                            med.id,
                          );
                          await service.deletar(med.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Medicamento e histórico excluídos',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      child: const Text(
                        'Excluir',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
