/// Application-wide constants for APIs, Hive boxes, Firestore collections,
/// promo rules, cuisines, and default meal customization options.
abstract final class AppConstants {
  // Brand Identity
  static const String appName = 'Warm Courier';
  static const String appTagline = 'Fresh meals delivered fast';

  // DummyJSON Recipes REST API
  static const String dummyJsonBaseUrl = 'https://dummyjson.com';
  static const String recipesEndpoint = '/recipes';
  static const String recipesSearchEndpoint = '/recipes/search';
  static const String recipesTagEndpoint = '/recipes/tag';
  static const int defaultRecipesLimit = 30;
  static const Duration apiTimeout = Duration(seconds: 10);

  // Hive Box Names
  static const String settingsBox = 'settings_box';
  static const String restaurantsCacheBox = 'restaurants_cache_box';
  static const String favoriteRestaurantsBox = 'favorite_restaurants_box';
  static const String foodCartBox = 'food_cart_box';
  static const String foodOrdersBox = 'food_orders_box';

  // Hive Keys
  static const String themeModeKey = 'theme_mode';
  static const String cachedRestaurantsKey = 'cached_restaurants_list';
  static const String favoriteRestaurantIdsKey = 'favorite_restaurant_ids';
  static const String defaultAddressKey = 'default_delivery_address';

  // Cloud Firestore Collections
  static const String usersCollection = 'users';
  static const String cartSubcollection = 'cart';
  static const String ordersSubcollection = 'orders';

  // Supported Promo Codes
  static const String promoWelcome20 = 'WELCOME20';
  static const String promoFreeDel = 'FREEDEL';
  static const double welcome20DiscountRate = 0.20;

  // Supported Payment Methods
  static const String paymentCashOnDelivery = 'Cash on Delivery';
  static const String paymentCreditDebitCard = 'Credit/Debit Card';

  // Cuisine Filter Pills
  static const List<String> cuisineCategories = [
    'All',
    'Burgers',
    'Pizza',
    'Asian',
    'Italian',
    'Healthy',
    'Desserts',
  ];

  // Menu Category Tabs
  static const List<String> menuCategories = [
    'Popular',
    'Main Dishes',
    'Sides & Appetizers',
    'Drinks & Desserts',
  ];

  // Curated Simulated Courier Names for Live Tracking
  static const List<String> simulatedCouriers = [
    'Marcus Vance',
    'Elena Rostova',
    'Tariq Al-Mansoor',
    'Sofia Chen',
  ];
}
