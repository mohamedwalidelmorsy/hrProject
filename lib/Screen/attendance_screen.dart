import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_models.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String selectedFilter = 'Daily';
  bool isCheckedIn = false;
  
  List<Map<String, dynamic>> attendanceRecords = List.generate(20, (index) => {
    'id': index,
    'name': 'Employee ${index + 1}',
    'empId': 'EMP00${index + 1}',
    'checkIn': '08:${(15 + index % 30).toString().padLeft(2, '0')} AM',
    'checkOut': '05:${(index % 60).toString().padLeft(2, '0')} PM',
    'status': index % 4 == 0 ? 'Late' : index % 4 == 1 ? 'Early' : 'On Time',
  });
  
  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
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
        actions: isAdmin ? [
          _buildExportMenu(),
          IconButton(icon: const Icon(Icons.filter_list), onPressed: () {}, tooltip: 'Filter'),
        ] : null,
      ),
      body: CustomScrollView(
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
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                  ),
                  onChanged: (value) => setState(() {}),
                ),
              ),
            ),
            // Filter Chips - على الشمال
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    children: ['Daily', 'Weekly', 'Monthly'].map((filter) {
                      final isSelected = selectedFilter == filter;
                      return ChoiceChip(
                        label: Text(filter),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() => selectedFilter = filter);
                          _refreshData();
                        },
                        selectedColor: Theme.of(context).colorScheme.primary,
                        backgroundColor: Theme.of(context).cardColor,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        side: BorderSide(
                          color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor,
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
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return isAdmin 
                      ? _buildAttendanceCard(attendanceRecords[index], index)
                      : _buildEmployeeAttendanceCard(index);
                },
                childCount: isAdmin ? attendanceRecords.length : 10,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      floatingActionButton: isAdmin ? _buildAdminFAB() : _buildEmployeeFAB(),
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
            Text('Export', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
      onSelected: (value) {
        if (value == 'pdf') _exportToPDF();
        else if (value == 'excel') _exportToExcel();
        else if (value == 'email') _sendEmail();
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'pdf', child: Row(children: [Icon(Icons.picture_as_pdf, color: Colors.red, size: 20), SizedBox(width: 12), Text('Export as PDF')])),
        const PopupMenuItem(value: 'excel', child: Row(children: [Icon(Icons.table_chart, color: Colors.green, size: 20), SizedBox(width: 12), Text('Export as Excel')])),
        const PopupMenuDivider(),
        PopupMenuItem(value: 'email', child: Row(children: [Icon(Icons.email, color: Theme.of(context).colorScheme.primary, size: 20), const SizedBox(width: 12), const Text('Send via Email')])),
      ],
    );
  }
  
  Widget _buildEmployeeQuickStatus() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(isCheckedIn ? Icons.check_circle : Icons.access_time, color: Colors.white, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isCheckedIn ? 'Checked In' : 'Not Checked In', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                Text(DateTime.now().toString().split('.')[0], style: const TextStyle(fontSize: 14, color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAttendanceCard(Map<String, dynamic> record, int index) {
    final statusColor = _getStatusColor(record['status']);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).dividerColor, width: 1.5)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(radius: 24, backgroundColor: Theme.of(context).colorScheme.primary, child: Text('E${index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(record['name'], style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(12)),
                            child: Text(record['status'], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(record['empId'], style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodySmall?.color)),
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
                _buildTimeInfo(Icons.login, 'Check In', record['checkIn'], Colors.green),
                _buildTimeInfo(Icons.logout, 'Check Out', record['checkOut'], Colors.red),
                IconButton(onPressed: () => _editAttendance(record, index), icon: Icon(Icons.edit, color: Theme.of(context).colorScheme.primary), tooltip: 'Edit'),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmployeeAttendanceCard(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).dividerColor, width: 1.5)),
      child: Row(
        children: [
          Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dec ${20 + index}, 2024', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                Text('08:15 AM - 05:30 PM', style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodySmall?.color)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(12)),
            child: const Text('Present', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTimeInfo(IconData icon, String label, String time, Color color) {
    return Column(children: [Icon(icon, color: color, size: 20), const SizedBox(height: 4), Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color)), Text(time, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface))]);
  }
  
  Widget _buildAdminFAB() => FloatingActionButton.extended(onPressed: _markAttendance, backgroundColor: Theme.of(context).colorScheme.primary, icon: const Icon(Icons.check), label: const Text('Mark Attendance'));
  Widget _buildEmployeeFAB() => FloatingActionButton.extended(onPressed: _toggleCheckIn, backgroundColor: isCheckedIn ? Colors.red : Colors.green, icon: Icon(isCheckedIn ? Icons.logout : Icons.login), label: Text(isCheckedIn ? 'Check Out' : 'Check In'));
  
  Color _getStatusColor(String status) => status == 'On Time' ? Colors.green : status == 'Late' ? Colors.orange : status == 'Early' ? Colors.blue : Colors.grey;
  void _refreshData() => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Refreshing $selectedFilter data...'), duration: const Duration(seconds: 1)));
  
  Future<void> _exportToPDF() async {
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('✅ PDF exported!'), backgroundColor: Colors.green, action: SnackBarAction(label: 'Open', textColor: Colors.white, onPressed: () {})));
  }
  
  Future<void> _exportToExcel() async {
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('✅ Excel exported!'), backgroundColor: Colors.green, action: SnackBarAction(label: 'Open', textColor: Colors.white, onPressed: () {})));
  }
  
  Future<void> _sendEmail() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Report'),
        content: TextField(decoration: const InputDecoration(labelText: 'Email', hintText: 'admin@company.com'), keyboardType: TextInputType.emailAddress),
        actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Send'))],
      ),
    );
    if (result == true && mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Email sent!'), backgroundColor: Colors.green));
  }
  
  Future<void> _markAttendance() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        String? selectedEmployee, checkInTime, checkOutTime;
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Mark Attendance'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Employee'),
                  items: attendanceRecords
                      .map<DropdownMenuItem<String>>(
                        (r) => DropdownMenuItem<String>(
                          value: r['empId'] as String,
                          child: Text(r['name'] as String),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setDialogState(() => selectedEmployee = v),
                ),                const SizedBox(height: 16),
                TextField(decoration: const InputDecoration(labelText: 'Check In'), onChanged: (v) => checkInTime = v),
                const SizedBox(height: 16),
                TextField(decoration: const InputDecoration(labelText: 'Check Out'), onChanged: (v) => checkOutTime = v),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(onPressed: () { if (selectedEmployee != null) Navigator.pop(context, {'employee': selectedEmployee!, 'checkIn': checkInTime ?? '', 'checkOut': checkOutTime ?? ''}); }, child: const Text('Save')),
            ],
          ),
        );
      },
    );
    if (result != null && mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Attendance marked!'), backgroundColor: Colors.green)); setState(() {}); }
  }
  
  Future<void> _editAttendance(Map<String, dynamic> record, int index) async {
    final checkInCtrl = TextEditingController(text: record['checkIn']), checkOutCtrl = TextEditingController(text: record['checkOut']);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit - ${record['name']}'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: checkInCtrl, decoration: const InputDecoration(labelText: 'Check In', prefixIcon: Icon(Icons.login))), const SizedBox(height: 16), TextField(controller: checkOutCtrl, decoration: const InputDecoration(labelText: 'Check Out', prefixIcon: Icon(Icons.logout)))]),
        actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save'))],
      ),
    );
    if (result == true && mounted) { setState(() { attendanceRecords[index]['checkIn'] = checkInCtrl.text; attendanceRecords[index]['checkOut'] = checkOutCtrl.text; }); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Updated!'), backgroundColor: Colors.green)); }
    checkInCtrl.dispose(); checkOutCtrl.dispose();
  }
  
  void _toggleCheckIn() {
    setState(() => isCheckedIn = !isCheckedIn);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isCheckedIn ? 'Checked in at ${TimeOfDay.now().format(context)}' : 'Checked out at ${TimeOfDay.now().format(context)}'), backgroundColor: Colors.green));
  }
}
