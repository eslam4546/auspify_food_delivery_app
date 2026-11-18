import 'package:dio/dio.dart';
import 'package:food_delivery_application/core/constants/app_constants.dart';
import 'package:food_delivery_application/core/errors/exceptions.dart';

/// Configured Dio HTTP client for the DummyJSON Recipes REST API.
class DioClient {
  DioClient({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: AppConstants.dummyJsonBaseUrl,
              connectTimeout: AppConstants.apiTimeout,
              receiveTimeout: AppConstants.apiTimeout,
              sendTimeout: AppConstants.apiTimeout,
              headers: const {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
              },
            ),
          );

  final Dio _dio;

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        path,
        queryParameters: queryParameters,
      );
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300 &&
          response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      throw ServerException(
        'Unexpected response (${response.statusCode}) from catalog API.',
      );
    } on DioException catch (e) {
      throw ServerException(
        e.message ?? 'Network request to recipe catalog failed.',
      );
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to fetch catalog data: $e');
    }
  }
}
