import 'package:flutter/material.dart';
import 'map_widget.dart';
import '../common/chat_screen.dart';
import '../common/rating_screen.dart';
import '../../services/data_service.dart';

class LiveTrackingScreen extends StatefulWidget {
  final String destination;
  final String? donationId;
  const LiveTrackingScreen({super.key, required this.destination, this.donationId});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Tracking & Routing'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Simulated Map Background
          const MapWidget(),
          
          // Floating Route Info
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.bolt, color: Colors.orange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Smart Route Optimized', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('Fastest path to ${widget.destination}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                    const Text('12 min', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Navigation Card
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.deepPurple,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Navigating to Destination', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            Text('Aurobindo Orphanage', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatScreen(peerName: 'Aurobindo Orphanage'))),
                        icon: const Icon(Icons.chat_bubble_outline, color: Colors.blue),
                        style: IconButton.styleFrom(backgroundColor: Colors.blue.shade50),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.call, color: Colors.green),
                        style: IconButton.styleFrom(backgroundColor: Colors.green.shade50),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  ElevatedButton(
                    onPressed: () => _showCompletionDialog(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('ARRIVED AT LOCATION', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCompletionDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 16),
            const Text('Delivery Successful!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'You have successfully delivered the food to Aurobindo Orphanage.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.eco, color: Colors.green, size: 16),
                SizedBox(width: 4),
                Text('Impact: +3.2 kg food saved', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (widget.donationId != null) {
                  DataService().updateDonationStatus(widget.donationId!, 'delivered');
                }
                Navigator.pop(context); // Pop dialog
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RatingScreen(
                      targetName: 'Aurobindo Orphanage',
                      role: 'NGO',
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('RATE EXPERIENCE & FINISH'),
            ),
          ],
        ),
      ),
    );
  }
}
