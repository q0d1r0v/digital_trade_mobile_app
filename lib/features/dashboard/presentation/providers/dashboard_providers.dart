import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../data/dashboard_service.dart';

final dashboardServiceProvider =
    Provider<DashboardService>((ref) => sl());

/// Date range currently driving every dashboard widget. Default =
/// last 3 months (inclusive of today) — matches the web dashboard's
/// starting range.
@immutable
class DashboardRange {
  const DashboardRange({required this.from, required this.to});

  factory DashboardRange.defaultRange() {
    final now = DateTime.now();
    final from = DateTime(now.year, now.month - 2, 1);
    return DashboardRange(from: from, to: now);
  }

  final DateTime from;
  final DateTime to;

  DashboardRange copyWith({DateTime? from, DateTime? to}) =>
      DashboardRange(from: from ?? this.from, to: to ?? this.to);

  @override
  bool operator ==(Object other) =>
      other is DashboardRange && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(from, to);
}

final dashboardRangeProvider =
    StateProvider<DashboardRange>((_) => DashboardRange.defaultRange());

/// Fetches every dashboard endpoint in parallel for the current range.
/// Invalidate after a successful sale / purchase so KPI cards update
/// without a manual refresh.
final dashboardSnapshotProvider =
    FutureProvider<DashboardSnapshot>((ref) async {
  final range = ref.watch(dashboardRangeProvider);
  final service = ref.watch(dashboardServiceProvider);
  return service.loadAll(from: range.from, to: range.to);
});
