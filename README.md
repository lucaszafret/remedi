# 💊 Remedi

<div align="center">

**Gerenciador de medicamentos**

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)](https://www.android.com)

</div>

---

## 📋 Sobre o Projeto

**Remedi** é um aplicativo Flutter intuitivo que ajuda a não esquecer de tomar seus medicamentos. Com notificações e histórico completo.

### ✨ Principais Funcionalidades

- 📱 **Interface Moderna**: Design limpo e intuitivo.
- ⏰ **Notificações Inteligentes**: Receba até 3 lembretes configuráveis antes de cada dose.
- 📊 **Histórico Completo**: Acompanhe todas as doses tomadas e perdidas.
- 🔔 **Painel de Notificações**: Veja rapidamente próximas doses e medicamentos atrasados.
- 📁 **Arquivamento**: Mantenha histórico de medicamentos finalizados.
- ✏️ **Edição Flexível**: Ajuste data e hora de doses tomadas.

---

## 🚀 Tecnologias

O Remedi foi desenvolvido com as seguintes tecnologias:

- **[Flutter](https://flutter.dev)** - Framework multiplataforma
- **[Dart](https://dart.dev)** - Linguagem de programação
- **[Hive](https://pub.dev/packages/hive)** - Banco de dados local leve e rápido
- **[Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications)** - Sistema de notificações locais

---

## 📱 Funcionalidades Detalhadas

### 🏠 Tela Principal
- Lista de medicamentos ativos.
- Banner de notificações com doses próximas (30 min) e atrasadas.
- Botão rápido "Tomei" para marcar doses.
- Acesso rápido a medicamentos arquivados.

### 💊 Gerenciamento de Medicamentos
- Cadastro completo: nome, dosagem, intervalo, horário inicial.
- Tratamentos com duração definida ou contínuos.
- Cálculo automático de horários de doses.
- Edição e arquivamento com manutenção de histórico.

### 🔔 Sistema de Notificações
- **1ª Notificação**: Configurável (padrão 30 min antes).
- **2ª Notificação**: Configurável (padrão 7 min antes).
- **3ª Notificação**: Fixa 1 minuto antes com botão "✓ Tomei"
- Reagendamento automático ao alterar configurações.

### 📚 Histórico
- Visualização de todas as doses tomadas.
- Agrupamento por data (Hoje, Ontem, etc).
- Edição de data/hora de doses registradas.
- Swipe para editar horário de dose.

### 📁 Medicamentos Arquivados
- Acesso a medicamentos finalizados.
- Opção de restaurar ou excluir permanentemente.
- Histórico preservado ao arquivar.

---
## 🛠️ Instalação e Desenvolvimento

### Pré-requisitos
- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)

### Configuração

```bash
# Clone o repositório
git clone https://github.com/lucaszafret/remedi.git

# Entre na pasta do projeto
cd remedi

# Instale as dependências
flutter pub get

# Execute o app
flutter run
```

### Build para Produção

```bash
# Android
flutter build apk --release
```

---

## 📄 Licença

Este projeto está publicado na playstore sob direitos de Lucas Zafret, não publique o app novamente.

---

## 👨‍💻 Autor

Desenvolvido por **Lucas Zafret**

[![GitHub](https://img.shields.io/badge/GitHub-100000?style=for-the-badge&logo=github&logoColor=white)](https://github.com/lucaszafret)

---

<div align="center">

**Feito com ❤️ e Flutter**

</div>
