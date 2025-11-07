import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../models/medicamento.dart';
import 'dose_service.dart';
import 'configuracoes_service.dart';

class NotificacaoService {
  static final NotificacaoService _instance = NotificacaoService._internal();
  factory NotificacaoService() => _instance;
  NotificacaoService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  final DoseService _doseService = DoseService();
  final ConfiguracoesService _configService = ConfiguracoesService();

  Future<void> initialize() async {
    // Inicializar timezone
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));

    // Configurações Android
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // Configurações iOS
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Solicitar permissões
    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    await _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  void _onNotificationTap(NotificationResponse response) {
    // Apenas marcar como tomada se for a ação específica "marcar_tomada"
    if (response.payload != null && response.actionId == 'marcar_tomada') {
      final parts = response.payload!.split('|');
      if (parts.length == 2) {
        final medicamentoId = parts[0];
        final horarioPrevisto = DateTime.parse(parts[1]);
        _doseService.marcarComoTomada(medicamentoId, horarioPrevisto);
      }
    }
    // Clicar na notificação apenas abre o app (sem marcar como tomado)
  }

  Future<void> agendarNotificacoesMedicamento(Medicamento medicamento) async {
    try {
      // Cancelar notificações antigas deste medicamento
      await cancelarNotificacoesMedicamento(medicamento.id);

      // Agendar apenas para os próximos 2 dias (ainda mais leve)
      final agora = DateTime.now();
      final dataInicio = DateTime(agora.year, agora.month, agora.day);
      final dataFim = dataInicio.add(const Duration(days: 2));

      final futurosAgendamentos = <Future>[];
      DateTime horario = medicamento.horarioPrimeiraDose;

      // Encontrar o primeiro horário futuro de forma mais eficiente
      final diferencaEmHoras = agora.difference(horario).inHours;
      if (diferencaEmHoras > 0) {
        final ciclos = (diferencaEmHoras / medicamento.intervaloHoras).ceil();
        horario = horario.add(
          Duration(hours: ciclos * medicamento.intervaloHoras),
        );
      }

      // Limitar a 20 notificações por medicamento (segurança)
      int contador = 0;
      const maxNotificacoes = 20;

      // Agendar notificações futuras até o limite de 2 dias
      while (horario.isBefore(dataFim) && contador < maxNotificacoes) {
        if (horario.isAfter(agora)) {
          futurosAgendamentos.add(
            _agendarNotificacoesParaDose(medicamento, horario),
          );
          contador++;
        }
        horario = horario.add(Duration(hours: medicamento.intervaloHoras));
      }

      // Aguardar todos os agendamentos em paralelo (com timeout)
      await Future.wait(futurosAgendamentos).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint(
            'Timeout ao agendar notificações para ${medicamento.nome}',
          );
          return [];
        },
      );
    } catch (e) {
      debugPrint('Erro ao agendar notificações para ${medicamento.nome}: $e');
      // Não propagar erro para não travar o app
    }
  }

  Future<void> _agendarNotificacoesParaDose(
    Medicamento medicamento,
    DateTime horarioDose,
  ) async {
    try {
      final medicamentoId = medicamento.id;

      // Gerar IDs únicos baseados no hash do medicamentoId + horário + tipo
      final baseId = '${medicamentoId}_${horarioDose.millisecondsSinceEpoch}'
          .hashCode
          .abs();

      // Obter configurações uma única vez
      final config = await _configService.obterConfiguracoes();
      final agora = DateTime.now();
      final agendamentos = <Future>[];

      // Primeira notificação (configurável, padrão 30 minutos)
      final horario1 = horarioDose.subtract(
        Duration(minutes: config.minutosNotificacao1),
      );
      if (horario1.isAfter(agora)) {
        agendamentos.add(
          _agendarNotificacao(
            id: baseId + 1,
            titulo: '⏰ Lembrete de Medicamento',
            corpo:
                '${medicamento.nome} ${medicamento.dosagem} em ${config.minutosNotificacao1} minutos\n${medicamento.quantidadePorDose} comprimido(s)',
            horario: horario1,
            payload: '$medicamentoId|${horarioDose.toIso8601String()}',
            comAcao: false,
          ),
        );
      }

      // Segunda notificação (configurável, padrão 7 minutos)
      final horario2 = horarioDose.subtract(
        Duration(minutes: config.minutosNotificacao2),
      );
      if (horario2.isAfter(agora)) {
        agendamentos.add(
          _agendarNotificacao(
            id: baseId + 2,
            titulo: '⏰ Lembrete de Medicamento',
            corpo:
                '${medicamento.nome} ${medicamento.dosagem} em ${config.minutosNotificacao2} minutos\n${medicamento.quantidadePorDose} comprimido(s)',
            horario: horario2,
            payload: '$medicamentoId|${horarioDose.toIso8601String()}',
            comAcao: false,
          ),
        );
      }

      // 1 minuto antes - com ação para marcar como tomado
      final horario1min = horarioDose.subtract(const Duration(minutes: 1));
      if (horario1min.isAfter(agora)) {
        agendamentos.add(
          _agendarNotificacao(
            id: baseId + 3,
            titulo: '💊 Hora do Medicamento!',
            corpo:
                '${medicamento.nome} ${medicamento.dosagem} AGORA\n${medicamento.quantidadePorDose} comprimido(s)',
            horario: horario1min,
            payload: '$medicamentoId|${horarioDose.toIso8601String()}',
            comAcao: true,
          ),
        );
      }

      // Agendar todas as notificações dessa dose em paralelo
      if (agendamentos.isNotEmpty) {
        await Future.wait(agendamentos);
      }
    } catch (e) {
      debugPrint('Erro ao agendar dose: $e');
      // Não propagar erro
    }
  }

  Future<void> _agendarNotificacao({
    required int id,
    required String titulo,
    required String corpo,
    required DateTime horario,
    required String payload,
    required bool comAcao,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'remedi_medicamentos',
      'Lembretes de Medicamentos',
      channelDescription: 'Notificações para lembrar de tomar medicamentos',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFFFF9800),
      actions: comAcao
          ? [
              const AndroidNotificationAction(
                'marcar_tomada',
                '✓ Tomei',
                titleColor: Color(0xFF4CAF50),
                showsUserInterface: true, // Abre o app
              ),
            ]
          : null,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      titulo,
      corpo,
      tz.TZDateTime.from(horario, tz.local),
      notificationDetails,
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelarNotificacoesMedicamento(String medicamentoId) async {
    // Cancelar todas as notificações pendentes
    final pendingNotifications = await _notifications
        .pendingNotificationRequests();

    for (final notification in pendingNotifications) {
      if (notification.payload?.startsWith(medicamentoId) ?? false) {
        await _notifications.cancel(notification.id);
      }
    }
  }

  Future<void> cancelarTodasNotificacoes() async {
    await _notifications.cancelAll();
  }
}
