import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/medicamento.dart';
import '../services/medicamento_service.dart';
import '../services/dose_service.dart';
import '../services/notificacao_service.dart';
import '../theme.dart';
import 'adicionar_medicamento_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _service = MedicamentoService();
  final _notificacaoService = NotificacaoService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Medicamentos'),
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Map>('medicamentos').listenable(),
        builder: (context, Box<Map> box, _) {
          final medicamentos = _service.listarTodos();

          if (medicamentos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.medical_services_outlined,
                    size: 80,
                    color: AppColors.textLight,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhum medicamento cadastrado',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: medicamentos.length,
            itemBuilder: (context, index) {
              final medicamento = medicamentos[index];
              return _MedicamentoCard(
                medicamento: medicamento,
                onEdit: () => _editarMedicamento(medicamento),
                onDelete: () => _confirmarExclusao(medicamento),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AdicionarMedicamentoScreen(),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: AppColors.background),
      ),
    );
  }

  void _editarMedicamento(Medicamento medicamento) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdicionarMedicamentoScreen(
          medicamento: medicamento,
        ),
      ),
    );
  }

  Future<void> _confirmarExclusao(Medicamento medicamento) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text('Deseja remover ${medicamento.nome}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      // Cancelar notificações do medicamento
      await _notificacaoService.cancelarNotificacoesMedicamento(medicamento.id);
      // Remover medicamento
      await _service.remover(medicamento.id);
    }
  }
}

class _MedicamentoCard extends StatefulWidget {
  final Medicamento medicamento;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MedicamentoCard({
    required this.medicamento,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_MedicamentoCard> createState() => _MedicamentoCardState();
}

class _MedicamentoCardState extends State<_MedicamentoCard> {
  bool _expandido = false;
  final _doseService = DoseService();

  @override
  Widget build(BuildContext context) {
    final proximaDose = widget.medicamento.proximaDose();
    final foiTomada = proximaDose != null ? _doseService.foiTomada(widget.medicamento.id, proximaDose) : false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => setState(() => _expandido = !_expandido),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho - sempre visível
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.medicamento.nome,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.medicamento.dosagem} • ${widget.medicamento.quantidadePorDose} comprimido(s)',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!_expandido) ...[
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      iconSize: 20,
                      color: AppColors.primary,
                      onPressed: widget.onEdit,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      iconSize: 20,
                      color: AppColors.error,
                      onPressed: widget.onDelete,
                    ),
                  ],
                ],
              ),

              if (!_expandido) ...[
                // Modo compacto - Próxima dose
                const SizedBox(height: 12),
                _ProximaDoseCompacta(
                  proximaDose: proximaDose,
                  foiTomada: foiTomada,
                  onMarcarTomada: () {
                    if (proximaDose != null) {
                      setState(() {
                        if (foiTomada) {
                          _doseService.desmarcarDose(widget.medicamento.id, proximaDose);
                        } else {
                          _doseService.marcarComoTomada(widget.medicamento.id, proximaDose);
                        }
                      });
                    }
                  },
                ),
              ],

              if (_expandido) ...[
                // Modo expandido - Detalhes
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'De ${widget.medicamento.intervaloHoras} em ${widget.medicamento.intervaloHoras} horas',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textLight,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          iconSize: 20,
                          color: AppColors.primary,
                          onPressed: widget.onEdit,
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          iconSize: 20,
                          color: AppColors.error,
                          onPressed: widget.onDelete,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _HorariosProximos3Dias(
                  medicamento: widget.medicamento,
                  doseService: _doseService,
                  onChanged: () => setState(() {}),
                ),
              ],

              // Indicador de expansão
              const SizedBox(height: 8),
              Center(
                child: Icon(
                  _expandido ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: AppColors.textLight,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget para mostrar próxima dose no modo compacto
class _ProximaDoseCompacta extends StatelessWidget {
  final DateTime? proximaDose;
  final bool foiTomada;
  final VoidCallback onMarcarTomada;

  const _ProximaDoseCompacta({
    required this.proximaDose,
    required this.foiTomada,
    required this.onMarcarTomada,
  });

  @override
  Widget build(BuildContext context) {
    if (proximaDose == null) {
      return const SizedBox.shrink();
    }

    final agora = DateTime.now();
    final diferenca = proximaDose!.difference(agora);
    final horarioFormatado = '${proximaDose!.hour.toString().padLeft(2, '0')}:${proximaDose!.minute.toString().padLeft(2, '0')}';

    String tempoRestante;
    if (diferenca.inMinutes < 60) {
      tempoRestante = 'em ${diferenca.inMinutes}min';
    } else if (diferenca.inHours < 24) {
      tempoRestante = 'em ${diferenca.inHours}h';
    } else {
      tempoRestante = 'amanhã';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: foiTomada
            ? AppColors.textLight.withValues(alpha: 0.1)
            : AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            foiTomada ? Icons.check_circle : Icons.schedule,
            color: foiTomada ? AppColors.textLight : AppColors.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  foiTomada ? 'Dose tomada' : 'Próxima dose',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$horarioFormatado ${!foiTomada ? '• $tempoRestante' : ''}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: foiTomada ? AppColors.textLight : AppColors.text,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              foiTomada ? Icons.undo : Icons.check,
              color: foiTomada ? AppColors.textLight : AppColors.primary,
            ),
            onPressed: onMarcarTomada,
          ),
        ],
      ),
    );
  }
}

// Widget para mostrar horários dos próximos 3 dias
class _HorariosProximos3Dias extends StatelessWidget {
  final Medicamento medicamento;
  final DoseService doseService;
  final VoidCallback onChanged;

  const _HorariosProximos3Dias({
    required this.medicamento,
    required this.doseService,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final horariosPorDia = medicamento.horariosProximos3Dias();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: horariosPorDia.entries.map((entry) {
        final dia = entry.key;
        final horarios = entry.value;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dia.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textLight,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              ...horarios.map((horario) {
                final agora = DateTime.now();
                final isPast = horario.isBefore(agora);
                final foiTomada = doseService.foiTomada(medicamento.id, horario);
                final horarioFormatado = '${horario.hour.toString().padLeft(2, '0')}:${horario.minute.toString().padLeft(2, '0')}';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: foiTomada
                              ? Colors.green
                              : isPast
                                  ? AppColors.textLight
                                  : AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          horarioFormatado,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: foiTomada || isPast ? AppColors.textLight : AppColors.text,
                            decoration: foiTomada || isPast ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                      if (foiTomada)
                        Text(
                          'tomado',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textLight,
                            fontStyle: FontStyle.italic,
                          ),
                        )
                      else if (!isPast)
                        IconButton(
                          icon: const Icon(Icons.check_circle_outline),
                          iconSize: 20,
                          color: AppColors.primary,
                          onPressed: () {
                            doseService.marcarComoTomada(medicamento.id, horario);
                            onChanged();
                          },
                        ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      }).toList(),
    );
  }
}
