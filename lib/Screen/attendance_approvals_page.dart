import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_models.dart';
import '../services/api_service.dart';

class AttendanceApprovalsPage extends StatefulWidget {
  const AttendanceApprovalsPage({super.key});

  @override
  State<AttendanceApprovalsPage> createState() =>
      _AttendanceApprovalsPageState();
}

class _AttendanceApprovalsPageState extends State<AttendanceApprovalsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String selectedDate = 'Today';
  String selectedDepartment = 'All';

  // State Variables
  List<Map<String, dynamic>> pendingApprovals = [];
  List<Map<String, dynamic>> approvedApprovals = [];
  List<Map<String, dynamic>> rejectedApprovals = [];
  bool isLoadingPending = true;
  bool isLoadingApproved = true;
  bool isLoadingRejected = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _loadApprovals('pending'),
      _loadApprovals('approved'),
      _loadApprovals('rejected'),
    ]);
  }

  Future<void> _loadApprovals(String status) async {
    final response = await ApiService.getAllAttendance(
      page: 1,
      perPage: 50,
      status: status,
    );

    if (mounted) {
      setState(() {
        if (response.success && response.data != null) {
          final data = List<Map<String, dynamic>>.from(
            response.data['data'] ?? [],
          );
          switch (status) {
            case 'pending':
              pendingApprovals = data;
              isLoadingPending = false;
              break;
            case 'approved':
              approvedApprovals = data;
              isLoadingApproved = false;
              break;
            case 'rejected':
              rejectedApprovals = data;
              isLoadingRejected = false;
              break;
          }
        } else {
          errorMessage = response.message;
          switch (status) {
            case 'pending':
              isLoadingPending = false;
              break;
            case 'approved':
              isLoadingApproved = false;
              break;
            case 'rejected':
              isLoadingRejected = false;
              break;
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (!authProvider.isAdmin) {
      return const Scaffold(body: Center(child: Text('Admin access only')));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Attendance Approvals',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilters,
            tooltip: 'Filter',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                isLoadingPending = true;
                isLoadingApproved = true;
                isLoadingRejected = true;
              });
              _loadAllData();
            },
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).colorScheme.primary,
          labelColor: Theme.of(context).colorScheme.primary,
          tabs: [
            Tab(text: 'Pending (${pendingApprovals.length})'),
            Tab(text: 'Approved (${approvedApprovals.length})'),
            Tab(text: 'Rejected (${rejectedApprovals.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildApprovalsList('pending', pendingApprovals, isLoadingPending),
          _buildApprovalsList('approved', approvedApprovals, isLoadingApproved),
          _buildApprovalsList('rejected', rejectedApprovals, isLoadingRejected),
        ],
      ),
    );
  }

  Widget _buildApprovalsList(
      String status, List<Map<String, dynamic>> approvals, bool isLoading) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildSummaryStats()),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        if (approvals.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    status == 'pending'
                        ? Icons.hourglass_empty
                        : status == 'approved'
                            ? Icons.check_circle_outline
                            : Icons.cancel_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No $status attendance records',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
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
                (context, index) => _buildAttendanceCard(
                  approval: approvals[index],
                  status: status,
                ),
                childCount: approvals.length,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSummaryStats() {
    return Container(
      margin: const EdgeInsets.all(16),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
              '${pendingApprovals.length}', 'Pending', Icons.pending_actions),
          Container(width: 1, height: 40, color: Colors.white30),
          _buildStatItem(
              '${approvedApprovals.length}', 'Approved', Icons.check_circle),
          Container(width: 1, height: 40, color: Colors.white30),
          _buildStatItem(
              '${rejectedApprovals.length}', 'Rejected', Icons.cancel),
        ],
      ),
    );
  }

  Widget _buildStatItem(String number, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          number,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white)),
      ],
    );
  }

  Widget _buildAttendanceCard({
    required Map<String, dynamic> approval,
    required String status,
  }) {
    final statusColor = _getStatusColor(status);
    final employeeName =
        approval['employee_name']?.toString() ??
        approval['name']?.toString() ??
        'Unknown Employee';
    final empId =
        approval['emp_id']?.toString() ??
        approval['employee_id']?.toString() ??
        'N/A';
    final department = approval['department']?.toString() ?? 'N/A';
    final checkIn = approval['check_in']?.toString() ?? approval['checkIn']?.toString() ?? 'N/A';
    final checkOut = approval['check_out']?.toString() ?? approval['checkOut']?.toString() ?? 'N/A';
    final date = approval['date']?.toString() ?? 'N/A';
    final approvalId = approval['id'];

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
                  radius: 28,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    employeeName.isNotEmpty
                        ? employeeName.substring(0, 1).toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
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
                              employeeName,
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
                              status.toUpperCase(),
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
                        '$empId - $department',
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Date: $date | In: $checkIn | Out: $checkOut',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (status == 'pending')
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approveAttendance(approvalId, employeeName),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rejectAttendance(approvalId, employeeName),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _approveAttendance(dynamic id, String employeeName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Attendance'),
        content: Text(
          'Are you sure you want to approve attendance for $employeeName?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final response = await ApiService.updateAttendance(
        attendanceId: id,
        status: 'approved',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response.success
                  ? 'Attendance approved for $employeeName'
                  : response.message ?? 'Failed to approve',
            ),
            backgroundColor: response.success ? Colors.green : Colors.red,
          ),
        );

        if (response.success) {
          setState(() {
            isLoadingPending = true;
            isLoadingApproved = true;
          });
          _loadAllData();
        }
      }
    }
  }

  Future<void> _rejectAttendance(dynamic id, String employeeName) async {
    final notesController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Attendance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to reject attendance for $employeeName?'),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final response = await ApiService.updateAttendance(
        attendanceId: id,
        status: 'rejected',
        notes: notesController.text.isNotEmpty ? notesController.text : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response.success
                  ? 'Attendance rejected for $employeeName'
                  : response.message ?? 'Failed to reject',
            ),
            backgroundColor: response.success ? Colors.red : Colors.grey,
          ),
        );

        if (response.success) {
          setState(() {
            isLoadingPending = true;
            isLoadingRejected = true;
          });
          _loadAllData();
        }
      }
    }
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Filters',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              children: ['Today', 'This Week', 'This Month'].map((date) {
                return ChoiceChip(
                  label: Text(date),
                  selected: selectedDate == date,
                  onSelected: (selected) {
                    setState(() => selectedDate = date);
                    Navigator.pop(context);
                    _loadAllData();
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
