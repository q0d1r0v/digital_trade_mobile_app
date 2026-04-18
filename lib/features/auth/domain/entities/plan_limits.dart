import 'package:equatable/equatable.dart';

/// Snapshot of a company's current plan + the feature gates derived from
/// its limits. Flatted from the nested shape the backend returns inside
/// the auth-user endpoint — mobile UI doesn't need the full relation.
class PlanLimits extends Equatable {
  const PlanLimits({
    required this.planType,
    required this.planName,
    required this.limits,
    this.usage = const {},
    this.status = 'active',
  });

  final String planType; // starter | business | enterprise
  final String planName;
  final Map<String, String> limits;
  final Map<String, int> usage;
  final String status;

  // ─── Feature gates ───────────────────────────────────────────────────

  bool get hasPos => _boolLimit('pos', fallback: true);
  bool get hasMultiCashbox => _boolLimit('multi_cashbox');
  bool get hasReports => _boolLimit('reports');
  bool get hasAiChat => _boolLimit('ai_chat');
  bool get hasDebtManagement => _boolLimit('debt_management');
  bool get hasInvoiceInput => _boolLimit('invoice_input', fallback: true);
  bool get hasInvoiceOutput => _boolLimit('invoice_output', fallback: true);

  int get maxUsers => _intLimit('max_users', fallback: 1);
  int get maxCashboxes => _intLimit('max_cashboxes', fallback: 2);
  int get maxProducts => _intLimit('max_products', fallback: 50);
  int get maxBranches => _intLimit('max_branches', fallback: 1);

  /// "unlimited" values surface as `-1`; call sites render that as "∞".
  int _intLimit(String key, {int fallback = 0}) {
    final raw = limits[key];
    if (raw == null) return fallback;
    if (raw == 'unlimited') return -1;
    return int.tryParse(raw) ?? fallback;
  }

  bool _boolLimit(String key, {bool fallback = false}) {
    final raw = limits[key]?.toLowerCase();
    if (raw == null) return fallback;
    return raw == 'true' || raw == '1';
  }

  bool get isStarter => planType == 'starter';
  bool get isBusiness => planType == 'business';
  bool get isEnterprise => planType == 'enterprise';

  @override
  List<Object?> get props => [planType, planName, limits, usage, status];
}
