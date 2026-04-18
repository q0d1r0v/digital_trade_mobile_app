import 'package:fpdart/fpdart.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/plan_entity.dart';
import '../../domain/repositories/plans_repository.dart';
import '../datasources/plans_remote_datasource.dart';

class PlansRepositoryImpl implements PlansRepository {
  PlansRepositoryImpl({
    required PlansRemoteDataSource remote,
    required NetworkInfo networkInfo,
  })  : _remote = remote,
        _networkInfo = networkInfo;

  final PlansRemoteDataSource _remote;
  final NetworkInfo _networkInfo;

  @override
  AsyncResult<List<PlanEntity>> getPlans() async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final models = await _remote.getPlans();
      return Right(models.map((m) => m.toEntity()).toList());
    } on AppException catch (e) {
      return Left(mapExceptionToFailure(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
