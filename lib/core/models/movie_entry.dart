import 'package:cloud_firestore/cloud_firestore.dart';

/// Status for a movie in the user's list
enum MovieStatus {
  watched,
  pending,
  abandoned,
  watching;

  String get label {
    switch (this) {
      case MovieStatus.watched:
        return 'Watched';
      case MovieStatus.pending:
        return 'Pending';
      case MovieStatus.abandoned:
        return 'Abandoned';
      case MovieStatus.watching:
        return 'Watching';
    }
  }

  String get labelEs {
    switch (this) {
      case MovieStatus.watched:
        return 'Vista';
      case MovieStatus.pending:
        return 'Pendiente';
      case MovieStatus.abandoned:
        return 'Abandonada';
      case MovieStatus.watching:
        return 'Viendo';
    }
  }

  String get icon {
    switch (this) {
      case MovieStatus.watched:
        return '✅';
      case MovieStatus.pending:
        return '📋';
      case MovieStatus.abandoned:
        return '❌';
      case MovieStatus.watching:
        return '▶️';
    }
  }

  static MovieStatus fromString(String value) {
    return MovieStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MovieStatus.pending,
    );
  }
}

/// A user's entry for a movie in their personal list
class MovieEntry {
  final int tmdbId;
  final String title;
  final String? posterPath;
  final MovieStatus status;
  final int? score; // 1-10
  final String? review;
  final List<String> genres;
  final int? year;
  final DateTime addedAt;
  final DateTime updatedAt;

  const MovieEntry({
    required this.tmdbId,
    required this.title,
    this.posterPath,
    required this.status,
    this.score,
    this.review,
    this.genres = const [],
    this.year,
    required this.addedAt,
    required this.updatedAt,
  });

  MovieEntry copyWith({
    int? tmdbId,
    String? title,
    String? posterPath,
    MovieStatus? status,
    int? score,
    String? review,
    List<String>? genres,
    int? year,
    DateTime? addedAt,
    DateTime? updatedAt,
  }) {
    return MovieEntry(
      tmdbId: tmdbId ?? this.tmdbId,
      title: title ?? this.title,
      posterPath: posterPath ?? this.posterPath,
      status: status ?? this.status,
      score: score ?? this.score,
      review: review ?? this.review,
      genres: genres ?? this.genres,
      year: year ?? this.year,
      addedAt: addedAt ?? this.addedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory MovieEntry.fromFirestore(Map<String, dynamic> data) {
    return MovieEntry(
      tmdbId: data['tmdbId'] as int,
      title: data['title'] as String? ?? '',
      posterPath: data['posterPath'] as String?,
      status: MovieStatus.fromString(data['status'] as String? ?? 'pending'),
      score: data['score'] as int?,
      review: data['review'] as String?,
      genres: (data['genres'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      year: data['year'] as int?,
      addedAt: (data['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt:
          (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'tmdbId': tmdbId,
      'title': title,
      'posterPath': posterPath,
      'status': status.name,
      'score': score,
      'review': review,
      'genres': genres,
      'year': year,
      'addedAt': Timestamp.fromDate(addedAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
