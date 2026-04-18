import 'package:equatable/equatable.dart';

/// Subset of PlanType used by the mobile onboarding UI. Enterprise is
/// intentionally excluded from the in-app picker because it requires a
/// sales conversation (see `POST /common/plans/enterprise-request`).
enum PlanType {
  starter,
  business,
  enterprise;

  String get apiValue => name;

  static PlanType fromApi(String? raw) => switch (raw) {
        'business' => PlanType.business,
        'enterprise' => PlanType.enterprise,
        _ => PlanType.starter,
      };
}

/// Pure-domain plan record. The backend returns a more detailed shape
/// (limits, created_at, is_active …) — the mobile UI only needs what fits
/// on a plan card, so we project down at the data layer.
class PlanEntity extends Equatable {
  const PlanEntity({
    required this.id,
    required this.name,
    required this.type,
    required this.price,
    this.description,
    this.limits = const {},
  });

  final int id;
  final String name;
  final PlanType type;
  final double price;
  final String? description;

  /// Feature → value map (e.g. `{"max_products": "unlimited", "pos": "true"}`).
  final Map<String, String> limits;

  bool get isFree => price == 0;

  @override
  List<Object?> get props => [id, name, type, price, description, limits];
}
