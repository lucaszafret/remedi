import 'package:flutter/material.dart';
import '../models/configuracoes.dart';
import '../services/configuracoes_service.dart';
import '../services/notificacao_service.dart';
import '../services/medicamento_service.dart';
import '../theme.dart';

class ConfiguracoesScreen extends StatefulWidget {
  const ConfiguracoesScreen({super.key});

  @override
  State<ConfiguracoesScreen> createState() => _ConfiguracoesScreenState();
}

class _ConfiguracoesScreenState extends State<ConfiguracoesScreen> {
  final _service = ConfiguracoesService();
  late Configuracoes _config;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarConfiguracoes();
  }

  Future<void> _carregarConfiguracoes() async {
    _config = await _service.obterConfiguracoes();
    setState(() {
      _carregando = false;
    });
  }

  Future<void> _salvarConfiguracoes() async {
    await _service.salvarConfiguracoes(_config);

    // Mostrar notificação de progresso (não bloqueia o app)
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(child: Text('Configurando notificações...')),
            ],
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(
            seconds: 10,
          ), // Tempo suficiente para completar
        ),
      );
    }

    // Reagendar em background (não bloqueia a UI)
    _reagendarNotificacoes()
        .then((_) {
          if (mounted) {
            // Remover a notificação de progresso
            ScaffoldMessenger.of(context).hideCurrentSnackBar();

            // Mostrar confirmação de sucesso
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text('Notificações configuradas com sucesso!'),
                    ),
                  ],
                ),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 2),
              ),
            );
          }
        })
        .catchError((error) {
          if (mounted) {
            // Remover a notificação de progresso
            ScaffoldMessenger.of(context).hideCurrentSnackBar();

            // Mostrar erro se houver
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.error, color: Colors.white),
                    SizedBox(width: 12),
                    Expanded(child: Text('Erro ao configurar notificações')),
                  ],
                ),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 3),
              ),
            );
          }
        });
  }

  Future<void> _reagendarNotificacoes() async {
    try {
      final notificacaoService = NotificacaoService();
      final medicamentoService = MedicamentoService();

      // Obter todos os medicamentos ativos
      final medicamentos = medicamentoService.listarTodos();

      // Reagendar notificações em paralelo (mais rápido)
      await Future.wait(
        medicamentos.map(
          (medicamento) =>
              notificacaoService.agendarNotificacoesMedicamento(medicamento),
        ),
      );
    } catch (e) {
      // Silenciosamente falhar se houver erro
      debugPrint('Erro ao reagendar notificações: $e');
    }
  }

  void _mostrarSeletorMinutos(bool isPrimeira) async {
    final minutos = await showDialog<int>(
      context: context,
      builder: (context) => _SeletorMinutosDialog(
        minutosAtual: isPrimeira
            ? _config.minutosNotificacao1
            : _config.minutosNotificacao2,
        titulo: isPrimeira ? 'Primeira notificação' : 'Segunda notificação',
      ),
    );

    if (minutos != null) {
      setState(() {
        if (isPrimeira) {
          _config = Configuracoes(
            minutosNotificacao1: minutos,
            minutosNotificacao2: _config.minutosNotificacao2,
          );
        } else {
          _config = Configuracoes(
            minutosNotificacao1: _config.minutosNotificacao1,
            minutosNotificacao2: minutos,
          );
        }
      });

      // Salvar e reagendar em background
      _salvarConfiguracoes();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text(
              'Notificações',
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Configure os horários das notificações antes da hora de tomar o medicamento',
              style: TextStyle(color: AppColors.textLight, fontSize: 14),
            ),
          ),
          const SizedBox(height: 16),
          _buildConfigItem(
            titulo: 'Primeira notificação',
            descricao: 'Lembrete antecipado',
            valor: '${_config.minutosNotificacao1} minutos antes',
            onTap: () => _mostrarSeletorMinutos(true),
          ),
          _buildConfigItem(
            titulo: 'Segunda notificação',
            descricao: 'Lembrete próximo',
            valor: '${_config.minutosNotificacao2} minutos antes',
            onTap: () => _mostrarSeletorMinutos(false),
          ),
          _buildConfigItem(
            titulo: 'Notificação final',
            descricao: 'Na hora de tomar (com botão)',
            valor: '1 minuto antes',
            onTap: null,
            isFixo: true,
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.primary, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'A última notificação sempre será 1 minuto antes e incluirá um botão para marcar como tomado',
                      style: TextStyle(color: AppColors.text, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigItem({
    required String titulo,
    required String descricao,
    required String valor,
    VoidCallback? onTap,
    bool isFixo = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: isFixo ? null : onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          titulo,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          descricao,
          style: const TextStyle(color: AppColors.textLight, fontSize: 14),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              valor,
              style: TextStyle(
                color: isFixo ? AppColors.textLight : AppColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (!isFixo) ...[
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: AppColors.textLight),
            ],
          ],
        ),
      ),
    );
  }
}

class _SeletorMinutosDialog extends StatefulWidget {
  final int minutosAtual;
  final String titulo;

  const _SeletorMinutosDialog({
    required this.minutosAtual,
    required this.titulo,
  });

  @override
  State<_SeletorMinutosDialog> createState() => _SeletorMinutosDialogState();
}

class _SeletorMinutosDialogState extends State<_SeletorMinutosDialog> {
  late int _minutosSelecionados;
  final List<int> _opcoes = [5, 7, 10, 15, 20, 30, 45, 60];

  @override
  void initState() {
    super.initState();
    _minutosSelecionados = widget.minutosAtual;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.titulo),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: _opcoes.map((minutos) {
          final isSelected = minutos == _minutosSelecionados;
          return ListTile(
            title: Text(
              '$minutos minutos',
              style: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.text,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            leading: Radio<int>(
              value: minutos,
              groupValue: _minutosSelecionados,
              onChanged: (value) {
                setState(() {
                  _minutosSelecionados = value!;
                });
              },
              activeColor: AppColors.primary,
            ),
            onTap: () {
              setState(() {
                _minutosSelecionados = minutos;
              });
            },
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _minutosSelecionados),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}
