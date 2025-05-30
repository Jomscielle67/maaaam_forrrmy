import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daddies_store/vendor/models/vendor_user_models.dart';
import 'package:daddies_store/vendor/views/auth/vendor_registration_screen.dart';
import 'package:daddies_store/vendor/views/screens/main_vendor_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    final CollectionReference _vendorsCollection = FirebaseFirestore.instance
        .collection('vendors');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendor Dashboard'),
        backgroundColor: const Color.fromARGB(255, 71, 150, 68),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _auth.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _vendorsCollection.doc(_auth.currentUser?.uid).snapshots(),
        builder: (
          BuildContext context,
          AsyncSnapshot<DocumentSnapshot> snapshot,
        ) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Something went wrong',
                style: TextStyle(fontSize: 16, color: Colors.red),
              ),
            );
          }

          if (!snapshot.hasData ||
              !snapshot.data!.exists ||
              _auth.currentUser == null) {
            return const VendorRegistrationScreen();
          }

          try {
            Map<String, dynamic> data =
                snapshot.data!.data() as Map<String, dynamic>;
            VendorUserModels vendorUserModels = VendorUserModels.fromJson(data);

            if (vendorUserModels.approved == true) {
              return const MainVendorScreen();
            }

            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.green[50]!,
                    Colors.white,
                  ],
                ),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (vendorUserModels.storeImage != null &&
                          vendorUserModels.storeImage!.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(bottom: 24.0),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.3),
                                spreadRadius: 2,
                                blurRadius: 5,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 60,
                            backgroundImage: NetworkImage(
                              vendorUserModels.storeImage!,
                            ),
                            onBackgroundImageError: (_, __) {},
                          ),
                        ),
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange[100],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Application Status',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Hello, Your Application has been sent to Shop admin. Admin will get back to you soon!',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[800],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              _buildInfoRow(
                                Icons.business,
                                vendorUserModels.bussinessName ?? 'No Business Name',
                              ),
                              const SizedBox(height: 12),
                              _buildInfoRow(
                                Icons.email,
                                vendorUserModels.email ?? 'No Email',
                              ),
                              const SizedBox(height: 12),
                              _buildInfoRow(
                                Icons.location_city,
                                '${vendorUserModels.cityValue ?? 'N/A'}, ${vendorUserModels.stateValue ?? 'N/A'}',
                              ),
                              const SizedBox(height: 12),
                              _buildInfoRow(
                                Icons.phone,
                                vendorUserModels.phoneNumber ?? 'N/A',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          } catch (e) {
            print("Error: $e");
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error accessing vendor data: $e',
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 71, 150, 68),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: const Color.fromARGB(255, 71, 150, 68)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
