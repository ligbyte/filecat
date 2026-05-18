# Repository Guidelines

## Project Structure & Module Organization

This repository is a Flutter application with a Rust native library. Primary
Dart code lives in `lib/`: `main.dart` starts the app, `rust_bridge.dart`
connects to the native library, and feature code is organized under `lib/src/`
by responsibility: `bindings/`, `controllers/`, `models/`, `pages/`, `routes/`,
`utils/`, `widgets/`, and `constants/`. Platform shells are in
`android/`, `ios/`, `linux/`, `macos/`, `web/`, and `windows/`. Rust source is in
`rust/src/lib.rs` with metadata in `rust/Cargo.toml`. Images, icons, SVGs, and
fonts are under `assets/`; register new assets in `pubspec.yaml` when needed.

## Build, Test, and Development Commands

- `flutter pub get`: install Dart and Flutter dependencies.
- `flutter analyze`: run static analysis using `flutter_lints`.
- `flutter test`: run Flutter unit/widget tests where present.
- `flutter run -d windows`: run locally. Replace `windows` with `macos`,
  `linux`, `web`, `android`, or `ios` for other targets.
- `cd rust; cargo build`: build the Rust `cdylib` used by the Flutter bridge.
- `cd rust; cargo build --release`: build the optimized native library before
  release packaging.
- `flutter build windows --release`: produce a Windows release build.

## Coding Style & Naming Conventions

Use `dart format .` and the lint rules from `analysis_options.yaml`. Dart files
use `snake_case.dart`; classes, widgets, and controllers use `PascalCase`;
variables and methods use `lowerCamelCase`. Follow the existing GetX structure:
routes in `app_routes.dart`/`app_pages.dart`, bindings in `lib/src/bindings/`,
and state in `lib/src/controllers/`. Rust code should use `cargo fmt`.

## Testing Guidelines

Place Flutter tests in `test/` using `*_test.dart` names. Platform tests
currently exist under `ios/RunnerTests/` and `macos/RunnerTests/`; add native
tests near the code they cover. Run `flutter test` and `flutter analyze` before
opening a PR. For Rust changes, run `cd rust; cargo test` when tests are added
and at least `cargo build` for FFI changes.

## Commit & Pull Request Guidelines

Recent commits use short Chinese summaries such as `GetX重构、国际化、帮助文档`.
Keep commits concise and focused on one change. Pull requests should include a
description, tested platforms, commands run, linked issues if applicable, and
screenshots or recordings for UI changes. Mention any Rust rebuild or
platform-specific setup required to verify the change.

## Security & Configuration Tips

Do not commit local signing keys, generated build output, or machine-specific IDE
files. Treat `filecat.dll` and rebuilt native artifacts as platform outputs; update
them only when the Rust bridge behavior intentionally changes.
