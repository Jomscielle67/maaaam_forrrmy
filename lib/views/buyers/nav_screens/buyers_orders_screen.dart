import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daddies_store/controllers/order_controller.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:intl/intl.dart';
import 'package:daddies_store/views/buyers/productDetails/product_detail_screen.dart';
import 'package:daddies_store/views/chat/chat_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BuyersOrdersScreen extends StatefulWidget {
  const BuyersOrdersScreen({super.key});

  @override
  State<BuyersOrdersScreen> createState() => _BuyersOrdersScreenState();
}

class _BuyersOrdersScreenState extends State<BuyersOrdersScreen> {
  final OrderController orderController = OrderController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Orders'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        child: StreamBuilder<QuerySnapshot>(
          stream: orderController.getBuyerOrders(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {});
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No orders yet',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                DocumentSnapshot orderDoc = snapshot.data!.docs[index];
                Map<String, dynamic> orderData = orderDoc.data() as Map<String, dynamic>;
                
                return FutureBuilder(
                  future: _loadVendorInfo(orderData),
                  builder: (context, vendorSnapshot) {
                    if (vendorSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    return _buildOrderCard(context, orderData);
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _loadVendorInfo(Map<String, dynamic> orderData) async {
    for (var product in orderData['products']) {
      if (product['vendorId'] != null) {
        try {
          final vendorDoc = await FirebaseFirestore.instance
              .collection('vendors')
              .doc(product['vendorId'])
              .get();
          
          if (vendorDoc.exists) {
            Map<String, dynamic> vendorData = vendorDoc.data() as Map<String, dynamic>;
            product['vendorName'] = vendorData['bussinessName'];
            product['vendorImage'] = vendorData['storeImage'];
            product['vendorLocation'] = '${vendorData['cityValue'] ?? ''}, ${vendorData['stateValue'] ?? ''}';
            product['vendorPhone'] = vendorData['phoneNumber'];
          }
        } catch (e) {
          print('Error loading vendor info: $e');
        }
      }
    }
  }

  Widget _buildOrderCard(BuildContext context, Map<String, dynamic> orderData) {
    final currencyFormat = NumberFormat.currency(symbol: '₱', decimalDigits: 2);
    final dateFormat = DateFormat('MMM dd, yyyy');
    
    // Get timestamp and convert to DateTime
    Timestamp? createdAt = orderData['createdAt'] as Timestamp?;
    String formattedDate = createdAt != null 
        ? dateFormat.format(createdAt.toDate())
        : 'Date not available';

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        title: Text(
          'Order #${orderData['orderId'].toString().substring(0, 8)}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Date: $formattedDate',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(orderData['status']),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    orderData['status'].toString().toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Total: ${currencyFormat.format(orderData['totalAmount'])}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Products'),
                const SizedBox(height: 8),
                ...List.generate(
                  (orderData['products'] as List).length,
                  (index) {
                    Map<String, dynamic> product = orderData['products'][index];
                    return GestureDetector(
                      onTap: () {
                        // Get the product document from Firestore
                        FirebaseFirestore.instance
                            .collection('products')
                            .doc(product['productId'])
                            .get()
                            .then((productDoc) {
                          if (productDoc.exists) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProductDetailScreen(
                                  productData: productDoc,
                                ),
                              ),
                            );
                          }
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (product['imageUrl'] != null)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      product['imageUrl'],
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          width: 60,
                                          height: 60,
                                          color: Colors.grey[200],
                                          child: const Icon(Icons.image_not_supported),
                                        );
                                      },
                                    ),
                                  ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product['productName'] ?? 'Unknown Product',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Quantity: ${product['quantity']}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                      if (product['size'] != null)
                                        Text(
                                          'Size: ${product['size']}',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Text(
                                  currencyFormat.format(product['price'] * product['quantity']),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 16),
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Colors.grey[200],
                                  backgroundImage: product['vendorImage'] != null && product['vendorImage'].toString().isNotEmpty
                                      ? NetworkImage(product['vendorImage'])
                                      : null,
                                  child: product['vendorImage'] == null || product['vendorImage'].toString().isEmpty
                                      ? const Icon(Icons.store, size: 16, color: Colors.grey)
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product['vendorName'] ?? 'Unknown Vendor',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 12,
                                        ),
                                      ),
                                      if (product['vendorLocation'] != null)
                                        Text(
                                          product['vendorLocation'],
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 11,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                if (product['vendorPhone'] != null)
                                  IconButton(
                                    icon: const Icon(Icons.phone, size: 16),
                                    onPressed: () {
                                      final currentUser = FirebaseAuth.instance.currentUser;
                                      if (currentUser == null) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Please sign in to chat with vendor'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                        return;
                                      }

                                      if (product['vendorId'] == null) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Vendor information not available'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                        return;
                                      }

                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ChatScreen(
                                            currentUserId: currentUser.uid,
                                            otherUserId: product['vendorId'],
                                            otherUserName: product['vendorName'] ?? 'Vendor',
                                          ),
                                        ),
                                      );
                                    },
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    visualDensity: VisualDensity.compact,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const Divider(height: 32),
                _buildSectionTitle('Shipping Information'),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow('Name', orderData['buyerName']),
                        const SizedBox(height: 8),
                        _buildInfoRow('Address', orderData['shippingAddress']),
                        const SizedBox(height: 8),
                        _buildInfoRow('Phone', orderData['buyerPhone']),
                        if (orderData['shippingMethod'] != null) ...[
                          const SizedBox(height: 8),
                          _buildInfoRow('Shipping Method', orderData['shippingMethod']),
                        ],
                        if (orderData['trackingNumber'] != null) ...[
                          const SizedBox(height: 8),
                          _buildInfoRow('Tracking Number', orderData['trackingNumber']),
                        ],
                      ],
                    ),
                  ),
                ),
                const Divider(height: 32),
                _buildSectionTitle('Payment Information'),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow('Method', orderData['paymentMethod']),
                      const SizedBox(height: 8),
                      _buildInfoRow('Status', orderData['paymentStatus'] ?? 'Pending'),
                      const SizedBox(height: 8),
                      _buildInfoRow('Subtotal', currencyFormat.format(orderData['subtotal'] ?? 0)),
                      if (orderData['shippingFee'] != null) ...[
                        const SizedBox(height: 8),
                        _buildInfoRow('Shipping Fee', currencyFormat.format(orderData['shippingFee'])),
                      ],
                      if (orderData['tax'] != null) ...[
                        const SizedBox(height: 8),
                        _buildInfoRow('Tax', currencyFormat.format(orderData['tax'])),
                      ],
                      const Divider(height: 16),
                      _buildInfoRow(
                        'Total Amount',
                        currencyFormat.format(orderData['totalAmount']),
                        isTotal: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (orderData['status'] == 'pending')
                  ElevatedButton(
                    onPressed: () => _cancelOrder(context, orderData['orderId']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Cancel Order'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isTotal ? Colors.black : Colors.grey[700],
            fontSize: isTotal ? 16 : 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isTotal ? Colors.black : Colors.black87,
            fontSize: isTotal ? 16 : 14,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'ready_for_pickup':
        return Colors.purple;
      case 'picked_up':
        return Colors.indigo;
      case 'on_delivery':
        return Colors.teal;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _cancelOrder(BuildContext context, String orderId) async {
    final OrderController orderController = OrderController();
    
    EasyLoading.show(status: 'Cancelling order...');
    String result = await orderController.cancelOrder(orderId);
    EasyLoading.dismiss();

    if (result == 'success') {
      EasyLoading.showSuccess('Order cancelled successfully');
    } else {
      EasyLoading.showError(result);
    }
  }
}
