class Survey {
  final dynamic id;
  final String title;
  final String description;
  final String categoryName;
  final String formattedCoordinates;
  final String formattedDate;

  // Koordinat untuk membuka Google Maps
  final double? latitude;
  final double? longitude;

  Survey({
    this.id,
    required this.title,
    required this.description,
    required this.categoryName,
    required this.formattedCoordinates,
    required this.formattedDate,
    this.latitude,
    this.longitude,
  });

  factory Survey.fromJson(Map<String, dynamic> json) {
    return Survey(
      // ID Survey
      id: json['id'],

      // Judul
      title: (json['title'] ??
              json['judul'] ??
              json['name'] ??
              'Survey')
          .toString(),

      // Deskripsi
      description: (json['description'] ??
              json['deskripsi'] ??
              json['keterangan'] ??
              'Tidak ada deskripsi')
          .toString(),

      // Kategori
      categoryName: (json['category_name'] ??
              json['categoryName'] ??
              json['category'] ??
              json['kategori'] ??
              'Umum')
          .toString(),

      // Koordinat yang ditampilkan
      formattedCoordinates: _getCoordinates(json),

      // Tanggal
      formattedDate: _getDate(json),

      // Latitude
      latitude: double.tryParse(
        (json['latitude'] ?? json['lat'])?.toString() ?? '',
      ),

      // Longitude
      longitude: double.tryParse(
        (json['longitude'] ??
                json['lng'] ??
                json['lon'])
            ?.toString() ??
            '',
      ),
    );
  }

  // ============================================================
  // MENGAMBIL KOORDINAT
  // ============================================================

  static String _getCoordinates(
    Map<String, dynamic> json,
  ) {
    final latitude = json['latitude'] ?? json['lat'];

    final longitude =
        json['longitude'] ??
        json['lng'] ??
        json['lon'];

    if (latitude != null && longitude != null) {
      return '$latitude, $longitude';
    }

    return 'Lokasi tidak tersedia';
  }

  // ============================================================
  // MENGAMBIL TANGGAL
  // ============================================================

  static String _getDate(
    Map<String, dynamic> json,
  ) {
    final value =
        json['created_at'] ??
        json['updated_at'] ??
        json['date'] ??
        json['tanggal'];

    if (value == null) {
      return 'Tanggal tidak tersedia';
    }

    try {
      final date = DateTime.parse(
        value.toString(),
      );

      final day =
          date.day.toString().padLeft(2, '0');

      final month =
          date.month.toString().padLeft(2, '0');

      final year =
          date.year.toString();

      return '$day-$month-$year';
    } catch (_) {
      return value.toString();
    }
  }
}