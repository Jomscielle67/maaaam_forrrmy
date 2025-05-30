import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String reviewId;
  final String productId;
  final String userId;
  final String userName;
  final String userImage;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final bool isVerifiedPurchase;

  Review({
    required this.reviewId,
    required this.productId,
    required this.userId,
    required this.userName,
    required this.userImage,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.isVerifiedPurchase,
  });

  Map<String, dynamic> toMap() {
    return {
      'reviewId': reviewId,
      'productId': productId,
      'userId': userId,
      'userName': userName,
      'userImage': userImage,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt,
      'isVerifiedPurchase': isVerifiedPurchase,
    };
  }

  factory Review.fromMap(Map<String, dynamic> map) {
    try {
      // Validate required fields
      if (map['productId'] == null) {
        print('Warning: productId is null in review data');
        print('Review data: $map');
      }
      if (map['userId'] == null) {
        print('Warning: userId is null in review data');
        print('Review data: $map');
      }

      // Handle createdAt field
      DateTime createdAt;
      if (map['createdAt'] is Timestamp) {
        createdAt = (map['createdAt'] as Timestamp).toDate();
      } else if (map['createdAt'] is DateTime) {
        createdAt = map['createdAt'] as DateTime;
      } else {
        print('Warning: createdAt is not a Timestamp or DateTime');
        print('createdAt value: ${map['createdAt']}');
        createdAt = DateTime.now(); // Fallback to current time
      }

      return Review(
        reviewId: map['reviewId']?.toString() ?? '',
        productId: map['productId']?.toString() ?? '',
        userId: map['userId']?.toString() ?? '',
        userName: map['userName']?.toString() ?? 'Anonymous',
        userImage: map['userImage']?.toString() ?? '',
        rating: (map['rating'] ?? 0.0).toDouble(),
        comment: map['comment']?.toString() ?? '',
        createdAt: createdAt,
        isVerifiedPurchase: map['isVerifiedPurchase'] ?? false,
      );
    } catch (e, stackTrace) {
      print('Error creating Review from map: $e');
      print('Stack trace: $stackTrace');
      print('Map data: $map');
      rethrow;
    }
  }
} 