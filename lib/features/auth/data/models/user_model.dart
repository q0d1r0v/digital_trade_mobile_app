import '../../domain/entities/plan_limits.dart';
import '../../domain/entities/user_entity.dart';

/// Wire-format DTO for the authenticated user. `GET /common/auth/auth-user`
/// returns the user with nested `profile`, `company`, and `company_plan`
/// (the last including `plan` + `limits` + `usage`). We flatten the subset
/// the mobile UI actually uses.
class UserModel {
  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    this.gender,
    this.type,
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
  final String? type;
  final String? avatarUrl;
  final String? companyId;
  final String? companyName;
  final PlanLimits? planLimits;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'] as Map<String, dynamic>?;
    final company = json['company'] as Map<String, dynamic>?;
    final companyPlan =
        json['company_plan'] as Map<String, dynamic>? ??
            company?['company_plan'] as Map<String, dynamic>?;
    return UserModel(
      id: json['id'].toString(),
      email: (json['email'] ?? '') as String,
      fullName: ((profile?['full_name'] ??
              profile?['fullName'] ??
              json['full_name'] ??
              json['fullName'] ??
              '') as String)
          .toString(),
      phone: (profile?['phone'] ?? json['phone']) as String?,
      gender: (profile?['gender'] ?? json['gender']) as String?,
      type: json['type'] as String?,
      avatarUrl:
          (profile?['avatar_url'] ?? json['avatar_url'] ?? json['avatarUrl'])
              as String?,
      companyId: (company?['id'] ?? json['company_id'])?.toString(),
      companyName: (company?['company_name'] ??
          company?['companyName'] ??
          company?['name']) as String?,
      planLimits: _parsePlanLimits(companyPlan),
    );
  }

  static PlanLimits? _parsePlanLimits(Map<String, dynamic>? cp) {
    if (cp == null) return null;
    final plan = cp['plan'] as Map<String, dynamic>? ?? const {};
    final limitsRaw = cp['limits'];
    final usageRaw = cp['usage'];

    // Backend flattens limits into `{feature: value}`; tolerate the legacy
    // array shape as a fallback.
    final limits = <String, String>{};
    if (limitsRaw is Map) {
      limitsRaw.forEach((k, v) => limits[k.toString()] = v.toString());
    } else if (limitsRaw is List) {
      for (final item in limitsRaw) {
        if (item is Map) {
          final f = item['feature']?.toString();
          final v = item['value']?.toString();
          if (f != null && v != null) limits[f] = v;
        }
      }
    }

    final usage = <String, int>{};
    if (usageRaw is Map) {
      usageRaw.forEach((k, v) {
        final n = v is num ? v.toInt() : int.tryParse(v.toString());
        if (n != null) usage[k.toString()] = n;
      });
    }

    return PlanLimits(
      planType: (plan['type'] ?? 'starter').toString(),
      planName: (plan['name'] ?? 'Starter').toString(),
      limits: limits,
      usage: usage,
      status: (cp['status'] ?? 'active').toString(),
    );
  }

  UserEntity toEntity() => UserEntity(
        id: id,
        fullName: fullName,
        email: email,
        phone: phone,
        gender: gender,
        role: type,
        avatarUrl: avatarUrl,
        companyId: companyId,
        companyName: companyName,
        planLimits: planLimits,
      );
}
