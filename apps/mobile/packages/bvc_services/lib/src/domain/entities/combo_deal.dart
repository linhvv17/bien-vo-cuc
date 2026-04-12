import 'service_item.dart';

class ComboDeal {
  ComboDeal({
    required this.id,
    required this.hotel,
    required this.food,
    required this.originalTotal,
    required this.discountedTotal,
    required this.discountPercent,
    required this.saved,
    this.title,
  });

  final String id;
  final String? title;
  final ServiceItem hotel;
  final ServiceItem food;
  final int originalTotal;
  final int discountedTotal;
  final int discountPercent;
  final int saved;

  factory ComboDeal.fromJson(Map<String, dynamic> json) {
    return ComboDeal(
      id: json['id'] as String,
      title: json['title'] as String?,
      hotel: ServiceItem.fromJson((json['hotel'] as Map).cast<String, dynamic>()),
      food: ServiceItem.fromJson((json['food'] as Map).cast<String, dynamic>()),
      originalTotal: (json['originalTotal'] as num).toInt(),
      discountedTotal: (json['discountedTotal'] as num).toInt(),
      discountPercent: (json['discountPercent'] as num).toInt(),
      saved: (json['saved'] as num).toInt(),
    );
  }
}

