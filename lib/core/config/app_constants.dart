class AppConstants {
  const AppConstants._();

  static const String appName = 'SharePlate';
  static const String appTagline = 'Share More. Waste Less.';
  static const String defaultCity = 'Cairo';
  static const int minimumPasswordLength = 6;

  static const List<String> donationUnits = <String>[
    'Meals',
    'Kg',
    'Boxes',
    'Portions',
  ];

  static const List<String> foodCategories = <String>[
    'Cooked Meals',
    'Bakery & Bread',
    'Fresh Produce',
    'Dairy & Eggs',
    'Pantry & Canned',
    'Beverages',
    'Other',
  ];

  /// Benchmark conversion metrics based on UNEP Food Waste Index and EPA WARM:
  /// - 1 Kg of surplus food ≈ 2.5 meals (~400g per meal portion)
  /// - 1 Box ≈ 10 meals on average
  /// - 1 Meal / Portion = 1 meal
  /// - 1 Kg of food saved prevents ~2.5 kg of CO2 equivalent emissions
  static const double mealsPerKg = 2.5;
  static const double mealsPerBox = 10.0;
  static const double co2SavedPerKg = 2.5;
}

class FirebaseCollections {
  const FirebaseCollections._();

  static const String rootCollection = 'zerowaste';
  static const String rootDocument = 'app';
  static const String users = '$rootCollection/$rootDocument/users';
  static const String donations = '$rootCollection/$rootDocument/donations';
  static const String notifications =
      '$rootCollection/$rootDocument/notifications';
}

class AppRoutes {
  const AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String addDonation = '/add-donation';
  static const String donations = '/donations';
  static const String donationDetails = '/donation-details';
  static const String notifications = '/notifications';
  static const String chatbot = '/chatbot';
  static const String map = '/map';
  static const String profile = '/profile';
  static const String admin = '/admin';
}

class MatchingConfig {
  const MatchingConfig._();

  static const double urgencyWeight = 60;
  static const double quantityWeight = 40;
  static const double quantityForFullScore = 100;
}
