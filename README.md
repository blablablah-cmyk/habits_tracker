# Habits Tracker App 
my 2nd years university project

A modern and intuitive habit tracking application built with Flutter. Currently in version 1.0.0a1 some feature might be missing or not works as intended (import/export data and notifications services)

## Features

-  Clean and intuitive user interface
-  Light/Dark theme support
-  Detailed habit tracking statistics
-  Time-based habit scheduling
-  Custom notifications
-  Progress tracking and streaks
-  Category organization
-  Local data persistence
-  Cross-platform support (iOS & Android)

## Getting Started

### Prerequisites

- Flutter SDK (latest version)
- Dart SDK
- Android Studio or VS Code
- iOS Simulator (for Mac), Android Emulator or Visual Studio (for Windows)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/blablablah-cmyk/habits_tracker.git
```

2. Navigate to the project directory:
```bash
cd habits_tracker
```

3. Install dependencies:
```bash
flutter pub get
```

4. Run the app:
```bash
flutter run
```

## Project Structure

```
lib/
├── models/         # Data models
├── providers/      # State management
├── screens/        # UI screens
├── services/       # Business logic
└── theme/          # App theming
```

## Features in Detail

### Habit Management
- Create, edit, and delete habits
- Set custom frequencies (daily, weekly, custom days)
- Track progress with detailed statistics
- Add notes and quantities to habits

### Customization
- Multiple habit categories
- Custom colors and icons
- Personalized reminders
- Flexible scheduling options

### Statistics
- Current and longest streaks
- Completion rates
- Daily/weekly/monthly views
- Progress visualization

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request
