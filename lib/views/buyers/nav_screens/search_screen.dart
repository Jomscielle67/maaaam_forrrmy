import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../productDetails/product_detail_screen.dart';
import '../main_screen.dart';
import '../../../models/cart_provider.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<String> recentSearches = [];
  List<String> popularSearches = [];
  List<Map<String, dynamic>> searchResults = [];
  bool isSearching = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    _loadPopularSearches();
    
    // Get the search query from the route arguments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is String) {
        print('Search query received: $args'); // Debug print
        _searchController.text = args;
        _performSearch(args);
      }
    });
  }

  Future<void> _loadRecentSearches() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final snapshot = await _firestore
          .collection('user_searches')
          .doc(userId)
          .collection('recent_searches')
          .orderBy('timestamp', descending: true)
          .limit(5)
          .get();

      setState(() {
        recentSearches = snapshot.docs
            .map((doc) => doc['query'] as String)
            .toList();
      });
    } catch (e) {
      print('Error loading recent searches: $e');
    }
  }

  Future<void> _loadPopularSearches() async {
    try {
      final snapshot = await _firestore
          .collection('popular_searches')
          .orderBy('count', descending: true)
          .limit(5)
          .get();

      setState(() {
        popularSearches = snapshot.docs
            .map((doc) => doc['query'] as String)
            .toList();
      });
    } catch (e) {
      print('Error loading popular searches: $e');
    }
  }

  Future<void> _saveSearch(String query) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      // Save to user's recent searches
      await _firestore
          .collection('user_searches')
          .doc(userId)
          .collection('recent_searches')
          .add({
        'query': query,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update popular searches
      final popularSearchRef = _firestore.collection('popular_searches').doc(query);
      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(popularSearchRef);
        if (doc.exists) {
          transaction.update(popularSearchRef, {
            'count': FieldValue.increment(1),
          });
        } else {
          transaction.set(popularSearchRef, {
            'query': query,
            'count': 1,
          });
        }
      });

      // Reload searches
      await _loadRecentSearches();
      await _loadPopularSearches();
    } catch (e) {
      print('Error saving search: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    print('Performing search for: $query'); // Debug print

    setState(() {
      isSearching = true;
    });

    try {
      // Save the search query
      await _saveSearch(query);

      // Split the search query into words and clean them
      List<String> searchWords = query.toLowerCase()
          .split(' ')
          .where((word) => word.isNotEmpty)
          .map((word) => word.trim())
          .toList();

      print('Search words: $searchWords'); // Debug print

      // Search in products collection
      QuerySnapshot productSnapshot = await _firestore
          .collection('products')
          .get();

      // Filter products locally to match any of the search words
      List<QueryDocumentSnapshot> filteredProducts = productSnapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        
        // Get and clean the searchable fields
        final productName = (data['productName'] ?? '').toString().toLowerCase().trim();
        final brandName = (data['brandName'] ?? '').toString().toLowerCase().trim();
        final description = (data['productDescription'] ?? '').toString().toLowerCase().trim();
        final category = (data['category'] ?? '').toString().toLowerCase().trim();

        // Debug print for each product
        print('Checking product: $productName');
        print('Brand: $brandName');
        print('Category: $category');

        // Check if any search word matches any of the fields
        bool matches = searchWords.any((word) {
          bool nameMatch = productName.contains(word);
          bool brandMatch = brandName.contains(word);
          bool descMatch = description.contains(word);
          bool categoryMatch = category.contains(word);

          if (nameMatch || brandMatch || descMatch || categoryMatch) {
            print('Match found for word "$word" in product: $productName');
          }

          return nameMatch || brandMatch || descMatch || categoryMatch;
        });

        return matches;
      }).toList();

      print('Products found: ${filteredProducts.length}'); // Debug print

      // Search in categories
      final QuerySnapshot categorySnapshot = await _firestore
          .collection('categories')
          .where('name', isGreaterThanOrEqualTo: query.toLowerCase())
          .where('name', isLessThanOrEqualTo: query.toLowerCase() + '\uf8ff')
          .get();

      print('Categories found: ${categorySnapshot.docs.length}'); // Debug print

      setState(() {
        searchResults = [
          ...filteredProducts.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            print('Adding product to results: ${data['productName']}'); // Debug print
            return {
              'type': 'product',
              'data': data,
              'id': doc.id,
            };
          }),
          ...categorySnapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            print('Adding category to results: ${data['name']}'); // Debug print
            return {
              'type': 'category',
              'data': data,
              'id': doc.id,
            };
          }),
        ];
        isSearching = false;
      });

      print('Total results: ${searchResults.length}'); // Debug print
    } catch (e) {
      print('Search error: $e'); // Debug print
      setState(() {
        isSearching = false;
      });
      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error performing search: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const MainScreen()),
              (route) => false,
            );
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar
              TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onSubmitted: _performSearch,
                decoration: InputDecoration(
                  hintText: 'Search for products',
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: SvgPicture.asset(
                      'assets/icons/search.svg',
                      width: 10,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
              const SizedBox(height: 24),

              if (isSearching)
                const Center(child: CircularProgressIndicator())
              else if (searchResults.isNotEmpty)
                Expanded(
                  child: ListView.builder(
                    itemCount: searchResults.length,
                    itemBuilder: (context, index) {
                      final item = searchResults[index];
                      if (item['type'] == 'product') {
                        return _buildProductCard(item);
                      } else {
                        return _buildCategoryCard(item);
                      }
                    },
                  ),
                )
              else if (_searchController.text.isNotEmpty)
                const Center(
                  child: Text('No results found'),
                )
              else ...[
                // Recent Searches Section
                if (recentSearches.isNotEmpty) ...[
                  const Text(
                    'Recent Searches',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: recentSearches.map((search) => _buildSearchChip(search)).toList(),
                  ),
                  const SizedBox(height: 24),
                ],

                // Popular Searches Section
                const Text(
                  'Popular Searches',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: popularSearches.map((search) => _buildSearchChip(search)).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> item) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(
                productData: item['data'],
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Product Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        item['data']['imageUrlList'][0] ?? '',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.image_not_supported, size: 40),
                        ),
                      ),
                      if (item['data']['discount'] != null && item['data']['discount'] > 0)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${item['data']['discount']}% OFF',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Product Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['data']['productName'] ?? 'No Name',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '\$${item['data']['productPrice']?.toString() ?? '0.0'}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        if (item['data']['originalPrice'] != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '\$${item['data']['originalPrice']}',
                            style: TextStyle(
                              fontSize: 14,
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'In Stock: ${item['data']['quantity'] ?? 0}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    if (item['data']['productDescription'] != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        item['data']['productDescription'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Add to cart functionality
                          final cartProvider = Provider.of<CartProvider>(context, listen: false);
                          
                          // Check if vendor ID exists
                          if (item['data']['vendorId'] == null || item['data']['vendorId'].toString().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Cannot add product: Missing vendor information'),
                                backgroundColor: Colors.red,
                                duration: Duration(seconds: 2),
                              ),
                            );
                            return;
                          }

                          cartProvider.addProductToCart(
                            item['id'],
                            item['data']['productName'] ?? 'No Name',
                            item['data']['imageUrlList'] ?? [],
                            1, // Default quantity
                            (item['data']['productPrice'] ?? 0.0).toDouble(),
                            item['data']['productSize'] ?? 'N/A',
                            item['data']['brandName'] ?? 'N/A',
                            item['data']['category'] ?? 'N/A',
                            item['data']['productDescription'] ?? 'N/A',
                            item['data']['vendorId'],
                            item['data']['quantity'] ?? 0,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Added to cart'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: const Icon(Icons.shopping_cart_outlined),
                        label: const Text('Add to Cart'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> item) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to category
        },
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.category,
                  size: 30,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  item['data']['name'] ?? 'No Name',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[600],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchChip(String label) {
    return GestureDetector(
      onTap: () {
        _searchController.text = label;
        _performSearch(label);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_forward_ios,
              size: 12,
              color: Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }
}