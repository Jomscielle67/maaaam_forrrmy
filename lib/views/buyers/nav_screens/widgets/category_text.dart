import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daddies_store/views/buyers/nav_screens/widgets/home_products.dart';
import 'package:daddies_store/views/buyers/nav_screens/widgets/main_products_widget.dart';
import 'package:flutter/material.dart';

class CategoryText extends StatefulWidget {
  const CategoryText({super.key});

  @override
  State<CategoryText> createState() => _CategoryTextState();
}

class _CategoryTextState extends State<CategoryText> {
  String _selectedCategory = '';

  @override
  Widget build(BuildContext context) {
    final Stream<QuerySnapshot> _categoryStream =
        FirebaseFirestore.instance.collection('categories').snapshots();
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Categories',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              StreamBuilder<QuerySnapshot>(
                stream: _categoryStream,
                builder: (
                  BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot,
                ) {
                  if (snapshot.hasError) {
                    return const Text('Something went wrong');
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return SizedBox(
                    height: 50,
                    child: Row(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: snapshot.data!.docs.length,
                            itemBuilder: (context, index) {
                              final categoryData = snapshot.data!.docs[index];
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ActionChip(
                                  label: Text(
                                    categoryData['categoryName'],
                                    style: TextStyle(
                                      color: _selectedCategory == categoryData['categoryName']
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                  backgroundColor: _selectedCategory == categoryData['categoryName']
                                      ? Theme.of(context).primaryColor
                                      : Colors.grey[200],
                                  onPressed: () {
                                    setState(() {
                                      _selectedCategory = categoryData['categoryName'];
                                    });
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.arrow_forward_ios, size: 20),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              if (_selectedCategory.isEmpty)
                MainProductsWidget(),
              if (_selectedCategory.isNotEmpty)
                HomeProducts(categoryName: _selectedCategory),
            ],
          ),
        ),
      ),
    );
  }
}
