import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CourierAuth {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current courier
  User? get currentUser => _auth.currentUser;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Register new courier
  Future<UserCredential> registerCourier({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    required String vehicleType,
    required String licenseNumber,
  }) async {
    try {
      // Create user with email and password
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create courier profile in Firestore
      await _firestore.collection('couriers').doc(userCredential.user!.uid).set({
        'name': fullName,
        'email': email,
        'phone': phoneNumber,
        'vehicleType': vehicleType,
        'licenseNumber': licenseNumber,
        'isAvailable': true,
        'assignedOrders': [],
        'rating': 0.0,
        'totalDeliveries': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Login courier
  Future<UserCredential> loginCourier({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Verify if user is a courier
      DocumentSnapshot courierDoc = await _firestore
          .collection('couriers')
          .doc(userCredential.user!.uid)
          .get();

      if (!courierDoc.exists) {
        await _auth.signOut();
        throw 'User is not registered as a courier';
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Logout courier
  Future<void> logoutCourier() async {
    try {
      // Update courier availability before logging out
      if (_auth.currentUser != null) {
        await _firestore
            .collection('couriers')
            .doc(_auth.currentUser!.uid)
            .update({
          'isAvailable': false,
        });
      }
      await _auth.signOut();
    } catch (e) {
      print('Error during logout: $e');
      // Still try to sign out even if updating availability fails
      await _auth.signOut();
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'Email is already in use.';
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}
