import 'package:flutter/material.dart';

class ManageVolunteersScreen extends StatelessWidget {
  const ManageVolunteersScreen({super.key});

  final List<Map<String, dynamic>> _volunteers = const [
    {'name': 'Arun Kumar', 'status': 'Available', 'distance': '0.8 km', 'rating': 4.8},
    {'name': 'Priya Das', 'status': 'On Delivery', 'distance': '2.4 km', 'rating': 4.9},
    {'name': 'Rahul Singh', 'status': 'Available', 'distance': '1.2 km', 'rating': 4.7},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Volunteers'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _volunteers.length,
        itemBuilder: (context, index) {
          final vol = _volunteers[index];
          final isAvailable = vol['status'] == 'Available';

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isAvailable ? Colors.green.shade100 : Colors.grey.shade200,
                child: Icon(Icons.person, color: isAvailable ? Colors.green : Colors.grey),
              ),
              title: Text(vol['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${vol['distance']} away • ${vol['status']}'),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      Text(vol['rating'].toString()),
                    ],
                  ),
                  if (isAvailable)
                    const Text('Assign', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
              onTap: isAvailable ? () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Task assigned to ${vol['name']}')),
                );
              } : null,
            ),
          );
        },
      ),
    );
  }
}
