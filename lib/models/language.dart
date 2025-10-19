class Language {
  final String name;
  final double rating;
  final int? judge0Id;

  Language({required this.name, required this.rating, this.judge0Id});

  factory Language.fromJson(Map<String, dynamic> json) {
    return Language(
      name: json['name'] as String,
      rating: (json['rating'] as num).toDouble(),
      judge0Id: json['judge0_id'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['rating'] = rating;
    if (judge0Id != null) data['judge0_id'] = judge0Id;
    return data;
  }

  @override
  String toString() {
    return '$name (${rating.toStringAsFixed(2)}%)';
  }
}
