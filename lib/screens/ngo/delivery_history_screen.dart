import 'package:flutter/material.dart';

class NgoDeliveryHistoryScreen extends StatelessWidget {
  const NgoDeliveryHistoryScreen({super.key});

  final List<Map<String, dynamic>> _history = const [
    {
      'id': 'DEL-885',
      'donor': 'A2B Sweets',
      'volunteer': 'Priya Das',
      'food': 'Assorted Sweets',
      'quantity': '4.2 kg',
      'timestamp': 'Just now',
      'status': 'In Transit',
    },
    {
      'id': 'DEL-882',
      'donor': 'Hotel Saravana Bhavan',
      'volunteer': 'Arun Kumar',
      'food': 'Vegetable Stew & Rice',
      'quantity': '12.5 kg',
      'timestamp': '2023-10-25 14:30',
      'status': 'Received',
    },
    {
      'id': 'DEL-879',
      'donor': 'Sangeetha Veg',
      'volunteer': 'Rahul Singh',
      'food': 'Idly & Sambar',
      'quantity': '8.0 kg',
      'timestamp': '2023-10-24 09:15',
      'status': 'Received',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NGO Delivery History'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _history.length,
        itemBuilder: (context, index) {
          final item = _history[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ID: ${item['id']}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item['status'],
                          style: TextStyle(
                            color: item['status'] == 'In Transit' ? Colors.orange : Colors.green, 
                            fontWeight: FontWeight.bold, 
                            fontSize: 12
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _buildDetailRow(Icons.restaurant, 'Donor', item['donor']),
                  _buildDetailRow(Icons.delivery_dining, 'Volunteer', item['volunteer']),
                  _buildDetailRow(Icons.fastfood, 'Food', item['food']),
                  _buildDetailRow(Icons.monitor_weight, 'Quantity', item['quantity']),
                  _buildDetailRow(Icons.access_time, 'Update', item['timestamp']),
                  if (item['status'] == 'In Transit') ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _showDeliveryQR(context, item['id']),
                            icon: const Icon(Icons.qr_code_2),
                            label: const Text('VERIFY DELIVERY'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDeliveryQR(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delivery'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('The volunteer will scan this QR to confirm the food has been received by your NGO.'),
            const SizedBox(height: 20),
            const Icon(Icons.qr_code_2, size: 200),
            const SizedBox(height: 8),
            Text('Ref: $id', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CLOSE')),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.orange),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        ],
      ),
    );
  }
}
