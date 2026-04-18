import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../auth/domain/entities/user_entity.dart';
import '../domain/entities/onboarding_task.dart';

/// Hits the normal list endpoints with `limit=1` and interprets "does at
/// least one row exist" as task completion. This mirrors
/// `useOnboardingProgress.ts` on the web frontend — there's no dedicated
/// onboarding endpoint on the backend.
///
/// Errors are swallowed per-probe and treated as "not done yet" so one
/// flaky endpoint doesn't kill the whole checklist.
class OnboardingProbeService {
  OnboardingProbeService(this._api);
  final ApiClient _api;

  /// Runs every probe in parallel and returns `{probe: isDone}`.
  Future<Map<OnboardingProbe, bool>> evaluate(UserEntity? user) async {
    final results = <OnboardingProbe, bool>{};
    final futures = <Future<void>>[];

    for (final task in kOnboardingTasks) {
      futures.add(() async {
        results[task.probe] = await _runProbe(task.probe, user);
      }());
    }
    await Future.wait(futures);
    return results;
  }

  Future<bool> _runProbe(OnboardingProbe probe, UserEntity? user) async {
    switch (probe) {
      case OnboardingProbe.companyProfile:
        // Pure client-side — the backend already guarantees a company row
        // exists after register, we just check whether the user filled it.
        final hasName = user?.companyName?.trim().isNotEmpty ?? false;
        final hasPhone = user?.phone?.trim().isNotEmpty ?? false;
        return hasName && hasPhone;
      case OnboardingProbe.firstCashbox:
        return _hasAny(
          ApiEndpoints.publicRecordsCashbox,
          query: {'type': 'sale'},
          listKeys: const ['data', 'items', 'rows'],
        );
      case OnboardingProbe.firstCategory:
        return _hasAny(ApiEndpoints.category);
      case OnboardingProbe.firstSupplier:
        return _hasAny(ApiEndpoints.supplier);
      case OnboardingProbe.firstProduct:
        return _hasAny(ApiEndpoints.product);
      case OnboardingProbe.firstInputInvoice:
        return _hasAny(ApiEndpoints.inputInvoice);
      case OnboardingProbe.firstSale:
        return _hasAny(ApiEndpoints.saleInvoice);
      case OnboardingProbe.inviteTeam:
        // "Invited" means > 1 row — the owner themselves is always the
        // first user, so we need at least a second entry.
        return _count(ApiEndpoints.companyUser, minimum: 2);
    }
  }

  Future<bool> _hasAny(
    String path, {
    Map<String, dynamic>? query,
    List<String> listKeys = const ['items', 'data', 'rows'],
  }) async {
    try {
      final response = await _api.get<dynamic>(
        path,
        query: {'page': 1, 'limit': 1, ...?query},
      );
      return _extractLength(response, listKeys) > 0;
    } on AppException {
      return false;
    } on DioException {
      return false;
    }
  }

  Future<bool> _count(String path, {required int minimum}) async {
    try {
      final response = await _api.get<dynamic>(
        path,
        query: {'page': 1, 'limit': minimum + 1},
      );
      return _extractLength(response, const ['items', 'data', 'rows']) >=
          minimum;
    } on AppException {
      return false;
    } on DioException {
      return false;
    }
  }

  int _extractLength(dynamic payload, List<String> listKeys) {
    if (payload is List) return payload.length;
    if (payload is Map<String, dynamic>) {
      for (final k in listKeys) {
        final v = payload[k];
        if (v is List) return v.length;
      }
      final total = payload['total'] ?? payload['count'];
      if (total is num) return total.toInt();
    }
    return 0;
  }
}
