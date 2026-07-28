import 'package:flutter/material.dart';

class ManageVolunteersAdminScreen extends StatelessWidget {
  const ManageVolunteersAdminScreen({super.key});

  final List<Map<String, dynamic>> _vols = const [
    {'name': 'Arun Kumar', 'trips': 142, 'rating': 4.9, 'status': 'Online'},
    {'name': 'Priya Das', 'trips': 85, 'rating': 4.8, 'status': 'Offline'},
    {'name': 'Rahul Singh', 'trips': 210, 'rating': 5.0, 'status': 'Online'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Volunteer Fleet'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _vols.length,
        itemBuilder: (context, index) {
          final vol = _vols[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: vol['status'] == 'Online' ? Colors.green : Colors.grey,
                child: const Icon(Icons.directions_bike, color: Colors.white, size: 20),
              ),
              title: Text(vol['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Trips: ${vol['trips']} • Rating: ${vol['rating']} ★'),
              trailing: Text(
                vol['status'],
                style: TextStyle(color: vol['status'] == 'Online' ? Colors.green : Colors.grey, fontWeight: FontWeight.bold),
              ),
            ),
          );
        },
      ),
    );
  }
}
