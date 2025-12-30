import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_models.dart';
import '../services/api_service.dart';

enum ShiftView { daily, weekly, monthly }

class ShiftsPage extends StatefulWidget {
  const ShiftsPage({super.key});

  @override
  State<ShiftsPage> createState() => _ShiftsPageState();
}

class _ShiftsPageState extends State<ShiftsPage> {
  ShiftView currentView = ShiftView.weekly;
  DateTime selectedDate = DateTime.now();
  
  // State Variables
  List<Map<String, dynamic>> shifts = [];
  List<Map<String, dynamic>> employees = [];
  bool isLoading = true;
  bool isLoadingEmployees = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    await Future.wait([
      _loadShifts(),
      _loadEmployees(),
    ]);
  }

  Future<void> _loadShifts() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isAdmin = authProvider.isAdmin;

    ApiResponse response;
    if (isAdmin) {
      response = await ApiService.getShifts();
    } else {
      response = await ApiService.getMyCurrentShift();
    }

    if (mounted) {
      setState(() {
        if (response.success && response.data != null) {
          if (isAdmin) {
            shifts = List<Map<String, dynamic>>.from(response.data['data'] ?? []);
          } else {
            // For employee, wrap single shift in list or get schedule
            if (response.data is List) {
              shifts = List<Map<String, dynamic>>.from(response.data);
            } else if (response.data['schedule'] != null) {
              shifts = List<Map<String, dynamic>>.from(response.data['schedule']);
            } else {
              shifts = [Map<String, dynamic>.from(response.data)];
            }
          }
        } else {
          errorMessage = response.message;
        }
        isLoading = false;
      });
    }
  }

  Future<void> _loadEmployees() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAdmin) return;

    setState(() => isLoadingEmployees = true);

    final response = await ApiService.getEmployees(perPage: 100);

    if (mounted) {
      setState(() {
        if (response.success && response.data != null) {
          employees = List<Map<String, dynamic>>.from(response.data['data'] ?? []);
        }
        isLoadingEmployees = false;
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
          isAdmin ? 'Shift Management' : 'My Schedule',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
          _buildViewSelector(),
          if (isAdmin) ...[
            IconButton(icon: const Icon(Icons.download), onPressed: _exportSchedule, tooltip: 'Export'),
            IconButton(icon: const Icon(Icons.settings), onPressed: _openSettings, tooltip: 'Settings'),
          ],
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: Column(
          children: [
            _buildDateNavigator(),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : errorMessage != null
                      ? _buildErrorState()
                      : _buildCurrentView(),
            ),
          ],
        ),
      ),
      floatingActionButton: isAdmin ? _buildAddShiftFAB() : null,
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
          ElevatedButton(
            onPressed: _loadData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildViewSelector() {
    return PopupMenuButton<ShiftView>(
      icon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _getViewName(currentView),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),
          ],
        ),
      ),
      onSelected: (view) => setState(() => currentView = view),
      itemBuilder: (context) => [
        const PopupMenuItem(value: ShiftView.daily, child: Row(children: [Icon(Icons.view_day, size: 20), SizedBox(width: 12), Text('Daily View')])),
        const PopupMenuItem(value: ShiftView.weekly, child: Row(children: [Icon(Icons.view_week, size: 20), SizedBox(width: 12), Text('Weekly View')])),
        const PopupMenuItem(value: ShiftView.monthly, child: Row(children: [Icon(Icons.calendar_month, size: 20), SizedBox(width: 12), Text('Monthly View')])),
      ],
    );
  }
  
  String _getViewName(ShiftView view) {
    switch (view) {
      case ShiftView.daily: return 'Daily';
      case ShiftView.weekly: return 'Weekly';
      case ShiftView.monthly: return 'Monthly';
    }
  }
  
  Widget _buildDateNavigator() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _previousPeriod,
            tooltip: 'Previous',
          ),
          TextButton.icon(
            onPressed: _selectDate,
            icon: const Icon(Icons.calendar_today, size: 18),
            label: Text(
              _getDateRangeText(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _nextPeriod,
            tooltip: 'Next',
          ),
        ],
      ),
    );
  }
  
  String _getDateRangeText() {
    switch (currentView) {
      case ShiftView.daily:
        return _formatDate(selectedDate, includeDay: true);
      case ShiftView.weekly:
        final start = _getWeekStart(selectedDate);
        final end = start.add(const Duration(days: 6));
        return '${_formatDateShort(start)} - ${_formatDateShort(end)}';
      case ShiftView.monthly:
        return _formatMonth(selectedDate);
    }
  }
  
  String _formatDate(DateTime date, {bool includeDay = false}) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    
    if (includeDay) {
      return '${days[date.weekday % 7]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
    }
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
  
  String _formatDateShort(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
  
  String _formatMonth(DateTime date) {
    final months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return '${months[date.month - 1]} ${date.year}';
  }
  
  String _formatDayName(DateTime date) {
    final days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${days[date.weekday % 7]}, ${months[date.month - 1]} ${date.day}';
  }
  
  DateTime _getWeekStart(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }
  
  void _previousPeriod() {
    setState(() {
      switch (currentView) {
        case ShiftView.daily:
          selectedDate = selectedDate.subtract(const Duration(days: 1));
          break;
        case ShiftView.weekly:
          selectedDate = selectedDate.subtract(const Duration(days: 7));
          break;
        case ShiftView.monthly:
          selectedDate = DateTime(selectedDate.year, selectedDate.month - 1, 1);
          break;
      }
    });
  }
  
  void _nextPeriod() {
    setState(() {
      switch (currentView) {
        case ShiftView.daily:
          selectedDate = selectedDate.add(const Duration(days: 1));
          break;
        case ShiftView.weekly:
          selectedDate = selectedDate.add(const Duration(days: 7));
          break;
        case ShiftView.monthly:
          selectedDate = DateTime(selectedDate.year, selectedDate.month + 1, 1);
          break;
      }
    });
  }
  
  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }
  
  Widget _buildCurrentView() {
    switch (currentView) {
      case ShiftView.daily:
        return _buildDailyView();
      case ShiftView.weekly:
        return _buildWeeklyView();
      case ShiftView.monthly:
        return _buildMonthlyView();
    }
  }
  
  Widget _buildDailyView() {
    final todayShifts = _getShiftsForDate(selectedDate);
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Today\'s Schedule',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
        ),
        const SizedBox(height: 16),
        if (todayShifts.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.event_busy, size: 64, color: Theme.of(context).colorScheme.primary.withValues(alpha: 128)),
                  const SizedBox(height: 16),
                  Text('No shifts scheduled for this day', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
                ],
              ),
            ),
          )
        else
          ...todayShifts.map((shift) => _buildShiftCard(shift)),
      ],
    );
  }
  
  Widget _buildWeeklyView() {
    final weekStart = _getWeekStart(selectedDate);
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: List.generate(7, (dayIndex) {
        final date = weekStart.add(Duration(days: dayIndex));
        final dayShifts = _getShiftsForDate(date);
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: _isToday(date) ? Theme.of(context).colorScheme.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDayName(date),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: _isToday(date) ? FontWeight.bold : FontWeight.w600,
                      color: _isToday(date) ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  if (_isToday(date)) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('Today', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            ),
            if (dayShifts.isEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 20, bottom: 16),
                child: Text('No shifts scheduled', style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodySmall?.color)),
              )
            else
              ...dayShifts.map((shift) => Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 8),
                child: _buildShiftCard(shift),
              )),
            Divider(color: Theme.of(context).dividerColor),
          ],
        );
      }),
    );
  }
  
  Widget _buildMonthlyView() {
    final firstDayOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
    final lastDayOfMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: daysInMonth + firstDayOfMonth.weekday - 1,
      itemBuilder: (context, index) {
        if (index < firstDayOfMonth.weekday - 1) {
          return const SizedBox();
        }

        final day = index - firstDayOfMonth.weekday + 2;
        final date = DateTime(selectedDate.year, selectedDate.month, day);
        final dayShifts = _getShiftsForDate(date);
        final hasShifts = dayShifts.isNotEmpty;

        return InkWell(
          onTap: () {
            setState(() {
              selectedDate = date;
              currentView = ShiftView.daily;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: _isToday(date)
                  ? Theme.of(context).colorScheme.primary
                  : hasShifts
                      ? Theme.of(context).colorScheme.primary.withValues(alpha: 51)
                      : Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _isToday(date)
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).dividerColor,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$day',
                  style: TextStyle(
                    fontWeight: _isToday(date) ? FontWeight.bold : FontWeight.normal,
                    color: _isToday(date)
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                if (hasShifts)
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _isToday(date) ? Colors.white : Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Map<String, dynamic>> _getShiftsForDate(DateTime date) {
    return shifts.where((shift) {
      final shiftDate = _parseShiftDate(shift);
      if (shiftDate != null) {
        return _isSameDay(shiftDate, date);
      }
      // If no specific date, check work_days
      final workDays = shift['work_days'];
      if (workDays != null) {
        final dayNames = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
        final dayName = dayNames[date.weekday - 1];
        if (workDays is List) {
          return workDays.any((d) => d.toString().toLowerCase() == dayName);
        } else if (workDays is String) {
          return workDays.toLowerCase().contains(dayName);
        }
      }
      return false;
    }).toList();
  }

  DateTime? _parseShiftDate(Map<String, dynamic> shift) {
    final dateValue = shift['date'];
    if (dateValue == null) return null;
    if (dateValue is DateTime) return dateValue;
    if (dateValue is String && dateValue.isNotEmpty) {
      try {
        return DateTime.parse(dateValue);
      } catch (e) {
        return null;
      }
    }
    return null;
  }
  
  Widget _buildShiftCard(Map<String, dynamic> shift) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isAdmin = authProvider.isAdmin;

    final employeeName = shift['employee_name']?.toString() ?? 
                         shift['employeeName']?.toString() ?? 
                         shift['name']?.toString() ?? 'Unknown';
    final shiftType = shift['type']?.toString() ?? 
                      shift['shift_name']?.toString() ?? 
                      shift['name']?.toString() ?? 'Shift';
    final startTime = shift['start_time']?.toString() ?? shift['startTime']?.toString() ?? '--';
    final endTime = shift['end_time']?.toString() ?? shift['endTime']?.toString() ?? '--';
    final color = _getShiftColor(shiftType);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 128), width: 2),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Text(
            employeeName.isNotEmpty ? employeeName.substring(0, 1).toUpperCase() : 'S',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          isAdmin ? employeeName : shiftType,
          style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
        ),
        subtitle: Text(
          isAdmin 
              ? '$shiftType • $startTime - $endTime'
              : '$startTime - $endTime',
          style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
        ),
        trailing: isAdmin
            ? PopupMenuButton(
                icon: const Icon(Icons.more_vert, size: 20),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Edit Shift')])),
                  const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
                ],
                onSelected: (value) {
                  if (value == 'edit') _editShift(shift);
                  else if (value == 'delete') _deleteShift(shift);
                },
              )
            : null,
      ),
    );
  }

  Color _getShiftColor(String shiftType) {
    final type = shiftType.toLowerCase();
    if (type.contains('morning')) return Colors.blue;
    if (type.contains('evening')) return Colors.orange;
    if (type.contains('night')) return Colors.purple;
    if (type.contains('off') || type.contains('holiday')) return Colors.green;
    return Theme.of(context).colorScheme.primary;
  }
  
  Widget _buildAddShiftFAB() {
    return FloatingActionButton.extended(
      onPressed: _addShift,
      backgroundColor: Theme.of(context).colorScheme.primary,
      icon: const Icon(Icons.add),
      label: const Text('Add Shift'),
    );
  }
  
  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
  bool _isToday(DateTime date) => _isSameDay(date, DateTime.now());
  
  Future<void> _addShift() async {
    final nameController = TextEditingController();
    final startTimeController = TextEditingController();
    final endTimeController = TextEditingController();
    String? selectedEmployeeId;
    List<String> selectedWorkDays = [];
    final workDayOptions = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: const Text('Add New Shift'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Shift Name',
                    hintText: 'e.g., Morning Shift',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: startTimeController,
                  decoration: const InputDecoration(
                    labelText: 'Start Time',
                    hintText: '09:00',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: endTimeController,
                  decoration: const InputDecoration(
                    labelText: 'End Time',
                    hintText: '17:00',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Work Days:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: workDayOptions.map((day) {
                    final isSelected = selectedWorkDays.contains(day);
                    return FilterChip(
                      label: Text(day.substring(0, 3)),
                      selected: isSelected,
                      onSelected: (selected) {
                        setDialogState(() {
                          if (selected) {
                            selectedWorkDays.add(day);
                          } else {
                            selectedWorkDays.remove(day);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );

    if (result == true && mounted) {
      final response = await ApiService.createShift(
        name: nameController.text,
        startTime: startTimeController.text,
        endTime: endTimeController.text,
        workDays: selectedWorkDays,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.success ? 'Shift created successfully!' : response.message ?? 'Failed'),
            backgroundColor: response.success ? Colors.green : Colors.red,
          ),
        );
        if (response.success) _loadShifts();
      }
    }
  }
  
  Future<void> _editShift(Map<String, dynamic> shift) async {
    final nameController = TextEditingController(text: shift['name']?.toString() ?? shift['shift_name']?.toString() ?? '');
    final startTimeController = TextEditingController(text: shift['start_time']?.toString() ?? shift['startTime']?.toString() ?? '');
    final endTimeController = TextEditingController(text: shift['end_time']?.toString() ?? shift['endTime']?.toString() ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: const Text('Edit Shift'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Shift Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: startTimeController,
                decoration: const InputDecoration(
                  labelText: 'Start Time',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: endTimeController,
                decoration: const InputDecoration(
                  labelText: 'End Time',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );

    if (result == true && mounted) {
      final response = await ApiService.updateShift(
        shiftId: shift['id'],
        name: nameController.text,
        startTime: startTimeController.text,
        endTime: endTimeController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.success ? 'Shift updated!' : response.message ?? 'Failed'),
            backgroundColor: response.success ? Colors.green : Colors.red,
          ),
        );
        if (response.success) _loadShifts();
      }
    }
  }
  
  Future<void> _deleteShift(Map<String, dynamic> shift) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Shift'),
        content: Text('Are you sure you want to delete this shift?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final response = await ApiService.deleteShift(shift['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.success ? 'Shift deleted!' : response.message ?? 'Failed'),
            backgroundColor: response.success ? Colors.green : Colors.red,
          ),
        );
        if (response.success) _loadShifts();
      }
    }
  }
  
  Future<void> _exportSchedule() async {
    final response = await ApiService.exportReportExcel(
      reportType: 'shifts',
      startDate: _getWeekStart(selectedDate).toIso8601String().split('T')[0],
      endDate: _getWeekStart(selectedDate).add(const Duration(days: 6)).toIso8601String().split('T')[0],
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.success ? 'Schedule exported!' : response.message ?? 'Failed'),
          backgroundColor: response.success ? Colors.green : Colors.red,
        ),
      );
    }
  }
  
  void _openSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: const Text('Shift Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Default Shift Duration'),
              subtitle: const Text('8 hours'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.notification_important),
              title: const Text('Shift Reminders'),
              subtitle: const Text('Enabled'),
              trailing: Switch(value: true, onChanged: (v) {}),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }
}