class City {
  const City({
    required this.name,
    required this.country,
    this.isFavorite = false,
  });

  final String name;
  final String country;
  final bool isFavorite;

  City copyWith({bool? isFavorite}) {
    return City(
      name: name,
      country: country,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  String get id => '$name|$country';
}
