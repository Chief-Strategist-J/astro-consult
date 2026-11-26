import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import '../../app_constants.dart';
import '../astrologers/astrologers_model.dart';

/// The signed-in astrologer's own public record (availability, rating, price).
class AstrologerAccount extends Equatable {
  const AstrologerAccount({
    required this.id,
    required this.name,
    required this.avatar,
    required this.status,
    required this.rating,
    required this.reviews,
    required this.pricePerMin,
  });

  final String id, name, avatar;
  final Availability status;
  final double rating, pricePerMin;
  final int reviews;

  bool get isNew => reviews == 0;

  factory AstrologerAccount.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final a = Astrologer.fromDoc(doc);
    return AstrologerAccount(
      id: doc.id,
      name: a.name,
      avatar: a.avatar,
      status: a.status,
      rating: a.rating,
      reviews: a.reviews,
      pricePerMin: (doc.data()?[Db.pricePerMin] as num? ?? 0).toDouble(),
    );
  }

  @override
  List<Object?> get props => [id, name, avatar, status, rating, reviews, pricePerMin];
}
