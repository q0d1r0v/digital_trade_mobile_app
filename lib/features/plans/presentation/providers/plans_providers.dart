import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../domain/entities/plan_entity.dart';
import '../../domain/repositories/plans_repository.dart';

final plansRepositoryProvider = Provider<PlansRepository>((ref) => sl());

/// Loads the list of plans once per register screen. `autoDispose` keeps
/// the cache short-lived — we prefer a fresh fetch when a user reopens
/// register rather than showing a possibly outdated price.
final plansListProvider =
    FutureProvider.autoDispose<List<PlanEntity>>((ref) async {
  final repo = ref.watch(plansRepositoryProvider);
  final result = await repo.getPlans();
  return result.fold((failure) => throw failure, (plans) => plans);
});
