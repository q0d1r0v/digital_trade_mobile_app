import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

import '../../core/constants/api_endpoints.dart';
import '../../core/error/app_exception.dart';
import '../../core/error/error_mapper.dart';
import '../../core/error/failure.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/result.dart';

/// Minimal service for company profile updates. The backend uses
/// `PUT /company/company/company/:id` with a multipart body — here we
/// always send JSON since the mobile UI doesn't yet support logo upload.
class CompanyService {
  CompanyService(this._api);
  final ApiClient _api;

  AsyncResult<void> updateCompany({
    required int id,
    required String name,
    required String companyName,
    required String phone,
    required String address,
  }) async {
    try {
      await _api.put<dynamic>(
        ApiEndpoints.companyById(id),
        data: {
          'name': name,
          'company_name': companyName,
          'phone': phone,
          'address': address,
        },
        options: Options(contentType: Headers.jsonContentType),
      );
      return const Right(null);
    } on AppException catch (e) {
      return Left(mapExceptionToFailure(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
