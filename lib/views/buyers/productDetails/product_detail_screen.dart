import 'package:flutter/material.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';
import 'package:provider/provider.dart';
import 'package:daddies_store/models/cart_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daddies_store/models/review_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:daddies_store/views/chat/chat_screen.dart';
import 'package:daddies_store/views/buyers/nav_screens/checkout_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final dynamic productData;

  const ProductDetailScreen({super.key, this.productData});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  String? selectedSize;
  late Map<String, dynamic> productData;
  int _currentImageIndex = 0;
  double _averageRating = 0.0;
  List<Review> _reviews = [];
  bool _isLoadingReviews = true;
  Map<String, dynamic>? _vendorInfo;
  bool _isLoadingVendor = true;

  @override
  void initState() {
    super.initState();
    if (widget.productData is DocumentSnapshot) {
      productData = (widget.productData as DocumentSnapshot).data() as Map<String, dynamic>;
      productData['productId'] = (widget.productData as DocumentSnapshot).id;
    } else {
      productData = widget.productData as Map<String, dynamic>;
    }
    print('Product Data: $productData'); // Debug log
    _loadReviews();
    _loadVendorInfo();
  }

  Future<void> _loadReviews() async {
    try {
      print('Loading reviews for product: ${productData['productId']}'); // Debug log
      
      // First, verify the product ID
      if (productData['productId'] == null) {
        print('Error: productId is null in productData');
        print('Product Data: $productData');
        return;
      }

      // Print the query we're about to execute
      print('Executing query: reviews where productId = ${productData['productId']}');

      final reviewsSnapshot = await FirebaseFirestore.instance
          .collection('reviews')
          .where('productId', isEqualTo: productData['productId'])
          .get();

      print('Found ${reviewsSnapshot.docs.length} reviews'); // Debug log

      if (reviewsSnapshot.docs.isEmpty) {
        print('No reviews found in Firestore');
        if (mounted) {
          setState(() {
            _reviews = [];
            _averageRating = 0.0;
            _isLoadingReviews = false;
          });
        }
        return;
      }

      // Sort the reviews in memory instead of in the query
      final reviews = reviewsSnapshot.docs
          .map((doc) {
            print('Processing review: ${doc.id}'); // Debug log
            print('Review data: ${doc.data()}'); // Debug log
            return Review.fromMap({...doc.data(), 'reviewId': doc.id});
          })
          .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Sort by createdAt in descending order

      print('Successfully processed ${reviews.length} reviews');

      double totalRating = 0;
      for (var review in reviews) {
        totalRating += review.rating;
      }

      if (mounted) {
        setState(() {
          _reviews = reviews;
          _averageRating = reviews.isEmpty ? 0 : totalRating / reviews.length;
          _isLoadingReviews = false;
        });
        print('Updated state with ${reviews.length} reviews'); // Debug log
        print('Average rating: $_averageRating'); // Debug log
      }
    } catch (e, stackTrace) {
      print('Error loading reviews: $e'); // Debug log
      print('Stack trace: $stackTrace'); // Debug log
      if (mounted) {
        setState(() {
          _isLoadingReviews = false;
        });
      }
    }
  }

  Future<void> _printOrderStructure(DocumentSnapshot orderDoc) async {
    print('Order Structure:');
    print('Order ID: ${orderDoc.id}');
    print('Order Data: ${orderDoc.data()}');
  }

  Future<bool> _canUserReview() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('User not logged in'); // Debug log
      return false;
    }

    print('Checking review eligibility for user: ${user.uid}'); // Debug log
    print('Product ID: ${productData['productId']}'); // Debug log

    // Get all delivered orders for the current user
    final ordersSnapshot = await FirebaseFirestore.instance
        .collection('orders')
        .where('buyerId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'delivered')
        .get();

    print('Found ${ordersSnapshot.docs.length} delivered orders'); // Debug log

    // Check if any of the delivered orders contain this product
    bool hasPurchasedProduct = false;
    for (var orderDoc in ordersSnapshot.docs) {
      await _printOrderStructure(orderDoc); // Print order structure for debugging
      
      final orderData = orderDoc.data() as Map<String, dynamic>;
      print('Checking order: ${orderData['orderId']}'); // Debug log
      
      // Check both possible product structures
      final products = orderData['products'] as List;
      for (var product in products) {
        print('Product in order: $product'); // Debug log
        
        // Check for both possible product ID fields
        final productId = product['productId'] ?? product['id'];
        if (productId == productData['productId']) {
          print('Found matching product in order'); // Debug log
          hasPurchasedProduct = true;
          break;
        }
      }
      if (hasPurchasedProduct) break;
    }

    // Check if user has already reviewed this product
    final existingReview = await FirebaseFirestore.instance
        .collection('reviews')
        .where('userId', isEqualTo: user.uid)
        .where('productId', isEqualTo: productData['productId'])
        .get();

    print('Has purchased product: $hasPurchasedProduct'); // Debug log
    print('Has existing review: ${existingReview.docs.isNotEmpty}'); // Debug log

    if (existingReview.docs.isNotEmpty) {
      print('Existing review details:'); // Debug log
      for (var doc in existingReview.docs) {
        print('Review ID: ${doc.id}'); // Debug log
        print('Review data: ${doc.data()}'); // Debug log
      }
    }

    return hasPurchasedProduct && existingReview.docs.isEmpty;
  }

  Future<void> _deleteReview(String reviewId) async {
    try {
      await FirebaseFirestore.instance
          .collection('reviews')
          .doc(reviewId)
          .delete();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadReviews(); // Reload reviews after deletion
      }
    } catch (e) {
      print('Error deleting review: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting review: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmationDialog(String reviewId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Review'),
        content: const Text('Are you sure you want to delete your review?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteReview(reviewId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<String?> _getUserReviewId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final existingReview = await FirebaseFirestore.instance
        .collection('reviews')
        .where('userId', isEqualTo: user.uid)
        .where('productId', isEqualTo: productData['productId'])
        .get();

    return existingReview.docs.isNotEmpty ? existingReview.docs.first.id : null;
  }

  void _showReviewDialog() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Check if user has already reviewed
    final existingReviewId = await _getUserReviewId();
    if (existingReviewId != null) {
      // Show confirmation to delete existing review
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Update Review'),
          content: const Text('You have already reviewed this product. Would you like to delete your existing review and write a new one?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showDeleteConfirmationDialog(existingReviewId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete & Write New'),
            ),
          ],
        ),
      );
      return;
    }

    // Check if user can review (has purchased and received the product)
    final canReview = await _canUserReview();
    if (!canReview) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can only review products you have purchased and received.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    double rating = 0;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Write a Review'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                    onPressed: () {
                      setState(() {
                        rating = index + 1;
                      });
                    },
                  );
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                decoration: const InputDecoration(
                  hintText: 'Write your review...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (rating == 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a rating')),
                  );
                  return;
                }

                if (commentController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please write a review comment')),
                  );
                  return;
                }

                try {
                  final userDoc = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .get();

                  final review = Review(
                    reviewId: '',
                    productId: productData['productId'],
                    userId: user.uid,
                    userName: userDoc.data()?['name'] ?? 'Anonymous',
                    userImage: userDoc.data()?['imageUrl'] ?? '',
                    rating: rating,
                    comment: commentController.text.trim(),
                    createdAt: DateTime.now(),
                    isVerifiedPurchase: true,
                  );

                  print('Submitting review: ${review.toMap()}'); // Debug log

                  final docRef = await FirebaseFirestore.instance
                      .collection('reviews')
                      .add(review.toMap());

                  print('Review submitted with ID: ${docRef.id}'); // Debug log

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Review submitted successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    await _loadReviews(); // Reload reviews after submission
                  }
                } catch (e) {
                  print('Error submitting review: $e'); // Debug log
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error submitting review: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadVendorInfo() async {
    try {
      print('Loading vendor info for vendorId: ${productData['vendorId']}');
      
      // First, ensure we have a valid vendorId
      if (productData['vendorId'] == null || productData['vendorId'].toString().isEmpty) {
        print('No vendorId found in product data');
        setState(() {
          _isLoadingVendor = false;
        });
        return;
      }

      // Try to get vendor info directly from the vendors collection
      final vendorDoc = await FirebaseFirestore.instance
          .collection('vendors')
          .doc(productData['vendorId'])
          .get();
      
      print('Vendor document exists: ${vendorDoc.exists}');
      if (vendorDoc.exists) {
        print('Vendor data: ${vendorDoc.data()}');
        setState(() {
          _vendorInfo = vendorDoc.data();
          _isLoadingVendor = false;
        });
        return;
      }

      // If vendor document doesn't exist, try to get the latest product data
      print('Vendor document not found, trying to get latest product data');
      final productDoc = await FirebaseFirestore.instance
          .collection('products')
          .doc(productData['productId'])
          .get();
      
      print('Product document exists: ${productDoc.exists}');
      if (productDoc.exists) {
        final latestProductData = productDoc.data();
        print('Latest product data: $latestProductData');
        
        // Check if the vendorId is different in the latest product data
        if (latestProductData?['vendorId'] != null && 
            latestProductData?['vendorId'] != productData['vendorId']) {
          print('Found different vendorId in latest product data: ${latestProductData?['vendorId']}');
          
          // Try to get vendor info with the new vendorId
          final newVendorDoc = await FirebaseFirestore.instance
              .collection('vendors')
              .doc(latestProductData?['vendorId'])
              .get();
          
          if (newVendorDoc.exists) {
            print('Found vendor with new vendorId');
            setState(() {
              _vendorInfo = newVendorDoc.data();
              _isLoadingVendor = false;
            });
            return;
          }
        }
      }

      // If we get here, we couldn't find the vendor information
      print('Could not find vendor information');
      setState(() {
        _isLoadingVendor = false;
      });
    } catch (e) {
      print('Error loading vendor info: $e');
      setState(() {
        _isLoadingVendor = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Product Details',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border, color: Colors.black),
            onPressed: () {
              // TODO: Implement wishlist functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.black),
            onPressed: () {
              // TODO: Implement share functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.message, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    currentUserId: FirebaseAuth.instance.currentUser!.uid,
                    otherUserId: productData['vendorId'],
                    otherUserName: productData['vendorName'] ?? 'Vendor',
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Carousel with Indicators
            Stack(
              children: [
                SizedBox(
                  height: 400,
                  child: PageView.builder(
                    onPageChanged: (index) {
                      setState(() {
                        _currentImageIndex = index;
                      });
                    },
                    itemCount: (productData['imageUrlList'] as List).length,
                    itemBuilder: (context, index) {
                      return Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: NetworkImage(productData['imageUrlList'][index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      productData['imageUrlList'].length,
                      (index) => Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentImageIndex == index
                              ? Colors.blue
                              : Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Product Information
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name and Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          productData['productName'] ?? 'Product Name',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        '\$${productData['productPrice']?.toString() ?? '0.00'}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Ratings Summary
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Column(
                          children: [
                            Row(
                              children: [
                                Icon(Icons.star, color: Colors.amber, size: 24),
                                const SizedBox(width: 4),
                                Text(
                                  _averageRating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${_reviews.length} reviews',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _showReviewDialog,
                                icon: const Icon(Icons.rate_review),
                                label: const Text('Write a Review'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Sizes
                  const Text(
                    'Select Size',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: (productData['sizeList'] as List?)?.map((size) {
                      final isSelected = size.toString() == selectedSize;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedSize = size.toString();
                          });
                        },
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.blue : Colors.white,
                            border: Border.all(
                              color: isSelected ? Colors.blue : Colors.grey.shade300,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              size.toString(),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList() ?? [
                      const Text('No sizes available'),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    productData['productDescription'] ?? 'No description available',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Additional Details
                  const Text(
                    'Product Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow('Category', productData['category'] ?? 'N/A'),
                  _buildDetailRow('Brand', productData['brandName'] ?? 'N/A'),
                  _buildDetailRow('Stock', '${productData['quantity'] ?? 0} units'),
                  
                  // Vendor Information
                  const SizedBox(height: 24),
                  const Text(
                    'Vendor Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_isLoadingVendor)
                    const Center(child: CircularProgressIndicator())
                  else if (_vendorInfo != null)
                    Column(
                      children: [
                        if (_vendorInfo!['storeImage'] != null && _vendorInfo!['storeImage'].toString().isNotEmpty)
                          CircleAvatar(
                            radius: 30,
                            backgroundImage: NetworkImage(_vendorInfo!['storeImage']),
                          ),
                        const SizedBox(height: 8),
                        _buildDetailRow('Store Name', _vendorInfo!['bussinessName'] ?? 'N/A'),
                        _buildDetailRow('Location', '${_vendorInfo!['cityValue'] ?? 'N/A'}, ${_vendorInfo!['stateValue'] ?? 'N/A'}'),
                      ],
                    )
                  else
                    const Text('Vendor information not available'),
                  
                  const SizedBox(height: 24),

                  // Reviews Section
                  const Text(
                    'Customer Reviews',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_isLoadingReviews)
                    const Center(child: CircularProgressIndicator())
                  else if (_reviews.isEmpty)
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.rate_review_outlined,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No reviews yet',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      children: [
                        // Average Rating Summary
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Column(
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.star, color: Colors.amber, size: 24),
                                      const SizedBox(width: 4),
                                      Text(
                                        _averageRating.toStringAsFixed(1),
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '${_reviews.length} reviews',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: _showReviewDialog,
                                      icon: const Icon(Icons.rate_review),
                                      label: const Text('Write a Review'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Reviews List
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _reviews.length,
                          itemBuilder: (context, index) {
                            final review = _reviews[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundImage: review.userImage.isNotEmpty
                                            ? NetworkImage(review.userImage)
                                            : null,
                                        child: review.userImage.isEmpty
                                            ? const Icon(Icons.person)
                                            : null,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              review.userName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            Text(
                                              review.createdAt.toString().split(' ')[0],
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (review.isVerifiedPurchase)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.green[50],
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.check_circle,
                                                color: Colors.green[700],
                                                size: 16,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Verified Purchase',
                                                style: TextStyle(
                                                  color: Colors.green[700],
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: List.generate(5, (index) {
                                      return Icon(
                                        index < review.rating
                                            ? Icons.star
                                            : Icons.star_border,
                                        color: Colors.amber,
                                        size: 20,
                                      );
                                    }),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    review.comment,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: selectedSize == null
                    ? null
                    : () {
                        final cartProvider = Provider.of<CartProvider>(context, listen: false);
                        
                        // Check if vendor ID exists
                        if (productData['vendorId'] == null || productData['vendorId'].toString().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Cannot add product: Missing vendor information'),
                              backgroundColor: Colors.red,
                              duration: Duration(seconds: 2),
                            ),
                          );
                          return;
                        }

                        // Check if vendor is approved
                        if (_vendorInfo == null || _vendorInfo!['approved'] != true) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Cannot add product: Vendor is not approved'),
                              backgroundColor: Colors.red,
                              duration: Duration(seconds: 2),
                            ),
                          );
                          return;
                        }

                        cartProvider.addProductToCart(
                          productData['productId'] ?? '',
                          productData['productName'] ?? 'Unknown Product',
                          productData['imageUrlList'] ?? [],
                          1,
                          (productData['productPrice'] ?? 0.0).toDouble(),
                          selectedSize ?? 'One Size',
                          productData['brandName'] ?? 'Unknown Brand',
                          productData['category'] ?? 'Uncategorized',
                          productData['productDescription'] ?? 'No description available',
                          productData['vendorId'],
                          productData['quantity'] ?? 0,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Product added to cart'),
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Add to Cart',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: selectedSize == null
                    ? null
                    : () {
                        final cartProvider = Provider.of<CartProvider>(context, listen: false);
                        
                        // Check if vendor ID exists
                        if (productData['vendorId'] == null || productData['vendorId'].toString().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Cannot add product: Missing vendor information'),
                              backgroundColor: Colors.red,
                              duration: Duration(seconds: 2),
                            ),
                          );
                          return;
                        }

                        // Check if vendor is approved
                        if (_vendorInfo == null || _vendorInfo!['approved'] != true) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Cannot add product: Vendor is not approved'),
                              backgroundColor: Colors.red,
                              duration: Duration(seconds: 2),
                            ),
                          );
                          return;
                        }

                        // Clear existing cart items
                        cartProvider.clearCart();

                        // Add the current product to cart
                        cartProvider.addProductToCart(
                          productData['productId'] ?? '',
                          productData['productName'] ?? 'Unknown Product',
                          productData['imageUrlList'] ?? [],
                          1,
                          (productData['productPrice'] ?? 0.0).toDouble(),
                          selectedSize ?? 'One Size',
                          productData['brandName'] ?? 'Unknown Brand',
                          productData['category'] ?? 'Uncategorized',
                          productData['productDescription'] ?? 'No description available',
                          productData['vendorId'],
                          productData['quantity'] ?? 0,
                        );

                        // Navigate to checkout screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CheckoutScreen(),
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Buy Now',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}