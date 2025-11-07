# 💊 Remedi

<div align="center">

**Seu assistente pessoal para gerenciamento de medicamentos**

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)](https://www.android.com)
[![iOS](https://img.shields.io/badge/iOS-000000?style=for-the-badge&logo=ios&logoColor=white)](https://www.apple.com/ios)

</div>

---

## 📋 Sobre o Projeto

**Remedi** é um aplicativo Flutter moderno e intuitivo que ajuda você a nunca mais esquecer de tomar seus medicamentos. Com notificações inteligentes e histórico completo, você mantém sua saúde em dia de forma simples e prática.

### ✨ Principais Funcionalidades

- 📱 **Interface Moderna**: Design limpo e intuitivo seguindo as melhores práticas de UX
- ⏰ **Notificações Inteligentes**: Receba até 3 lembretes configuráveis antes de cada dose
- 📊 **Histórico Completo**: Acompanhe todas as doses tomadas e perdidas
- 🔔 **Painel de Notificações**: Veja rapidamente próximas doses e medicamentos atrasados
- 📁 **Arquivamento**: Mantenha histórico de medicamentos finalizados
- ✏️ **Edição Flexível**: Ajuste data e hora de doses tomadas
- 🎨 **Temas Personalizados**: Interface agradável com cores suaves

---

## 🚀 Tecnologias

O Remedi foi desenvolvido com as seguintes tecnologias:

- **[Flutter](https://flutter.dev)** - Framework multiplataforma
- **[Dart](https://dart.dev)** - Linguagem de programação
- **[Hive](https://pub.dev/packages/hive)** - Banco de dados local leve e rápido
- **[Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications)** - Sistema de notificações locais
- **[Timezone](https://pub.dev/packages/timezone)** - Gerenciamento de fuso horário

---

## 📱 Funcionalidades Detalhadas

### 🏠 Tela Principal
- Lista de medicamentos ativos
- Banner de notificações com doses próximas (30 min) e atrasadas
- Botão rápido "Tomei" para marcar doses
- Acesso rápido a medicamentos arquivados

### 💊 Gerenciamento de Medicamentos
- Cadastro completo: nome, dosagem, intervalo, horário inicial
- Tratamentos com duração definida ou contínuos
- Cálculo automático de horários de doses
- Edição e arquivamento com manutenção de histórico

### 🔔 Sistema de Notificações
- **1ª Notificação**: Configurável (padrão 30 min antes)
- **2ª Notificação**: Configurável (padrão 7 min antes)
- **3ª Notificação**: Fixa 1 minuto antes com botão "✓ Tomei"
- Reagendamento automático ao alterar configurações

### 📚 Histórico
- Visualização de todas as doses tomadas
- Agrupamento por data (Hoje, Ontem, etc)
- Edição de data/hora de doses registradas
- Swipe para editar horário de dose

### 📁 Medicamentos Arquivados
- Acesso a medicamentos finalizados
- Opção de restaurar ou excluir permanentemente
- Histórico preservado ao arquivar

---

## 🎯 Como Usar

### Adicionar um Medicamento
1. Toque no botão **+** na barra inferior
2. Preencha os dados do medicamento
3. Configure o horário da primeira dose
4. Defina o intervalo entre doses
5. Opcionalmente, defina duração do tratamento

### Marcar Dose como Tomada
- **Da notificação**: Toque no botão "✓ Tomei" (notificação de 1 min)
- **Da tela principal**: Toque em "Tomei" no card do medicamento
- **Do banner**: Toque em "Tomar" nas notificações pendentes

### Configurar Notificações
1. Acesse a aba **Configurações**
2. Ajuste os minutos da primeira e segunda notificação
3. As notificações serão reagendadas automaticamente

---

## 🛠️ Instalação e Desenvolvimento

### Pré-requisitos
- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)
- Android Studio / Xcode (para desenvolvimento mobile)

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

# iOS
flutter build ios --release
```

---

## 📦 Estrutura do Projeto

```
lib/
├── main.dart                    # Entrada do aplicativo
├── theme.dart                   # Definições de cores e temas
├── models/                      # Modelos de dados
│   ├── medicamento.dart
│   ├── dose_tomada.dart
│   └── configuracoes.dart
├── screens/                     # Telas do aplicativo
│   ├── home_screen.dart
│   ├── historico_screen.dart
│   ├── configuracoes_screen.dart
│   ├── arquivados_screen.dart
│   └── adicionar_medicamento_screen.dart
├── services/                    # Lógica de negócio
│   ├── medicamento_service.dart
│   ├── dose_service.dart
│   ├── notificacao_service.dart
│   └── configuracoes_service.dart
└── widgets/                     # Componentes reutilizáveis
    ├── medicamento_card.dart
    ├── custom_app_bar.dart
    └── custom_bottom_nav_bar.dart
```

---

## 🎨 Design System

### Paleta de Cores
- **Primary**: `#FF9800` (Laranja)
- **Background**: `#FAFAFA` (Cinza claro)
- **Text**: `#333333` (Cinza escuro)
- **Text Light**: `#666666` (Cinza médio)
- **Error**: `#F44336` (Vermelho)

### Componentes
- Cards com sombra suave e cantos arredondados (16px)
- Botões com elevação zero e cores vibrantes
- Ícones em containers coloridos e arredondados

---

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

---

## 👨‍💻 Autor

Desenvolvido por **Lucas Zafret**

[![GitHub](https://img.shields.io/badge/GitHub-100000?style=for-the-badge&logo=github&logoColor=white)](https://github.com/lucaszafret)

---

<div align="center">

**Feito com ❤️ e Flutter**

</div>
