import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_models.dart';

class EmployeesPage extends StatefulWidget {
  const EmployeesPage({super.key});

  @override
  State<EmployeesPage> createState() => _EmployeesPageState();
}

class _EmployeesPageState extends State<EmployeesPage> {
  final TextEditingController _searchController = TextEditingController();
  String selectedDepartment = 'All';
  
  final List<String> departments = ['All', 'IT', 'HR', 'Sales', 'Finance', 'Marketing'];
  
  final List<Map<String, dynamic>> employees = List.generate(
    20,
    (index) => {
      'id': index,
      'name': 'Employee ${index + 1}',
      'empId': 'EMP00${index + 1}',
      'role': ['Software Engineer', 'HR Manager', 'Sales Lead', 'Financial Analyst', 'Marketing Specialist'][index % 5],
      'department': ['IT', 'HR', 'Sales', 'Finance', 'Marketing'][index % 5],
      'email': 'employee${index + 1}@company.com',
      'phone': '+966 50 ${(index + 1).toString().padLeft(3, '0')} ${(index + 1).toString().padLeft(4, '0')}',
      'isOnline': index % 3 == 0,
    },
  );
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin = authProvider.isAdmin;
    final screenWidth = MediaQuery.of(context).size.width;
    
    int crossAxisCount;
    double childAspectRatio;
    
    if (screenWidth < 600) {
      crossAxisCount = 2;
      childAspectRatio = 0.70;
    } else if (screenWidth < 900) {
      crossAxisCount = 3;
      childAspectRatio = 0.75;
    } else if (screenWidth < 1400) {
      crossAxisCount = 4;
      childAspectRatio = 0.80;
    } else {
      crossAxisCount = 5;
      childAspectRatio = 0.85;
    }
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          isAdmin ? 'Employees Management' : 'Team Directory',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: isAdmin ? [_buildExportMenu()] : null,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search employees...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (value) => setState(() {}),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                children: departments.map((dept) {
                  final isSelected = selectedDepartment == dept;
                  return ChoiceChip(
                    label: Text(dept == 'All' ? 'All Departments' : dept),
                    selected: isSelected,
                    onSelected: (selected) => setState(() => selectedDepartment = dept),
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
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: childAspectRatio,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildEmployeeCard(employees[index], isAdmin),
                childCount: employees.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
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
            Text('Export', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
      onSelected: (value) {
        if (value == 'pdf') _exportToPDF();
        else if (value == 'excel') _exportToExcel();
        else if (value == 'email') _sendEmail();
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'pdf', child: Row(children: [Icon(Icons.picture_as_pdf, color: Colors.red, size: 20), SizedBox(width: 12), Text('Export as PDF')])),
        PopupMenuItem(value: 'excel', child: Row(children: [Icon(Icons.table_chart, color: Colors.green, size: 20), SizedBox(width: 12), Text('Export as Excel')])),
        PopupMenuDivider(),
        PopupMenuItem(value: 'email', child: Row(children: [Icon(Icons.email, color: Colors.blue, size: 20), SizedBox(width: 12), Text('Send via Email')])),
      ],
    );
  }
  
  Widget _buildEmployeeCard(Map<String, dynamic> employee, bool isAdmin) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _viewEmployeeProfile(employee),
        onHover: (hovering) {},
        borderRadius: BorderRadius.circular(16),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).dividerColor, width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              child: Text(
                                employee['name'].toString().substring(0, 1),
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                            if (employee['isOnline'] == true)
                              Positioned(
                                right: -2,
                                bottom: -2,
                                child: Tooltip(
                                  message: 'Online',
                                  child: Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          employee['name'].toString(),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          employee['role'].toString(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            employee['department'].toString(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (isAdmin)
                  Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _editEmployee(employee),
                            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16)),
                            child: Container(
                              alignment: Alignment.center,
                              child: Icon(Icons.edit, size: 16, color: Theme.of(context).colorScheme.primary),
                            ),
                          ),
                        ),
                        Container(width: 1, color: Theme.of(context).dividerColor),
                        Expanded(
                          child: InkWell(
                            onTap: () => _deleteEmployee(employee),
                            borderRadius: const BorderRadius.only(bottomRight: Radius.circular(16)),
                            child: Container(
                              alignment: Alignment.center,
                              child: const Icon(Icons.delete, size: 16, color: Colors.red),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  void _viewEmployeeProfile(Map<String, dynamic> employee) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(employee['name'].toString().substring(0, 1), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(employee['name'].toString())),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('Employee ID', employee['empId'].toString()),
              _buildInfoRow('Role', employee['role'].toString()),
              _buildInfoRow('Department', employee['department'].toString()),
              _buildInfoRow('Email', employee['email'].toString()),
              _buildInfoRow('Phone', employee['phone'].toString()),
              _buildInfoRow('Status', employee['isOnline'] == true ? '🟢 Online' : '⚪ Offline'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
  
  Future<void> _editEmployee(Map<String, dynamic> employee) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${employee['name']}'),
        content: const Text('Edit functionality will be implemented here.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Updated!'), backgroundColor: Colors.green),
      );
    }
  }
  
  Future<void> _deleteEmployee(Map<String, dynamic> employee) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Employee'),
        content: Text('Are you sure you want to delete ${employee['name']}?'),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Deleted!'), backgroundColor: Colors.red),
      );
    }
  }
  
  Future<void> _exportToPDF() async {
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('✅ PDF exported!'),
        backgroundColor: Colors.green,
        action: SnackBarAction(label: 'Open', textColor: Colors.white, onPressed: () {}),
      ),
    );
  }
  
  Future<void> _exportToExcel() async {
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('✅ Excel exported!'),
        backgroundColor: Colors.green,
        action: SnackBarAction(label: 'Open', textColor: Colors.white, onPressed: () {}),
      ),
    );
  }
  
  Future<void> _sendEmail() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Report'),
        content: TextField(
          decoration: const InputDecoration(labelText: 'Email', hintText: 'admin@company.com'),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Send')),
        ],
      ),
    );
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Email sent!'), backgroundColor: Colors.green),
      );
    }
  }
}
