import 'package:daddies_store/provider/product_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ShippingScreen extends StatefulWidget {
  @override
  State<ShippingScreen> createState() => ShippingScreenState();
}

class ShippingScreenState extends State<ShippingScreen> with AutomaticKeepAliveClientMixin {
  bool? _chargeShipping = false;
  final _formKey = GlobalKey<FormState>();
  final _shippingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Add listener to provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      productProvider.addListener(_handleProviderChange);
    });
  }

  @override
  void dispose() {
    // Remove listener when widget is disposed
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    productProvider.removeListener(_handleProviderChange);
    _shippingController.dispose();
    super.dispose();
  }

  void _handleProviderChange() {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    if (productProvider.productData.isEmpty) {
      resetForm();
    }
  }

  @override
  bool get wantKeepAlive => true;

  void resetForm() {
    if (mounted) {
      setState(() {
        _chargeShipping = false;
        _shippingController.clear();
        _formKey.currentState?.reset();
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Form is valid, proceed with submission
      final ProductProvider _productProvider = Provider.of<ProductProvider>(context, listen: false);
      if (_chargeShipping == true) {
        _productProvider.getFormData(
          chargeShipping: _chargeShipping,
          shippingCharge: int.parse(_shippingController.text),
        );
      } else {
        _productProvider.getFormData(chargeShipping: _chargeShipping);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final ProductProvider _productProvider = Provider.of<ProductProvider>(context);
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Shipping Information',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFDF9B43),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Reset Fields'),
                          content: const Text('Are you sure you want to reset all fields in this section?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('CANCEL'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                resetForm();
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
              const SizedBox(height: 20),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      CheckboxListTile(
                        title: const Text(
                          'Charge Shipping',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                          ),
                        ),
                        value: _chargeShipping,
                        onChanged: (value) {
                          setState(() {
                            _chargeShipping = value;
                            _productProvider.getFormData(chargeShipping: _chargeShipping);
                          });
                        },
                      ),

                      if (_chargeShipping == true) 
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextFormField(
                            controller: _shippingController,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (_chargeShipping == true) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter shipping charge';
                                }
                                if (int.tryParse(value) == null) {
                                  return 'Please enter a valid number';
                                }
                                if (int.parse(value) < 0) {
                                  return 'Shipping charge cannot be negative';
                                }
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              labelText: 'Shipping Charge',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: const Icon(Icons.local_shipping),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      if (_chargeShipping == true) {
                        _productProvider.getFormData(
                          chargeShipping: _chargeShipping,
                          shippingCharge: int.parse(_shippingController.text),
                        );
                      } else {
                        _productProvider.getFormData(chargeShipping: _chargeShipping);
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Shipping information saved successfully!'),
                          backgroundColor: Color(0xFFDF9B43),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.save),
                  label: const Text(
                    'Save Shipping Information',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDF9B43),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
