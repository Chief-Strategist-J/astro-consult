import 'package:equatable/equatable.dart';

import '../astrologers/astrologers_model.dart';
import 'astrologer_detail_model.dart';

class AstrologerDetailState extends Equatable {
  const AstrologerDetailState({required this.astrologer, this.reviews = const [], this.loading = true, this.error});
  final Astrologer astrologer;
  final List<Review> reviews;
  final bool loading;
  final String? error;

  AstrologerDetailState copyWith({Astrologer? astrologer, List<Review>? reviews, bool? loading, String? error, bool clearError = false}) =>
      AstrologerDetailState(
        astrologer: astrologer ?? this.astrologer,
        reviews: reviews ?? this.reviews,
        loading: loading ?? this.loading,
        error: clearError ? null : (error ?? this.error),
      );

  @override
  List<Object?> get props => [astrologer, reviews, loading, error];
}
