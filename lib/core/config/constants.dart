class AppConstants {
  // App Info
  static const String appName = '밀리터리트래커';
  static const String appVersion = '1.0.0';
  
  // Workout Goals
  static const int squatGoal = 100;
  static const int lungeGoal = 50;
  static const int walkGoal = 10000;
  static const double runGoal = 5.0;
  
  // Workout Increments
  static const int squatIncrement = 10;
  static const int lungeIncrement = 10;
  static const int walkIncrement = 1000;
  static const double runIncrement = 0.5;
  
  // API (추후 사용)
  static const String baseUrl = 'https://api.example.com';
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // Local Storage Keys
  static const String keyUserId = 'user_id';
  static const String keyUserEmail = 'user_email';
  static const String keyIsLoggedIn = 'is_logged_in';
  static const String keyThemeMode = 'theme_mode';
}

