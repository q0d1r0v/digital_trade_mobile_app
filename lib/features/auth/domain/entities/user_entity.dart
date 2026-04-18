import 'package:equatable/equatable.dart';

import 'plan_limits.dart';

/// Pure business object. Knows nothing about JSON, HTTP or Flutter.
///
/// `planLimits` comes from the nested `company_plan` in auth-user and is
/// used by the UI to gate features per tier (POS, invite team, etc.).
class UserEntity extends Equatable {
  const UserEntity({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    this.gender,
    this.role,
    this.avatarUrl,
    this.companyId,
    this.companyName,
    this.planLimits,
  });

  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String? gender;
  final String? role;
  final String? avatarUrl;
  final String? companyId;
  final String? companyName;
  final PlanLimits? planLimits;

  bool get isAdmin => role == 'admin' || role == 'super_admin';
  bool get isDirector => role == 'director';

  @override
  List<Object?> get props => [
        id,
        fullName,
        email,
        phone,
        gender,
        role,
        avatarUrl,
        companyId,
        companyName,
        planLimits,
      ];
}
