import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import '../../app_constants.dart';

enum Availability { online, busy, offline }

extension AvailabilityLabel on Availability {
  String get label => switch (this) {
        Availability.online => AppStrings.availOnline,
        Availability.busy => AppStrings.availBusy,
        Availability.offline => AppStrings.availOffline,
      };
}

class Astrologer extends Equatable {
  const Astrologer({
    required this.id,
    required this.name,
    required this.avatar,
    required this.expertise,
    required this.languages,
    required this.experience,
    required this.rating,
    required this.reviews,
    required this.pricePerMin,
    required this.status,
    required this.about,
  });

  final String id, name, avatar, about;
  final List<String> expertise, languages;
  final int experience, reviews;
  final double rating, pricePerMin;
  final Availability status;

  bool get isOnline => status == Availability.online;

  factory Astrologer.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final j = doc.data() ?? const {};
    return Astrologer(
      id: doc.id,
      name: j[Db.name] as String? ?? '',
      avatar: j[Db.avatar] as String? ?? '',
      about: j[Db.about] as String? ?? '',
      expertise: List<String>.from(j[Db.expertise] as List? ?? const []),
      languages: List<String>.from(j[Db.languages] as List? ?? const []),
      experience: (j[Db.experience] as num? ?? 0).toInt(),
      reviews: (j[Db.reviewCount] as num? ?? 0).toInt(),
      rating: (j[Db.rating] as num? ?? 0).toDouble(),
      pricePerMin: (j[Db.pricePerMin] as num? ?? 0).toDouble(),
      status: Availability.values.firstWhere((s) => s.name == j[Db.status], orElse: () => Availability.offline),
    );
  }

  @override
  List<Object?> get props => [id, status, rating, pricePerMin, name];
}

enum AstrologerSort { rating, priceLow, priceHigh, experience }

extension AstrologerSortLabel on AstrologerSort {
  String get label => switch (this) {
        AstrologerSort.rating => AppStrings.sortRating,
        AstrologerSort.priceLow => AppStrings.sortPriceLow,
        AstrologerSort.priceHigh => AppStrings.sortPriceHigh,
        AstrologerSort.experience => AppStrings.sortExperience,
      };
}
