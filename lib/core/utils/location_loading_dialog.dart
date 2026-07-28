import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/location_provider_v2.dart';
import '../errors/location_exception.dart';
import 'manual_location_picker.dart';

class LocationLoadingDialog extends StatelessWidget {
  const LocationLoadingDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const LocationLoadingDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocationProviderV2>(
      builder: (context, provider, _) {
        if (provider.location != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pop(context);
          });
        }

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (provider.error == null) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                Text(
                  provider.loadingMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Retries: ${provider.retryCount}", style: const TextStyle(fontSize: 12, color: Colors.blue)),
                    const SizedBox(width: 24),
                    Text("Time: ${provider.elapsedSeconds}s", style: const TextStyle(fontSize: 12, color: Colors.orange)),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  "Please ensure you are under a clear sky for better accuracy.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ] else ...[
                const Icon(Icons.location_off, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  provider.error!.message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("CANCEL"),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (provider.error?.type == LocationErrorType.permissionDeniedForever ||
                            provider.error?.type == LocationErrorType.serviceDisabled) {
                          provider.openSettings();
                        } else {
                          provider.fetchLocation();
                        }
                      },
                      child: Text(
                        provider.error?.type == LocationErrorType.permissionDeniedForever ||
                                provider.error?.type == LocationErrorType.serviceDisabled
                            ? "OPEN SETTINGS"
                            : "RETRY",
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ManualLocationPicker()),
                    );
                    if (result != null) {
                      provider.setManualLocation(result);
                    }
                  },
                  child: const Text("SELECT MANUALLY", style: TextStyle(color: Colors.blue)),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
