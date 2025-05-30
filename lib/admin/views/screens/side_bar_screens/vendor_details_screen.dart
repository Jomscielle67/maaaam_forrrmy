import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class VendorDetailsScreen extends StatelessWidget {
  static const String routeName = 'VendorDetailsScreen';
  final DocumentSnapshot vendorData;

  const VendorDetailsScreen({
    super.key,
    required this.vendorData,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Vendor Details',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 12.0 : 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with logo and business name
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Logo
                    Container(
                      height: isSmallScreen ? 80 : 100,
                      width: isSmallScreen ? 80 : 100,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 15,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: vendorData['storeImage'] != null &&
                              vendorData['storeImage'].toString().isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.network(
                                vendorData['storeImage'],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.store, size: 48, color: Color(0xFF6C757D)),
                              ),
                            )
                          : const Icon(Icons.store, size: 48, color: Color(0xFF6C757D)),
                    ),
                    SizedBox(height: isSmallScreen ? 16 : 24),
                    // Business name and status
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          vendorData['bussinessName'] ?? 'No name',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 24 : 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                            color: const Color(0xFF1A1A1A),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: isSmallScreen ? 8 : 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: vendorData['approved'] == true
                                ? const Color(0xFFE8F5E9)
                                : const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: vendorData['approved'] == true
                                  ? const Color(0xFF81C784)
                                  : const Color(0xFFFFB74D),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                vendorData['approved'] == true
                                    ? Icons.check_circle
                                    : Icons.pending,
                                size: 16,
                                color: vendorData['approved'] == true
                                    ? const Color(0xFF2E7D32)
                                    : const Color(0xFFF57C00),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                vendorData['approved'] == true ? 'Approved' : 'Pending',
                                style: TextStyle(
                                  color: vendorData['approved'] == true
                                      ? const Color(0xFF2E7D32)
                                      : const Color(0xFFF57C00),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: isSmallScreen ? 24 : 32),
              // Business Information
              _buildSection(
                title: 'Business Information',
                icon: Icons.business,
                isSmallScreen: isSmallScreen,
                children: [
                  _buildInfoRow('Business Name', vendorData['bussinessName'] ?? 'N/A'),
                  _buildInfoRow('Email', vendorData['email'] ?? 'N/A'),
                  _buildInfoRow('Phone', vendorData['phoneNumber'] ?? 'N/A'),
                  _buildInfoRow('Tax Number', vendorData['taxNumber'] ?? 'N/A'),
                  _buildInfoRow('Tax Registered', vendorData['taxRegistered'] == true ? 'Yes' : 'No'),
                  _buildInfoRow('User ID', vendorData['userId'] ?? 'N/A'),
                ],
              ),
              SizedBox(height: isSmallScreen ? 16 : 24),
              // Location Information
              _buildSection(
                title: 'Location Information',
                icon: Icons.location_on,
                isSmallScreen: isSmallScreen,
                children: [
                  _buildInfoRow('City', vendorData['cityValue'] ?? 'N/A'),
                  _buildInfoRow('State', vendorData['stateValue'] ?? 'N/A'),
                  _buildInfoRow('Country', vendorData['countryValue'] ?? 'N/A'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
    required bool isSmallScreen,
  }) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF1976D2),
                  size: isSmallScreen ? 20 : 24,
                ),
              ),
              SizedBox(width: isSmallScreen ? 8 : 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: isSmallScreen ? 18 : 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A1A1A),
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 16 : 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6C757D),
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1A1A1A),
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 8),
          Divider(
            color: const Color(0xFFE9ECEF),
            height: 1,
            thickness: 1,
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return '${date.day}/${date.month}/${date.year}';
    }
    return 'N/A';
  }
} 