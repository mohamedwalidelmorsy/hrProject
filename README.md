# HR Pro - Employee Management System

![Flutter](https://img.shields.io/badge/Flutter-3.10.4+-02569B?style=for-the-badge&logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?style=for-the-badge&logo=dart)
![Provider](https://img.shields.io/badge/Provider-6.1.5-4CAF50?style=for-the-badge)

A comprehensive HR Management System built with Flutter for Android, iOS, Web, and Desktop.

---

## Table of Contents
1. [Features](#features)
2. [Tech Stack](#tech-stack)
3. [Project Structure](#project-structure)
4. [Getting Started](#getting-started)
5. [API Reference](#api-reference)
6. [Data Models](#data-models)
7. [State Management](#state-management)
8. [Screens & Access Control](#screens--access-control)
9. [Demo Mode](#demo-mode)
10. [Testing](#testing)
11. [Configuration](#configuration)

---

## Features

### Authentication
- JWT token-based authentication
- Login with email/password
- User registration
- Password reset via email
- Remember me functionality
- Session management

### Dashboard
- **Admin**: Company statistics, attendance charts, pending approvals
- **Employee**: Personal stats, quick check-in/out, leave balance

### Attendance Management
- Check-in/Check-out with timestamp
- Location tracking (latitude/longitude)
- Attendance history with filters
- Manual attendance marking (Admin)
- Approval workflow

### Employee Management (Admin)
- Employee directory with search
- Filter by department/status
- CRUD operations
- Pagination support

### Leave Management
- Submit leave requests
- Multiple leave types (Annual, Sick, Emergency, Casual)
- Approval workflow with admin notes
- Status tracking (Pending/Approved/Rejected)

### Shift Management
- Create and manage shifts
- Assign employees to shifts
- Daily/Weekly/Monthly views

### Reports & Analytics
- Attendance reports
- Employee reports
- Export to PDF/Excel

### Settings
- Profile management
- Password change
- Dark/Light theme toggle

---

## Tech Stack

| Technology | Version | Purpose |
|------------|---------|---------|
| Flutter | 3.10.4+ | UI Framework |
| Dart | 3.0+ | Programming Language |
| Provider | 6.1.5+ | State Management |
| HTTP | 1.6.0 | API Communication |
| SharedPreferences | 2.2.3 | Local Storage |

---

## Project Structure

```
lib/
├── main.dart                              # App entry point, providers setup
├── theme_provider.dart                    # Dark/Light theme management
│
├── services/
│   ├── api_service.dart                   # REST API client (50+ endpoints)
│   └── demo_data.dart                     # Demo login accounts
│
└── Screen/
    ├── auth_models.dart                   # User model, AuthProvider, RoleChecker
    ├── login_screen_updated.dart          # Login page
    ├── create_account_page.dart           # Registration page
    ├── dashboard_screen.dart              # Main dashboard (role-based)
    ├── attendance_screen.dart             # Attendance management
    ├── attendance_approvals_page.dart     # Attendance approvals (Admin)
    ├── employees_page.dart                # Employee directory (Admin)
    ├── shifts_page.dart                   # Shift management
    ├── leaves_page.dart                   # Leave requests
    ├── reports_page.dart                  # Reports & analytics
    ├── profile_page.dart                  # User profile
    └── schedule_card_widget.dart          # Reusable shift widget

test/
└── unit/
    ├── api_response_test.dart             # API response tests
    ├── user_model_test.dart               # User model tests
    └── theme_provider_test.dart           # Theme provider tests
```

---

## Getting Started

### Prerequisites
- Flutter SDK 3.10.4+
- Dart SDK 3.0+
- Android Studio / VS Code
- Git

### Installation

```bash
# Clone repository
git clone https://github.com/your-username/hr_pro_app.git
cd hr_pro_app

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Build Commands

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release

# Web
flutter build web --release

# Windows
flutter build windows --release
```

---

## API Reference

**Base URL:** Configure in `lib/services/api_service.dart`
```dart
static const String baseUrl = 'https://your-api-domain.com/api';
```

**Authentication:** Bearer token in `Authorization` header
**Timeout:** 30 seconds

---

### Authentication Endpoints

| Method | Endpoint | Description | Request Body |
|--------|----------|-------------|--------------|
| POST | `/auth/login` | User login | `{email, password}` |
| POST | `/auth/register` | Registration | `{name, email, password, password_confirmation, phone?}` |
| POST | `/auth/logout` | Logout | - |
| POST | `/auth/forgot-password` | Reset request | `{email}` |
| POST | `/auth/reset-password` | Reset password | `{token, email, password, password_confirmation}` |
| GET | `/auth/me` | Current user | - |
| PUT | `/auth/profile` | Update profile | `{name?, email?, phone?, avatar?}` |
| PUT | `/auth/change-password` | Change password | `{current_password, new_password, new_password_confirmation}` |

---

### Dashboard Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/dashboard/stats` | Statistics |
| GET | `/dashboard/activities?limit=10` | Recent activities |
| GET | `/dashboard/notifications?page=1` | Notifications |
| PUT | `/dashboard/notifications/{id}/read` | Mark as read |

---

### Employee Endpoints

| Method | Endpoint | Description | Query Params |
|--------|----------|-------------|--------------|
| GET | `/employees` | List employees | `page, per_page, search, department, status` |
| GET | `/employees/{id}` | Single employee | - |
| POST | `/employees` | Create employee | - |
| PUT | `/employees/{id}` | Update employee | - |
| DELETE | `/employees/{id}` | Delete employee | - |
| GET | `/employees/departments` | List departments | - |

**Create/Update Employee Body:**
```json
{
  "name": "string",
  "email": "string",
  "phone": "string",
  "department": "string",
  "position": "string",
  "hire_date": "YYYY-MM-DD",
  "salary": "float (optional)",
  "avatar": "string (optional)"
}
```

---

### Attendance Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/attendance/check-in` | Check in |
| POST | `/attendance/check-out` | Check out |
| GET | `/attendance/my` | My attendance |
| GET | `/attendance` | All attendance (Admin) |
| GET | `/attendance/today` | Today's status |
| POST | `/attendance/mark` | Manual mark (Admin) |
| PUT | `/attendance/{id}` | Update record |

**Check In/Out Body:**
```json
{
  "timestamp": "ISO 8601 datetime",
  "notes": "string (optional)",
  "latitude": "float (optional)",
  "longitude": "float (optional)"
}
```

**Query Params for `/attendance`:**
- `page` - Page number
- `per_page` - Items per page
- `start_date` - Filter start (YYYY-MM-DD)
- `end_date` - Filter end (YYYY-MM-DD)
- `employee_id` - Filter by employee
- `search` - Search term
- `status` - Filter by status
- `department` - Filter by department

**Manual Mark Body (Admin):**
```json
{
  "employee_id": "string",
  "check_in": "HH:MM:SS (optional)",
  "check_out": "HH:MM:SS (optional)",
  "date": "YYYY-MM-DD (optional)",
  "status": "string (optional)",
  "notes": "string (optional)"
}
```

---

### Shift Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/shifts?page=1` | List shifts |
| GET | `/shifts/{id}` | Single shift |
| POST | `/shifts` | Create shift |
| PUT | `/shifts/{id}` | Update shift |
| DELETE | `/shifts/{id}` | Delete shift |
| POST | `/shifts/{id}/assign` | Assign employee |
| GET | `/shifts/my/current` | My current shift |

**Create/Update Shift Body:**
```json
{
  "name": "string",
  "start_time": "HH:MM",
  "end_time": "HH:MM",
  "description": "string (optional)",
  "work_days": ["monday", "tuesday", "..."]
}
```

**Assign Shift Body:**
```json
{
  "employee_id": "integer",
  "start_date": "YYYY-MM-DD",
  "end_date": "YYYY-MM-DD (optional)"
}
```

---

### Leave Request Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/leave-requests?page=1&status=` | List requests |
| POST | `/leave-requests` | Create request |
| PUT | `/leave-requests/{id}/status` | Approve/Reject (Admin) |

**Create Leave Request Body:**
```json
{
  "type": "annual | sick | emergency | casual | unpaid",
  "start_date": "YYYY-MM-DD",
  "end_date": "YYYY-MM-DD",
  "reason": "string (optional)"
}
```

**Update Status Body (Admin):**
```json
{
  "status": "approved | rejected",
  "admin_notes": "string (optional)"
}
```

---

### Report Endpoints

| Method | Endpoint | Query Params |
|--------|----------|--------------|
| GET | `/reports/attendance` | `start_date, end_date, department_id?, employee_id?` |
| GET | `/reports/employees` | `department?, status?` |
| GET | `/reports/shifts` | `start_date, end_date` |
| GET | `/reports/monthly` | `year, month` |
| GET | `/reports/export/pdf` | `type, start_date, end_date` |
| GET | `/reports/export/excel` | `type, start_date, end_date` |

---

## Data Models

### User Model
```json
{
  "id": "string",
  "name": "string",
  "email": "string",
  "role": "admin | employee",
  "employee_id": "string | null",
  "department": "string | null",
  "position": "string | null",
  "phone": "string | null",
  "avatar_url": "string | null"
}
```

### Employee Model
```json
{
  "id": "integer",
  "name": "string",
  "email": "string",
  "phone": "string",
  "department": "string",
  "position": "string",
  "hire_date": "YYYY-MM-DD",
  "salary": "float | null",
  "status": "Active | Inactive | On Leave"
}
```

### Attendance Model
```json
{
  "id": "integer",
  "employee_id": "integer",
  "employee_name": "string",
  "date": "YYYY-MM-DD",
  "check_in": "HH:MM:SS | null",
  "check_out": "HH:MM:SS | null",
  "status": "Present | Absent | Late | Early",
  "notes": "string | null",
  "latitude": "float | null",
  "longitude": "float | null"
}
```

### Leave Request Model
```json
{
  "id": "integer",
  "employee_id": "integer",
  "employee_name": "string",
  "type": "annual | sick | emergency | casual | unpaid",
  "start_date": "YYYY-MM-DD",
  "end_date": "YYYY-MM-DD",
  "reason": "string",
  "status": "pending | approved | rejected",
  "admin_notes": "string | null",
  "created_at": "ISO 8601 datetime"
}
```

### Shift Model
```json
{
  "id": "integer",
  "name": "string",
  "start_time": "HH:MM",
  "end_time": "HH:MM",
  "description": "string | null",
  "work_days": ["monday", "tuesday", "..."],
  "employees_assigned": "integer"
}
```

### Dashboard Stats Model
```json
{
  "total_employees": "integer",
  "new_employees_this_month": "integer",
  "present_today": "integer",
  "absent_today": "integer",
  "late_arrivals": "integer",
  "pending_leaves": "integer",
  "pending_approvals": "integer"
}
```

---

## API Response Format

### Success Response
```json
{
  "success": true,
  "data": { ... },
  "message": "Success message"
}
```

### Error Response
```json
{
  "success": false,
  "message": "Error message",
  "errors": {
    "field_name": ["validation error 1", "validation error 2"]
  }
}
```

### Paginated Response
```json
{
  "success": true,
  "data": [...],
  "meta": {
    "current_page": 1,
    "last_page": 10,
    "per_page": 20,
    "total": 200
  }
}
```

### HTTP Status Codes

| Code | Description | Action |
|------|-------------|--------|
| 200 | Success | - |
| 201 | Created | - |
| 400 | Bad Request | Check request format |
| 401 | Unauthorized | Token expired/invalid, re-login |
| 403 | Forbidden | No permission |
| 404 | Not Found | Resource doesn't exist |
| 422 | Validation Error | Check `errors` field |
| 500 | Server Error | Retry later |

---

## State Management

### Provider Architecture

```
MultiProvider (main.dart)
├── AuthProvider      # Authentication state
└── ThemeProvider     # Theme state
```

### AuthProvider (`lib/Screen/auth_models.dart`)
- Manages user login/logout state
- Stores token in SharedPreferences
- Methods:
  - `login(email, password)` - Authenticate user
  - `logout()` - Clear session
  - `updateProfile(data)` - Update user info
  - `changePassword(current, new)` - Change password

### ThemeProvider (`lib/theme_provider.dart`)
- Manages dark/light theme
- Persists preference in SharedPreferences
- Methods:
  - `toggleTheme()` - Switch theme
  - `setTheme(bool isDark)` - Set specific theme

---

## Screens & Access Control

| Screen | Admin | Employee |
|--------|-------|----------|
| Login | Yes | Yes |
| Dashboard | Full Stats | Personal Stats |
| Employees | CRUD | No Access |
| Attendance | All Records | Personal Only |
| Attendance Approvals | Yes | No Access |
| Shifts | Manage | View Only |
| Leaves | Approve/Reject | Request Only |
| Reports | All Reports | Personal Only |
| Profile | Yes | Yes |

### Role Values
- `admin` - Full system access
- `employee` - Limited access (personal data only)

---

## Demo Mode

Demo Mode allows testing without a real backend (login only).

### Enable/Disable
```dart
// lib/services/api_service.dart (line 26)
static const bool isDemoMode = true;  // true = demo login, false = real API
```

### Test Accounts

| Role | Email | Password |
|------|-------|----------|
| Admin | admin@hrpro.com | admin123 |
| Employee | employee@hrpro.com | emp123 |

> **Note:** Demo mode only works for login. Other API calls require a real backend.

---

## Testing

### Run Tests
```bash
# All tests
flutter test

# With coverage
flutter test --coverage

# Specific file
flutter test test/unit/user_model_test.dart

# Code analysis
flutter analyze
```

### Test Files
| File | Coverage |
|------|----------|
| `api_response_test.dart` | API response handling |
| `user_model_test.dart` | User model & RoleChecker |
| `theme_provider_test.dart` | Theme management |

---

## Configuration

### API URL
```dart
// lib/services/api_service.dart (line 19)
static const String baseUrl = 'https://your-api-domain.com/api';
```

### Request Timeout
```dart
// lib/services/api_service.dart (line 22)
static const int timeoutSeconds = 30;
```

### Theme Colors
```dart
// lib/theme_provider.dart
// Dark Theme:  Primary #3B82F6, Background #0F172A
// Light Theme: Primary #2563EB, Background #F1F5F9
```

---

## Responsive Breakpoints

| Device | Width | Layout |
|--------|-------|--------|
| Mobile | < 600px | Single column, drawer navigation |
| Tablet | 600-900px | 2 columns |
| Desktop | > 1200px | 4 columns, sidebar navigation |

---

## License

MIT License

---

## Support

For issues and feature requests, please create an issue in the repository.
