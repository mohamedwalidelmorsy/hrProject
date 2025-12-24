import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_models.dart';

enum ShiftView { daily, weekly, monthly }

class ShiftsPage extends StatefulWidget {
  const ShiftsPage({super.key});

  @override
  State<ShiftsPage> createState() => _ShiftsPageState();
}

class _ShiftsPageState extends State<ShiftsPage> {
  ShiftView currentView = ShiftView.weekly;
  DateTime selectedDate = DateTime.now();
  
  // Mock employees with availability
  final List<Map<String, dynamic>> employees = [
    {
      'id': 1,
      'name': 'Ahmed Ali',
      'role': 'Waiter',
      'availability': {
        'monday': ['09:00-17:00'],
        'tuesday': ['09:00-17:00'],
        'wednesday': ['09:00-17:00'],
        'thursday': ['09:00-17:00'],
        'friday': ['09:00-17:00'],
      },
    },
    {
      'id': 2,
      'name': 'Sara Mohammed',
      'role': 'Chef',
      'availability': {
        'monday': ['14:00-22:00'],
        'tuesday': ['14:00-22:00'],
        'wednesday': ['14:00-22:00'],
        'thursday': ['14:00-22:00'],
        'friday': ['14:00-22:00'],
        'saturday': ['14:00-22:00'],
      },
    },
    {
      'id': 3,
      'name': 'Omar Hassan',
      'role': 'Manager',
      'availability': {
        'monday': ['08:00-20:00'],
        'tuesday': ['08:00-20:00'],
        'wednesday': ['08:00-20:00'],
        'thursday': ['08:00-20:00'],
        'friday': ['08:00-20:00'],
        'saturday': ['08:00-16:00'],
      },
    },
  ];
  
  // Mock shifts
  List<Map<String, dynamic>> shifts = [];
  
  @override
  void initState() {
    super.initState();
    _loadMockShifts();
  }
  
  void _loadMockShifts() {
    final now = DateTime.now();
    shifts = [
      {
        'id': 1,
        'employeeId': 1,
        'employeeName': 'Ahmed Ali',
        'date': DateTime(now.year, now.month, now.day),
        'startTime': '09:00',
        'endTime': '17:00',
        'type': 'Morning Shift',
        'color': Colors.blue,
      },
      {
        'id': 2,
        'employeeId': 2,
        'employeeName': 'Sara Mohammed',
        'date': DateTime(now.year, now.month, now.day),
        'startTime': '14:00',
        'endTime': '22:00',
        'type': 'Evening Shift',
        'color': Colors.orange,
      },
    ];
  }
  
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin = authProvider.isAdmin;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Shift Management', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          _buildViewSelector(),
          if (isAdmin) ...[
            IconButton(icon: const Icon(Icons.download), onPressed: _exportSchedule, tooltip: 'Export'),
            IconButton(icon: const Icon(Icons.settings), onPressed: _openSettings, tooltip: 'Settings'),
          ],
        ],
      ),
      body: Column(
        children: [
          _buildDateNavigator(),
          Expanded(
            child: _buildCurrentView(),
          ),
        ],
      ),
      floatingActionButton: isAdmin ? _buildAddShiftFAB() : null,
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
    final todayShifts = shifts.where((s) => _isSameDay(s['date'], selectedDate)).toList();
    
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
                  Text('No shifts scheduled for today', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
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
        final dayShifts = shifts.where((s) => _isSameDay(s['date'], date)).toList();
        
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
    return Center(child: Text('Monthly Calendar View - Coming Soon', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)));
  }
  
  Widget _buildShiftCard(Map<String, dynamic> shift) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: shift['color'].withValues(alpha: 128), width: 2),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: shift['color'],
          child: Text(shift['employeeName'].substring(0, 1), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        title: Text(shift['employeeName'], style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
        subtitle: Text('${shift['type']} • ${shift['startTime']} - ${shift['endTime']}', style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color)),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert, size: 20),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Edit Shift')])),
            const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
          ],
          onSelected: (value) {
            if (value == 'edit') _editShift(shift);
            else if (value == 'delete') _deleteShift(shift);
          },
        ),
      ),
    );
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
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Shift'),
        content: const Text('Shift creation dialog will be implemented here.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Create')),
        ],
      ),
    );
  }
  
  void _editShift(Map<String, dynamic> shift) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Edit shift for ${shift['employeeName']}')));
  }
  
  void _deleteShift(Map<String, dynamic> shift) {
    setState(() => shifts.removeWhere((s) => s['id'] == shift['id']));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Shift deleted'), backgroundColor: Colors.red));
  }
  
  void _exportSchedule() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exporting schedule...')));
  }
  
  void _openSettings() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Shift settings')));
  }
}
