import 'package:flutter/material.dart';

class ManageUsersScreen extends StatelessWidget {
  const ManageUsersScreen({super.key});

  final List<Map<String, String>> _users = const [
    {'name': 'Kabil M', 'role': 'Donor', 'email': 'kabil@example.com', 'status': 'Active'},
    {'name': 'Arun Kumar', 'role': 'Volunteer', 'email': 'arun@example.com', 'status': 'On Task'},
    {'name': 'Chennai Food Bank', 'role': 'NGO', 'email': 'cfb@ngo.org', 'status': 'Active'},
    {'name': 'Suresh Raina', 'role': 'Donor', 'email': 'suresh@example.com', 'status': 'Inactive'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name or email...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.red.shade50,
                    child: Text(user['name']![0], style: const TextStyle(color: Colors.red)),
                  ),
                  title: Text(user['name']!),
                  subtitle: Text('${user['role']} • ${user['email']}'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: user['status'] == 'Active' ? Colors.green.shade50 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      user['status']!,
                      style: TextStyle(
                        color: user['status'] == 'Active' ? Colors.green : Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  onTap: () => _showUserActions(context, user['name']!),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.red,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }

  void _showUserActions(BuildContext context, String name) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(leading: const Icon(Icons.edit), title: Text('Edit $name'), onTap: () {}),
          ListTile(leading: const Icon(Icons.block, color: Colors.orange), title: const Text('Suspend User'), onTap: () {}),
          ListTile(leading: const Icon(Icons.delete, color: Colors.red), title: const Text('Delete User'), onTap: () {}),
        ],
      ),
    );
  }
}
