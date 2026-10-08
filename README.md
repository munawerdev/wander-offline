# WanderOffline

WanderOffline is a Flutter travel companion app organized around feature modules and a Clean Architecture style data/domain split. This README describes the app repository; it is not a Mason brick.

## 📋 Version Information

- **Flutter**: 3.47.0
- **Dart**: 3.13.0
- **Java**: 25.0.3

## 🎯 Key Features

- ✅ **Clean Architecture** with Domain-Driven Design
- ✅ **State Management** with Flutter Cubit
- ✅ **Dependency Injection** with GetIt
- ✅ **Network Layer** with Dio interceptors
- ✅ **Local Storage** with SharedPreferences
- ✅ **Responsive Design** with ScreenUtil
- ✅ **UI Components** library
- ✅ **Navigation** with custom transitions

## 📁 Source structure

```
lib/
├── 📂 config/                    # Global configuration
│   ├── 📂 navigation/           # Navigation setup and routing
│   ├── 📂 response/             # API response handling
│   └── 📂 theme/                # App theming
├── 📂 core/                     # Core utilities and services
│   ├── 📂 constants/            # Global constants
│   ├── 📂 services/             # Core services
│   ├── 📂 show/                 # Snack bars and navigation observer
│   ├── 📂 utils/                # Utility functions
│   └── 📂 widgets/              # Reusable widgets library
├── 📂 data/                     # Data layer (Repository Pattern)
│   ├── 📂 datasources/          # Data sources (Remote/Local)
│   ├── 📂 models/               # Data models
│   └── 📂 repositories/         # Repository implementations
├── 📂 domain/                   # Business logic layer
│   ├── 📂 failures/             # Error handling
│   ├── 📂 repositories/         # Repository interfaces
│   └── 📂 usecases/             # Business use cases
├── 📂 features/                 # Feature modules (UI, Cubit, navigation, params)
│   ├── 📂 auth/login/
│   ├── 📂 bottom_nav/
│   ├── 📂 home/
│   └── 📂 splash/
├── injection_container.dart     # Dependency injection setup
└── main.dart                     # Main application entry point
```

## 🤝 Contributing

1. Fork the repository (`https://github.com/munawerdev/mason_cli`)
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request
