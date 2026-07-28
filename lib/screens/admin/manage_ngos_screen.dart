import 'package:flutter/material.dart';

class ManageNgosScreen extends StatelessWidget {
  const ManageNgosScreen({super.key});

  final List<Map<String, dynamic>> _ngos = const [
    {'name': 'Helping Hands', 'location': 'Chennai Central', 'capacity': 'High', 'status': 'Verified'},
    {'name': 'Feed The Needy', 'location': 'T. Nagar', 'capacity': 'Medium', 'status': 'Pending'},
    {'name': 'Green Earth Bank', 'location': 'Adyar', 'capacity': 'High', 'status': 'Verified'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NGO Partners'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _ngos.length,
        itemBuilder: (context, index) {
          final ngo = _ngos[index];
          final isVerified = ngo['status'] == 'Verified';
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const CircleAvatar(backgroundColor: Colors.orange, child: Icon(Icons.business, color: Colors.white)),
              title: Text(ngo['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${ngo['location']} • Capacity: ${ngo['capacity']}'),
              trailing: Icon(
                isVerified ? Icons.verified : Icons.pending_actions,
                color: isVerified ? Colors.blue : Colors.orange,
              ),
              onTap: () {},
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.red,
        child: const Icon(Icons.add_business, color: Colors.white),
      ),
    );
  }
}
