import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_models.dart';
import '../services/api_service.dart';

class LeavesPage extends StatefulWidget {
  const LeavesPage({super.key});

  @override
  State<LeavesPage> createState() => _LeavesPageState();
}

class _LeavesPageState extends State<LeavesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String selectedFilter = 'All';

  // State Variables
  List<dynamic> pendingLeaves = [];
  List<dynamic> approvedLeaves = [];
  List<dynamic> rejectedLeaves = [];
  bool isLoadingPending = true;
  bool isLoadingApproved = true;
  bool isLoadingRejected = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllLeaves();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllLeaves() async {
    await Future.wait([
      _loadLeaves('pending'),
      _loadLeaves('approved'),
      _loadLeaves('rejected'),
    ]);
  }

  Future<void> _loadLeaves(String status) async {
    final response = await ApiService.getLeaveRequests(status: status);

    if (mounted) {
      setState(() {
        if (response.success && response.data != null) {
          final leaves = response.data['data'] ?? [];
          switch (status) {
            case 'pending':
              pendingLeaves = leaves;
              isLoadingPending = false;
              break;
            case 'approved':
              approvedLeaves = leaves;
              isLoadingApproved = false;
              break;
            case 'rejected':
              rejectedLeaves = leaves;
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
    final isAdmin = authProvider.isAdmin;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          isAdmin ? 'Leave Management' : 'My Leaves',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).colorScheme.primary,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Theme.of(context).textTheme.bodySmall?.color,
          tabs: [
            Tab(text: 'Pending (${pendingLeaves.length})'),
            Tab(text: 'Approved (${approvedLeaves.length})'),
            Tab(text: 'Rejected (${rejectedLeaves.length})'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                isLoadingPending = true;
                isLoadingApproved = true;
                isLoadingRejected = true;
              });
              _loadAllLeaves();
            },
            tooltip: 'Refresh',
          ),
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () {},
              tooltip: 'Filter',
            ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLeavesList('pending', pendingLeaves, isLoadingPending),
          _buildLeavesList('approved', approvedLeaves, isLoadingApproved),
          _buildLeavesList('rejected', rejectedLeaves, isLoadingRejected),
        ],
      ),
      floatingActionButton: !isAdmin ? _buildRequestLeaveFAB() : null,
    );
  }

  Widget _buildLeavesList(String status, List<dynamic> leaves, bool isLoading) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (leaves.isEmpty) {
      return Center(
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
              'No $status leaves',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadLeaves(status),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: leaves.length,
        itemBuilder: (context, index) {
          return _buildLeaveCard(leave: leaves[index], status: status);
        },
      ),
    );
  }

  Widget _buildLeaveCard({
    required Map<String, dynamic> leave,
    required String status,
  }) {
    final statusColor = _getStatusColor(status);
    final employeeName =
        leave['employee_name']?.toString() ??
        leave['user_name']?.toString() ??
        'Unknown';
    final leaveType = leave['type']?.toString() ?? 'Leave';
    final startDate = leave['start_date']?.toString() ?? 'N/A';
    final endDate = leave['end_date']?.toString() ?? 'N/A';
    final days =
        leave['days']?.toString() ?? _calculateDays(startDate, endDate);
    final reason = leave['reason']?.toString() ?? '';
    final leaveId = leave['id'];

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
                        leaveType,
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (reason.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          reason,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDateInfo(
                  Icons.calendar_today,
                  'Start',
                  _formatDate(startDate),
                ),
                _buildDateInfo(Icons.event, 'End', _formatDate(endDate)),
                _buildDateInfo(Icons.timelapse, 'Duration', '$days days'),
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
                      onPressed: () => _approveLeave(leaveId, employeeName),
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
                      onPressed: () => _rejectLeave(leaveId, employeeName),
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

  Widget _buildDateInfo(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildRequestLeaveFAB() {
    return FloatingActionButton.extended(
      onPressed: _showRequestLeaveDialog,
      backgroundColor: Theme.of(context).colorScheme.primary,
      icon: const Icon(Icons.add),
      label: const Text('Request Leave'),
    );
  }

  Future<void> _approveLeave(dynamic leaveId, String employeeName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Leave'),
        content: Text(
          'Are you sure you want to approve leave for $employeeName?',
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
      final response = await ApiService.updateLeaveRequestStatus(
        requestId: leaveId,
        status: 'approved',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response.success
                  ? 'Leave approved for $employeeName'
                  : response.message ?? 'Failed',
            ),
            backgroundColor: response.success ? Colors.green : Colors.red,
          ),
        );
        if (response.success) _loadAllLeaves();
      }
    }
  }

  Future<void> _rejectLeave(dynamic leaveId, String employeeName) async {
    final notesController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Leave'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to reject leave for $employeeName?'),
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
      final response = await ApiService.updateLeaveRequestStatus(
        requestId: leaveId,
        status: 'rejected',
        adminNotes: notesController.text.isNotEmpty
            ? notesController.text
            : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response.success
                  ? 'Leave rejected for $employeeName'
                  : response.message ?? 'Failed',
            ),
            backgroundColor: response.success ? Colors.red : Colors.grey,
          ),
        );
        if (response.success) _loadAllLeaves();
      }
    }
  }

  void _showRequestLeaveDialog() {
    final leaveTypes = [
      'Annual Leave',
      'Sick Leave',
      'Emergency Leave',
      'Casual Leave',
      'Other',
    ];
    String selectedType = leaveTypes[0];
    DateTime? startDate;
    DateTime? endDate;
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: Text(
            'Request Leave',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Leave Type',
                    border: OutlineInputBorder(),
                  ),
                  items: leaveTypes.map((type) {
                    return DropdownMenuItem(value: type, child: Text(type));
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() => selectedType = value ?? selectedType);
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Start Date'),
                  subtitle: Text(
                    startDate != null
                        ? _formatDate(startDate.toString())
                        : 'Select date',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setDialogState(() => startDate = date);
                    }
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('End Date'),
                  subtitle: Text(
                    endDate != null
                        ? _formatDate(endDate.toString())
                        : 'Select date',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: startDate ?? DateTime.now(),
                      firstDate: startDate ?? DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setDialogState(() => endDate = date);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Reason',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
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
              onPressed: () async {
                if (startDate == null || endDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select start and end dates'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                Navigator.pop(context);

                final response = await ApiService.createLeaveRequest(
                  type: selectedType,
                  startDate: startDate!.toIso8601String().split('T')[0],
                  endDate: endDate!.toIso8601String().split('T')[0],
                  reason: reasonController.text.isNotEmpty
                      ? reasonController.text
                      : null,
                );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        response.success
                            ? 'Leave request submitted!'
                            : response.message ?? 'Failed',
                      ),
                      backgroundColor: response.success
                          ? Colors.green
                          : Colors.red,
                    ),
                  );
                  if (response.success) _loadAllLeaves();
                }
              },
              child: const Text('Submit'),
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

  String _formatDate(String dateStr) {
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

  String _calculateDays(String start, String end) {
    try {
      final startDate = DateTime.parse(start);
      final endDate = DateTime.parse(end);
      return '${endDate.difference(startDate).inDays + 1}';
    } catch (e) {
      return 'N/A';
    }
  }
}
