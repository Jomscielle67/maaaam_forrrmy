import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daddies_store/provider/product_provider.dart';
import 'package:daddies_store/vendor/views/screens/upload_tap_screens/attributes_screen.dart';
import 'package:daddies_store/vendor/views/screens/upload_tap_screens/general_screen.dart';
import 'package:daddies_store/vendor/views/screens/upload_tap_screens/image_Screen.dart';
import 'package:daddies_store/vendor/views/screens/upload_tap_screens/shipping_screen.dart';
import 'package:daddies_store/vendor/views/screens/main_vendor_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UploadScreen extends StatefulWidget {
  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  int _currentTabIndex = 0;

  void _clearAllData() {
    final ProductProvider productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );

    productProvider.clearAllData();

    if (_formKey.currentState != null) {
      _formKey.currentState!.reset();
    }

    setState(() {
      _currentTabIndex = 0;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product saved successfully!'),
          backgroundColor: Color.fromARGB(255, 16, 155, 23),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  Future<void> _saveProduct() async {
    final ProductProvider productProvider = Provider.of<ProductProvider>(context, listen: false);
    
    if (!productProvider.validateForm()) {
      _showValidationError('Please fill in all required fields correctly');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final productId = Uuid().v4();
      final productData = {
        'productId': productId,
        'productName': productProvider.productData['productName'],
        'productDescription': productProvider.productData['productDescription'],
        'category': productProvider.productData['category'],
        'quantity': productProvider.productData['quantity'],
        'productPrice': productProvider.productData['productPrice'],
        'imageUrlList': productProvider.productData['imageUrlList'],
        'sizeList': productProvider.productData['sizeList'],
        'brandName': productProvider.productData['brandName'],
        'approved': false,
        'chargeShipping': productProvider.productData['chargeShipping'],
        'shippingCharge': productProvider.productData['shippingCharge'],
        'scheduleDate': productProvider.productData['scheduleDate'],
        'vendorId': FirebaseAuth.instance.currentUser?.uid,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      };

      await _firestore.collection('products').doc(productId).set(productData);
      
      if (mounted) {
        // Show success snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product saved successfully!'),
            backgroundColor: Color(0xFFDF9B43),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(10),
          ),
        );
        
        _clearAllData();
        
        // Navigate after a short delay to allow the snackbar to be seen
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const MainVendorScreen(),
              ),
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        print(e.toString());
        _showValidationError('Error saving product: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Builder(
        builder: (context) => Form(
          key: _formKey,
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: const Color(0xFFDF9B43),
              elevation: 2,
              title: const Text(
                'Upload Product',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              bottom: TabBar(
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                onTap: (index) {
                  setState(() {
                    _currentTabIndex = index;
                  });
                },
                tabs: const [
                  Tab(icon: Icon(Icons.info_outline), text: 'General'),
                  Tab(icon: Icon(Icons.local_shipping_outlined), text: 'Shipping'),
                  Tab(icon: Icon(Icons.list_alt_outlined), text: 'Attributes'),
                  Tab(icon: Icon(Icons.image_outlined), text: 'Images'),
                ],
              ),
            ),
            body: Stack(
              children: [
                TabBarView(
                  children: [
                    GeneralScreen(),
                    ShippingScreen(),
                    AttributesScreen(),
                    ImageScreen(),
                  ],
                ),
                if (_isLoading)
                  Container(
                    color: Colors.black.withOpacity(0.5),
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFFDF9B43),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            bottomNavigationBar: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _saveProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDF9B43),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(Icons.save),
                      label: Text(
                        _isLoading ? 'SAVING...' : 'SAVE PRODUCT',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: _isLoading ? null : () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Reset Form'),
                          content: const Text('Are you sure you want to reset all form data?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('CANCEL'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _clearAllData();
                              },
                              child: const Text('RESET'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.refresh),
                    color: const Color(0xFFDF9B43),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
