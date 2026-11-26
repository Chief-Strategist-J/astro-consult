import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app_constants.dart';

class Review {
  const Review({required this.user, required this.rating, required this.text});
  final String user, text;
  final int rating;

  factory Review.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final j = doc.data();
    return Review(
      user: j[Db.reviewUser] as String? ?? '',
      rating: (j[Db.reviewRating] as num? ?? 0).toInt(),
      text: j[Db.reviewText] as String? ?? '',
    );
  }
}
