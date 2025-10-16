import 'package:flutter/material.dart';

class ManagerDashboardTab extends StatelessWidget {
  const ManagerDashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: Text(
          '📊 Manager Dashboard overview\n\n(Place KPIs, Recent Pokes, Quick Actions here)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
