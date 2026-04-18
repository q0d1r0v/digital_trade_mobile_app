import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/error/error_mapper.dart';
import '../../../core/error/failure.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/result.dart';

/// Product-specific service. Unlike the generic [CatalogService], product
/// create/update go through **multipart** so the backend can accept
/// images alongside the JSON fields. Simple resources (category, brand,
/// supplier) continue to use the JSON-only catalog service.
///
/// Endpoints:
///   - `POST   /company/product/product` (multipart)
///   - `POST   /company/product/product/with-variations` (json, nested)
///   - `PUT    /company/product/product/:id` (multipart)
class ProductService {
  ProductService(this._api);
  final ApiClient _api;

  AsyncResult<Map<String, dynamic>> create({
    required int companyId,
    required String name,
    required int categoryId,
    required int unitId,
    String? code,
    String? description,
    int? brandId,
    List<XFile> images = const [],
  }) async {
    try {
      final formData = await _buildForm(
        companyId: companyId,
        name: name,
        categoryId: categoryId,
        unitId: unitId,
        code: code,
        description: description,
        brandId: brandId,
        images: images,
      );
      final response = await _api.post<dynamic>(
        ApiEndpoints.product,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return Right(_asMap(response));
    } on AppException catch (e) {
      return Left(mapExceptionToFailure(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  AsyncResult<Map<String, dynamic>> update({
    required int id,
    required int companyId,
    required String name,
    required int categoryId,
    required int unitId,
    String? code,
    String? description,
    int? brandId,
    List<XFile> newImages = const [],
  }) async {
    try {
      final formData = await _buildForm(
        companyId: companyId,
        name: name,
        categoryId: categoryId,
        unitId: unitId,
        code: code,
        description: description,
        brandId: brandId,
        images: newImages,
      );
      final response = await _api.put<dynamic>(
        '${ApiEndpoints.product}/$id',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return Right(_asMap(response));
    } on AppException catch (e) {
      return Left(mapExceptionToFailure(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  Future<FormData> _buildForm({
    required int companyId,
    required String name,
    required int categoryId,
    required int unitId,
    String? code,
    String? description,
    int? brandId,
    required List<XFile> images,
  }) async {
    final form = FormData();
    form.fields.addAll([
      MapEntry('name', name),
      MapEntry('company_id', companyId.toString()),
      MapEntry('category_id', categoryId.toString()),
      MapEntry('unit_id', unitId.toString()),
      if (code != null && code.isNotEmpty) MapEntry('code', code),
      if (description != null && description.isNotEmpty)
        MapEntry('description', description),
      if (brandId != null) MapEntry('brand_id', brandId.toString()),
    ]);
    for (final img in images) {
      form.files.add(
        MapEntry(
          'images',
          await MultipartFile.fromFile(
            img.path,
            filename: img.name,
          ),
        ),
      );
    }
    return form;
  }

  Map<String, dynamic> _asMap(dynamic response) {
    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is Map<String, dynamic>) return data;
      return response;
    }
    return const {};
  }
}
