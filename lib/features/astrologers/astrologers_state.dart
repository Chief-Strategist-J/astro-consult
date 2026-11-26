import 'package:equatable/equatable.dart';

import 'astrologers_model.dart';

class AstrologersState extends Equatable {
  const AstrologersState({
    this.items = const [],
    this.loading = false,
    this.error,
    this.query = '',
    this.expertise,
    this.onlyOnline = false,
    this.sort = AstrologerSort.rating,
  });

  final List<Astrologer> items;
  final bool loading, onlyOnline;
  final String? error, expertise;
  final String query;
  final AstrologerSort sort;

  List<String> get allExpertise => ({for (final a in items) ...a.expertise}.toList()..sort());

  List<Astrologer> get visible {
    final q = query.trim().toLowerCase();
    final list = items.where((a) {
      if (onlyOnline && !a.isOnline) return false;
      if (expertise != null && !a.expertise.contains(expertise)) return false;
      if (q.isEmpty) return true;
      return a.name.toLowerCase().contains(q) ||
          a.expertise.any((e) => e.toLowerCase().contains(q)) ||
          a.languages.any((l) => l.toLowerCase().contains(q));
    }).toList();
    list.sort((a, b) => switch (sort) {
          AstrologerSort.rating => b.rating.compareTo(a.rating),
          AstrologerSort.priceLow => a.pricePerMin.compareTo(b.pricePerMin),
          AstrologerSort.priceHigh => b.pricePerMin.compareTo(a.pricePerMin),
          AstrologerSort.experience => b.experience.compareTo(a.experience),
        });
    return list;
  }

  AstrologersState copyWith({
    List<Astrologer>? items,
    bool? loading,
    String? error,
    bool clearError = false,
    String? query,
    String? expertise,
    bool clearExpertise = false,
    bool? onlyOnline,
    AstrologerSort? sort,
  }) =>
      AstrologersState(
        items: items ?? this.items,
        loading: loading ?? this.loading,
        error: clearError ? null : (error ?? this.error),
        query: query ?? this.query,
        expertise: clearExpertise ? null : (expertise ?? this.expertise),
        onlyOnline: onlyOnline ?? this.onlyOnline,
        sort: sort ?? this.sort,
      );

  @override
  List<Object?> get props => [items, loading, error, query, expertise, onlyOnline, sort];
}
