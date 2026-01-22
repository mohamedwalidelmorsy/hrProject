import 'package:flutter_test/flutter_test.dart';
import 'package:hr_pro_app/services/api_service.dart';

void main() {
  group('ApiResponse Tests', () {
    test('ApiResponse with success true', () {
      final response = ApiResponse(
        success: true,
        data: {'id': 1, 'name': 'Test'},
        message: 'Success',
        statusCode: 200,
      );

      expect(response.success, true);
      expect(response.data, {'id': 1, 'name': 'Test'});
      expect(response.message, 'Success');
      expect(response.statusCode, 200);
      expect(response.errors, isNull);
    });

    test('ApiResponse with success false', () {
      final response = ApiResponse(
        success: false,
        message: 'Invalid credentials',
        statusCode: 401,
      );

      expect(response.success, false);
      expect(response.data, isNull);
      expect(response.message, 'Invalid credentials');
      expect(response.statusCode, 401);
    });

    test('ApiResponse with validation errors', () {
      final response = ApiResponse(
        success: false,
        message: 'Validation failed',
        statusCode: 422,
        errors: {
          'email': ['Email is required'],
          'password': ['Password must be at least 8 characters'],
        },
      );

      expect(response.success, false);
      expect(response.statusCode, 422);
      expect(response.errors, isNotNull);
      expect(response.errors['email'], ['Email is required']);
      expect(response.errors['password'], ['Password must be at least 8 characters']);
    });

    test('ApiResponse with list data', () {
      final response = ApiResponse(
        success: true,
        data: {
          'data': [
            {'id': 1, 'name': 'Employee 1'},
            {'id': 2, 'name': 'Employee 2'},
          ],
          'total': 2,
          'per_page': 10,
          'current_page': 1,
        },
        statusCode: 200,
      );

      expect(response.success, true);
      expect(response.data['data'], isList);
      expect(response.data['data'].length, 2);
      expect(response.data['total'], 2);
    });

    test('ApiResponse with null message defaults correctly', () {
      final response = ApiResponse(
        success: false,
        statusCode: 500,
      );

      expect(response.success, false);
      expect(response.message, isNull);
      expect(response.statusCode, 500);
    });

    test('ApiResponse stores status code correctly', () {
      final successResponse = ApiResponse(success: true, statusCode: 200);
      final createdResponse = ApiResponse(success: true, statusCode: 201);
      final badRequestResponse = ApiResponse(success: false, statusCode: 400);
      final unauthorizedResponse = ApiResponse(success: false, statusCode: 401);
      final forbiddenResponse = ApiResponse(success: false, statusCode: 403);
      final notFoundResponse = ApiResponse(success: false, statusCode: 404);
      final serverErrorResponse = ApiResponse(success: false, statusCode: 500);

      expect(successResponse.statusCode, 200);
      expect(createdResponse.statusCode, 201);
      expect(badRequestResponse.statusCode, 400);
      expect(unauthorizedResponse.statusCode, 401);
      expect(forbiddenResponse.statusCode, 403);
      expect(notFoundResponse.statusCode, 404);
      expect(serverErrorResponse.statusCode, 500);
    });
  });
}
