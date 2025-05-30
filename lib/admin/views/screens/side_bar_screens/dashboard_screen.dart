import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardScreen extends StatelessWidget {
  static const String routeName = 'DashboardScreen';

  const DashboardScreen({super.key});

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate the number of columns based on screen width
        int crossAxisCount = (constraints.maxWidth > 1200)
            ? 4
            : (constraints.maxWidth > 900)
                ? 3
                : (constraints.maxWidth > 600)
                    ? 2
                    : 1;

        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(constraints.maxWidth > 600 ? 32.0 : 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.dashboard_outlined,
                              size: 28,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Text(
                            'Dashboard',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 28,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (constraints.maxWidth > 600)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, size: 16, color: Colors.blue.shade700),
                            const SizedBox(width: 8),
                            Text(
                              'Today',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 32),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('vendors').snapshots(),
                  builder: (context, vendorsSnapshot) {
                    if (!vendorsSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final vendors = vendorsSnapshot.data!.docs;
                    final approvedVendors = vendors.where((doc) => doc['approved'] == true).length;
                    final pendingVendors = vendors.length - approvedVendors;

                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('products').snapshots(),
                      builder: (context, productsSnapshot) {
                        if (!productsSnapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final totalProducts = productsSnapshot.data!.docs.length;

                        return GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: constraints.maxWidth > 600 ? 24 : 16,
                          mainAxisSpacing: constraints.maxWidth > 600 ? 24 : 16,
                          childAspectRatio: constraints.maxWidth > 600 ? 1.5 : 1.8,
                          children: [
                            _buildStatCard(
                              'Total Vendors',
                              vendors.length.toString(),
                              Icons.store,
                              Colors.blue.shade700,
                            ),
                            _buildStatCard(
                              'Approved Vendors',
                              approvedVendors.toString(),
                              Icons.check_circle_outline,
                              Colors.green.shade700,
                            ),
                            _buildStatCard(
                              'Pending Vendors',
                              pendingVendors.toString(),
                              Icons.pending_outlined,
                              Colors.orange.shade700,
                            ),
                            _buildStatCard(
                              'Total Products',
                              totalProducts.toString(),
                              Icons.inventory_2_outlined,
                              Colors.purple.shade700,
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 32),
                Container(
                  padding: EdgeInsets.all(constraints.maxWidth > 600 ? 28 : 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.trending_up,
                                  color: Colors.blue.shade700,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Text(
                                'Recent Activity',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                          if (constraints.maxWidth > 600)
                            TextButton.icon(
                              onPressed: () {},
                              icon: Icon(Icons.filter_list, size: 18, color: Colors.grey[600]),
                              label: Text(
                                'Filter',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: EdgeInsets.symmetric(
                          vertical: constraints.maxWidth > 600 ? 32 : 24,
                          horizontal: constraints.maxWidth > 600 ? 24 : 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.history,
                                size: constraints.maxWidth > 600 ? 48 : 40,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No recent activity',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: constraints.maxWidth > 600 ? 16 : 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Activity will appear here',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: constraints.maxWidth > 600 ? 14 : 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}