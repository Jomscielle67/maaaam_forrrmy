import 'dart:io';

import 'package:daddies_store/provider/product_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class ImageScreen extends StatefulWidget {
  const ImageScreen({super.key});

  @override
  State<ImageScreen> createState() => ImageScreenState();
}

class ImageScreenState extends State<ImageScreen> with AutomaticKeepAliveClientMixin {
  final ImagePicker picker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  List<File> _image = [];
  List<String> _imageUrlList = [];
  bool _isUploading = false;

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
    super.dispose();
  }

  void _handleProviderChange() {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    if (productProvider.productData.isEmpty) {
      resetForm();
    }
  }

  Future<void> chooseImage() async {
    try {
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70, // Compress image quality
        maxWidth: 1024, // Limit image width
        maxHeight: 1024, // Limit image height
      );

      if (pickedFile != null) {
        setState(() {
          _image.add(File(pickedFile.path));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting image: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void resetForm() {
    if (mounted) {
      setState(() {
        _image.clear();
        _imageUrlList.clear();
        _isUploading = false;
      });
    }
  }

  @override
  bool get wantKeepAlive => true;

  Future<void> _uploadImages() async {
    if (_image.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one image'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    _imageUrlList.clear();
    EasyLoading.show(
      status: 'Uploading images...',
      maskType: EasyLoadingMaskType.black,
    );

    try {
      for (var img in _image) {
        // Create a unique filename
        final String fileName = '${Uuid().v4()}.jpg';
        final Reference ref = _storage
            .ref()
            .child('productImage')
            .child(fileName);

        // Upload the file
        final UploadTask uploadTask = ref.putFile(
          img,
          SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {'picked-file-path': img.path},
          ),
        );

        // Get download URL
        final TaskSnapshot taskSnapshot = await uploadTask;
        final String downloadUrl = await taskSnapshot.ref.getDownloadURL();
        
        _imageUrlList.add(downloadUrl);
      }

      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      productProvider.getFormData(imageUrlList: _imageUrlList);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Images uploaded successfully!'),
            backgroundColor: Color(0xFFDF9B43),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading images: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      EasyLoading.dismiss();
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final productProvider = Provider.of<ProductProvider>(context);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Product Images',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFDF9B43),
                  ),
                ),
                IconButton(
                  onPressed: _isUploading ? null : () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Reset Images'),
                        content: const Text('Are you sure you want to remove all uploaded images?'),
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
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _image.length + 1,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1,
                      ),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return GestureDetector(
                            onTap: _isUploading ? null : chooseImage,
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: _isUploading
                                    ? const CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Color(0xFFDF9B43),
                                        ),
                                      )
                                    : const Icon(
                                        Icons.add_a_photo_outlined,
                                        size: 30,
                                        color: Color(0xFFDF9B43),
                                      ),
                              ),
                            ),
                          );
                        } else {
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(_image[index - 1], fit: BoxFit.cover),
                              ),
                              Positioned(
                                top: 5,
                                right: 5,
                                child: GestureDetector(
                                  onTap: _isUploading
                                      ? null
                                      : () {
                                          setState(() {
                                            _image.removeAt(index - 1);
                                          });
                                        },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isUploading ? null : _uploadImages,
                        icon: _isUploading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.cloud_upload_outlined),
                        label: Text(
                          _isUploading ? 'Uploading...' : 'Upload Images',
                          style: const TextStyle(fontWeight: FontWeight.bold),
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
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
