import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/medicamento.dart';
import '../services/medicamento_service.dart';
import '../theme.dart';

class AdicionarMedicamentoScreen extends StatefulWidget {
  final Medicamento? medicamento;

  const AdicionarMedicamentoScreen({super.key, this.medicamento});

  @override
  State<AdicionarMedicamentoScreen> createState() =>
      _AdicionarMedicamentoScreenState();
}

class _AdicionarMedicamentoScreenState
    extends State<AdicionarMedicamentoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = MedicamentoService();

  final _nomeController = TextEditingController();
  final _dosagemController = TextEditingController();
  final _intervaloController = TextEditingController();
  final _quantidadeController = TextEditingController();

  TimeOfDay _horarioPrimeiraDose = const TimeOfDay(hour: 8, minute: 0);

  bool get _isEdicao => widget.medicamento != null;

  @override
  void initState() {
    super.initState();
    if (_isEdicao) {
      final med = widget.medicamento!;
      _nomeController.text = med.nome;
      _dosagemController.text = med.dosagem;
      _intervaloController.text = med.intervaloHoras.toString();
      _quantidadeController.text = med.quantidadePorDose.toString();
      _horarioPrimeiraDose = TimeOfDay(
        hour: med.horarioPrimeiraDose.hour,
        minute: med.horarioPrimeiraDose.minute,
      );
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _dosagemController.dispose();
    _intervaloController.dispose();
    _quantidadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdicao ? 'Editar Medicamento' : 'Adicionar Medicamento'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Nome do medicamento
            TextFormField(
              controller: _nomeController,
              decoration: const InputDecoration(
                labelText: 'Nome do medicamento',
                hintText: 'Ex: Paracetamol',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.medication),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Digite o nome do medicamento';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Dosagem
            TextFormField(
              controller: _dosagemController,
              decoration: const InputDecoration(
                labelText: 'Dosagem',
                hintText: 'Ex: 20mg',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.analytics_outlined),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Digite a dosagem';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Intervalo entre doses
            TextFormField(
              controller: _intervaloController,
              decoration: const InputDecoration(
                labelText: 'Intervalo entre doses (horas)',
                hintText: 'Ex: 8',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.access_time),
                suffixText: 'horas',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Digite o intervalo';
                }
                final intervalo = int.tryParse(value);
                if (intervalo == null || intervalo <= 0 || intervalo > 24) {
                  return 'Digite um intervalo válido (1-24)';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Quantidade por dose
            TextFormField(
              controller: _quantidadeController,
              decoration: const InputDecoration(
                labelText: 'Quantidade por dose',
                hintText: 'Ex: 1',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.pin),
                suffixText: 'comprimido(s)',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Digite a quantidade';
                }
                final quantidade = int.tryParse(value);
                if (quantidade == null || quantidade <= 0) {
                  return 'Digite uma quantidade válida';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Horário da primeira dose
            Card(
              child: ListTile(
                leading: const Icon(Icons.schedule),
                title: const Text('Horário da primeira dose'),
                subtitle: Text(
                  '${_horarioPrimeiraDose.hour.toString().padLeft(2, '0')}:${_horarioPrimeiraDose.minute.toString().padLeft(2, '0')}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: _selecionarHorario,
              ),
            ),
            const SizedBox(height: 24),

            // Botão salvar
            FilledButton.icon(
              onPressed: _salvar,
              icon: const Icon(Icons.check),
              label: Text(_isEdicao ? 'Atualizar Medicamento' : 'Salvar Medicamento'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.background,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selecionarHorario() async {
    final horario = await showTimePicker(
      context: context,
      initialTime: _horarioPrimeiraDose,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: AppColors.background,
              dialBackgroundColor: AppColors.primary.withValues(alpha: 0.1),
              hourMinuteColor: AppColors.primary.withValues(alpha: 0.2),
            ),
          ),
          child: child!,
        );
      },
    );

    if (horario != null) {
      setState(() {
        _horarioPrimeiraDose = horario;
      });
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final agora = DateTime.now();
    final horarioPrimeiraDose = DateTime(
      agora.year,
      agora.month,
      agora.day,
      _horarioPrimeiraDose.hour,
      _horarioPrimeiraDose.minute,
    );

    final medicamento = Medicamento(
      id: _isEdicao ? widget.medicamento!.id : DateTime.now().millisecondsSinceEpoch.toString(),
      nome: _nomeController.text,
      dosagem: _dosagemController.text,
      intervaloHoras: int.parse(_intervaloController.text),
      quantidadePorDose: int.parse(_quantidadeController.text),
      horarioPrimeiraDose: horarioPrimeiraDose,
    );

    if (_isEdicao) {
      await _service.atualizar(medicamento);
    } else {
      await _service.adicionar(medicamento);
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEdicao
              ? 'Medicamento atualizado com sucesso!'
              : 'Medicamento adicionado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
