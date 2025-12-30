import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_models.dart';
import '../theme_provider.dart';
import '../services/api_service.dart';
import 'attendance_screen.dart';
import 'attendance_approvals_page.dart';
import 'employees_page.dart';
import 'reports_page.dart';
import 'profile_page.dart';
import 'leaves_page.dart';
import 'shifts_page.dart';
import 'login_screen_updated.dart';

// ═══════════════════════════════════════════════════════════════
// Dashboard Screen - محسّن مع Theme Support و API Integration
// ═══════════════════════════════════════════════════════════════

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // ═══════════════════════════════════════════════════════════════
  // State Variables
  // ═══════════════════════════════════════════════════════════════

  // Dashboard Stats
  Map<String, dynamic> dashboardStats = {};
  bool isLoadingStats = true;

  // Weekly Attendance Data
  List<Map<String, dynamic>> weeklyAttendance = [];
  bool isLoadingWeekly = true;

  // Attendance Approvals
  Map<String, dynamic> approvalsData = {};
  List<dynamic> recentApprovals = [];
  bool isLoadingApprovals = true;

  // Working Today
  List<dynamic> workingToday = [];
  bool isLoadingWorking = true;

  // Employee Info (for employee view)
  Map<String, dynamic> employeeInfo = {};
  Map<String, dynamic> employeeStats = {};
  bool isLoadingEmployeeInfo = true;

  // ═══════════════════════════════════════════════════════════════
  // Lifecycle Methods
  // ═══════════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isAdmin = authProvider.isAdmin;

    if (isAdmin) {
      await Future.wait([
        _loadDashboardStats(),
        _loadWeeklyAttendance(),
        _loadAttendanceApprovals(),
        _loadWorkingToday(),
      ]);
    } else {
      await Future.wait([_loadEmployeeStats(), _loadEmployeeInfo()]);
    }
  }

  Future<void> _loadDashboardStats() async {
    final response = await ApiService.getDashboardStats();
    if (mounted) {
      setState(() {
        if (response.success && response.data != null) {
          dashboardStats = response.data;
        }
        isLoadingStats = false;
      });
    }
  }

  Future<void> _loadWeeklyAttendance() async {
    final response = await ApiService.getAttendanceReport(
      startDate: DateTime.now()
          .subtract(const Duration(days: 7))
          .toIso8601String()
          .split('T')[0],
      endDate: DateTime.now().toIso8601String().split('T')[0],
    );
    if (mounted) {
      setState(() {
        if (response.success && response.data != null) {
          weeklyAttendance = List<Map<String, dynamic>>.from(
            response.data['weekly'] ?? [],
          );
        }
        isLoadingWeekly = false;
      });
    }
  }

  Future<void> _loadAttendanceApprovals() async {
    final response = await ApiService.getAllAttendance(page: 1);
    if (mounted) {
      setState(() {
        if (response.success && response.data != null) {
          approvalsData = {
            'pending': response.data['pending_count'] ?? 0,
            'approved': response.data['approved_count'] ?? 0,
            'rejected': response.data['rejected_count'] ?? 0,
          };
          recentApprovals = response.data['recent'] ?? [];
        }
        isLoadingApprovals = false;
      });
    }
  }

  Future<void> _loadWorkingToday() async {
    final response = await ApiService.getAllAttendance(
      startDate: DateTime.now().toIso8601String().split('T')[0],
      endDate: DateTime.now().toIso8601String().split('T')[0],
    );
    if (mounted) {
      setState(() {
        if (response.success && response.data != null) {
          workingToday = response.data['data'] ?? [];
        }
        isLoadingWorking = false;
      });
    }
  }

  Future<void> _loadEmployeeStats() async {
    final response = await ApiService.getMyAttendance();
    if (mounted) {
      setState(() {
        if (response.success && response.data != null) {
          employeeStats = response.data['stats'] ?? {};
        }
        isLoadingStats = false;
      });
    }
  }

  Future<void> _loadEmployeeInfo() async {
    final response = await ApiService.getTodayAttendanceStatus();
    if (mounted) {
      setState(() {
        if (response.success && response.data != null) {
          employeeInfo = response.data;
        }
        isLoadingEmployeeInfo = false;
      });
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // Build Method
  // ═══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin = authProvider.isAdmin;
    final userName = authProvider.currentUser?.name ?? 'User';
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 900;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(userName, !isWideScreen),
      drawer: !isWideScreen
          ? _buildDrawer(isAdmin, authProvider, userName)
          : null,
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: Row(
          children: [
            if (isWideScreen)
              SizedBox(
                width: 260,
                child: _buildPersistentDrawer(isAdmin, authProvider, userName),
              ),
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeCard(userName, isAdmin),
                    const SizedBox(height: 24),
                    if (isAdmin) ...[
                      _buildAdminStats(),
                      const SizedBox(height: 24),
                      _buildAdminCharts(),
                      const SizedBox(height: 24),
                      _buildAttendanceApprovalsCard(),
                      const SizedBox(height: 24),
                      _buildShiftCoverCard(),
                    ] else ...[
                      _buildEmployeeQuickActions(),
                      const SizedBox(height: 24),
                      _buildEmployeeStats(),
                      const SizedBox(height: 24),
                      _buildEmployeeInfoCard(),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: null,
    );
  }

  PreferredSizeWidget _buildAppBar(String userName, bool showMenuButton) {
    return AppBar(
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      elevation: 0,
      leading: showMenuButton ? null : const SizedBox.shrink(),
      automaticallyImplyLeading: showMenuButton,
      title: Text(
        'HR Pro Dashboard',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      actions: [
        Builder(
          builder: (context) {
            final themeProvider = context.watch<ThemeProvider>();
            return IconButton(
              icon: Icon(
                themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                size: 24,
                color: Theme.of(context).iconTheme.color,
              ),
              onPressed: () => context.read<ThemeProvider>().toggleTheme(),
              tooltip: themeProvider.isDarkMode ? 'Light Mode' : 'Dark Mode',
            );
          },
        ),
        Stack(
          children: [
            IconButton(
              icon: Icon(
                Icons.notifications_outlined,
                size: 24,
                color: Theme.of(context).iconTheme.color,
              ),
              onPressed: () {},
            ),
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
        IconButton(
          icon: Icon(
            Icons.settings_outlined,
            size: 24,
            color: Theme.of(context).iconTheme.color,
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildPersistentDrawer(
    bool isAdmin,
    AuthProvider authProvider,
    String userName,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          right: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    authProvider.currentUser?.initials ?? 'AA',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  userName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isAdmin ? 'Administrator' : 'Employee',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
          Divider(color: Theme.of(context).dividerColor, height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildDrawerItem(
                  icon: Icons.dashboard,
                  title: 'Dashboard',
                  isActive: true,
                  onTap: () {},
                ),
                _buildDrawerItem(
                  icon: Icons.access_time,
                  title: 'Attendance',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AttendanceScreen()),
                  ),
                ),
                if (isAdmin)
                  _buildDrawerItem(
                    icon: Icons.pending_actions,
                    title: 'Attendance Approvals',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AttendanceApprovalsPage(),
                      ),
                    ),
                  ),
                if (isAdmin)
                  _buildDrawerItem(
                    icon: Icons.people,
                    title: 'Employees',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EmployeesPage()),
                    ),
                  ),
                _buildDrawerItem(
                  icon: Icons.schedule,
                  title: isAdmin ? 'Shifts' : 'My Schedule',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ShiftsPage()),
                  ),
                ),
                _buildDrawerItem(
                  icon: Icons.beach_access,
                  title: isAdmin ? 'Leave Requests' : 'My Leaves',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LeavesPage()),
                  ),
                ),
                _buildDrawerItem(
                  icon: Icons.bar_chart,
                  title: 'Reports',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ReportsPage()),
                  ),
                ),
                const SizedBox(height: 8),
                Divider(color: Theme.of(context).dividerColor, height: 1),
                const SizedBox(height: 8),
                _buildDrawerItem(
                  icon: Icons.person,
                  title: 'Profile',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfilePage()),
                  ),
                ),
                _buildDrawerItem(
                  icon: Icons.settings,
                  title: 'Settings',
                  onTap: () {},
                ),
                _buildDrawerItem(
                  icon: Icons.logout,
                  title: 'Logout',
                  isLogout: true,
                  onTap: () => _confirmLogout(authProvider),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(
    bool isAdmin,
    AuthProvider authProvider,
    String userName,
  ) {
    return Drawer(
      backgroundColor: Theme.of(context).cardColor,
      child: _buildPersistentDrawer(isAdmin, authProvider, userName),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    bool isActive = false,
    bool isLogout = false,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isLogout
            ? Colors.red
            : isActive
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).iconTheme.color,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isLogout
              ? Colors.red
              : isActive
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isActive,
      selectedTileColor: Theme.of(
        context,
      ).colorScheme.primary.withValues(alpha: 26),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      onTap: onTap,
    );
  }

  Widget _buildWelcomeCard(String userName, bool isAdmin) {
    final hour = DateTime.now().hour;
    String greeting;
    String emoji;

    if (hour < 12) {
      greeting = 'Good Morning';
      emoji = '👋';
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
      emoji = '☀️';
    } else {
      greeting = 'Good Evening';
      emoji = '🌙';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 77),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$greeting! $emoji',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isAdmin
                ? 'Ready to manage your team effectively?'
                : 'Ready to make today productive?',
            style: const TextStyle(fontSize: 16, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminStats() {
    if (isLoadingStats) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount;
        double childAspectRatio;

        if (constraints.maxWidth < 400) {
          crossAxisCount = 2;
          childAspectRatio = 1.0;
        } else if (constraints.maxWidth < 600) {
          crossAxisCount = 2;
          childAspectRatio = 1.15;
        } else if (constraints.maxWidth < 900) {
          crossAxisCount = 2;
          childAspectRatio = 1.3;
        } else if (constraints.maxWidth < 1200) {
          crossAxisCount = 4;
          childAspectRatio = 1.25;
        } else {
          crossAxisCount = 4;
          childAspectRatio = 1.35;
        }

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: constraints.maxWidth < 600 ? 12 : 16,
          crossAxisSpacing: constraints.maxWidth < 600 ? 12 : 16,
          childAspectRatio: childAspectRatio,
          children: [
            _buildStatCard(
              icon: Icons.people,
              number: '${dashboardStats['total_employees'] ?? 0}',
              label: 'Total Employees',
              trend: '+${dashboardStats['new_employees_this_month'] ?? 0}',
              color: Theme.of(context).colorScheme.primary,
            ),
            _buildStatCard(
              icon: Icons.check_circle,
              number: '${dashboardStats['present_today'] ?? 0}',
              label: 'Present Today',
              trend: '+${dashboardStats['present_change'] ?? 0}',
              color: Colors.green,
            ),
            _buildStatCard(
              icon: Icons.cancel,
              number: '${dashboardStats['absent_today'] ?? 0}',
              label: 'Absent',
              trend: '${dashboardStats['absent_change'] ?? 0}',
              color: Colors.red,
            ),
            _buildStatCard(
              icon: Icons.schedule,
              number: '${dashboardStats['late_arrivals'] ?? 0}',
              label: 'Late Arrivals',
              trend: '${dashboardStats['late_change'] ?? 0}',
              color: Colors.orange,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String number,
    required String label,
    required String trend,
    required Color color,
  }) {
    final isPositive = !trend.startsWith('-');
    final trendColor = isPositive ? Colors.green : Colors.red;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallCard = constraints.maxWidth < 160;

        return Container(
          padding: EdgeInsets.all(isSmallCard ? 12 : 16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: color, size: isSmallCard ? 22 : 28),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallCard ? 6 : 8,
                      vertical: isSmallCard ? 3 : 4,
                    ),
                    decoration: BoxDecoration(
                      color: trendColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      trend,
                      style: TextStyle(
                        fontSize: isSmallCard ? 9 : 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                number,
                style: TextStyle(
                  fontSize: isSmallCard ? 28 : 36,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(height: isSmallCard ? 2 : 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: isSmallCard ? 11 : 13,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAdminCharts() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly Attendance Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: isLoadingWeekly
                ? const Center(child: CircularProgressIndicator())
                : weeklyAttendance.isEmpty
                ? const Center(child: Text('No data available'))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: weeklyAttendance.map((day) {
                      return _buildSimpleBar(
                        day['day'] ?? '',
                        (day['percentage'] ?? 0.0).toDouble() / 100,
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleBar(String day, double value) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              height: 160 * value,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              day,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeQuickActions() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.1,
          children: [
            _buildActionCard(
              icon: Icons.login,
              title: 'Check In',
              color: Colors.green,
              onTap: () async {
                final response = await ApiService.checkIn();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        response.success
                            ? 'Checked in successfully!'
                            : response.message ?? 'Failed',
                      ),
                      backgroundColor: response.success
                          ? Colors.green
                          : Colors.red,
                    ),
                  );
                  if (response.success) _loadDashboardData();
                }
              },
            ),
            _buildActionCard(
              icon: Icons.calendar_today,
              title: 'View Schedule',
              color: Theme.of(context).colorScheme.primary,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ShiftsPage()),
              ),
            ),
            _buildActionCard(
              icon: Icons.card_travel,
              title: 'Request Leave',
              color: Colors.orange,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LeavesPage()),
              ),
            ),
            _buildActionCard(
              icon: Icons.person,
              title: 'Edit Profile',
              color: Colors.purple,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withValues(alpha: 179)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeStats() {
    if (isLoadingStats) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.3,
          children: [
            _buildStatCard(
              icon: Icons.check_circle,
              number: '${employeeStats['days_present'] ?? 0}',
              label: 'Days Present',
              trend: '+${employeeStats['present_change'] ?? 0}',
              color: Colors.green,
            ),
            _buildStatCard(
              icon: Icons.schedule,
              number: '${employeeStats['working_hours'] ?? 0}h',
              label: 'Working Hours',
              trend: '+${employeeStats['hours_change'] ?? 0}h',
              color: Theme.of(context).colorScheme.primary,
            ),
            _buildStatCard(
              icon: Icons.percent,
              number: '${employeeStats['attendance_rate'] ?? 0}%',
              label: 'Attendance Rate',
              trend: '+${employeeStats['rate_change'] ?? 0}%',
              color: Colors.purple,
            ),
            _buildStatCard(
              icon: Icons.beach_access,
              number: '${employeeStats['remaining_leave'] ?? 0}',
              label: 'Remaining Leave',
              trend: '${employeeStats['leave_change'] ?? 0}',
              color: Colors.orange,
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmployeeInfoCard() {
    if (isLoadingEmployeeInfo) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today\'s Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.work,
            'Current Shift',
            employeeInfo['shift_name'] ?? 'N/A',
          ),
          _buildInfoRow(
            Icons.schedule,
            'Working Hours',
            employeeInfo['working_hours'] ?? 'N/A',
          ),
          _buildInfoRow(
            Icons.location_on,
            'Status',
            employeeInfo['status'] ?? 'N/A',
          ),
          _buildInfoRow(
            Icons.access_time,
            'Last Check-in',
            employeeInfo['check_in_time'] ?? 'N/A',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceApprovalsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.pending_actions,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attendance Approvals',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Review employee attendance records',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (isLoadingApprovals)
            const Center(child: CircularProgressIndicator())
          else
            Row(
              children: [
                Expanded(
                  child: _buildApprovalStat(
                    '${approvalsData['pending'] ?? 0}',
                    'Pending',
                    Icons.schedule,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildApprovalStat(
                    '${approvalsData['approved'] ?? 0}',
                    'Approved',
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildApprovalStat(
                    '${approvalsData['rejected'] ?? 0}',
                    'Rejected',
                    Icons.cancel,
                    Colors.red,
                  ),
                ),
              ],
            ),

          const SizedBox(height: 20),

          Text(
            'Recent Requests',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),

          if (isLoadingApprovals)
            const Center(child: CircularProgressIndicator())
          else if (recentApprovals.isEmpty)
            const Text('No recent requests')
          else
            ...recentApprovals.take(3).map((approval) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Text(
                        (approval['employee_name'] ?? 'U')
                            .substring(0, 1)
                            .toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            approval['employee_name'] ?? 'Unknown',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            '${approval['check_in'] ?? ''} - ${approval['check_out'] ?? ''}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(
                                context,
                              ).textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(approval['status']),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        (approval['status'] ?? 'PENDING').toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AttendanceApprovalsPage(),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: Theme.of(context).colorScheme.primary),
              ),
              child: Text(
                'View All Approvals',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  Widget _buildShiftCoverCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.purple, Colors.deepPurple],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.swap_horiz,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Today\'s Working Employees',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Employees scheduled to work today',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Text(
            'Working Today',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),

          if (isLoadingWorking)
            const Center(child: CircularProgressIndicator())
          else if (workingToday.isEmpty)
            const Text('No employees working today')
          else
            ...workingToday.take(5).map((employee) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.purple,
                      child: Text(
                        (employee['employee_name'] ?? 'U')
                            .substring(0, 1)
                            .toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            employee['employee_name'] ?? 'Unknown',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            employee['shift_name'] ?? 'N/A',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ShiftsPage()),
                );
              },
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: const Text('View All Shifts'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.purple,
                side: const BorderSide(color: Colors.purple),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalStat(
    String number,
    String label,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 6),
            Text(
              number,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
      ],
    );
  }

  void _confirmLogout(AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(
          'Logout',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await authProvider.logout();
              await ApiService.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
