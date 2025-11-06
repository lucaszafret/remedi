import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/medicamento.dart';
import '../services/medicamento_service.dart';
import '../services/notificacao_service.dart';
import '../theme.dart';

class AdicionarMedicamentoScreen extends StatefulWidget {
  final Medicamento? medicamento;
  final VoidCallback? onSaved;

  const AdicionarMedicamentoScreen({
    super.key,
    this.medicamento,
    this.onSaved,
  });

  @override
  State<AdicionarMedicamentoScreen> createState() =>
      _AdicionarMedicamentoScreenState();
}

class _AdicionarMedicamentoScreenState
    extends State<AdicionarMedicamentoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = MedicamentoService();
  final _notificacaoService = NotificacaoService();

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
    final content = Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (_isEdicao)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Editar Medicamento',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          _buildTextField(
            controller: _nomeController,
            label: 'Nome do medicamento',
            hint: 'Ex: Paracetamol',
            icon: Icons.medication,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Digite o nome do medicamento';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _dosagemController,
            label: 'Dosagem',
            hint: 'Ex: 500mg',
            icon: Icons.local_pharmacy,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Digite a dosagem';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _intervaloController,
            label: 'Intervalo entre doses (horas)',
            hint: 'Ex: 8',
            icon: Icons.access_time,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Digite o intervalo';
              }
              final intervalo = int.tryParse(value);
              if (intervalo == null || intervalo <= 0 || intervalo > 24) {
                return 'Digite um intervalo entre 1 e 24 horas';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _quantidadeController,
            label: 'Quantidade por dose',
            hint: 'Ex: 1',
            icon: Icons.format_list_numbered,
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
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Horário da primeira dose',
                      style: const TextStyle(
                        color: AppColors.textLight,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _selecionarHorario,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_horarioPrimeiraDose.hour.toString().padLeft(2, '0')}:${_horarioPrimeiraDose.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _salvar,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              _isEdicao ? 'Atualizar Medicamento' : 'Adicionar Medicamento',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    // Se for edição, mostra como rota com AppBar
    if (_isEdicao) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(child: content),
      );
    }

    // Se não for edição, mostra apenas o conteúdo (vai estar dentro do HomeScreen)
    return content;
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: const TextStyle(
        color: AppColors.text,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primary),
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        labelStyle: const TextStyle(color: AppColors.textLight),
        hintStyle: TextStyle(color: AppColors.textLight.withValues(alpha: 0.5)),
      ),
      validator: validator,
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

    await _notificacaoService.agendarNotificacoesMedicamento(medicamento);

    if (mounted) {
      // Se for edição, volta para tela anterior
      if (_isEdicao) {
        Navigator.pop(context, true);
      } else {
        // Se não for edição, limpa o formulário e chama callback
        _nomeController.clear();
        _dosagemController.clear();
        _intervaloController.clear();
        _quantidadeController.clear();
        setState(() {
          _horarioPrimeiraDose = const TimeOfDay(hour: 8, minute: 0);
        });

        widget.onSaved?.call();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEdicao
              ? 'Medicamento atualizado!'
              : 'Medicamento adicionado!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
