import 'package:url_launcher/url_launcher.dart';
import 'package:logger/logger.dart';

class IntentUtils {
  static final Logger _logger = Logger();

  static Future<void> makePhoneCall(String phoneNumber) async {
    if (phoneNumber.isEmpty) return;
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        _logger.e('Could not launch phone dialer for $phoneNumber');
      }
    } catch (e) {
      _logger.e('Error launching phone dialer: $e');
    }
  }

  static Future<void> sendWhatsAppMessage(String phoneNumber, String message) async {
    if (phoneNumber.isEmpty) return;
    
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');
    final url = "https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}";
    final uri = Uri.parse(url);
    
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _logger.e('Could not launch WhatsApp for $phoneNumber');
      }
    } catch (e) {
      _logger.e('Error launching WhatsApp: $e');
    }
  }

  static Future<void> openMapNavigation(double lat, double lng) async {
    // Open in generic map apps via geo: URI or web fallback
    final geoUrl = Uri.parse("geo:$lat,$lng?q=$lat,$lng");
    final webUrl = Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lng");
    
    try {
      if (await canLaunchUrl(geoUrl)) {
        await launchUrl(geoUrl);
      } else {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      _logger.e('Error launching maps: $e');
    }
  }
}
