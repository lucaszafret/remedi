class Configuracoes {
  final int minutosNotificacao1;
  final int minutosNotificacao2;

  Configuracoes({
    this.minutosNotificacao1 = 30,
    this.minutosNotificacao2 = 7,
  });

  Map<String, dynamic> toMap() {
    return {
      'minutosNotificacao1': minutosNotificacao1,
      'minutosNotificacao2': minutosNotificacao2,
    };
  }

  factory Configuracoes.fromMap(Map<String, dynamic> map) {
    return Configuracoes(
      minutosNotificacao1: map['minutosNotificacao1'] ?? 30,
      minutosNotificacao2: map['minutosNotificacao2'] ?? 7,
    );
  }
}
