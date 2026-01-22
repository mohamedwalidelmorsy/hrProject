/// ============================================================================
/// HR Pro - Demo Login Data
/// ============================================================================
/// Demo accounts for testing login without backend
/// ============================================================================

class DemoData {
  // Demo Users for Login Only
  static const Map<String, Map<String, dynamic>> users = {
    'admin@hrpro.com': {
      'id': '1',
      'name': 'System Admin',
      'email': 'admin@hrpro.com',
      'password': 'admin123',
      'role': 'admin',
      'department': 'Administration',
      'position': 'HR Manager',
      'phone': '+1234567890',
      'employee_id': 'EMP001',
    },
    'employee@hrpro.com': {
      'id': '2',
      'name': 'John Smith',
      'email': 'employee@hrpro.com',
      'password': 'emp123',
      'role': 'employee',
      'department': 'IT',
      'position': 'Software Developer',
      'phone': '+1234567891',
      'employee_id': 'EMP002',
    },
  };
}
