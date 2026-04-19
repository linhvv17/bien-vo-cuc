class AccommodationDetail {
  AccommodationDetail({
    required this.service,
    required this.rooms,
    required this.roomTypeGroups,
    required this.preferenceOptions,
  });

  final AccommodationServiceBlock service;
  final List<RoomItem> rooms;
  /// Gom theo loại: phòng đơn / đôi / gia đình — còn bao nhiêu phòng trống.
  final List<RoomTypeGroup> roomTypeGroups;
  final List<PreferenceOption> preferenceOptions;

  factory AccommodationDetail.fromJson(Map<String, dynamic> json) {
    return AccommodationDetail(
      service: AccommodationServiceBlock.fromJson((json['service'] as Map).cast<String, dynamic>()),
      rooms: (json['rooms'] as List<dynamic>? ?? const [])
          .map((e) => RoomItem.fromJson((e as Map).cast<String, dynamic>()))
          .toList(growable: false),
      roomTypeGroups: (json['roomTypeGroups'] as List<dynamic>? ?? const [])
          .map((e) => RoomTypeGroup.fromJson((e as Map).cast<String, dynamic>()))
          .toList(growable: false),
      preferenceOptions: (json['preferenceOptions'] as List<dynamic>? ?? const [])
          .map((e) => PreferenceOption.fromJson((e as Map).cast<String, dynamic>()))
          .toList(growable: false),
    );
  }

  /// Gom loại phòng để hiển thị stepper: ưu tiên [roomTypeGroups] từ API, nếu rỗng thì suy ra từ [rooms].
  List<RoomTypeGroup> get effectiveRoomTypeGroups {
    if (roomTypeGroups.isNotEmpty) return roomTypeGroups;
    if (rooms.isEmpty) return const [];
    final map = <String, _RoomTypeAggregate>{};
    for (final r in rooms) {
      final a = map.putIfAbsent(r.roomType, () => _RoomTypeAggregate());
      a.inventory += 1;
      a.availableCount += r.availableCount;
      if (r.maxGuests > a.maxGuests) a.maxGuests = r.maxGuests;
    }
    return map.entries.map((e) {
      final t = e.key;
      final a = e.value;
      return RoomTypeGroup(
        roomType: t,
        labelVi: roomTypeLabelVi(t),
        availableCount: a.availableCount,
        inventory: a.inventory,
        maxGuests: a.maxGuests > 0 ? a.maxGuests : 1,
        pricePerNight: service.price,
      );
    }).toList(growable: false);
  }
}

class _RoomTypeAggregate {
  int inventory = 0;
  int availableCount = 0;
  int maxGuests = 0;
}

class RoomTypeGroup {
  RoomTypeGroup({
    required this.roomType,
    required this.labelVi,
    required this.availableCount,
    required this.inventory,
    required this.maxGuests,
    required this.pricePerNight,
  });

  final String roomType;
  final String labelVi;
  final int availableCount;
  final int inventory;
  final int maxGuests;
  final int pricePerNight;

  factory RoomTypeGroup.fromJson(Map<String, dynamic> json) {
    return RoomTypeGroup(
      roomType: json['roomType'] as String,
      labelVi: (json['labelVi'] as String?) ?? json['roomType'] as String,
      availableCount: (json['availableCount'] as num?)?.toInt() ?? 0,
      inventory: (json['inventory'] as num?)?.toInt() ?? 0,
      maxGuests: (json['maxGuests'] as num?)?.toInt() ?? 1,
      pricePerNight: (json['pricePerNight'] as num?)?.toInt() ?? 0,
    );
  }
}

class AccommodationServiceBlock {
  AccommodationServiceBlock({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.maxCapacity,
    required this.images,
    this.addressLine,
    this.locationSummary,
    this.provider,
  });

  final String id;
  final String name;
  final String description;
  final int price;
  final int maxCapacity;
  final List<String> images;
  final String? addressLine;
  final String? locationSummary;
  final ProviderBlock? provider;

  factory AccommodationServiceBlock.fromJson(Map<String, dynamic> json) {
    final raw = json['images'];
    final imgs = <String>[];
    if (raw is List) {
      for (final v in raw) {
        if (v is String && v.isNotEmpty) imgs.add(v);
      }
    }
    Map<String, dynamic>? p;
    final pr = json['provider'];
    if (pr is Map) p = pr.cast<String, dynamic>();

    return AccommodationServiceBlock(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      price: (json['price'] as num?)?.toInt() ?? 0,
      maxCapacity: (json['maxCapacity'] as num?)?.toInt() ?? 0,
      images: imgs,
      addressLine: json['addressLine'] as String?,
      locationSummary: json['locationSummary'] as String?,
      provider: p == null ? null : ProviderBlock.fromJson(p),
    );
  }
}

class ProviderBlock {
  ProviderBlock({this.id, this.name, this.phone, this.address});

  final String? id;
  final String? name;
  final String? phone;
  final String? address;

  factory ProviderBlock.fromJson(Map<String, dynamic> json) {
    return ProviderBlock(
      id: json['id'] as String?,
      name: json['name'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
    );
  }
}

class RoomItem {
  RoomItem({
    required this.id,
    required this.code,
    required this.name,
    required this.roomType,
    required this.maxGuests,
    this.floor,
    required this.images,
    required this.available,
    required this.availableCount,
    this.pricePerNight,
  });

  final String id;
  final String code;
  final String name;
  final String roomType;
  final int maxGuests;
  final int? floor;
  final List<String> images;
  final bool available;
  final int availableCount;
  /// Giá/đêm hiển thị (đã gộp giá phòng hoặc giá cơ sở).
  final int? pricePerNight;

  factory RoomItem.fromJson(Map<String, dynamic> json) {
    final raw = json['images'];
    final imgs = <String>[];
    if (raw is List) {
      for (final v in raw) {
        if (v is String && v.isNotEmpty) imgs.add(v);
      }
    }
    return RoomItem(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      roomType: json['roomType'] as String,
      maxGuests: (json['maxGuests'] as num?)?.toInt() ?? 1,
      floor: (json['floor'] as num?)?.toInt(),
      images: imgs,
      available: json['available'] == true,
      availableCount: (json['availableCount'] as num?)?.toInt() ?? 0,
      pricePerNight: (json['pricePerNight'] as num?)?.toInt(),
    );
  }
}

class PreferenceOption {
  PreferenceOption({required this.key, required this.label});

  final String key;
  final String label;

  factory PreferenceOption.fromJson(Map<String, dynamic> json) {
    return PreferenceOption(
      key: json['key'] as String,
      label: json['label'] as String,
    );
  }
}

String roomTypeLabelVi(String t) {
  return switch (t) {
    'SINGLE' => 'Phòng đơn',
    'DOUBLE' => 'Phòng đôi (1 giường)',
    'TWIN' => 'Phòng đôi (2 giường đơn)',
    'FAMILY' => 'Phòng gia đình',
    'DORM' => 'Tập thể / dorm',
    'SUITE' => 'Suite',
    'QUAD' => 'Phòng 4 người',
    _ => t,
  };
}
