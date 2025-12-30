import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// ============================================================================
/// HR Pro - API Service
/// ============================================================================
/// ملف مركزي لجميع الـ API Calls
/// الإصدار: 1.0.0
/// ============================================================================

class ApiService {
  // ══════════════════════════════════════════════════════════════════════════
  // Configuration
  // ══════════════════════════════════════════════════════════════════════════
  
  /// Base URL - غيّره حسب سيرفر الباك اند
  static const String baseUrl = 'https://your-api-domain.com/api';
  
  /// Timeout للـ requests (بالثواني)
  static const int timeoutSeconds = 30;

  // ══════════════════════════════════════════════════════════════════════════
  // Token Management
  // ══════════════════════════════════════════════════════════════════════════

  /// حفظ الـ Token بعد تسجيل الدخول
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  /// جلب الـ Token المحفوظ
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  /// حذف الـ Token (تسجيل خروج)
  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  /// حفظ بيانات المستخدم
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(userData));
  }

  /// جلب بيانات المستخدم المحفوظة
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

  /// Headers بدون Token (للـ Login و Register)
  static Map<String, String> get _publicHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Headers مع Token (للـ Authenticated Requests)
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

  /// معالجة الـ Response
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
          message: body?['message'] ?? 'طلب غير صالح',
          statusCode: 400,
        );
      case 401:
        // Token منتهي أو غير صالح
        removeToken();
        return ApiResponse(
          success: false,
          message: 'جلسة منتهية، يرجى تسجيل الدخول مرة أخرى',
          statusCode: 401,
        );
      case 403:
        return ApiResponse(
          success: false,
          message: 'غير مصرح لك بهذا الإجراء',
          statusCode: 403,
        );
      case 404:
        return ApiResponse(
          success: false,
          message: 'البيانات غير موجودة',
          statusCode: 404,
        );
      case 422:
        // Validation Errors
        final errors = body?['errors'];
        String errorMessage = 'بيانات غير صالحة';
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
          message: 'خطأ في الخادم، يرجى المحاولة لاحقاً',
          statusCode: 500,
        );
      default:
        return ApiResponse(
          success: false,
          message: 'حدث خطأ غير متوقع',
          statusCode: response.statusCode,
        );
    }
  }

  /// معالجة الأخطاء
  static ApiResponse _handleError(dynamic error) {
    if (error is SocketException) {
      return ApiResponse(
        success: false,
        message: 'لا يوجد اتصال بالإنترنت',
        statusCode: 0,
      );
    } else if (error.toString().contains('TimeoutException')) {
      return ApiResponse(
        success: false,
        message: 'انتهت مهلة الاتصال، يرجى المحاولة مرة أخرى',
        statusCode: 0,
      );
    }
    return ApiResponse(
      success: false,
      message: 'حدث خطأ: ${error.toString()}',
      statusCode: 0,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Authentication Endpoints
  // ══════════════════════════════════════════════════════════════════════════

  /// تسجيل الدخول
  static Future<ApiResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await post(
      '/auth/login',
      body: {
        'email': email,
        'password': password,
      },
      auth: false,
    );

    // حفظ التوكن وبيانات المستخدم عند النجاح
    if (response.success && response.data != null) {
      await saveToken(response.data['token']);
      await saveUserData(response.data['user']);
    }

    return response;
  }

  /// تسجيل مستخدم جديد
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

  /// تسجيل الخروج
  static Future<ApiResponse> logout() async {
    final response = await post('/auth/logout');
    await removeToken();
    return response;
  }

  /// نسيت كلمة المرور
  static Future<ApiResponse> forgotPassword({required String email}) async {
    return await post(
      '/auth/forgot-password',
      body: {'email': email},
      auth: false,
    );
  }

  /// إعادة تعيين كلمة المرور
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

  /// جلب بيانات المستخدم الحالي
  static Future<ApiResponse> getCurrentUser() async {
    return await get('/auth/me');
  }

  /// تحديث الملف الشخصي
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

  /// تغيير كلمة المرور
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

  /// جلب إحصائيات الداشبورد
  static Future<ApiResponse> getDashboardStats() async {
    return await get('/dashboard/stats');
  }

  /// جلب آخر الأنشطة
  static Future<ApiResponse> getRecentActivities({int limit = 10}) async {
    return await get('/dashboard/activities?limit=$limit');
  }

  /// جلب الإشعارات
  static Future<ApiResponse> getNotifications({int page = 1}) async {
    return await get('/dashboard/notifications?page=$page');
  }

  /// تحديد الإشعار كمقروء
  static Future<ApiResponse> markNotificationAsRead(int notificationId) async {
    return await put('/dashboard/notifications/$notificationId/read');
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Employees Endpoints
  // ══════════════════════════════════════════════════════════════════════════

  /// جلب قائمة الموظفين
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

  /// جلب بيانات موظف واحد
  static Future<ApiResponse> getEmployee(int employeeId) async {
    return await get('/employees/$employeeId');
  }

  /// إضافة موظف جديد
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

  /// تحديث بيانات موظف
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

  /// حذف موظف
  static Future<ApiResponse> deleteEmployee(int employeeId) async {
    return await delete('/employees/$employeeId');
  }

  /// جلب الأقسام
  static Future<ApiResponse> getDepartments() async {
    return await get('/employees/departments');
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Attendance Endpoints
  // ══════════════════════════════════════════════════════════════════════════

  /// تسجيل حضور (Check In)
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

  /// تسجيل انصراف (Check Out)
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

  /// جلب سجل الحضور للمستخدم الحالي
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

  /// جلب سجل حضور جميع الموظفين (Admin)
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

  /// تسجيل حضور يدوي (Admin)
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

  /// جلب حالة الحضور اليوم
  static Future<ApiResponse> getTodayAttendanceStatus() async {
    return await get('/attendance/today');
  }

  /// تعديل سجل حضور (Admin)
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

  /// جلب جميع الشفتات
  static Future<ApiResponse> getShifts({int page = 1}) async {
    return await get('/shifts?page=$page');
  }

  /// جلب شفت واحد
  static Future<ApiResponse> getShift(int shiftId) async {
    return await get('/shifts/$shiftId');
  }

  /// إنشاء شفت جديد
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

  /// تحديث شفت
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

  /// حذف شفت
  static Future<ApiResponse> deleteShift(int shiftId) async {
    return await delete('/shifts/$shiftId');
  }

  /// تعيين شفت لموظف
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

  /// جلب الشفت الحالي للمستخدم
  static Future<ApiResponse> getMyCurrentShift() async {
    return await get('/shifts/my/current');
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Reports Endpoints
  // ══════════════════════════════════════════════════════════════════════════

  /// تقرير الحضور
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

  /// تقرير الموظفين
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

  /// تقرير الشفتات
  static Future<ApiResponse> getShiftsReport({
    required String startDate,
    required String endDate,
  }) async {
    return await get('/reports/shifts?start_date=$startDate&end_date=$endDate');
  }

  /// ملخص شهري
  static Future<ApiResponse> getMonthlySummary({
    required int year,
    required int month,
  }) async {
    return await get('/reports/monthly?year=$year&month=$month');
  }

  /// تصدير تقرير PDF
  static Future<ApiResponse> exportReportPdf({
    required String reportType,
    required String startDate,
    required String endDate,
  }) async {
    return await get(
      '/reports/export/pdf?type=$reportType&start_date=$startDate&end_date=$endDate',
    );
  }

  /// تصدير تقرير Excel
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
  // Leave Requests Endpoints (إضافي - طلبات الإجازات)
  // ══════════════════════════════════════════════════════════════════════════

  /// جلب طلبات الإجازات
  static Future<ApiResponse> getLeaveRequests({
    int page = 1,
    String? status,
  }) async {
    String endpoint = '/leave-requests?page=$page';
    if (status != null) endpoint += '&status=$status';
    return await get(endpoint);
  }

  /// إنشاء طلب إجازة
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

  /// الموافقة/الرفض على طلب إجازة (Admin)
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