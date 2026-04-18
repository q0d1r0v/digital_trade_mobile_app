import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../models/plan_model.dart';

abstract interface class PlansRemoteDataSource {
  Future<List<PlanModel>> getPlans();
}

class PlansRemoteDataSourceImpl implements PlansRemoteDataSource {
  PlansRemoteDataSourceImpl(this._api);
  final ApiClient _api;

  @override
  Future<List<PlanModel>> getPlans() async {
    final response = await _api.get<dynamic>(
      ApiEndpoints.plans,
      options: Options(extra: const {'skipAuth': true}),
    );
    // Backend wraps list responses either as `{ items: [...] }` or returns
    // the list directly — handle both.
    final list = response is Map<String, dynamic>
        ? (response['items'] ?? response['data'] ?? response['plans'])
        : response;
    if (list is! List) return const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(PlanModel.fromJson)
        .toList();
  }
}
