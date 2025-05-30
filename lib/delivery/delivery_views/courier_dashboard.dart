import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../delivery_controllers/courier_controllers.dart';
import '../delivery_controllers/courier_auth.dart';
import 'courier_login_screen.dart';

class CourierDashboard extends StatefulWidget {
  const CourierDashboard({super.key});

  @override
  State<CourierDashboard> createState() => _CourierDashboardState();
}

class _CourierDashboardState extends State<CourierDashboard> {
  final CourierController _courierController = CourierController();
  final CourierAuth _auth = CourierAuth();
  bool _isLoading = false;
  final currencyFormat = NumberFormat.currency(symbol: '₱', decimalDigits: 2);
  final dateFormat = DateFormat('MMM dd, yyyy hh:mm a');
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  void _checkAuthState() {
    if (_auth.currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const CourierLoginScreen()),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_auth.currentUser == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Courier Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _auth.logoutCourier();
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const CourierLoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('couriers')
            .doc(_auth.currentUser?.uid)
            .snapshots(),
        builder: (context, courierSnapshot) {
          if (courierSnapshot.hasError) {
            return Center(child: Text('Error: ${courierSnapshot.error}'));
          }

          if (!courierSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          Map<String, dynamic> courierData = courierSnapshot.data!.data() as Map<String, dynamic>;
          bool isAvailable = courierData['isAvailable'] ?? true;
          String? currentOrderId = courierData['currentOrderId'];

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Card
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Status',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              Switch(
                                value: isAvailable,
                                onChanged: _isLoading ? null : (value) => _updateAvailability(value),
                                activeColor: Colors.green,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isAvailable ? 'Available for Delivery' : 'Currently on Delivery',
                            style: TextStyle(
                              color: isAvailable ? Colors.green : Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem(
                                'Total Deliveries',
                                courierData['totalDeliveries']?.toString() ?? '0',
                                Icons.local_shipping,
                              ),
                              _buildStatItem(
                                'Rating',
                                (courierData['rating']?.toStringAsFixed(1) ?? '0.0'),
                                Icons.star,
                                color: Colors.amber,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Current Delivery
                  if (currentOrderId != null)
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('delivery_orders')
                          .doc(currentOrderId)
                          .snapshots(),
                      builder: (context, orderSnapshot) {
                        if (!orderSnapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        Map<String, dynamic> orderData = orderSnapshot.data!.data() as Map<String, dynamic>;
                        return _buildCurrentDeliveryCard(orderData);
                      },
                    ),

                  const SizedBox(height: 16),

                  // Assigned Orders
                  Text(
                    'Assigned Orders',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<QuerySnapshot>(
                    stream: _courierController.getAssignedOrders(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      }

                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text('No assigned orders'),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          DocumentSnapshot doc = snapshot.data!.docs[index];
                          Map<String, dynamic> orderData = doc.data() as Map<String, dynamic>;
                          return _buildOrderCard(orderData);
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, {Color? color}) {
    return Column(
      children: [
        Icon(icon, color: color ?? Colors.blue, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentDeliveryCard(Map<String, dynamic> orderData) {
    String status = orderData['status'];
    bool canUpdateStatus = status == 'picked_up' || status == 'on_delivery';

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Current Delivery',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toString().toUpperCase().replaceAll('_', ' '),
                    style: TextStyle(
                      color: _getStatusColor(status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDeliveryInfoRow('Order ID', '#${orderData['orderId'].toString().substring(0, 8)}'),
            _buildDeliveryInfoRow('Customer', orderData['buyerName']),
            _buildDeliveryInfoRow('Address', orderData['shippingAddress']),
            _buildDeliveryInfoRow('Amount', currencyFormat.format(orderData['totalAmount'])),
            const SizedBox(height: 16),
            if (canUpdateStatus)
              Row(
                children: [
                  if (status == 'picked_up')
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : () => _updateDeliveryStatus(orderData['orderId'], 'on_delivery'),
                        icon: const Icon(Icons.directions_bike),
                        label: const Text('Start Delivery'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  if (status == 'on_delivery')
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : () => _updateDeliveryStatus(orderData['orderId'], 'delivered'),
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Mark Delivered'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> orderData) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text('Order #${orderData['orderId'].toString().substring(0, 8)}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Customer: ${orderData['buyerName']}'),
            Text('Amount: ${currencyFormat.format(orderData['totalAmount'])}'),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getStatusColor(orderData['status']).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            orderData['status'].toString().toUpperCase().replaceAll('_', ' '),
            style: TextStyle(
              color: _getStatusColor(orderData['status']),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        onTap: () {
          // TODO: Navigate to order details
        },
      ),
    );
  }

  Widget _buildDeliveryInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'picked_up':
        return Colors.blue;
      case 'on_delivery':
        return Colors.orange;
      case 'delivered':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<void> _updateAvailability(bool isAvailable) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('couriers')
          .doc(_auth.currentUser?.uid)
          .update({
        'isAvailable': isAvailable,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating availability: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateDeliveryStatus(String orderId, String status) async {
    setState(() {
      _isLoading = true;
    });

    try {
      String result = await _courierController.updateDeliveryStatus(orderId, status);
      
      if (result == 'success') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Status updated to ${status.replaceAll('_', ' ')}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update status: $result'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
