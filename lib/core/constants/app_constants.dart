class AppConstants {
  static const String appName = "FoodRescue AI";

  // API Base URL - Render Production Server
  static const String baseUrl =
      "https://food-bridge-ai.onrender.com/api/";

  /// Root Server URL (without /api/ prefix or trailing slash)
  /// Used for static assets and socket connections
  static String get serverBaseUrl {
    final clean = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    if (clean.endsWith('/api')) {
      return clean.substring(0, clean.length - 4);
    }

    return clean;
  }

  // Authentication Endpoints
  static const String loginUrl = "auth/login";
  static const String registerDonorUrl = "auth/register/donor";
  static const String registerNgoUrl = "auth/register/ngo";
  static const String getProfileUrl = "user/profile";

  // Storage Keys
  static const String tokenKey = "token";
  static const String roleKey = "role";
  static const String userDataKey = "user_data";

  /// Safe URL Builder
  static String buildUrl(String endpoint) {
    final cleanBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    final cleanEndpoint =
        endpoint.startsWith('/') ? endpoint : '/$endpoint';

    return '$cleanBase$cleanEndpoint';
  }
}