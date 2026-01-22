import 'package:flutter_test/flutter_test.dart';
import 'package:hr_pro_app/Screen/auth_models.dart';

void main() {
  group('User Model Tests', () {
    test('User.fromJson creates user correctly', () {
      final json = {
        'id': '123',
        'name': 'John Doe',
        'email': 'john@example.com',
        'role': 'admin',
        'employee_id': 'EMP001',
        'department': 'IT',
        'avatar_url': 'https://example.com/avatar.png',
        'phone': '+1234567890',
        'position': 'Manager',
      };

      final user = User.fromJson(json);

      expect(user.id, '123');
      expect(user.name, 'John Doe');
      expect(user.email, 'john@example.com');
      expect(user.role, 'admin');
      expect(user.employeeId, 'EMP001');
      expect(user.department, 'IT');
      expect(user.avatarUrl, 'https://example.com/avatar.png');
      expect(user.phone, '+1234567890');
      expect(user.position, 'Manager');
    });

    test('User.fromJson handles null optional fields', () {
      final json = {
        'id': '123',
        'name': 'John Doe',
        'email': 'john@example.com',
        'role': 'employee',
      };

      final user = User.fromJson(json);

      expect(user.id, '123');
      expect(user.name, 'John Doe');
      expect(user.email, 'john@example.com');
      expect(user.role, 'employee');
      expect(user.employeeId, isNull);
      expect(user.department, isNull);
      expect(user.avatarUrl, isNull);
      expect(user.phone, isNull);
      expect(user.position, isNull);
    });

    test('User.toJson converts user to map correctly', () {
      final user = User(
        id: '123',
        name: 'John Doe',
        email: 'john@example.com',
        role: 'admin',
        employeeId: 'EMP001',
        department: 'IT',
        avatarUrl: 'https://example.com/avatar.png',
        phone: '+1234567890',
        position: 'Manager',
      );

      final json = user.toJson();

      expect(json['id'], '123');
      expect(json['name'], 'John Doe');
      expect(json['email'], 'john@example.com');
      expect(json['role'], 'admin');
      expect(json['employee_id'], 'EMP001');
      expect(json['department'], 'IT');
      expect(json['avatar_url'], 'https://example.com/avatar.png');
      expect(json['phone'], '+1234567890');
      expect(json['position'], 'Manager');
    });

    test('User.isAdmin returns true for admin role', () {
      final user = User(
        id: '123',
        name: 'Admin User',
        email: 'admin@example.com',
        role: 'admin',
      );

      expect(user.isAdmin, true);
      expect(user.isEmployee, false);
    });

    test('User.isEmployee returns true for employee role', () {
      final user = User(
        id: '123',
        name: 'Employee User',
        email: 'employee@example.com',
        role: 'employee',
      );

      expect(user.isEmployee, true);
      expect(user.isAdmin, false);
    });

    test('User.initials returns correct initials', () {
      final user = User(
        id: '123',
        name: 'John Doe',
        email: 'john@example.com',
        role: 'employee',
      );

      expect(user.initials, 'JD');
    });

    test('User.initials returns first two chars for single name', () {
      final user = User(
        id: '123',
        name: 'John',
        email: 'john@example.com',
        role: 'employee',
      );

      // For single names with 2+ chars, returns first 2 characters
      expect(user.initials, 'JO');
    });

    test('User.initials returns single char for single char name', () {
      final user = User(
        id: '123',
        name: 'J',
        email: 'j@example.com',
        role: 'employee',
      );

      expect(user.initials, 'J');
    });

    test('User.copyWith creates a copy with updated fields', () {
      final user = User(
        id: '123',
        name: 'John Doe',
        email: 'john@example.com',
        role: 'employee',
      );

      final updatedUser = user.copyWith(
        name: 'Jane Doe',
        role: 'admin',
      );

      expect(updatedUser.id, '123');
      expect(updatedUser.name, 'Jane Doe');
      expect(updatedUser.email, 'john@example.com');
      expect(updatedUser.role, 'admin');
    });
  });

  group('RoleChecker Tests', () {
    test('canManageEmployees returns true for admin', () {
      expect(RoleChecker.canManageEmployees('admin'), true);
    });

    test('canManageEmployees returns false for employee', () {
      expect(RoleChecker.canManageEmployees('employee'), false);
    });

    test('canViewAllReports returns true for admin', () {
      expect(RoleChecker.canViewAllReports('admin'), true);
    });

    test('canViewAllReports returns false for employee', () {
      expect(RoleChecker.canViewAllReports('employee'), false);
    });

    test('canEditShifts returns true for admin', () {
      expect(RoleChecker.canEditShifts('admin'), true);
    });

    test('canEditShifts returns false for employee', () {
      expect(RoleChecker.canEditShifts('employee'), false);
    });

    test('canApproveLeaves returns true for admin', () {
      expect(RoleChecker.canApproveLeaves('admin'), true);
    });

    test('canApproveLeaves returns false for employee', () {
      expect(RoleChecker.canApproveLeaves('employee'), false);
    });

    test('canCheckInOut returns true for employee', () {
      expect(RoleChecker.canCheckInOut('employee'), true);
    });

    test('canCheckInOut returns false for admin', () {
      // Only employees can check in/out per the business logic
      expect(RoleChecker.canCheckInOut('admin'), false);
    });

    test('canRequestLeave returns true for employee', () {
      expect(RoleChecker.canRequestLeave('employee'), true);
    });

    test('canRequestLeave returns true for admin', () {
      expect(RoleChecker.canRequestLeave('admin'), true);
    });
  });
}
