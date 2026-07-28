import 'package:flutter/material.dart';
import '../../services/data_service.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: DataService().notificationStream,
        initialData: const [],
        builder: (context, snapshot) {
          final notifications = snapshot.data ?? [];
          
          if (notifications.isEmpty) {
            return const Center(child: Text('No notifications yet.'));
          }

          return ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final note = notifications[index];
              final Color color = Color(note['color']);
              
              final iconData = IconData(note['icon'] as int? ?? 0xe44f, fontFamily: 'MaterialIcons');
              
              return ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.1),
                  child: Icon(
                    iconData,
                    color: color,
                  ),
                ),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(note['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(note['time'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(note['body']),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
