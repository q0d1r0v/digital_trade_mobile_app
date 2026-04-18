import '../../domain/entities/plan_entity.dart';

/// Wire DTO for GET /common/plans. Backend returns:
/// ```
/// {
///   "id": 1,
///   "name": "Starter",
///   "type": "starter",
///   "description": "...",
///   "price": "0.00",
///   "is_active": true,
///   "limits": [ { "feature": "max_cashboxes", "value": "2" }, ... ]
/// }
/// ```
class PlanModel {
  const PlanModel({
    required this.id,
    required this.name,
    required this.type,
    required this.price,
    required this.limits,
    this.description,
  });

  final int id;
  final String name;
  final String type;
  final double price;
  final String? description;
  final Map<String, String> limits;

  factory PlanModel.fromJson(Map<String, dynamic> json) {
    final rawLimits = json['limits'];
    final limits = <String, String>{};
    if (rawLimits is List) {
      for (final item in rawLimits) {
        if (item is Map<String, dynamic>) {
          final feature = item['feature']?.toString();
          final value = item['value']?.toString();
          if (feature != null && value != null) {
            limits[feature] = value;
          }
        }
      }
    }
    return PlanModel(
      id: (json['id'] as num).toInt(),
      name: (json['name'] ?? '') as String,
      type: (json['type'] ?? 'starter') as String,
      description: json['description'] as String?,
      price: _asDouble(json['price']),
      limits: limits,
    );
  }

  PlanEntity toEntity() => PlanEntity(
        id: id,
        name: name,
        type: PlanType.fromApi(type),
        price: price,
        description: description,
        limits: limits,
      );

  static double _asDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }
}
