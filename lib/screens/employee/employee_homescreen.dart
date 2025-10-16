import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EmployeeHomeScreen extends StatefulWidget {
  const EmployeeHomeScreen({super.key});

  @override
  State<EmployeeHomeScreen> createState() => _EmployeeHomeScreenState();
}

class _EmployeeHomeScreenState extends State<EmployeeHomeScreen> {
  bool loading = false;

  Future<void> _logout() async {
    setState(() => loading = true);
    try {
      await FirebaseAuth.instance.signOut();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text('Employee Dashboard',
            style: textTheme.titleMedium?.copyWith(color: Colors.white)),
        backgroundColor: color,
        actions: [
          IconButton(
            icon: loading
                ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: loading ? null : _logout,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome 👋',
                style: textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Your assigned stock tasks will appear here.',
              style: textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.task_alt, color: color),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No current tasks assigned.',
                      style: textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('You can poke your manager if stock is low:',
                style: textTheme.titleMedium),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Poke manager feature coming soon!')));
              },
              icon: const Icon(Icons.notification_add),
              label: const Text('Poke Manager'),
            ),
          ],
        ),
      ),
    );
  }
}
