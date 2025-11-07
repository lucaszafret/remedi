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
    // Cancelar notificações antigas deste medicamento
    await cancelarNotificacoesMedicamento(medicamento.id);

    // Agendar para os próximos 7 dias
    final hoje = DateTime.now();
    for (int dia = 0; dia < 7; dia++) {
      final data = DateTime(
        hoje.year,
        hoje.month,
        hoje.day,
      ).add(Duration(days: dia));
      final proximoDia = data.add(const Duration(days: 1));

      DateTime horario = medicamento.horarioPrimeiraDose;

      // Voltar até antes da data
      while (horario.isAfter(data)) {
        horario = horario.subtract(Duration(hours: medicamento.intervaloHoras));
      }

      // Avançar até o primeiro horário da data
      while (horario.isBefore(data)) {
        horario = horario.add(Duration(hours: medicamento.intervaloHoras));
      }

      // Agendar notificações para cada horário do dia
      while (horario.isBefore(proximoDia)) {
        if (horario.isAfter(DateTime.now())) {
          await _agendarNotificacoesParaDose(medicamento, horario);
        }
        horario = horario.add(Duration(hours: medicamento.intervaloHoras));
      }
    }
  }

  Future<void> _agendarNotificacoesParaDose(
    Medicamento medicamento,
    DateTime horarioDose,
  ) async {
    final medicamentoId = medicamento.id;

    // Gerar IDs únicos baseados no hash do medicamentoId + horário + tipo
    final baseId = '${medicamentoId}_${horarioDose.millisecondsSinceEpoch}'
        .hashCode
        .abs();

    // Obter configurações
    final config = await _configService.obterConfiguracoes();

    // Primeira notificação (configurável, padrão 30 minutos)
    final horario1 = horarioDose.subtract(
      Duration(minutes: config.minutosNotificacao1),
    );
    if (horario1.isAfter(DateTime.now())) {
      await _agendarNotificacao(
        id: baseId + 1,
        titulo: '⏰ Lembrete de Medicamento',
        corpo:
            '${medicamento.nome} ${medicamento.dosagem} em ${config.minutosNotificacao1} minutos\n${medicamento.quantidadePorDose} comprimido(s)',
        horario: horario1,
        payload: '$medicamentoId|${horarioDose.toIso8601String()}',
        comAcao: false,
      );
    }

    // Segunda notificação (configurável, padrão 7 minutos)
    final horario2 = horarioDose.subtract(
      Duration(minutes: config.minutosNotificacao2),
    );
    if (horario2.isAfter(DateTime.now())) {
      await _agendarNotificacao(
        id: baseId + 2,
        titulo: '⏰ Lembrete de Medicamento',
        corpo:
            '${medicamento.nome} ${medicamento.dosagem} em ${config.minutosNotificacao2} minutos\n${medicamento.quantidadePorDose} comprimido(s)',
        horario: horario2,
        payload: '$medicamentoId|${horarioDose.toIso8601String()}',
        comAcao: false,
      );
    }

    // 1 minuto antes - com ação para marcar como tomado
    final horario1min = horarioDose.subtract(const Duration(minutes: 1));
    if (horario1min.isAfter(DateTime.now())) {
      await _agendarNotificacao(
        id: baseId + 3,
        titulo: '💊 Hora do Medicamento!',
        corpo:
            '${medicamento.nome} ${medicamento.dosagem} AGORA\n${medicamento.quantidadePorDose} comprimido(s)',
        horario: horario1min,
        payload: '$medicamentoId|${horarioDose.toIso8601String()}',
        comAcao: true,
      );
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
