import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrderVendorController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get available couriers
  Stream<QuerySnapshot> getAvailableCouriers() {
    return _firestore
        .collection('couriers')
        .where('isAvailable', isEqualTo: true)
        .snapshots();
  }

  // Assign courier to order
  Future<String> assignCourierToOrder({
    required String orderId,
    required String courierId,
  }) async {
    try {
      // Get courier details
      DocumentSnapshot courierDoc = await _firestore
          .collection('couriers')
          .doc(courierId)
          .get();

      if (!courierDoc.exists) {
        return 'Courier not found';
      }

      Map<String, dynamic> courierData = courierDoc.data() as Map<String, dynamic>;
      
      // Check if courier is available
      if (!courierData['isAvailable']) {
        return 'Courier is not available';
      }

      // Get order details
      DocumentSnapshot orderDoc = await _firestore
          .collection('orders')
          .doc(orderId)
          .get();

      if (!orderDoc.exists) {
        return 'Order not found';
      }

      Map<String, dynamic> orderData = orderDoc.data() as Map<String, dynamic>;

      // Check if order is ready for pickup
      if (orderData['status'] != 'ready_for_pickup') {
        return 'Order is not ready for pickup';
      }

      // Start a batch write
      WriteBatch batch = _firestore.batch();

      // Update order with courier information
      DocumentReference orderRef = _firestore.collection('orders').doc(orderId);
      batch.update(orderRef, {
        'courierId': courierId,
        'courierName': courierData['name'],
        'status': 'picked_up',
        'pickedUpAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Create delivery order
      DocumentReference deliveryOrderRef = _firestore.collection('delivery_orders').doc(orderId);
      batch.set(deliveryOrderRef, {
        'orderId': orderId,
        'courierId': courierId,
        'courierName': courierData['name'],
        'status': 'picked_up',
        'vendorId': orderData['vendorId'],
        'vendorName': orderData['vendorName'] ?? 'Unknown Vendor',
        'buyerId': orderData['buyerId'],
        'buyerName': orderData['buyerName'],
        'buyerPhone': orderData['buyerPhone'],
        'shippingAddress': orderData['shippingAddress'],
        'totalAmount': orderData['totalAmount'],
        'createdAt': FieldValue.serverTimestamp(),
        'pickedUpAt': FieldValue.serverTimestamp(),
      });

      // Update courier status and assigned orders
      DocumentReference courierRef = _firestore.collection('couriers').doc(courierId);
      batch.update(courierRef, {
        'isAvailable': false,
        'assignedOrders': FieldValue.arrayUnion([orderId]),
        'currentOrderId': orderId,
        'lastAssignedAt': FieldValue.serverTimestamp(),
      });

      // Send notifications
      await _sendNotifications(
        orderId: orderId,
        courierName: courierData['name'],
        buyerId: orderData['buyerId'],
        vendorId: orderData['vendorId'],
        courierId: courierId,
      );

      // Commit the batch
      await batch.commit();

      return 'success';
    } catch (e) {
      return 'Error assigning courier: $e';
    }
  }

  // Helper method to send notifications
  Future<void> _sendNotifications({
    required String orderId,
    required String courierName,
    required String buyerId,
    required String vendorId,
    required String courierId,
  }) async {
    try {
      // Notify buyer
      await _firestore.collection('notifications').add({
        'userId': buyerId,
        'title': 'Order Picked Up',
        'body': 'Your order has been picked up by $courierName',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Notify vendor
      await _firestore.collection('notifications').add({
        'userId': vendorId,
        'title': 'Order Picked Up',
        'body': 'Order #${orderId.substring(0, 8)} has been picked up by $courierName',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Notify courier
      await _firestore.collection('notifications').add({
        'userId': courierId,
        'title': 'New Delivery Assignment',
        'body': 'You have been assigned to deliver order #${orderId.substring(0, 8)}',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error sending notifications: $e');
    }
  }
}
