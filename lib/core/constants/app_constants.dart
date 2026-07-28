class AppConstants {
  static const String appName = "FoodRescue AI";
  
  // API Base URL (For Android Emulator: 10.0.2.2, For Physical Device: Use LAN IP)
  static const String baseUrl = "http://10.0.2.2:5000/api/";

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
