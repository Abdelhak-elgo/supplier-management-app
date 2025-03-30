# Supplier Management App - Setup Instructions

This document provides instructions for setting up the Supplier Management App after downloading the source code.

## Prerequisites

Make sure you have the following installed:

1. Flutter SDK (latest stable version recommended)
2. Dart SDK (included with Flutter)
3. Android Studio or VS Code with Flutter extensions
4. Git

## Setup Steps

### 1. Create a new Flutter project (Option 1)

```bash
# Create a new Flutter project
flutter create supplier_management_app
cd supplier_management_app

# Remove the default lib folder and replace with the downloaded one
rm -rf lib/
```

### 2. Set up existing code (Option 2)

If you've downloaded the ZIP file:

```bash
# Extract the ZIP file
unzip supplier-management-app-essentials.zip -d supplier_management_app
cd supplier_management_app
```

### 3. Install dependencies

Update the pubspec.yaml file with the project's dependencies, then run:

```bash
flutter pub get
```

### 4. Run the app

```bash
flutter run
```

## Project Structure

The app follows a clean architecture approach with feature-based organization:

```
lib/
├── app.dart               # App entry point with routes
├── main.dart              # Main function and dependency injection
├── core/                  # Core functionality
│   ├── constants/         # App-wide constants
│   ├── database/          # SQLite database helper
│   ├── services/          # Common services (PDF, etc.)
│   ├── theme/             # App theme configuration
│   ├── utils/             # Utility functions
│   └── widgets/           # Reusable widgets
└── features/              # App features
    ├── clients/           # Client management
    ├── dashboard/         # Dashboard and statistics
    ├── invoices/          # Invoice management
    ├── orders/            # Order management
    ├── products/          # Product management
    └── reports/           # Reports and analytics
```

Each feature module contains:
- models/ - Data models
- repository/ - Data access layer
- bloc/ - Business logic components
- screens/ - UI screens
- widgets/ - Feature-specific widgets

## Key Dependencies

The app relies on the following main packages:
- flutter_bloc - For state management
- sqflite - For local SQLite database
- path_provider - For file system access
- pdf - For PDF generation
- fl_chart - For analytics charts
- intl - For internationalization and formatting

## Troubleshooting

If you encounter any issues:
1. Make sure Flutter is properly installed: `flutter doctor`
2. Ensure all dependencies are correctly resolved: `flutter pub get`
3. Clear the build cache if needed: `flutter clean`