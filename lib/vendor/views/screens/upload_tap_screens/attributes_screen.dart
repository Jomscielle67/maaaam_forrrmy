import 'package:daddies_store/provider/product_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AttributesScreen extends StatefulWidget {
  @override
  State<AttributesScreen> createState() => AttributesScreenState();
}

class AttributesScreenState extends State<AttributesScreen> with AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _sizeController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  bool _entered = false;
  bool _isSaved = false;
  List<String> _sizeList = [];

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
    _sizeController.dispose();
    _brandController.dispose();
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
        _sizeController.clear();
        _brandController.clear();
        _entered = false;
        _isSaved = false;
        _sizeList.clear();
        _formKey.currentState?.reset();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final _productProvider = Provider.of<ProductProvider>(context);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Product Attributes',
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _brandController,
                        onChanged: (value) {
                          _productProvider.getFormData(brandName: value);
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter brand name';
                          }
                          if (value.length < 2) {
                            return 'Brand name must be at least 2 characters';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: 'Brand',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.branding_watermark),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Container(
                              width: 100,
                              child: TextFormField(
                                controller: _sizeController,
                                onChanged: (value) {
                                  setState(() {
                                    _entered = true;
                                  });
                                },
                                validator: (value) {
                                  if (_entered && (value == null || value.isEmpty)) {
                                    return 'Please enter size';
                                  }
                                  if (_entered && value!.length < 1) {
                                    return 'Size must be at least 1 character';
                                  }
                                  return null;
                                },
                                decoration: InputDecoration(
                                  labelText: 'Size',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  prefixIcon: const Icon(Icons.straighten),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          _entered == true
                              ? ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFDF9B43),
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: () {
                                    if (_formKey.currentState!.validate()) {
                                      setState(() {
                                        if (_sizeController.text.trim().isNotEmpty) {
                                          _sizeList.add(_sizeController.text.trim());
                                          _sizeController.clear();
                                          _entered = false;
                                        }
                                      });
                                    }
                                  },
                                  child: const Text(
                                    'Add',
                                    style: TextStyle(color: Colors.white, fontSize: 16),
                                  ),
                                )
                              : const Text('Enter the size'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (_sizeList.isNotEmpty) ...[
                const Text(
                  'Added Sizes:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 100,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _sizeList.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDF9B43).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _sizeList[index],
                              style: const TextStyle(fontSize: 14),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20),
                              onPressed: () {
                                setState(() {
                                  _sizeList.removeAt(index);
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _productProvider.getFormData(
                        brandName: _brandController.text,
                        sizeList: _sizeList,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Attributes saved successfully!'),
                          backgroundColor: Color(0xFFDF9B43),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.save),
                  label: const Text(
                    'Save Attributes',
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
