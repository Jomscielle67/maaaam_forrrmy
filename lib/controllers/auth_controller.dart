import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  

  uploadProfileImageToStorage(Uint8List imageBytes) async {
    try {
      Reference ref = _storage.ref().child('profilePics').child(_auth.currentUser!.uid);
      UploadTask uploadTask = ref.putData(imageBytes);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw 'Error uploading profile image: $e';
    }
  }

  Future<Uint8List?> pickImage(ImageSource source) async {
    final ImagePicker imagePicker = ImagePicker();

    try {
      final XFile? file = await imagePicker.pickImage(source: source);
      if (file != null) {
        return await file.readAsBytes();
      }
      return null;
    } catch (e) {
      throw 'Error picking image: $e';
    }
  }

  // Signup method
  Future<String> SignUpUsers(
    String email,
    String fullName,
    String phoneNumber,
    String password1,
    String password2,
    Uint8List? image,
  ) async {
    try {
      if (email.isEmpty ||
          fullName.isEmpty ||
          phoneNumber.isEmpty ||
          password1.isEmpty ||
          password2.isEmpty ||
          image == null) {
        return "Please fill in all fields";
      }

      if (!RegExp(
        r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
      ).hasMatch(email)) {
        return "Please enter a valid email address";
      }

      if (!RegExp(r'^(09|\+639)\d{9}$').hasMatch(phoneNumber)) {
        return "Enter a valid PH phone number";
      }

      if (password1 != password2) {
        return "Passwords do not match";
      }

      // Create user with email and password
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password1,
      );

      // Upload profile image
      String profileImageUrl = await uploadProfileImageToStorage(image);

      // Create user document in Firestore
      await _firestore.collection('buyers').doc(cred.user!.uid).set({
        'email': email,
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'uid': cred.user!.uid,
        'address': '',
        'profileImage': profileImageUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return 'success';
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'weak-password':
          return 'The password provided is too weak.';
        case 'email-already-in-use':
          return 'An account already exists for that email.';
        case 'invalid-email':
          return 'The email address is not valid.';
        default:
          return 'An error occurred during sign up: ${e.message}';
      }
    } catch (e) {
      return 'An unexpected error occurred: $e';
    }
  }

  // Login method
  Future<String> loginUser(String email, String password) async {
    try {
      if (email.isEmpty || password.isEmpty) {
        return "Please fill in all fields";
      }

      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return 'success';
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return 'No user found with this email';
        case 'wrong-password':
          return 'Wrong password';
        case 'invalid-email':
          return 'Invalid email format';
        case 'user-disabled':
          return 'This account has been disabled';
        case 'too-many-requests':
          return 'Too many failed login attempts. Please try again later';
        default:
          return 'Login failed: ${e.message}';
      }
    } catch (e) {
      return 'An unexpected error occurred: $e';
    }
  }
}

