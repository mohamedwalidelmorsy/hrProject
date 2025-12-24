import 'package:flutter/material.dart';

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
  
  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.employeeId,
    this.department,
    this.avatarUrl,
  });
  
  bool get isAdmin => role == 'admin';
  bool get isEmployee => role == 'employee';
  
  String get initials {
    final names = name.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    }
    return name.substring(0, 2).toUpperCase();
  }
  
  // Convert من JSON (من API)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'employee',
      employeeId: json['employee_id'],
      department: json['department'],
      avatarUrl: json['avatar_url'],
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
    };
  }
}

// ═══════════════════════════════════════════════════════════════
// Auth Provider - للـ State Management
// ═══════════════════════════════════════════════════════════════
class AuthProvider with ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isEmployee => _currentUser?.isEmployee ?? false;
  
  // Login
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      // هنا حتكون الـ API call الحقيقي
      await Future.delayed(const Duration(seconds: 2));
      
      // مثال: Admin Login
      if (email == 'admin@hrpro.com') {
        _currentUser = User(
          id: '1',
          name: 'Ahmed Admin',
          email: email,
          role: 'admin',
        );
      } 
      // مثال: Employee Login
      else if (email.contains('@')) {
        _currentUser = User(
          id: '2',
          name: 'Mohamed Employee',
          email: email,
          role: 'employee',
          employeeId: 'EMP001',
          department: 'IT',
        );
      } else {
        throw Exception('Invalid credentials');
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Logout
  Future<void> logout() async {
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }
  
  // Check if user is logged in (من SharedPreferences)
  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // هنا تقرأ من SharedPreferences
      // final prefs = await SharedPreferences.getInstance();
      // final userJson = prefs.getString('user');
      
      await Future.delayed(const Duration(seconds: 1));
      
      // مثال فقط
      // if (userJson != null) {
      //   _currentUser = User.fromJson(jsonDecode(userJson));
      // }
    } catch (e) {
      _errorMessage = e.toString();
    }
    
    _isLoading = false;
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
