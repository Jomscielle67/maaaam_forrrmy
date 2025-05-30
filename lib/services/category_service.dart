import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category_model.dart';

class CategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Category>> getCategories() async {
    try {
      final QuerySnapshot snapshot = await _firestore.collection('categories').get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Category.fromJson({
          'id': doc.id,
          ...data,
        });
      }).toList();
    } catch (e) {
      print('Error fetching categories: $e');
      return [];
    }
  }

  Future<void> initializeSampleCategories() async {
    try {
      // Check if categories already exist
      final QuerySnapshot snapshot = await _firestore.collection('categories').get();
      if (snapshot.docs.isNotEmpty) {
        print('Categories already exist, skipping initialization');
        return;
      }

      // Sample categories data
      final List<Map<String, dynamic>> categories = [
        {
          'name': 'Electronics',
          'imageUrl': 'https://images.unsplash.com/photo-1498049794561-7780e7231661?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1470&q=80',
          'description': 'Latest gadgets and electronic devices',
        },
        {
          'name': 'Fashion',
          'imageUrl': 'https://images.unsplash.com/photo-1445205170230-053b83016050?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1471&q=80',
          'description': 'Trendy clothing and accessories',
        },
        {
          'name': 'Home & Living',
          'imageUrl': 'https://images.unsplash.com/photo-1484101403633-562f891dc89a?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1474&q=80',
          'description': 'Furniture and home decor items',
        },
        {
          'name': 'Beauty',
          'imageUrl': 'https://images.unsplash.com/photo-1596462502278-27bfdc403348?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1480&q=80',
          'description': 'Beauty and personal care products',
        },
        {
          'name': 'Sports',
          'imageUrl': 'https://images.unsplash.com/photo-1461896836934-ffe607ba8211?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1470&q=80',
          'description': 'Sports equipment and accessories',
        },
        {
          'name': 'Books',
          'imageUrl': 'https://images.unsplash.com/photo-1495446815901-a7297e633e8d?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1470&q=80',
          'description': 'Books and educational materials',
        },
      ];

      // Add categories to Firestore
      for (var category in categories) {
        await _firestore.collection('categories').add(category);
      }
      print('Sample categories initialized successfully');
    } catch (e) {
      print('Error initializing sample categories: $e');
    }
  }
} 