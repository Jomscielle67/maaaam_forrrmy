import 'package:daddies_store/models/product_attributes.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CartProvider with ChangeNotifier {
  Map<String, CartsAttributes> _cartItems = {};
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Map<String, CartsAttributes> get getCartItems {
    return _cartItems;
  }

  double get totalAmount {
    double total = 0.0;
    _cartItems.forEach((key, cartItem) {
      total += cartItem.productPrice * cartItem.quantity;
    });
    return total;
  }

  // Load cart from Firestore
  Future<void> loadCart() async {
    if (_auth.currentUser == null) {
      debugPrint('Cannot load cart: No user logged in');
      return;
    }

    try {
      debugPrint('Loading cart for user: ${_auth.currentUser!.uid}');
      final cartSnapshot = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('cart')
          .get();

      _cartItems.clear();
      for (var doc in cartSnapshot.docs) {
        final data = doc.data();
        debugPrint('Loading cart item: ${doc.id} - ${data['productName']}');
        _cartItems[doc.id] = CartsAttributes(
          productName: data['productName'] ?? '',
          productId: doc.id,
          imageUrl: List<String>.from(data['imageUrl'] ?? []),
          quantity: data['quantity'] ?? 1,
          productPrice: (data['productPrice'] ?? 0.0).toDouble(),
          productSize: data['productSize'] ?? '',
          brandName: data['brandName'] ?? '',
          category: data['category'] ?? '',
          productDescription: data['productDescription'] ?? '',
          vendorId: data['vendorId'] ?? '',
          stock: data['stock'] ?? 0,
        );
      }
      debugPrint('Cart loaded with ${_cartItems.length} items');
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading cart: $e');
    }
  }

  // Save cart to Firestore
  Future<void> _saveCartToFirestore() async {
    if (_auth.currentUser == null) {
      debugPrint('Cannot save cart: No user logged in');
      return;
    }

    try {
      debugPrint('Saving cart for user: ${_auth.currentUser!.uid}');
      final batch = _firestore.batch();
      final cartRef = _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('cart');

      // Add current cart items
      _cartItems.forEach((productId, cartItem) {
        debugPrint('Saving cart item: $productId - ${cartItem.productName}');
        final docRef = cartRef.doc(productId);
        batch.set(docRef, {
          'productName': cartItem.productName,
          'imageUrl': cartItem.imageUrl,
          'quantity': cartItem.quantity,
          'productPrice': cartItem.productPrice,
          'productSize': cartItem.productSize,
          'brandName': cartItem.brandName,
          'category': cartItem.category,
          'productDescription': cartItem.productDescription,
          'vendorId': cartItem.vendorId,
          'stock': cartItem.stock,
        });
      });

      await batch.commit();
      debugPrint('Cart saved successfully with ${_cartItems.length} items');
    } catch (e) {
      debugPrint('Error saving cart: $e');
    }
  }

  void addProductToCart(
    String productId,
    String productName,
    List imageUrl,
    int quantity,
    double productPrice,
    String productSize,
    String brandName,
    String category,
    String productDescription,
    String vendorId,
    int stock,
  ) {
    debugPrint('Adding product to cart: $productId - $productName');
    debugPrint('Current cart items before adding: ${_cartItems.length}');
    
    if (_cartItems.containsKey(productId)) {
      debugPrint('Updating existing cart item');
      // Update existing item
      _cartItems.update(
        productId,
        (existingCartItem) => CartsAttributes(
          productName: existingCartItem.productName,
          productId: existingCartItem.productId,
          imageUrl: existingCartItem.imageUrl,
          quantity: existingCartItem.quantity + quantity,
          productPrice: existingCartItem.productPrice,
          productSize: existingCartItem.productSize,
          brandName: existingCartItem.brandName,
          category: existingCartItem.category,
          productDescription: existingCartItem.productDescription,
          vendorId: existingCartItem.vendorId,
          stock: existingCartItem.stock,
        ),
      );
    } else {
      debugPrint('Adding new cart item');
      // Add new item
      _cartItems.putIfAbsent(
        productId,
        () => CartsAttributes(
          productName: productName,
          productId: productId,
          imageUrl: imageUrl,
          quantity: quantity,
          productPrice: productPrice,
          productSize: productSize,
          brandName: brandName,
          category: category,
          productDescription: productDescription,
          vendorId: vendorId,
          stock: stock,
        ),
      );
    }
    debugPrint('Cart items after adding: ${_cartItems.length}');
    notifyListeners();
    _saveCartToFirestore();
  }

  void updateCartItem(
    String productId, {
    String? size,
    int? quantity,
  }) {
    if (_cartItems.containsKey(productId)) {
      final existingItem = _cartItems[productId]!;
      _cartItems.update(
        productId,
        (existingCartItem) => CartsAttributes(
          productName: existingCartItem.productName,
          productId: existingCartItem.productId,
          imageUrl: existingCartItem.imageUrl,
          quantity: quantity ?? existingCartItem.quantity,
          productPrice: existingCartItem.productPrice,
          productSize: size ?? existingCartItem.productSize,
          brandName: existingCartItem.brandName,
          category: existingCartItem.category,
          productDescription: existingCartItem.productDescription,
          vendorId: existingCartItem.vendorId,
          stock: existingCartItem.stock,
        ),
      );
      notifyListeners();
      _saveCartToFirestore();
    }
  }

  void updateQuantity(String productId, int quantity) {
    if (_cartItems.containsKey(productId)) {
      final cartItem = _cartItems[productId]!;
      // Only update if new quantity is valid (greater than 0 and not exceeding stock)
      if (quantity > 0 && quantity <= cartItem.stock) {
        _cartItems.update(
          productId,
          (existingCartItem) => CartsAttributes(
            productName: existingCartItem.productName,
            productId: existingCartItem.productId,
            imageUrl: existingCartItem.imageUrl,
            quantity: quantity,
            productPrice: existingCartItem.productPrice,
            productSize: existingCartItem.productSize,
            brandName: existingCartItem.brandName,
            category: existingCartItem.category,
            productDescription: existingCartItem.productDescription,
            vendorId: existingCartItem.vendorId,
            stock: existingCartItem.stock,
          ),
        );
        notifyListeners();
        _saveCartToFirestore();
      }
    }
  }

  void removeItem(String productId) {
    _cartItems.remove(productId);
    notifyListeners();
    _saveCartToFirestore();
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
    _saveCartToFirestore();
  }
}

