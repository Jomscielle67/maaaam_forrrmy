// Reset form to initial state
import 'dart:typed_data';

import 'package:country_state_city_picker/country_state_city_picker.dart';
import 'package:daddies_store/vendor/controllers/vendor_register_controller.dart';
import 'package:daddies_store/views/buyers/main_screen.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class VendorRegistrationScreen extends StatefulWidget {
  const VendorRegistrationScreen({super.key});

  @override
  State<VendorRegistrationScreen> createState() =>
      _VendorRegistrationScreenState();
}

class _VendorRegistrationScreenState extends State<VendorRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final VendorController _vendorController = VendorController();

  // Controllers
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _taxIdController = TextEditingController();

  // Location and Images
  String countryValue = '';
  String stateValue = '';
  String cityValue = '';
  Uint8List? _storeImage;
  Uint8List? _validIdImage;

  String bussinessName = '';
  String email = '';
  String phoneNumber = '';
  String taxNumber = '';

  // Tax
  String? _taxStatus;
  final List<String> _taxOptions = ['Yes', 'No'];

  Future<void> selectGalleryImage(String type) async {
    Uint8List? im = await _vendorController.pickStorageImage(
      ImageSource.gallery,
    );
    if (im != null) {
      setState(() {
        if (type == 'store') {
          _storeImage = im;
        } else {
          _validIdImage = im;
        }
      });
    }
  }

  Future<void> _saveVendorDetail() async {
    if (_formKey.currentState!.validate()) {
      if (_storeImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a store image.')),
        );
        return;
      }

      if (_validIdImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please upload a valid ID image.')),
        );
        return;
      }

      // Location validation with more helpful feedback
      if (countryValue.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select your country.')),
        );
        return;
      }

      if (stateValue.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select your state/province.')),
        );
        return;
      }

      if (cityValue.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select or enter your city.')),
        );
        return;
      }

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.pink),
            ),
          );
        },
      );

      try {
        // Get values from controllers
        bussinessName = _businessNameController.text;
        email = _emailController.text;
        phoneNumber = _phoneController.text;
        taxNumber = _taxIdController.text;

        String result = await _vendorController.registerVendor(
          bussinessName,
          email,
          phoneNumber,
          countryValue,
          stateValue,
          cityValue,
          _storeImage!,
          _validIdImage!,
          _taxStatus ?? 'No',
          taxNumber,
        );

        // Close loading dialog
        Navigator.pop(context);

        if (result == 'success') {
          // Reset the form after successful registration
          _resetForm();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration successful! Form has been reset.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result), backgroundColor: Colors.red),
          );
        }
      } catch (e) {
        // Close loading dialog if there's an error
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _resetForm() {
    setState(() {
      // Clear text controllers
      _businessNameController.clear();
      _emailController.clear();
      _phoneController.clear();
      _taxIdController.clear();

      // Reset variables
      bussinessName = '';
      email = '';
      phoneNumber = '';
      taxNumber = '';

      // Reset location
      countryValue = '';
      stateValue = '';
      cityValue = '';

      // Reset tax status
      _taxStatus = null;

      // Reset images
      _storeImage = null;
      _validIdImage = null;
    });

    // Reset form validation state
    _formKey.currentState?.reset();
  }

  void _showTermsAndConditions() {
    print('Showing terms and conditions dialog'); // Debug print
    showDialog(
      context: context,
      builder: (BuildContext context) {
        print('Building dialog'); // Debug print
        return AlertDialog(
          title: const Text('Terms and Conditions'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'By registering as a vendor, you agree to the following terms and conditions:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text('1. You must provide accurate and truthful information.'),
                Text('2. You are responsible for maintaining the security of your account.'),
                Text('3. You must comply with all applicable laws and regulations.'),
                Text('4. We reserve the right to suspend or terminate your account if you violate these terms.'),
                Text('5. You must maintain proper business licenses and permits.'),
                Text('6. You are responsible for all content and products you list.'),
                Text('7. You must provide timely customer service and support.'),
                Text('8. You agree to pay all applicable fees and commissions.'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const MainScreen()),
                );
              },
              child: const Text('Reject'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                _saveVendorDetail(); // Proceed with registration
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
              ),
              child: const Text('Accept'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _taxIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.pinkAccent, Colors.purple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Store Image',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () => selectGalleryImage('store'),
                      child: Container(
                        height: 100,
                        width: 100,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 3),
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.white,
                        ),
                        child: _storeImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.memory(_storeImage!, fit: BoxFit.cover),
                              )
                            : const Icon(
                                CupertinoIcons.photo_camera_solid,
                                size: 50,
                                color: Colors.pink,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Vendor Registration",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.pink,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Valid ID Upload Section
                        const Text(
                          "Valid ID Upload",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: GestureDetector(
                            onTap: () => selectGalleryImage('id'),
                            child: _validIdImage != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.memory(_validIdImage!, fit: BoxFit.cover),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        CupertinoIcons.doc_text,
                                        size: 50,
                                        color: Colors.pink,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Upload Valid ID',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        _buildTextField(
                          controller: _businessNameController,
                          label: 'Business Name',
                          onChanged: (value) => bussinessName = value,
                          validator: (value) =>
                              value!.isEmpty ? 'Please enter your business name' : null,
                        ),
                        const SizedBox(height: 12),

                        _buildTextField(
                          controller: _emailController,
                          label: 'Email Address',
                          inputType: TextInputType.emailAddress,
                          onChanged: (value) => email = value,
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!RegExp(
                              r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                            ).hasMatch(value)) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        _buildTextField(
                          controller: _phoneController,
                          label: 'Phone Number',
                          inputType: TextInputType.phone,
                          onChanged: (value) => phoneNumber = value,
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Please enter your phone number';
                            }
                            if (value.length < 10) {
                              return 'Please enter a valid phone number';
                            }
                            if (!RegExp(r'^(09|\+639)\d{9}$').hasMatch(value)) {
                              return "Enter a valid PH phone number";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Location selector with manual city entry option
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Location Details",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 10),
                            SelectState(
                              onCountryChanged: (value) {
                                setState(() {
                                  countryValue = value;
                                  stateValue = '';
                                  cityValue = '';
                                });
                              },
                              onStateChanged: (value) {
                                setState(() {
                                  stateValue = value;
                                  cityValue = '';
                                });
                              },
                              onCityChanged: (value) {
                                setState(() {
                                  cityValue = value;
                                });
                              },
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                              ),
                            ),

                            if (stateValue.isNotEmpty && cityValue.isEmpty)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 12),
                                  const Text(
                                    "Can't find your city? Enter it manually:",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    decoration: InputDecoration(
                                      labelText: 'City Name',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 14,
                                      ),
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        cityValue = value;
                                      });
                                    },
                                  ),
                                ],
                              ),

                            if (countryValue.isNotEmpty ||
                                stateValue.isNotEmpty ||
                                cityValue.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(top: 10),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Country: ${countryValue.isNotEmpty ? countryValue : "Not selected"}',
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'State: ${stateValue.isNotEmpty ? stateValue : "Not selected"}',
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'City: ${cityValue.isNotEmpty ? cityValue : "Not selected"}',
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Tax Information Section
                        const Text(
                          "Tax Information",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Text(
                              'Tax Registered?',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _taxStatus,
                                items: _taxOptions
                                    .map(
                                      (value) => DropdownMenuItem(
                                        value: value,
                                        child: Text(value),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) => setState(() => _taxStatus = value),
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                ),
                                validator: (value) =>
                                    value == null ? 'Please select tax status' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        if (_taxStatus == 'Yes')
                          _buildTextField(
                            controller: _taxIdController,
                            label: 'Tax ID',
                            onChanged: (value) => taxNumber = value,
                            validator: (value) =>
                                value!.isEmpty ? 'Please enter your Tax ID' : null,
                          ),
                        if (_taxStatus == 'Yes') const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.pink,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 2,
                            ),
                            onPressed: _showTermsAndConditions,
                            child: const Text(
                              'Register',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required Function(String) onChanged,
    TextInputType inputType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: inputType,
      validator: validator,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }
}
