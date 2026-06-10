```
lib/
├── core/
│   ├── constants/colors.dart
│   └── utils/formatters.dart
├── database/
│   └── database_manager.dart (sudah diperbaiki)
├── models/
│   ├── product_model.dart
│   ├── stock_history_model.dart
│   ├── supplier_model.dart
│   └── user_model.dart (baru)
├── repositories/
│   ├── product_repository.dart
│   ├── supplier_repository.dart
│   ├── stock_repository.dart
│   └── user_repository.dart (sudah dibuat)
├── providers/
│   ├── auth_provider.dart (untuk user/onboarding)
│   ├── product_provider.dart
│   ├── supplier_provider.dart
│   ├── stock_provider.dart
│   └── theme_provider.dart (pertahankan)
├── screens/
│   ├── splash_screen.dart
│   ├── onboarding_screen.dart
│   ├── dashboard/
│   │   ├── components/
│   │   └── dashboard_screen.dart
│   ├── produk/
│   │   ├── components/
│   │   └── produk_screen.dart
│   ├── mutasi/
│   │   ├── components/
│   │   └── mutasi_screen.dart
│   └── profile/
│       └── profile_screen.dart
└── widgets/
    ├── custom_chart.dart
    ├── glass_card.dart
    └── stat_card.dart
```