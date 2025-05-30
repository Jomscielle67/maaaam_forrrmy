import 'package:daddies_store/vendor/views/auth/vendor_auth_screen.dart';
import 'package:flutter/material.dart';
import 'package:daddies_store/vendor/views/auth/vendor_registration_screen.dart';

class VendorTerms extends StatelessWidget {
  const VendorTerms({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 27, 126, 219),
        title: const Text(
          'Vendor Terms & Conditions',
          style: TextStyle(
            fontFamily: 'Brand-Bold',
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Terms and Conditions for Vendors',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '1. Eligibility',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              '• You must be at least 18 years old\n'
              '• You must have a valid business registration\n'
              '• You must comply with all local laws and regulations',
            ),
            const SizedBox(height: 15),
            const Text(
              '2. Business Requirements',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              '• Valid business license\n'
              '• Tax registration number\n'
              '• Bank account for payments\n'
              '• Valid identification documents',
            ),
            const SizedBox(height: 15),
            const Text(
              '3. Product Guidelines',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              '• Products must be authentic and as described\n'
              '• No counterfeit or illegal items\n'
              '• Clear product images and descriptions required\n'
              '• Fair pricing policies',
            ),
            const SizedBox(height: 15),
            const Text(
              '4. Platform Rules',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              '• Maintain good customer service\n'
              '• Respond to inquiries within 24 hours\n'
              '• Process orders promptly\n'
              '• Maintain accurate inventory',
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const VendorAuthScreen(),
                        
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                  child: const Text(
                    'Accept',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
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
}