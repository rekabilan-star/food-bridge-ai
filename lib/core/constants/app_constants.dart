class AppConstants {
  static const String appName = "FoodRescue AI";

  // API Base URL - Production Render Server
  static const String baseUrl =
      "https://food-bridge-ai.onrender.com/api/";

  // Endpoints
  static const String loginUrl = "auth/login";
  static const String registerDonorUrl = "auth/register/donor";
  static const String registerNgoUrl = "auth/register/ngo";
  static const String getProfileUrl = "user/profile";

  // Storage Keys
  static const String tokenKey = "token";
  static const String roleKey = "role";
  static const String userDataKey = "user_data";
}
