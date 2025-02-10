import 'package:flutter/material.dart';
import 'main.dart';
import 'bills_view.dart';
import 'customer_details.dart';
import 'tree_details.dart';
import 'widgets/powered_by_banner.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.brown.shade800,
        title: Row(
          children: [
            Icon(
              Icons.forest,
              color: Colors.green.shade300,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Plathottathil',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    'Timbers & Saw Mill',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.green.shade200,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        elevation: 4,
        shadowColor: Colors.brown.shade900,
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16.0,
                crossAxisSpacing: 16.0,
                children: [
                  // Billing Form Button
                  _buildMenuButton(
                    context,
                    'New Bill',
                    Icons.receipt_long,
                    Colors.blue,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const BillingForm()),
                    ),
                  ),

                  // View Bills Button
                  _buildMenuButton(
                    context,
                    'View Bills',
                    Icons.list_alt,
                    Colors.green,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const BillsView()),
                    ),
                  ),

                  // Customer Details Button
                  _buildMenuButton(
                    context,
                    'Customers',
                    Icons.people,
                    Colors.orange,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const CustomerDetails()),
                    ),
                  ),

                  // Tree Details Button
                  _buildMenuButton(
                    context,
                    'Trees',
                    Icons.forest,
                    Colors.brown,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const TreeDetails()),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const PoweredByBanner(),
        ],
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context, String title, IconData icon,
      Color color, VoidCallback onPressed) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.5),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: color,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
