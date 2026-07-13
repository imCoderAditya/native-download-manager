# Contributing to Native Download Manager

Thank you for your interest in contributing to the `native_download_manager` package! Contributions are welcome from anyone.

## Development Setup

1. Fork and clone the repository.
2. Ensure you have the Flutter SDK installed (Dart >=3, Flutter >=3.30).
3. Get package dependencies:
   ```bash
   flutter pub get
   ```

## Running Code Generation (Pigeon)

If you modify Pigeon configurations in `pigeons/messages.dart`, you must regenerate native bindings:
```bash
dart run pigeon --input pigeons/messages.dart
```

## Running Tests

Verify your changes by running the unit tests:
```bash
flutter test
```

## Code Style

- Follow standard [Effective Dart guidelines](https://dart.dev/guides/language/effective-dart).
- Avoid modifying generated files (`Messages.g.swift`, `Messages.g.kt`, `native_api.g.dart`) directly; change the Pigeon schemas instead.
- Write unit tests for new features.
