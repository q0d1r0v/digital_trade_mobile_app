import 'package:equatable/equatable.dart';

/// Lightweight `{id, label}` tuple used to populate dropdowns for related
/// resources (units, repositories, currencies, roles, categories, …).
///
/// `fromJson` is deliberately forgiving because backend resources don't
/// all expose a top-level `name` field:
/// - plans use `name`
/// - roles use `name`
/// - product units use `name`
/// - **company currencies** wrap the real currency: `{id, currency: {name}}`
/// - **users** surface their label via `profile.full_name`
/// - invoices sometimes expose `number` or `code` as the display label
/// Handling this once here means every picker gets the right label
/// without per-resource model classes for a string.
class NamedRef extends Equatable {
  const NamedRef({required this.id, required this.name});

  final int id;
  final String name;

  factory NamedRef.fromJson(Map<String, dynamic> json) => NamedRef(
        id: (json['id'] as num).toInt(),
        name: _extractName(json),
      );

  static String _extractName(Map<String, dynamic> j) {
    // Direct string fields, ordered by how "label-like" they are.
    const directKeys = [
      'name',
      'title',
      'full_name',
      'fullName',
      'display_name',
      'displayName',
      'code',
      'number',
      'email',
      'label',
    ];
    for (final k in directKeys) {
      final v = j[k];
      if (v is String && v.trim().isNotEmpty) return v;
    }

    // Common nested relations the backend inlines on list responses.
    const nestedKeys = [
      'currency',
      'role',
      'plan',
      'profile',
      'product',
      'user',
      'supplier',
      'client',
      'category',
      'brand',
      'repository',
      'cashbox',
    ];
    for (final k in nestedKeys) {
      final nested = j[k];
      if (nested is Map<String, dynamic>) {
        final inner = _extractName(nested);
        if (inner.isNotEmpty) return inner;
      }
    }

    // Last resort — stringify the id so dropdowns aren't visually empty.
    final id = j['id'];
    return id == null ? '' : '#$id';
  }

  @override
  List<Object?> get props => [id, name];

  @override
  String toString() => name;
}
