import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'demo_data.dart';

/// ============================================================================
/// HR Pro - API Service
/// ============================================================================
/// Central file for all API calls
/// Version: 1.0.0
/// ============================================================================

class ApiService {
  // ══════════════════════════════════════════════════════════════════════════
  // Configuration
  // ══════════════════════════════════════════════════════════════════════════

  /// Base URL - Change this to your backend server URL
  static const String baseUrl = 'https://your-api-domain.com/api';

  /// Request timeout in seconds
  static const int timeoutSeconds = 30;

  /// Demo Mode - Enable to use demo login accounts
  /// Set to false when backend is ready
  static const bool isDemoMode = true;

  // ══════════════════════════════════════════════════════════════════════════
  // Token Management
  // ══════════════════════════════════════════════════════════════════════════

  /// Save token after login
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  /// Get saved token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  /// Remove token (logout)
  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  /// Save user data
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(userData));
  }

  /// Get saved user data
  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('user_data');
    if (data != null) {
      return jsonDecode(data);
    }
    return null;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Headers
  // ══════════════════════════════════════════════════════════════════════════

  /// Headers without token (for Login and Register)
  static Map<String, String> get _publicHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Headers with token (for authenticated requests)
  static Future<Map<String, String>> get _authHeaders async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HTTP Methods (Core)
  // ══════════════════════════════════════════════════════════════════════════

  /// GET Request
  static Future<ApiResponse> get(String endpoint, {bool auth = true}) async {
    try {
      final headers = auth ? await _authHeaders : _publicHeaders;
      final response = await http
          .get(
            Uri.parse('$baseUrl$endpoint'),
            headers: headers,
          )
          .timeout(Duration(seconds: timeoutSeconds));

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// POST Request
  static Future<ApiResponse> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    try {
      final headers = auth ? await _authHeaders : _publicHeaders;
      final response = await http
          .post(
            Uri.parse('$baseUrl$endpoint'),
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(Duration(seconds: timeoutSeconds));

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// PUT Request
  static Future<ApiResponse> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    try {
      final headers = auth ? await _authHeaders : _publicHeaders;
      final response = await http
          .put(
            Uri.parse('$baseUrl$endpoint'),
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(Duration(seconds: timeoutSeconds));

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// DELETE Request
  static Future<ApiResponse> delete(String endpoint, {bool auth = true}) async {
    try {
      final headers = auth ? await _authHeaders : _publicHeaders;
      final response = await http
          .delete(
            Uri.parse('$baseUrl$endpoint'),
            headers: headers,
          )
          .timeout(Duration(seconds: timeoutSeconds));

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Response & Error Handling
  // ══════════════════════════════════════════════════════════════════════════

  /// Handle API response
  static ApiResponse _handleResponse(http.Response response) {
    final body = response.body.isNotEmpty ? jsonDecode(response.body) : null;

    switch (response.statusCode) {
      case 200:
      case 201:
        return ApiResponse(
          success: true,
          data: body,
          statusCode: response.statusCode,
        );
      case 400:
        return ApiResponse(
          success: false,
          message: body?['message'] ?? 'Bad request',
          statusCode: 400,
        );
      case 401:
        removeToken();
        return ApiResponse(
          success: false,
          message: 'Session expired, please login again',
          statusCode: 401,
        );
      case 403:
        return ApiResponse(
          success: false,
          message: 'You are not authorized to perform this action',
          statusCode: 403,
        );
      case 404:
        return ApiResponse(
          success: false,
          message: 'Data not found',
          statusCode: 404,
        );
      case 422:
        final errors = body?['errors'];
        String errorMessage = 'Invalid data';
        if (errors is Map) {
          errorMessage = errors.values.first is List
              ? errors.values.first.first
              : errors.values.first.toString();
        }
        return ApiResponse(
          success: false,
          message: errorMessage,
          errors: errors,
          statusCode: 422,
        );
      case 500:
        return ApiResponse(
          success: false,
          message: 'Server error, please try again later',
          statusCode: 500,
        );
      default:
        return ApiResponse(
          success: false,
          message: 'An unexpected error occurred',
          statusCode: response.statusCode,
        );
    }
  }

  /// Handle errors
  static ApiResponse _handleError(dynamic error) {
    if (error is SocketException) {
      return ApiResponse(
        success: false,
        message: 'No internet connection',
        statusCode: 0,
      );
    } else if (error.toString().contains('TimeoutException')) {
      return ApiResponse(
        success: false,
        message: 'Connection timeout, please try again',
        statusCode: 0,
      );
    }
    return ApiResponse(
      success: false,
      message: 'Error: ${error.toString()}',
      statusCode: 0,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Authentication Endpoints
  // ══════════════════════════════════════════════════════════════════════════

  /// Login
  static Future<ApiResponse> login({
    required String email,
    required String password,
  }) async {
    // Demo Mode - Use demo accounts for login
    if (isDemoMode) {
      final user = DemoData.users[email.toLowerCase()];
      if (user != null && user['password'] == password) {
        final userData = Map<String, dynamic>.from(user);
        userData.remove('password');

        await saveToken('demo_token_${user['id']}');
        await saveUserData(userData);

        return ApiResponse(
          success: true,
          data: {
            'token': 'demo_token_${user['id']}',
            'user': userData,
          },
          statusCode: 200,
        );
      } else {
        return ApiResponse(
          success: false,
          message: 'Invalid email or password',
          statusCode: 401,
        );
      }
    }

    // Real API call
    final response = await post(
      '/auth/login',
      body: {
        'email': email,
        'password': password,
      },
      auth: false,
    );

    if (response.success && response.data != null) {
      await saveToken(response.data['token']);
      await saveUserData(response.data['user']);
    }

    return response;
  }

  /// Register new user
  static Future<ApiResponse> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? phone,
  }) async {
    return await post(
      '/auth/register',
      body: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        if (phone != null) 'phone': phone,
      },
      auth: false,
    );
  }

  /// Logout
  static Future<ApiResponse> logout() async {
    final response = await post('/auth/logout');
    await removeToken();
    return response;
  }

  /// Forgot password
  static Future<ApiResponse> forgotPassword({required String email}) async {
    return await post(
      '/auth/forgot-password',
      body: {'email': email},
      auth: false,
    );
  }

  /// Reset password
  static Future<ApiResponse> resetPassword({
    required String token,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    return await post(
      '/auth/reset-password',
      body: {
        'token': token,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
      auth: false,
    );
  }

  /// Get current user data
  static Future<ApiResponse> getCurrentUser() async {
    return await get('/auth/me');
  }

  /// Update profile
  static Future<ApiResponse> updateProfile({
    String? name,
    String? email,
    String? phone,
    String? avatar,
  }) async {
    return await put(
      '/auth/profile',
      body: {
        if (name != null) 'name': name,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        if (avatar != null) 'avatar': avatar,
      },
    );
  }

  /// Change password
  static Future<ApiResponse> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    return await put(
      '/auth/change-password',
      body: {
        'current_password': currentPassword,
        'new_password': newPassword,
        'new_password_confirmation': newPasswordConfirmation,
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Dashboard Endpoints
  // ══════════════════════════════════════════════════════════════════════════

  /// Get dashboard statistics
  static Future<ApiResponse> getDashboardStats() async {
    return await get('/dashboard/stats');
  }

  /// Get recent activities
  static Future<ApiResponse> getRecentActivities({int limit = 10}) async {
    return await get('/dashboard/activities?limit=$limit');
  }

  /// Get notifications
  static Future<ApiResponse> getNotifications({int page = 1}) async {
    return await get('/dashboard/notifications?page=$page');
  }

  /// Mark notification as read
  static Future<ApiResponse> markNotificationAsRead(int notificationId) async {
    return await put('/dashboard/notifications/$notificationId/read');
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Employees Endpoints
  // ══════════════════════════════════════════════════════════════════════════

  /// Get employees list
  static Future<ApiResponse> getEmployees({
    int page = 1,
    int perPage = 10,
    String? search,
    String? department,
    String? status,
  }) async {
    String endpoint = '/employees?page=$page&per_page=$perPage';
    if (search != null && search.isNotEmpty) endpoint += '&search=$search';
    if (department != null) endpoint += '&department=$department';
    if (status != null) endpoint += '&status=$status';
    return await get(endpoint);
  }

  /// Get single employee
  static Future<ApiResponse> getEmployee(int employeeId) async {
    return await get('/employees/$employeeId');
  }

  /// Create new employee
  static Future<ApiResponse> createEmployee({
    required String name,
    required String email,
    required String phone,
    required String department,
    required String position,
    required String hireDate,
    double? salary,
    String? avatar,
  }) async {
    return await post(
      '/employees',
      body: {
        'name': name,
        'email': email,
        'phone': phone,
        'department': department,
        'position': position,
        'hire_date': hireDate,
        if (salary != null) 'salary': salary,
        if (avatar != null) 'avatar': avatar,
      },
    );
  }

  /// Update employee
  static Future<ApiResponse> updateEmployee({
    required int employeeId,
    String? name,
    String? email,
    String? phone,
    String? department,
    String? position,
    double? salary,
    String? status,
  }) async {
    return await put(
      '/employees/$employeeId',
      body: {
        if (name != null) 'name': name,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        if (department != null) 'department': department,
        if (position != null) 'position': position,
        if (salary != null) 'salary': salary,
        if (status != null) 'status': status,
      },
    );
  }

  /// Delete employee
  static Future<ApiResponse> deleteEmployee(int employeeId) async {
    return await delete('/employees/$employeeId');
  }

  /// Get departments
  static Future<ApiResponse> getDepartments() async {
    return await get('/employees/departments');
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Attendance Endpoints
  // ══════════════════════════════════════════════════════════════════════════

  /// Check In
  static Future<ApiResponse> checkIn({
    String? notes,
    double? latitude,
    double? longitude,
  }) async {
    return await post(
      '/attendance/check-in',
      body: {
        'timestamp': DateTime.now().toIso8601String(),
        if (notes != null) 'notes': notes,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      },
    );
  }

  /// Check Out
  static Future<ApiResponse> checkOut({
    String? notes,
    double? latitude,
    double? longitude,
  }) async {
    return await post(
      '/attendance/check-out',
      body: {
        'timestamp': DateTime.now().toIso8601String(),
        if (notes != null) 'notes': notes,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      },
    );
  }

  /// Get current user's attendance records
  static Future<ApiResponse> getMyAttendance({
    String? startDate,
    String? endDate,
    int page = 1,
  }) async {
    String endpoint = '/attendance/my?page=$page';
    if (startDate != null) endpoint += '&start_date=$startDate';
    if (endDate != null) endpoint += '&end_date=$endDate';
    return await get(endpoint);
  }

  /// Get all employees attendance (Admin)
  static Future<ApiResponse> getAllAttendance({
    String? startDate,
    String? endDate,
    int? employeeId,
    int page = 1,
    int perPage = 20,
    String? search,
    String? status,
    String? department,
  }) async {
    String endpoint = '/attendance?page=$page&per_page=$perPage';
    if (startDate != null) endpoint += '&start_date=$startDate';
    if (endDate != null) endpoint += '&end_date=$endDate';
    if (employeeId != null) endpoint += '&employee_id=$employeeId';
    if (search != null && search.isNotEmpty) endpoint += '&search=$search';
    if (status != null) endpoint += '&status=$status';
    if (department != null) endpoint += '&department=$department';
    return await get(endpoint);
  }

  /// Manual attendance mark (Admin)
  static Future<ApiResponse> markAttendance({
    required String employeeId,
    String? checkIn,
    String? checkOut,
    String? date,
    String? status,
    String? notes,
  }) async {
    return await post(
      '/attendance/mark',
      body: {
        'employee_id': employeeId,
        if (checkIn != null) 'check_in': checkIn,
        if (checkOut != null) 'check_out': checkOut,
        if (date != null) 'date': date,
        if (status != null) 'status': status,
        if (notes != null) 'notes': notes,
      },
    );
  }

  /// Get today's attendance status
  static Future<ApiResponse> getTodayAttendanceStatus() async {
    return await get('/attendance/today');
  }

  /// Update attendance record (Admin)
  static Future<ApiResponse> updateAttendance({
    required int attendanceId,
    String? checkIn,
    String? checkOut,
    String? status,
    String? notes,
  }) async {
    return await put(
      '/attendance/$attendanceId',
      body: {
        if (checkIn != null) 'check_in': checkIn,
        if (checkOut != null) 'check_out': checkOut,
        if (status != null) 'status': status,
        if (notes != null) 'notes': notes,
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Shifts Endpoints
  // ══════════════════════════════════════════════════════════════════════════

  /// Get all shifts
  static Future<ApiResponse> getShifts({int page = 1}) async {
    return await get('/shifts?page=$page');
  }

  /// Get single shift
  static Future<ApiResponse> getShift(int shiftId) async {
    return await get('/shifts/$shiftId');
  }

  /// Create new shift
  static Future<ApiResponse> createShift({
    required String name,
    required String startTime,
    required String endTime,
    String? description,
    List<String>? workDays,
  }) async {
    return await post(
      '/shifts',
      body: {
        'name': name,
        'start_time': startTime,
        'end_time': endTime,
        if (description != null) 'description': description,
        if (workDays != null) 'work_days': workDays,
      },
    );
  }

  /// Update shift
  static Future<ApiResponse> updateShift({
    required int shiftId,
    String? name,
    String? startTime,
    String? endTime,
    String? description,
    List<String>? workDays,
  }) async {
    return await put(
      '/shifts/$shiftId',
      body: {
        if (name != null) 'name': name,
        if (startTime != null) 'start_time': startTime,
        if (endTime != null) 'end_time': endTime,
        if (description != null) 'description': description,
        if (workDays != null) 'work_days': workDays,
      },
    );
  }

  /// Delete shift
  static Future<ApiResponse> deleteShift(int shiftId) async {
    return await delete('/shifts/$shiftId');
  }

  /// Assign shift to employee
  static Future<ApiResponse> assignShiftToEmployee({
    required int shiftId,
    required int employeeId,
    required String startDate,
    String? endDate,
  }) async {
    return await post(
      '/shifts/$shiftId/assign',
      body: {
        'employee_id': employeeId,
        'start_date': startDate,
        if (endDate != null) 'end_date': endDate,
      },
    );
  }

  /// Get current user's shift
  static Future<ApiResponse> getMyCurrentShift() async {
    return await get('/shifts/my/current');
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Reports Endpoints
  // ══════════════════════════════════════════════════════════════════════════

  /// Get attendance report
  static Future<ApiResponse> getAttendanceReport({
    required String startDate,
    required String endDate,
    int? departmentId,
    int? employeeId,
  }) async {
    String endpoint = '/reports/attendance?start_date=$startDate&end_date=$endDate';
    if (departmentId != null) endpoint += '&department_id=$departmentId';
    if (employeeId != null) endpoint += '&employee_id=$employeeId';
    return await get(endpoint);
  }

  /// Get employees report
  static Future<ApiResponse> getEmployeesReport({
    String? department,
    String? status,
  }) async {
    String endpoint = '/reports/employees';
    List<String> params = [];
    if (department != null) params.add('department=$department');
    if (status != null) params.add('status=$status');
    if (params.isNotEmpty) endpoint += '?${params.join('&')}';
    return await get(endpoint);
  }

  /// Get shifts report
  static Future<ApiResponse> getShiftsReport({
    required String startDate,
    required String endDate,
  }) async {
    return await get('/reports/shifts?start_date=$startDate&end_date=$endDate');
  }

  /// Get monthly summary
  static Future<ApiResponse> getMonthlySummary({
    required int year,
    required int month,
  }) async {
    return await get('/reports/monthly?year=$year&month=$month');
  }

  /// Export PDF report
  static Future<ApiResponse> exportReportPdf({
    required String reportType,
    required String startDate,
    required String endDate,
  }) async {
    return await get(
      '/reports/export/pdf?type=$reportType&start_date=$startDate&end_date=$endDate',
    );
  }

  /// Export Excel report
  static Future<ApiResponse> exportReportExcel({
    required String reportType,
    required String startDate,
    required String endDate,
  }) async {
    return await get(
      '/reports/export/excel?type=$reportType&start_date=$startDate&end_date=$endDate',
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Leave Requests Endpoints
  // ══════════════════════════════════════════════════════════════════════════

  /// Get leave requests
  static Future<ApiResponse> getLeaveRequests({
    int page = 1,
    String? status,
  }) async {
    String endpoint = '/leave-requests?page=$page';
    if (status != null) endpoint += '&status=$status';
    return await get(endpoint);
  }

  /// Create leave request
  static Future<ApiResponse> createLeaveRequest({
    required String type,
    required String startDate,
    required String endDate,
    String? reason,
  }) async {
    return await post(
      '/leave-requests',
      body: {
        'type': type,
        'start_date': startDate,
        'end_date': endDate,
        if (reason != null) 'reason': reason,
      },
    );
  }

  /// Approve/Reject leave request (Admin)
  static Future<ApiResponse> updateLeaveRequestStatus({
    required int requestId,
    required String status,
    String? adminNotes,
  }) async {
    return await put(
      '/leave-requests/$requestId/status',
      body: {
        'status': status,
        if (adminNotes != null) 'admin_notes': adminNotes,
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// API Response Model
// ══════════════════════════════════════════════════════════════════════════════

class ApiResponse {
  final bool success;
  final dynamic data;
  final String? message;
  final dynamic errors;
  final int statusCode;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.errors,
    required this.statusCode,
  });

  @override
  String toString() {
    return 'ApiResponse(success: $success, statusCode: $statusCode, message: $message)';
  }
}
