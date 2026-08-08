import 'package:flutter/material.dart';

class SmsLogsScreen extends StatefulWidget {
  const SmsLogsScreen({super.key});

  @override
  State<SmsLogsScreen> createState() => _SmsLogsScreenState();
}

class _SmsLogsScreenState extends State<SmsLogsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("SMS Audit Logs")),
      body: const Center(
        child: Text("SMS Logs Integration Ready on Backend.\nAdmin UI for viewing logs is being optimized."),
      ),
    );
  }
}
