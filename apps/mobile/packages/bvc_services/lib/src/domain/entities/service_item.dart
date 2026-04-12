class ServiceItem {
  ServiceItem({
    required this.id,
    required this.type,
    required this.name,
    required this.description,
    required this.price,
    required this.maxCapacity,
    required this.images,
    this.providerName,
    this.addressLine,
    this.locationSummary,
  });

  final String id;
  final String type; // ACCOMMODATION | FOOD | VEHICLE | TOUR
  final String name;
  final String description;
  final int price;
  final int maxCapacity;
  final List<String> images;
  /// Tên nhà cung cấp (từ API khi có `provider`).
  final String? providerName;
  final String? addressLine;
  final String? locationSummary;

  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    final rawImages = json['images'];
    final images = <String>[];
    if (rawImages is List) {
      for (final v in rawImages) {
        if (v is String && v.isNotEmpty) images.add(v);
      }
    }

    String? providerName;
    final p = json['provider'];
    if (p is Map<String, dynamic>) {
      final n = p['name'];
      if (n is String && n.isNotEmpty) providerName = n;
    }

    return ServiceItem(
      id: json['id'] as String,
      type: json['type'] as String,
      name: (json['name'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      price: (json['price'] as num?)?.toInt() ?? 0,
      maxCapacity: (json['maxCapacity'] as num?)?.toInt() ?? 0,
      images: images,
      providerName: providerName,
      addressLine: json['addressLine'] as String?,
      locationSummary: json['locationSummary'] as String?,
    );
  }
}

