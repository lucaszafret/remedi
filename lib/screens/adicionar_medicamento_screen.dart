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
  final _diasTratamentoController = TextEditingController();
  final _quantidadeTotalController = TextEditingController();

  DateTime _dataHoraInicio = DateTime.now();
  String _tipoDuracao = 'continuo'; // 'continuo', 'dias', 'quantidade'

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
      _dataHoraInicio = med.horarioPrimeiraDose;

      // Carregar duração do tratamento
      if (med.diasTratamento != null) {
        _tipoDuracao = 'dias';
        _diasTratamentoController.text = med.diasTratamento.toString();
      } else if (med.quantidadeTotal != null) {
        _tipoDuracao = 'quantidade';
        _quantidadeTotalController.text = med.quantidadeTotal.toString();
      } else {
        _tipoDuracao = 'continuo';
      }
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _dosagemController.dispose();
    _intervaloController.dispose();
    _quantidadeController.dispose();
    _diasTratamentoController.dispose();
    _quantidadeTotalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (_isEdicao)
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Editar Medicamento',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                ],
              ),
            ),

          // SECTION: INFORMAÇÕES BÁSICAS
          _buildSectionTitle('Informações Básicas', Icons.info_outline),
          const SizedBox(height: 12),
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
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildTextField(
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
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _quantidadeController,
                  label: 'Qtd/dose',
                  hint: 'Ex: 1',
                  icon: Icons.format_list_numbered,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Digite';
                    }
                    final quantidade = int.tryParse(value);
                    if (quantidade == null || quantidade <= 0) {
                      return 'Inválido';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _intervaloController,
            label: 'Intervalo entre doses (horas)',
            hint: 'Ex: 8 (de 8 em 8 horas)',
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

          const SizedBox(height: 32),

          // SECTION: INÍCIO DO TRATAMENTO
          _buildSectionTitle('Início do Tratamento', Icons.event_available),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                InkWell(
                  onTap: _selecionarData,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.calendar_month,
                            color: AppColors.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Data de início',
                                style: TextStyle(
                                  color: AppColors.textLight,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_dataHoraInicio.day.toString().padLeft(2, '0')}/${_dataHoraInicio.month.toString().padLeft(2, '0')}/${_dataHoraInicio.year}',
                                style: const TextStyle(
                                  color: AppColors.text,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: AppColors.textLight,
                        ),
                      ],
                    ),
                  ),
                ),
                Divider(height: 1, color: AppColors.textLight.withValues(alpha: 0.1)),
                InkWell(
                  onTap: _selecionarHorario,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.access_time,
                            color: AppColors.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Horário da primeira dose',
                                style: TextStyle(
                                  color: AppColors.textLight,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_dataHoraInicio.hour.toString().padLeft(2, '0')}:${_dataHoraInicio.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                  color: AppColors.text,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: AppColors.textLight,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // SECTION: DURAÇÃO DO TRATAMENTO
          _buildSectionTitle('Duração do Tratamento', Icons.timeline),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
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
                    Expanded(
                      child: _buildDurationChip(
                        label: 'Contínuo',
                        icon: Icons.all_inclusive,
                        isSelected: _tipoDuracao == 'continuo',
                        onTap: () {
                          setState(() {
                            _tipoDuracao = 'continuo';
                            _diasTratamentoController.clear();
                            _quantidadeTotalController.clear();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDurationChip(
                        label: 'Dias',
                        icon: Icons.event,
                        isSelected: _tipoDuracao == 'dias',
                        onTap: () {
                          setState(() {
                            _tipoDuracao = 'dias';
                            _quantidadeTotalController.clear();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDurationChip(
                        label: 'Qtd',
                        icon: Icons.inventory_2,
                        isSelected: _tipoDuracao == 'quantidade',
                        onTap: () {
                          setState(() {
                            _tipoDuracao = 'quantidade';
                            _diasTratamentoController.clear();
                          });
                        },
                      ),
                    ),
                  ],
                ),
                if (_tipoDuracao == 'dias') ...[
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _diasTratamentoController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Quantos dias de tratamento?',
                      hintText: 'Ex: 7',
                      prefixIcon: Icon(Icons.event, color: AppColors.primary),
                      filled: true,
                      fillColor: AppColors.primary.withValues(alpha: 0.05),
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
                      labelStyle: const TextStyle(color: AppColors.textLight),
                      hintStyle: TextStyle(color: AppColors.textLight.withValues(alpha: 0.5)),
                    ),
                    validator: (value) {
                      if (_tipoDuracao == 'dias' && (value == null || value.isEmpty)) {
                        return 'Digite os dias de tratamento';
                      }
                      if (_tipoDuracao == 'dias') {
                        final dias = int.tryParse(value!);
                        if (dias == null || dias <= 0) {
                          return 'Digite um número válido de dias';
                        }
                      }
                      return null;
                    },
                    onChanged: (value) {
                      if (value.isNotEmpty && _intervaloController.text.isNotEmpty && _quantidadeController.text.isNotEmpty) {
                        _calcularQuantidadePorDias();
                      }
                    },
                  ),
                  if (_diasTratamentoController.text.isNotEmpty && _intervaloController.text.isNotEmpty && _quantidadeController.text.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: AppColors.primary, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _getTextoCalculoDias(),
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
                if (_tipoDuracao == 'quantidade') ...[
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _quantidadeTotalController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Quantidade total de comprimidos',
                      hintText: 'Ex: 30',
                      prefixIcon: Icon(Icons.inventory_2, color: AppColors.primary),
                      filled: true,
                      fillColor: AppColors.primary.withValues(alpha: 0.05),
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
                      labelStyle: const TextStyle(color: AppColors.textLight),
                      hintStyle: TextStyle(color: AppColors.textLight.withValues(alpha: 0.5)),
                    ),
                    validator: (value) {
                      if (_tipoDuracao == 'quantidade' && (value == null || value.isEmpty)) {
                        return 'Digite a quantidade total';
                      }
                      if (_tipoDuracao == 'quantidade') {
                        final quantidade = int.tryParse(value!);
                        if (quantidade == null || quantidade <= 0) {
                          return 'Digite uma quantidade válida';
                        }
                      }
                      return null;
                    },
                    onChanged: (value) {
                      if (value.isNotEmpty && _intervaloController.text.isNotEmpty && _quantidadeController.text.isNotEmpty) {
                        _calcularDiasPorQuantidade();
                      }
                    },
                  ),
                  if (_quantidadeTotalController.text.isNotEmpty && _intervaloController.text.isNotEmpty && _quantidadeController.text.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: AppColors.primary, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _getTextoCalculoQuantidade(),
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _salvar,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
              shadowColor: AppColors.primary.withValues(alpha: 0.3),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_isEdicao ? Icons.check_circle : Icons.add_circle, size: 22),
                const SizedBox(width: 8),
                Text(
                  _isEdicao ? 'Atualizar Medicamento' : 'Adicionar Medicamento',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
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

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildDurationChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppColors.primary,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
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
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primary),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.textLight.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.textLight.withValues(alpha: 0.2)),
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
        labelStyle: TextStyle(color: AppColors.textLight, fontSize: 14),
        hintStyle: TextStyle(color: AppColors.textLight.withValues(alpha: 0.5)),
      ),
      validator: validator,
    );
  }

  void _calcularQuantidadePorDias() {
    setState(() {});
  }

  void _calcularDiasPorQuantidade() {
    setState(() {});
  }

  String _getTextoCalculoDias() {
    final dias = int.tryParse(_diasTratamentoController.text);
    final intervalo = int.tryParse(_intervaloController.text);
    final quantidadePorDose = int.tryParse(_quantidadeController.text);

    if (dias == null || intervalo == null || quantidadePorDose == null) {
      return '';
    }

    final dosesHorasPorDia = 24 / intervalo;
    final totalDoses = (dias * dosesHorasPorDia).ceil();
    final totalComprimidos = totalDoses * quantidadePorDose;

    return '📊 Total necessário: $totalComprimidos comprimidos ($totalDoses doses)';
  }

  String _getTextoCalculoQuantidade() {
    final quantidadeTotal = int.tryParse(_quantidadeTotalController.text);
    final intervalo = int.tryParse(_intervaloController.text);
    final quantidadePorDose = int.tryParse(_quantidadeController.text);

    if (quantidadeTotal == null || intervalo == null || quantidadePorDose == null) {
      return '';
    }

    final dosesHorasPorDia = 24 / intervalo;
    final totalDoses = quantidadeTotal / quantidadePorDose;
    final dias = (totalDoses / dosesHorasPorDia).ceil();

    return '📊 Duração: aproximadamente $dias dias';
  }

  Future<void> _selecionarData() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _dataHoraInicio,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.background,
            ),
          ),
          child: child!,
        );
      },
    );

    if (data != null) {
      setState(() {
        _dataHoraInicio = DateTime(
          data.year,
          data.month,
          data.day,
          _dataHoraInicio.hour,
          _dataHoraInicio.minute,
        );
      });
    }
  }

  Future<void> _selecionarHorario() async {
    final horario = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _dataHoraInicio.hour, minute: _dataHoraInicio.minute),
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
        _dataHoraInicio = DateTime(
          _dataHoraInicio.year,
          _dataHoraInicio.month,
          _dataHoraInicio.day,
          horario.hour,
          horario.minute,
        );
      });
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Determinar valores de duração baseado no tipo selecionado
    int? diasTratamento;
    int? quantidadeTotal;

    if (_tipoDuracao == 'dias') {
      diasTratamento = int.parse(_diasTratamentoController.text);
    } else if (_tipoDuracao == 'quantidade') {
      quantidadeTotal = int.parse(_quantidadeTotalController.text);
    }

    final medicamento = Medicamento(
      id: _isEdicao ? widget.medicamento!.id : DateTime.now().millisecondsSinceEpoch.toString(),
      nome: _nomeController.text,
      dosagem: _dosagemController.text,
      intervaloHoras: int.parse(_intervaloController.text),
      quantidadePorDose: int.parse(_quantidadeController.text),
      horarioPrimeiraDose: _dataHoraInicio,
      diasTratamento: diasTratamento,
      quantidadeTotal: quantidadeTotal,
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
        _diasTratamentoController.clear();
        _quantidadeTotalController.clear();
        setState(() {
          _dataHoraInicio = DateTime.now();
          _tipoDuracao = 'continuo';
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
