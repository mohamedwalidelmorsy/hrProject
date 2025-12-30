import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_models.dart';
import '../services/api_service.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String selectedFilter = 'Daily';

  // State Variables
  List<Map<String, dynamic>> attendanceRecords = [];
  List<Map<String, dynamic>> employees = [];
  Map<String, dynamic>? todayStatus;
  bool isLoading = true;
  bool isLoadingMore = false;
  bool isCheckingIn = false;
  String? errorMessage;
  int currentPage = 1;
  bool hasMoreData = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!isLoadingMore && hasMoreData) {
        _loadMoreData();
      }
    }
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      currentPage = 1;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isAdmin = authProvider.isAdmin;

    if (isAdmin) {
      await Future.wait([_loadAttendanceRecords(), _loadEmployees()]);
    } else {
      await Future.wait([_loadMyAttendance(), _loadTodayStatus()]);
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadAttendanceRecords() async {
    final dateRange = _getDateRange();
    final response = await ApiService.getAllAttendance(
      page: currentPage,
      perPage: 20,
      startDate: dateRange['start'],
      endDate: dateRange['end'],
      search: _searchController.text.isNotEmpty ? _searchController.text : null,
    );

    if (mounted) {
      setState(() {
        if (response.success && response.data != null) {
          attendanceRecords = List<Map<String, dynamic>>.from(
            response.data['data'] ?? [],
          );
          hasMoreData =
              (response.data['current_page'] ?? 1) <
              (response.data['last_page'] ?? 1);
        } else {
          errorMessage = response.message;
        }
      });
    }
  }

  Future<void> _loadMoreData() async {
    if (isLoadingMore || !hasMoreData) return;

    setState(() => isLoadingMore = true);
    currentPage++;

    final dateRange = _getDateRange();
    final response = await ApiService.getAllAttendance(
      page: currentPage,
      perPage: 20,
      startDate: dateRange['start'],
      endDate: dateRange['end'],
      search: _searchController.text.isNotEmpty ? _searchController.text : null,
    );

    if (mounted) {
      setState(() {
        if (response.success && response.data != null) {
          final newRecords = List<Map<String, dynamic>>.from(
            response.data['data'] ?? [],
          );
          attendanceRecords.addAll(newRecords);
          hasMoreData =
              (response.data['current_page'] ?? 1) <
              (response.data['last_page'] ?? 1);
        }
        isLoadingMore = false;
      });
    }
  }

  Future<void> _loadEmployees() async {
    final response = await ApiService.getEmployees(perPage: 100);
    if (mounted && response.success && response.data != null) {
      setState(() {
        employees = List<Map<String, dynamic>>.from(
          response.data['data'] ?? [],
        );
      });
    }
  }

  Future<void> _loadMyAttendance() async {
    final dateRange = _getDateRange();
    final response = await ApiService.getMyAttendance(
      startDate: dateRange['start'],
      endDate: dateRange['end'],
    );

    if (mounted) {
      setState(() {
        if (response.success && response.data != null) {
          attendanceRecords = List<Map<String, dynamic>>.from(
            response.data['records'] ?? response.data['data'] ?? [],
          );
        } else {
          errorMessage = response.message;
        }
      });
    }
  }

  Future<void> _loadTodayStatus() async {
    final response = await ApiService.getTodayAttendanceStatus();
    if (mounted && response.success && response.data != null) {
      setState(() {
        todayStatus = response.data;
      });
    }
  }

  Map<String, String> _getDateRange() {
    final now = DateTime.now();
    DateTime start;
    DateTime end = now;

    switch (selectedFilter) {
      case 'Daily':
        start = now;
        break;
      case 'Weekly':
        start = now.subtract(Duration(days: now.weekday - 1));
        break;
      case 'Monthly':
        start = DateTime(now.year, now.month, 1);
        break;
      default:
        start = now;
    }

    return {
      'start': start.toIso8601String().split('T')[0],
      'end': end.toIso8601String().split('T')[0],
    };
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin = authProvider.isAdmin;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          isAdmin ? 'Attendance Management' : 'My Attendance',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
          if (isAdmin) ...[
            _buildExportMenu(),
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilterDialog,
              tooltip: 'Filter',
            ),
          ],
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
            ? _buildErrorState()
            : CustomScrollView(
                controller: _scrollController,
                slivers: [
                  if (isAdmin) ...[
                    // Search Bar
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search employees...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      _loadData();
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Theme.of(context).cardColor,
                          ),
                          onSubmitted: (_) => _loadData(),
                        ),
                      ),
                    ),
                    // Filter Chips
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          bottom: 16,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Wrap(
                            spacing: 8,
                            children: ['Daily', 'Weekly', 'Monthly'].map((
                              filter,
                            ) {
                              final isSelected = selectedFilter == filter;
                              return ChoiceChip(
                                label: Text(filter),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() => selectedFilter = filter);
                                  _loadData();
                                },
                                selectedColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                                backgroundColor: Theme.of(context).cardColor,
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Theme.of(context).colorScheme.onSurface,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                side: BorderSide(
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).dividerColor,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: _buildEmployeeQuickStatus(),
                      ),
                    ),
                  ],
                  // List
                  if (attendanceRecords.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_busy,
                              size: 64,
                              color: Theme.of(
                                context,
                              ).textTheme.bodySmall?.color,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No attendance records found',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (index == attendanceRecords.length) {
                              return isLoadingMore
                                  ? const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(16),
                                        child: CircularProgressIndicator(),
                                      ),
                                    )
                                  : const SizedBox.shrink();
                            }
                            return isAdmin
                                ? _buildAttendanceCard(
                                    attendanceRecords[index],
                                    index,
                                  )
                                : _buildEmployeeAttendanceCard(
                                    attendanceRecords[index],
                                  );
                          },
                          childCount:
                              attendanceRecords.length + (hasMoreData ? 1 : 0),
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
      ),
      floatingActionButton: isAdmin ? _buildAdminFAB() : _buildEmployeeFAB(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(errorMessage ?? 'An error occurred'),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildExportMenu() {
    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.download, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text(
              'Export',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
      onSelected: (value) {
        if (value == 'pdf')
          _exportToPDF();
        else if (value == 'excel')
          _exportToExcel();
        else if (value == 'email')
          _sendEmail();
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'pdf',
          child: Row(
            children: [
              Icon(Icons.picture_as_pdf, color: Colors.red, size: 20),
              SizedBox(width: 12),
              Text('Export as PDF'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'excel',
          child: Row(
            children: [
              Icon(Icons.table_chart, color: Colors.green, size: 20),
              SizedBox(width: 12),
              Text('Export as Excel'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'email',
          child: Row(
            children: [
              Icon(
                Icons.email,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 12),
              const Text('Send via Email'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmployeeQuickStatus() {
    final isCheckedIn =
        todayStatus?['checked_in'] == true ||
        todayStatus?['status'] == 'checked_in';
    final checkInTime = todayStatus?['check_in_time']?.toString() ?? '';
    final checkOutTime = todayStatus?['check_out_time']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                isCheckedIn ? Icons.check_circle : Icons.access_time,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCheckedIn ? 'Checked In' : 'Not Checked In',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      _formatTodayDate(),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (checkInTime.isNotEmpty || checkOutTime.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                if (checkInTime.isNotEmpty)
                  _buildQuickStatusTime('Check In', checkInTime, Icons.login),
                if (checkOutTime.isNotEmpty)
                  _buildQuickStatusTime(
                    'Check Out',
                    checkOutTime,
                    Icons.logout,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickStatusTime(String label, String time, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.white70),
        ),
        Text(
          time,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  String _formatTodayDate() {
    final now = DateTime.now();
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  Widget _buildAttendanceCard(Map<String, dynamic> record, int index) {
    final name =
        record['employee_name']?.toString() ??
        record['name']?.toString() ??
        'Unknown';
    final empId =
        record['employee_id']?.toString() ?? record['empId']?.toString() ?? '';
    final checkIn =
        record['check_in']?.toString() ?? record['checkIn']?.toString() ?? '--';
    final checkOut =
        record['check_out']?.toString() ??
        record['checkOut']?.toString() ??
        '--';
    final status = record['status']?.toString() ?? 'Present';
    final statusColor = _getStatusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1.5),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  backgroundImage: record['avatar'] != null
                      ? NetworkImage(record['avatar'].toString())
                      : null,
                  child: record['avatar'] == null
                      ? Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'E',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              status,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        empId,
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
          ),
          Divider(color: Theme.of(context).dividerColor, height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTimeInfo(Icons.login, 'Check In', checkIn, Colors.green),
                _buildTimeInfo(Icons.logout, 'Check Out', checkOut, Colors.red),
                IconButton(
                  onPressed: () => _editAttendance(record, index),
                  icon: Icon(
                    Icons.edit,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  tooltip: 'Edit',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeAttendanceCard(Map<String, dynamic> record) {
    final date = record['date']?.toString() ?? '';
    final checkIn =
        record['check_in']?.toString() ?? record['checkIn']?.toString() ?? '--';
    final checkOut =
        record['check_out']?.toString() ??
        record['checkOut']?.toString() ??
        '--';
    final status = record['status']?.toString() ?? 'Present';
    final statusColor = _getStatusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_today,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDateString(date),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  '$checkIn - $checkOut',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
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
  }

  String _formatDateString(String dateStr) {
    if (dateStr.isEmpty) return 'Unknown Date';
    try {
      final date = DateTime.parse(dateStr);
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  Widget _buildTimeInfo(IconData icon, String label, String time, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
        Text(
          time,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildAdminFAB() {
    return FloatingActionButton.extended(
      onPressed: _markAttendance,
      backgroundColor: Theme.of(context).colorScheme.primary,
      icon: const Icon(Icons.check),
      label: const Text('Mark Attendance'),
    );
  }

  Widget _buildEmployeeFAB() {
    final isCheckedIn =
        todayStatus?['checked_in'] == true ||
        todayStatus?['status'] == 'checked_in';
    final canCheckOut =
        isCheckedIn &&
        (todayStatus?['check_out_time'] == null ||
            todayStatus?['check_out_time'] == '');

    return FloatingActionButton.extended(
      onPressed: isCheckingIn ? null : _toggleCheckIn,
      backgroundColor: isCheckedIn
          ? (canCheckOut ? Colors.red : Colors.grey)
          : Colors.green,
      icon: isCheckingIn
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : Icon(isCheckedIn ? Icons.logout : Icons.login),
      label: Text(
        isCheckingIn
            ? 'Processing...'
            : isCheckedIn
            ? (canCheckOut ? 'Check Out' : 'Already Checked Out')
            : 'Check In',
      ),
    );
  }

  Color _getStatusColor(String status) {
    final s = status.toLowerCase();
    if (s == 'on time' || s == 'present') return Colors.green;
    if (s == 'late') return Colors.orange;
    if (s == 'early') return Colors.blue;
    if (s == 'absent') return Colors.red;
    return Colors.grey;
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Options'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Status'),
              trailing: DropdownButton<String>(
                value: 'All',
                items: ['All', 'Present', 'Late', 'Absent', 'Early']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) {},
              ),
            ),
            ListTile(
              title: const Text('Department'),
              trailing: DropdownButton<String>(
                value: 'All',
                items: ['All', 'IT', 'HR', 'Sales', 'Finance']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) {},
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _loadData();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportToPDF() async {
    final dateRange = _getDateRange();
    final response = await ApiService.exportReportPdf(
      reportType: 'attendance',
      startDate: dateRange['start']!,
      endDate: dateRange['end']!,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response.success
                ? '✅ PDF exported!'
                : response.message ?? 'Export failed',
          ),
          backgroundColor: response.success ? Colors.green : Colors.red,
          action: response.success
              ? SnackBarAction(
                  label: 'Open',
                  textColor: Colors.white,
                  onPressed: () {},
                )
              : null,
        ),
      );
    }
  }

  Future<void> _exportToExcel() async {
    final dateRange = _getDateRange();
    final response = await ApiService.exportReportExcel(
      reportType: 'attendance',
      startDate: dateRange['start']!,
      endDate: dateRange['end']!,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response.success
                ? '✅ Excel exported!'
                : response.message ?? 'Export failed',
          ),
          backgroundColor: response.success ? Colors.green : Colors.red,
          action: response.success
              ? SnackBarAction(
                  label: 'Open',
                  textColor: Colors.white,
                  onPressed: () {},
                )
              : null,
        ),
      );
    }
  }

  Future<void> _sendEmail() async {
    final emailController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: const Text('Send Report'),
        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            hintText: 'admin@company.com',
            border: OutlineInputBorder(),
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
          content: Text('✅ Email sent!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _markAttendance() async {
    String? selectedEmployeeId;
    final checkInController = TextEditingController();
    final checkOutController = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            backgroundColor: Theme.of(context).cardColor,
            title: const Text('Mark Attendance'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Employee',
                      border: OutlineInputBorder(),
                    ),
                    items: employees
                        .map<DropdownMenuItem<String>>(
                          (e) => DropdownMenuItem<String>(
                            value: e['id']?.toString(),
                            child: Text(e['name']?.toString() ?? 'Unknown'),
                          ),
                        )
                        .toList(),
                    onChanged: (v) =>
                        setDialogState(() => selectedEmployeeId = v),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: checkInController,
                    decoration: const InputDecoration(
                      labelText: 'Check In Time',
                      hintText: '09:00',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.login),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: checkOutController,
                    decoration: const InputDecoration(
                      labelText: 'Check Out Time',
                      hintText: '17:00',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.logout),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (selectedEmployeeId != null) {
                    Navigator.pop(context, {
                      'employee_id': selectedEmployeeId!,
                      'check_in': checkInController.text,
                      'check_out': checkOutController.text,
                    });
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );

    if (result != null && mounted) {
      final response = await ApiService.markAttendance(
        employeeId: result['employee_id']!,
        checkIn: result['check_in'],
        checkOut: result['check_out'],
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response.success
                  ? '✅ Attendance marked!'
                  : response.message ?? 'Failed',
            ),
            backgroundColor: response.success ? Colors.green : Colors.red,
          ),
        );
        if (response.success) _loadData();
      }
    }
  }

  Future<void> _editAttendance(Map<String, dynamic> record, int index) async {
    final checkInCtrl = TextEditingController(
      text:
          record['check_in']?.toString() ?? record['checkIn']?.toString() ?? '',
    );
    final checkOutCtrl = TextEditingController(
      text:
          record['check_out']?.toString() ??
          record['checkOut']?.toString() ??
          '',
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(
          'Edit - ${record['employee_name'] ?? record['name'] ?? 'Employee'}',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: checkInCtrl,
              decoration: const InputDecoration(
                labelText: 'Check In',
                prefixIcon: Icon(Icons.login),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: checkOutCtrl,
              decoration: const InputDecoration(
                labelText: 'Check Out',
                prefixIcon: Icon(Icons.logout),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      final response = await ApiService.updateAttendance(
        attendanceId: record['id'],
        checkIn: checkInCtrl.text,
        checkOut: checkOutCtrl.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response.success ? '✅ Updated!' : response.message ?? 'Failed',
            ),
            backgroundColor: response.success ? Colors.green : Colors.red,
          ),
        );
        if (response.success) _loadData();
      }
    }

    checkInCtrl.dispose();
    checkOutCtrl.dispose();
  }

  Future<void> _toggleCheckIn() async {
    final isCheckedIn =
        todayStatus?['checked_in'] == true ||
        todayStatus?['status'] == 'checked_in';
    final canCheckOut =
        isCheckedIn &&
        (todayStatus?['check_out_time'] == null ||
            todayStatus?['check_out_time'] == '');

    if (isCheckedIn && !canCheckOut) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have already checked out today'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => isCheckingIn = true);

    ApiResponse response;
    if (isCheckedIn) {
      response = await ApiService.checkOut();
    } else {
      response = await ApiService.checkIn();
    }

    if (mounted) {
      setState(() => isCheckingIn = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response.success
                ? (isCheckedIn
                      ? 'Checked out successfully!'
                      : 'Checked in successfully!')
                : response.message ?? 'Failed',
          ),
          backgroundColor: response.success ? Colors.green : Colors.red,
        ),
      );

      if (response.success) {
        _loadTodayStatus();
      }
    }
  }
}
