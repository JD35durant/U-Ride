# U-Ride — Guide d'Architecture Mobile Flutter

Ce guide détaille la structure recommandée pour porter le prototype U-Ride vers une application mobile Flutter native conformément aux choix technologiques prévus au cahier des charges (Flutter + Supabase + PostgreSQL).

## 1. Arborescence du Projet Flutter (`lib/`)

```
lib/
├── main.dart                          # Point d'entrée, initialisation Supabase
├── app.dart                           # MaterialApp, Thème officiel U-Ride
├── core/
│   ├── constants/
│   │   ├── colors.dart                # Palette de la charte (#153B50, #167D8D, etc.)
│   │   ├── typography.dart            # Configuration Inter / Aptos
│   │   └── api_constants.dart
│   ├── network/
│   │   └── supabase_client.dart       # Instance Supabase singleton
│   ├── theme/
│   │   └── app_theme.dart             # ThemeData clair et sombre
│   └── utils/
│       └── smartmatch_calculator.dart # Moteur de score local
├── features/
│   ├── auth/
│   │   ├── data/auth_repository.dart
│   │   ├── models/student_user.dart
│   │   └── presentation/screens/login_screen.dart
│   ├── rides/
│   │   ├── data/rides_repository.dart
│   │   ├── models/ride.dart
│   │   ├── models/booking.dart
│   │   ├── presentation/controllers/rides_controller.dart
│   │   ├── presentation/screens/explore_screen.dart
│   │   ├── presentation/screens/publish_ride_screen.dart
│   │   └── presentation/widgets/ride_card.dart
│   ├── chat/
│   │   ├── data/chat_repository.dart
│   │   ├── models/message.dart
│   │   └── presentation/screens/chat_screen.dart
│   └── profile/
│       ├── data/profile_repository.dart
│       ├── models/review.dart
│       └── presentation/screens/profile_screen.dart
```

## 2. Configuration du Thème (Charte Graphique)

```dart
import 'package:flutter/material.dart';

class URideColors {
  static const Color primary = Color(0xFF153B50);      // Bleu profond
  static const Color accent = Color(0xFF167D8D);       // Turquoise
  static const Color success = Color(0xFF5E9C76);      // Vert doux
  static const Color lightBg = Color(0xFFF0F6F7);      // Gris bleuté très pâle
  static const Color anthracite = Color(0xFF2D3741);   // Texte principal
  static const Color alertRed = Color(0xFFB42318);     // Alerte rouge foncé
}
```

## 3. Dépendances recommandées (`pubspec.yaml`)

```yaml
dependencies:
  flutter:
    sdk: flutter
  supabase_flutter: ^2.8.0
  flutter_riverpod: ^2.5.1
  go_router: ^14.0.0
  google_fonts: ^6.2.1
  intl: ^0.19.0
```
