# Project Overview

This project is a Fintech application built with Flutter. It appears to be designed for university students and staff, with features related to SACCOs (Savings and Credit Cooperative Organizations), financial literacy, and mobile payments.

## Project Structure

The `lib` directory is organized as follows:

- `main.dart`: The entry point of the application.
- `assets/`: Contains static assets like images and fonts.
- `models/`: Contains the data models for the application (e.g., `sacco.dart`, `transaction.dart`).
- `screens/`: Contains the different screens of the application (e.g., `home_dashboard.dart`, `sacco_dashboard.dart`).
- `services/`: Contains services that interact with APIs or manage application state (e.g., `api_service.dart`, `auth_service.dart`).
- `widgets/`: Contains reusable widgets used throughout the application (e.g., `sacco_card.dart`, `glass_bottom_nav_bar.dart`).

## Dependencies

The project uses the following main dependencies:

- `flutter`: The Flutter framework.
- `http`: For making HTTP requests to a server.
- `flutter_secure_storage`: For storing data securely.
- `shared_preferences`: For storing non-sensitive key-value data.
- `shimmer`: To create a shimmering effect, likely for loading UI.
- `intl`: For internationalization and localization.
- `cached_network_image`: To cache network images.
- `flutter_svg`: To render SVG files.
- `cupertino_icons`: For iOS-style icons.
- `flutter_lints`: For code linting.

## Coding Conventions

- **File Naming**: Files are named using `snake_case.dart`.
- **Code Style**: The project seems to follow the standard Dart and Flutter coding style. It is recommended to use the auto-formatter in your IDE to maintain consistency.
