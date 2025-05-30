import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class VendorController {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> _uploadImageToStorage(Uint8List image, String type) async {
    // Upload image to Firebase Storage
    Reference ref = _storage
        .ref()
        .child(type == 'store' ? 'storeImages' : 'validIdImages')
        .child(_auth.currentUser!.uid);
    UploadTask uploadTask = ref.putData(image);
    TaskSnapshot snapshot = await uploadTask.whenComplete(() {});
    String downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  Future<Uint8List?> pickStorageImage(ImageSource source) async {
    final ImagePicker _imagePicker = ImagePicker();
    XFile? _file = await _imagePicker.pickImage(source: source);
    if (_file != null) {
      return await _file.readAsBytes();
    } else {
      print('No image selected');
      return null;
    }
  }

  Future<String> registerVendor(
    String bussinessName,
    String email,
    String phoneNumber,
    String countryValue,
    String stateValue,
    String cityValue,
    Uint8List storeImage,
    Uint8List validIdImage,
    String taxRegistered,
    String taxNumber,
  ) async {
    // Validate all inputs first
    if (bussinessName.isEmpty) {
      return 'Please enter your business name';
    }
    if (email.isEmpty) {
      return 'Please enter your email';
    }
    if (!RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(email)) {
      return 'Please enter a valid email';
    }
    if (phoneNumber.isEmpty) {
      return 'Please enter your phone number';
    }
    if (phoneNumber.length < 10) {
      return 'Please enter a valid phone number';
    }
    if (!RegExp(r'^(09|\+639)\d{9}$').hasMatch(phoneNumber)) {
      return "Enter a valid PH phone number";
    }
    if (countryValue.isEmpty) {
      return 'Please select your country';
    }
    if (stateValue.isEmpty) {
      return 'Please select your state';
    }
    if (cityValue.isEmpty) {
      return 'Please select your city';
    }
    if (storeImage == null) {
      return 'Please select a store image';
    }
    if (validIdImage == null) {
      return 'Please upload a valid ID image';
    }
    if (taxRegistered == 'Yes' && taxNumber.isEmpty) {
      return 'Please enter your tax number';
    }

    try {
      // Upload both images
      String storeImageUrl = await _uploadImageToStorage(storeImage, 'store');
      String validIdImageUrl = await _uploadImageToStorage(validIdImage, 'id');

      // Set empty tax number if not registered
      if (taxRegistered == 'No') {
        taxNumber = '';
      }

      await _firestore.collection('vendors').doc(_auth.currentUser!.uid).set({
        'bussinessName': bussinessName,
        'email': email,
        'phoneNumber': phoneNumber,
        'countryValue': countryValue,
        'stateValue': stateValue,
        'cityValue': cityValue,
        'storeImage': storeImageUrl,
        'validIdImage': validIdImageUrl,
        'taxRegistered': taxRegistered,
        'taxNumber': taxNumber,
        'approved': false,
        'userId': _auth.currentUser!.uid,
      });

      return 'success';
    } catch (e) {
      return 'An error occurred: ${e.toString()}';
    }
  }
}
