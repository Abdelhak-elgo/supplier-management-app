# Supplier Management App

A comprehensive Flutter-based mobile application for suppliers to manage products, clients, orders, and invoices with an offline-first architecture using SQLite for local data storage.

![App Preview](https://via.placeholder.com/800x400?text=Supplier+Management+App)

## Features

- **Dashboard**: Overview of business statistics and quick action buttons
- **Product Management**: Create, view, edit, and delete products with categories
- **Client Management**: Maintain a database of clients with contact information
- **Order Processing**: Create and manage orders, track status, and inventory levels
- **Invoicing**: Generate PDF invoices from orders with customization options
- **Reports & Analytics**: Business analytics with visualizations
- **Offline-First**: Works without an internet connection using local SQLite database

## Technology Stack

- **Frontend/Backend**: Flutter
- **State Management**: BLoC pattern
- **Database**: SQLite (local)
- **PDF Generation**: dart:pdf
- **UI Framework**: Material 3 with custom theming

## Architecture

The app follows a clean architecture approach with a feature-based organization:

- **Core Layer**: Database helper, services, utilities, theme, constants, reusable widgets
- **Feature Modules**: Each major feature (products, clients, orders, etc.) has its own directory with:
  - Models: Data structures
  - Repository: Data access layer
  - BLoC: Business logic components
  - Screens: UI components
  - Widgets: Feature-specific widgets

## Getting Started

See the [setup instructions](setup_instructions.md) for details on how to set up and run the project.

## Screenshots

*(Coming soon)*

## License

This project is licensed under the MIT License - see the LICENSE file for details.
