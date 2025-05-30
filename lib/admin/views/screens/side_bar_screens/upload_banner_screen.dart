import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daddies_store/admin/views/screens/side_bar_screens/widgets/banner_widget.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class UploadBannerScreen extends StatefulWidget {
  static const String routeName = '/upload-banner';

  const UploadBannerScreen({super.key});

  @override
  State<UploadBannerScreen> createState() => _UploadBannerScreenState();
}

class _UploadBannerScreenState extends State<UploadBannerScreen> {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Uint8List? _image;
  String? fileName;
  bool _isUploading = false;

  Future<void> pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.image,
        withData: true,
      );

      if (result != null) {
        if (result.files.first.size > 5 * 1024 * 1024) { // 5MB limit
          EasyLoading.showError('Image size should be less than 5MB');
          return;
        }
        
        setState(() {
          _image = result.files.first.bytes;
          fileName = result.files.first.name;
        });
      }
    } catch (e) {
      EasyLoading.showError('Error picking image: $e');
    }
  }

  Future<String> _uploadBannersToStorage(dynamic image) async {
    try {
      Reference ref = _storage.ref().child('Banners').child(fileName!);
      UploadTask uploadTask = ref.putData(image);
      TaskSnapshot snapShot = await uploadTask;
      return await snapShot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  Future<void> uploadToFirebaseStore() async {
    if (_image == null) {
      EasyLoading.showError('Please select an image first');
      return;
    }

    setState(() => _isUploading = true);
    EasyLoading.show(status: 'Uploading...');

    try {
      String imageUrl = await _uploadBannersToStorage(_image);
      
      await _firestore.collection('banners').doc(fileName).set({
        'image': imageUrl,
        'uploadedAt': FieldValue.serverTimestamp(),
      });

      EasyLoading.showSuccess('Banner uploaded successfully!');
      setState(() {
        _image = null;
        fileName = null;
      });
    } catch (e) {
      EasyLoading.showError('Failed to upload: $e');
    } finally {
      setState(() => _isUploading = false);
      EasyLoading.dismiss();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'BANNERS',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 36,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 20),
            const Divider(color: Colors.grey),
            const SizedBox(height: 20),
            
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    bool isSmallScreen = constraints.maxWidth < 600;
                    
                    return isSmallScreen
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              _buildImagePreview(),
                              const SizedBox(height: 20),
                              _buildUploadInfo(),
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildImagePreview(),
                              const SizedBox(width: 40),
                              Expanded(
                                child: _buildUploadInfo(),
                              ),
                            ],
                          );
                  },
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            const Divider(color: Colors.grey),
            const SizedBox(height: 20),
            
            const Text(
              'ALL BANNERS',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 24,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 20),
            const BannerWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Column(
      children: [
        Container(
          height: 200,
          width: 200,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: Colors.grey.shade300,
              width: 2,
            ),
          ),
          child: _image != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: Image.memory(
                    _image!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_outlined,
                        size: 50,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No Image Selected',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _isUploading ? null : pickImage,
          icon: const Icon(Icons.upload_file),
          label: const Text('Select Image'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upload Banner',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Supported formats: JPG, PNG\nMaximum size: 5MB',
          style: TextStyle(
            color: Colors.grey,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _isUploading ? null : uploadToFirebaseStore,
          icon: _isUploading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.save),
          label: Text(_isUploading ? 'Uploading...' : 'Save Banner'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: 32,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }
}
 