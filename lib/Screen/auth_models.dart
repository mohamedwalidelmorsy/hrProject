import 'package:flutter/material.dart';
import '../services/api_service.dart';

// ═══════════════════════════════════════════════════════════════
// User Model
// ═══════════════════════════════════════════════════════════════
class User {
  final String id;
  final String name;
  final String email;
  final String role; // 'admin' أو 'employee'
  final String? employeeId;
  final String? department;
  final String? avatarUrl;
  final String? phone;
  final String? position;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.employeeId,
    this.department,
    this.avatarUrl,
    this.phone,
    this.position,
  });

  bool get isAdmin => role == 'admin';
  bool get isEmployee => role == 'employee';

  String get initials {
    final names = name.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    }
    if (name.isNotEmpty) {
      return name.length >= 2
          ? name.substring(0, 2).toUpperCase()
          : name[0].toUpperCase();
    }
    return 'U';
  }

  // Convert من JSON (من API)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'employee',
      employeeId: json['employee_id']?.toString(),
      department: json['department']?.toString(),
      avatarUrl: json['avatar_url']?.toString() ?? json['avatar']?.toString(),
      phone: json['phone']?.toString(),
      position: json['position']?.toString(),
    );
  }

  // Convert لـ JSON (للحفظ)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'employee_id': employeeId,
      'department': department,
      'avatar_url': avatarUrl,
      'phone': phone,
      'position': position,
    };
  }

  // Create a copy with updated fields
  User copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? employeeId,
    String? department,
    String? avatarUrl,
    String? phone,
    String? position,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      employeeId: employeeId ?? this.employeeId,
      department: department ?? this.department,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phone: phone ?? this.phone,
      position: position ?? this.position,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Auth Provider - للـ State Management مع API Integration
// ═══════════════════════════════════════════════════════════════
class AuthProvider with ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _errorMessage;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _isAuthenticated && _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isEmployee => _currentUser?.isEmployee ?? false;

  // ═══════════════════════════════════════════════════════════════
  // Set User from API Response
  // ═══════════════════════════════════════════════════════════════
  Future<void> setUserFromApi(Map<String, dynamic> userData) async {
    _currentUser = User.fromJson(userData);
    _isAuthenticated = true;
    _errorMessage = null;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════
  // Login with API
  // ═══════════════════════════════════════════════════════════════
  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.login(email: email, password: password);

      if (response.success && response.data != null) {
        // Token is automatically saved by ApiService.login()
        if (response.data['user'] != null) {
          _currentUser = User.fromJson(response.data['user']);
          _isAuthenticated = true;
        }
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message ?? 'Login failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // Logout with API
  // ═══════════════════════════════════════════════════════════════
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await ApiService.logout();
    } catch (e) {
      // Continue with local logout even if API fails
    }

    _currentUser = null;
    _isAuthenticated = false;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════
  // Check Auth Status from Stored Token
  // ═══════════════════════════════════════════════════════════════
  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Check if token exists
      final token = await ApiService.getToken();

      if (token != null && token.isNotEmpty) {
        // Verify token by getting current user
        final response = await ApiService.getCurrentUser();

        if (response.success && response.data != null) {
          _currentUser = User.fromJson(response.data['user'] ?? response.data);
          _isAuthenticated = true;
        } else {
          // Token invalid, clear it
          await ApiService.removeToken();
          _isAuthenticated = false;
        }
      } else {
        _isAuthenticated = false;
      }

      // Also check stored user data
      final userData = await ApiService.getUserData();
      if (userData != null && _currentUser == null) {
        _currentUser = User.fromJson(userData);
        _isAuthenticated = true;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isAuthenticated = false;
    }

    _isLoading = false;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════
  // Update User Profile
  // ═══════════════════════════════════════════════════════════════
  Future<bool> updateProfile({
    String? name,
    String? email,
    String? phone,
    String? avatar,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.updateProfile(
        name: name,
        email: email,
        phone: phone,
        avatar: avatar,
      );

      if (response.success) {
        // Update local user data
        if (_currentUser != null) {
          _currentUser = _currentUser!.copyWith(
            name: name ?? _currentUser!.name,
            email: email ?? _currentUser!.email,
            phone: phone ?? _currentUser!.phone,
            avatarUrl: avatar ?? _currentUser!.avatarUrl,
          );
          // Save updated user data
          await ApiService.saveUserData(_currentUser!.toJson());
        }
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // Change Password
  // ═══════════════════════════════════════════════════════════════
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        newPasswordConfirmation: confirmPassword,
      );

      _isLoading = false;
      if (!response.success) {
        _errorMessage = response.message;
      }
      notifyListeners();
      return response.success;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // Clear Error
  // ═══════════════════════════════════════════════════════════════
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

// ═══════════════════════════════════════════════════════════════
// Role Checker - Helper Functions
// ═══════════════════════════════════════════════════════════════
class RoleChecker {
  static bool isAdmin(String? role) => role == 'admin';
  static bool isEmployee(String? role) => role == 'employee';

  // للصلاحيات المتقدمة
  static bool canManageEmployees(String? role) => isAdmin(role);
  static bool canViewAllReports(String? role) => isAdmin(role);
  static bool canEditShifts(String? role) => isAdmin(role);
  static bool canApproveLeaves(String? role) => isAdmin(role);

  // للموظف
  static bool canViewOwnData(String? role) => true;
  static bool canRequestLeave(String? role) => true;
  static bool canCheckInOut(String? role) => isEmployee(role);
}
