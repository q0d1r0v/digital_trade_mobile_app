import '../../../../core/utils/result.dart';
import '../entities/plan_entity.dart';

abstract interface class PlansRepository {
  AsyncResult<List<PlanEntity>> getPlans();
}
