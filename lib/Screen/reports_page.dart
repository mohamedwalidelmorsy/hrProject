import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_models.dart';
import '../services/api_service.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  String selectedPeriod = 'This Month';
  final List<String> periods = [
    'Today',
    'This Week',
    'This Month',
    'This Year',
    'Custom',
  ];
  final Map<String, IconData> periodIcons = {
    'Today': Icons.today,
    'This Week': Icons.calendar_view_week,
    'This Month': Icons.calendar_month,
    'This Year': Icons.calendar_today,
    'Custom': Icons.date_range,
  };

  // State Variables
  Map<String, dynamic> adminStats = {};
  Map<String, dynamic> employeeStats = {};
  List<Map<String, dynamic>> weeklyAttendance = [];
  List<Map<String, dynamic>> departmentPerformance = [];
  List<Map<String, dynamic>> detailedReport = [];
  List<Map<String, dynamic>> myWeeklyAttendance = [];
  Map<String, dynamic> performanceMetrics = {};

  bool isLoadingStats = true;
  bool isLoadingCharts = true;
  bool isLoadingReport = true;
  bool isExporting = false;
  String? errorMessage;

  // Date range for custom period
  DateTime startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    await Future.wait([_loadStats(), _loadChartData(), _loadDetailedReport()]);
  }

  Future<void> _loadStats() async {
    setState(() => isLoadingStats = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isAdmin = authProvider.isAdmin;

    if (isAdmin) {
      final response = await ApiService.getDashboardStats();
      if (mounted) {
        setState(() {
          if (response.success && response.data != null) {
            adminStats = response.data;
          }
          isLoadingStats = false;
        });
      }
    } else {
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
  }

  Future<void> _loadChartData() async {
    setState(() => isLoadingCharts = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isAdmin = authProvider.isAdmin;

    final dateRange = _getDateRange();

    if (isAdmin) {
      // Load attendance chart data
      final attendanceResponse = await ApiService.getAttendanceReport(
        startDate: dateRange['start']!,
        endDate: dateRange['end']!,
      );

      // Load department performance
      final deptResponse = await ApiService.getEmployeesReport();

      if (mounted) {
        setState(() {
          if (attendanceResponse.success && attendanceResponse.data != null) {
            weeklyAttendance = List<Map<String, dynamic>>.from(
              attendanceResponse.data['weekly'] ?? [],
            );
          }
          if (deptResponse.success && deptResponse.data != null) {
            departmentPerformance = List<Map<String, dynamic>>.from(
              deptResponse.data['departments'] ?? [],
            );
          }
          isLoadingCharts = false;
        });
      }
    } else {
      // Load employee's own data
      final response = await ApiService.getMyAttendance();
      if (mounted) {
        setState(() {
          if (response.success && response.data != null) {
            myWeeklyAttendance = List<Map<String, dynamic>>.from(
              response.data['weekly'] ?? [],
            );
            performanceMetrics = response.data['performance'] ?? {};
          }
          isLoadingCharts = false;
        });
      }
    }
  }

  Future<void> _loadDetailedReport() async {
    setState(() => isLoadingReport = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isAdmin = authProvider.isAdmin;
    final dateRange = _getDateRange();

    ApiResponse response;
    if (isAdmin) {
      response = await ApiService.getAttendanceReport(
        startDate: dateRange['start']!,
        endDate: dateRange['end']!,
      );
    } else {
      response = await ApiService.getMyAttendance(
        startDate: dateRange['start'],
        endDate: dateRange['end'],
      );
    }

    if (mounted) {
      setState(() {
        if (response.success && response.data != null) {
          detailedReport = List<Map<String, dynamic>>.from(
            response.data['records'] ?? response.data['data'] ?? [],
          );
        }
        isLoadingReport = false;
      });
    }
  }

  Map<String, String> _getDateRange() {
    DateTime start;
    DateTime end = DateTime.now();

    switch (selectedPeriod) {
      case 'Today':
        start = DateTime.now();
        break;
      case 'This Week':
        start = end.subtract(Duration(days: end.weekday - 1));
        break;
      case 'This Month':
        start = DateTime(end.year, end.month, 1);
        break;
      case 'This Year':
        start = DateTime(end.year, 1, 1);
        break;
      case 'Custom':
        start = startDate;
        end = endDate;
        break;
      default:
        start = DateTime(end.year, end.month, 1);
    }

    return {
      'start': start.toIso8601String().split('T')[0],
      'end': end.toIso8601String().split('T')[0],
    };
  }

  void _onPeriodChanged(String period) {
    if (period == 'Custom') {
      _showDateRangePicker();
    } else {
      setState(() => selectedPeriod = period);
      _loadAllData();
    }
  }

  int _getCrossAxisCount(double width) {
    if (width < 600) return 2;
    if (width < 1200) return 3;
    return 4;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin = authProvider.isAdmin;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          isAdmin ? 'Reports & Analytics' : 'My Reports',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllData,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _showExportDialog,
            tooltip: 'Export',
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () => _exportReport('print'),
            tooltip: 'Print',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAllData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPeriodSelector(),
              const SizedBox(height: 24),
              isAdmin ? _buildAdminStats() : _buildEmployeeStats(),
              const SizedBox(height: 24),
              Text(
                'Analytics',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              isAdmin ? _buildAdminCharts() : _buildEmployeeCharts(),
              const SizedBox(height: 24),
              _buildDetailedReport(isAdmin),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: periods.map((period) {
            final isSelected = selectedPeriod == period;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                avatar: Icon(
                  periodIcons[period],
                  size: 16,
                  color: isSelected
                      ? Colors.white
                      : Theme.of(context).textTheme.bodySmall?.color,
                ),
                label: Text(period),
                selected: isSelected,
                onSelected: (selected) => _onPeriodChanged(period),
                backgroundColor: Colors.transparent,
                selectedColor: Theme.of(context).colorScheme.primary,
                labelStyle: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : Theme.of(context).textTheme.bodySmall?.color,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildAdminStats() {
    if (isLoadingStats) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = _getCrossAxisCount(constraints.maxWidth);

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.1,
          children: [
            _buildStatCard(
              icon: Icons.access_time,
              number: '${adminStats['total_hours'] ?? 0}',
              label: 'Total Hours',
              color: Colors.blue,
              trend: '+${adminStats['hours_change'] ?? 0}%',
              isUp: true,
            ),
            _buildStatCard(
              icon: Icons.check_circle,
              number: '${adminStats['attendance_rate'] ?? 0}%',
              label: 'Attendance Rate',
              color: Colors.green,
              trend: '+${adminStats['rate_change'] ?? 0}%',
              isUp: true,
            ),
            _buildStatCard(
              icon: Icons.schedule,
              number: '${adminStats['late_arrivals'] ?? 0}',
              label: 'Late Arrivals',
              color: Colors.orange,
              trend: '${adminStats['late_change'] ?? 0}%',
              isUp: false,
            ),
            _buildStatCard(
              icon: Icons.cancel,
              number: '${adminStats['absent_today'] ?? 0}',
              label: 'Absences',
              color: Colors.red,
              trend: '${adminStats['absent_change'] ?? 0}%',
              isUp: false,
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmployeeStats() {
    if (isLoadingStats) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = _getCrossAxisCount(constraints.maxWidth);

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.1,
          children: [
            _buildStatCard(
              icon: Icons.calendar_today,
              number: '${employeeStats['days_present'] ?? 0}',
              label: 'Days Present',
              color: Colors.green,
            ),
            _buildStatCard(
              icon: Icons.schedule,
              number: '${employeeStats['working_hours'] ?? 0}h',
              label: 'Working Hours',
              color: Colors.blue,
            ),
            _buildStatCard(
              icon: Icons.trending_up,
              number: '${employeeStats['attendance_rate'] ?? 0}%',
              label: 'Attendance Rate',
              color: Colors.purple,
            ),
            _buildStatCard(
              icon: Icons.beach_access,
              number: '${employeeStats['remaining_leave'] ?? 0}',
              label: 'Remaining Leaves',
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
    required Color color,
    String? trend,
    bool? isUp,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 28),
              if (trend != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 77),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    trend,
                    style: const TextStyle(
                      fontSize: 12,
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
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminCharts() {
    if (isLoadingCharts) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        _buildAttendanceChart(),
        const SizedBox(height: 16),
        _buildDepartmentChart(),
      ],
    );
  }

  Widget _buildEmployeeCharts() {
    if (isLoadingCharts) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        _buildMyAttendanceChart(),
        const SizedBox(height: 16),
        _buildPerformanceChart(),
      ],
    );
  }

  Widget _buildAttendanceChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Attendance Overview',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Icon(
                Icons.bar_chart,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: weeklyAttendance.isEmpty
                ? const Center(child: Text('No data available'))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: weeklyAttendance.map((day) {
                      final percentage =
                          (day['percentage'] ?? 0.0).toDouble() / 100;
                      return _buildChartBar(
                        day['day']?.toString() ?? '',
                        percentage,
                        percentage >= 0.9 ? Colors.green : Colors.orange,
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Department Performance',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 20),
          if (departmentPerformance.isEmpty)
            const Center(child: Text('No data available'))
          else
            ...departmentPerformance.map((dept) {
              final colors = [
                Colors.blue,
                Colors.purple,
                Colors.green,
                Colors.orange,
                Colors.pink,
              ];
              final index = departmentPerformance.indexOf(dept);
              return _buildDepartmentRow(
                dept['name']?.toString() ?? 'Unknown',
                (dept['attendance_rate'] ?? 0.0).toDouble() / 100,
                colors[index % colors.length],
              );
            }),
        ],
      ),
    );
  }

  Widget _buildMyAttendanceChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Attendance This Week',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 20),
          if (myWeeklyAttendance.isEmpty)
            const Center(child: Text('No data available'))
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: myWeeklyAttendance.map((day) {
                final status = day['status']?.toString() ?? 'absent';
                final isPresent = status == 'present';
                final isLate = status == 'late';
                return _buildDayStatus(
                  day['day']?.toString().substring(0, 1) ?? '',
                  isPresent || isLate,
                  isLate,
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildPerformanceChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance Metrics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 20),
          _buildProgressRow(
            'Punctuality',
            (performanceMetrics['punctuality'] ?? 0.0).toDouble() / 100,
            Colors.green,
          ),
          _buildProgressRow(
            'Attendance',
            (performanceMetrics['attendance'] ?? 0.0).toDouble() / 100,
            Colors.blue,
          ),
          _buildProgressRow(
            'Task Completion',
            (performanceMetrics['task_completion'] ?? 0.0).toDouble() / 100,
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildChartBar(String label, double height, Color color) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            '${(height * 100).toInt()}%',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 150 * height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 179)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentRow(String dept, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dept,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                '${(value * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayStatus(String day, bool isPresent, bool isLate) {
    Color color;
    IconData icon;

    if (isLate) {
      color = Colors.orange;
      icon = Icons.schedule;
    } else if (isPresent) {
      color = Colors.green;
      icon = Icons.check_circle;
    } else {
      color = Colors.red;
      icon = Icons.cancel;
    }

    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(
          day,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressRow(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                '${(value * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedReport(bool isAdmin) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Detailed Report',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            TextButton.icon(
              onPressed: _showExportDialog,
              icon: const Icon(Icons.download, size: 18),
              label: const Text('Export'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (isLoadingReport)
          const Center(child: CircularProgressIndicator())
        else if (detailedReport.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: const Center(child: Text('No records found')),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).dividerColor,
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                _buildReportHeader(),
                ...detailedReport.take(10).map((record) {
                  return _buildReportRow(
                    record['employee_name']?.toString() ??
                        record['name']?.toString() ??
                        'Unknown',
                    record['employee_id']?.toString() ??
                        record['date']?.toString() ??
                        '',
                    record['check_in']?.toString() ?? 'N/A',
                    record['check_out']?.toString() ?? 'N/A',
                    record['total_hours']?.toString() ?? 'N/A',
                  );
                }),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildReportHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 26),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              'Name',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'ID/Date',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'In',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Out',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Hours',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportRow(
    String name,
    String id,
    String checkIn,
    String checkOut,
    String hours,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              name,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          Expanded(
            child: Text(
              id,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ),
          Expanded(
            child: Text(
              checkIn,
              style: const TextStyle(fontSize: 13, color: Colors.green),
            ),
          ),
          Expanded(
            child: Text(
              checkOut,
              style: const TextStyle(fontSize: 13, color: Colors.red),
            ),
          ),
          Expanded(
            child: Text(
              hours,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: startDate, end: endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedPeriod = 'Custom';
        startDate = picked.start;
        endDate = picked.end;
      });
      _loadAllData();
    }
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(
          'Export Report',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: Text(
                'Export as PDF',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _exportReport('pdf');
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart, color: Colors.green),
              title: Text(
                'Export as Excel',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _exportReport('excel');
              },
            ),
            ListTile(
              leading: const Icon(Icons.email, color: Colors.blue),
              title: Text(
                'Send via Email',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _sendReportEmail();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportReport(String format) async {
    setState(() => isExporting = true);

    final dateRange = _getDateRange();
    ApiResponse response;

    if (format == 'pdf') {
      response = await ApiService.exportReportPdf(
        reportType: 'attendance',
        startDate: dateRange['start']!,
        endDate: dateRange['end']!,
      );
    } else if (format == 'excel') {
      response = await ApiService.exportReportExcel(
        reportType: 'attendance',
        startDate: dateRange['start']!,
        endDate: dateRange['end']!,
      );
    } else {
      // Print
      response = await ApiService.exportReportPdf(
        reportType: 'attendance',
        startDate: dateRange['start']!,
        endDate: dateRange['end']!,
      );
    }

    if (mounted) {
      setState(() => isExporting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response.success
                ? 'Report exported successfully!'
                : response.message ?? 'Failed to export report',
          ),
          backgroundColor: response.success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _sendReportEmail() async {
    final emailController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: const Text('Send Report'),
        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(
            labelText: 'Email Address',
            hintText: 'admin@company.com',
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Send'),
          ),
        ],
      ),
    );

    if (result == true && emailController.text.isNotEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report sent successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
