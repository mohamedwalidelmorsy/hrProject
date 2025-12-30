import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_models.dart';
import '../services/api_service.dart';

class EmployeesPage extends StatefulWidget {
  const EmployeesPage({super.key});

  @override
  State<EmployeesPage> createState() => _EmployeesPageState();
}

class _EmployeesPageState extends State<EmployeesPage> {
  final TextEditingController _searchController = TextEditingController();
  String selectedDepartment = 'All';

  // State Variables
  List<dynamic> employees = [];
  List<String> departments = ['All'];
  bool isLoading = true;
  bool isLoadingMore = false;
  String? errorMessage;
  int currentPage = 1;
  int totalPages = 1;

  @override
  void initState() {
    super.initState();
    _loadDepartments();
    _loadEmployees();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDepartments() async {
    final response = await ApiService.getDepartments();
    if (mounted && response.success && response.data != null) {
      setState(() {
        final deptList = response.data['departments'] as List? ?? [];
        departments = ['All', ...deptList.map((d) => d.toString())];
      });
    }
  }

  Future<void> _loadEmployees({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        currentPage = 1;
        isLoading = true;
        errorMessage = null;
      });
    }

    final response = await ApiService.getEmployees(
      page: currentPage,
      perPage: 20,
      search: _searchController.text.isNotEmpty ? _searchController.text : null,
      department: selectedDepartment != 'All' ? selectedDepartment : null,
    );

    if (mounted) {
      setState(() {
        isLoading = false;
        isLoadingMore = false;
        if (response.success && response.data != null) {
          if (refresh || currentPage == 1) {
            employees = response.data['data'] ?? [];
          } else {
            employees.addAll(response.data['data'] ?? []);
          }
          totalPages = response.data['meta']?['last_page'] ?? 1;
        } else {
          errorMessage = response.message;
        }
      });
    }
  }

  Future<void> _loadMoreEmployees() async {
    if (isLoadingMore || currentPage >= totalPages) return;

    setState(() {
      isLoadingMore = true;
      currentPage++;
    });

    await _loadEmployees();
  }

  void _onSearchChanged(String value) {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchController.text == value) {
        _loadEmployees(refresh: true);
      }
    });
  }

  void _onDepartmentChanged(String dept) {
    setState(() {
      selectedDepartment = dept;
    });
    _loadEmployees(refresh: true);
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
      body: RefreshIndicator(
        onRefresh: () => _loadEmployees(refresh: true),
        child: CustomScrollView(
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
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: _onSearchChanged,
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
                      onSelected: (selected) => _onDepartmentChanged(dept),
                      selectedColor: Theme.of(context).colorScheme.primary,
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
            if (isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (errorMessage != null)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      Text(errorMessage!, style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _loadEmployees(refresh: true),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else if (employees.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No employees found',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: childAspectRatio,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    if (index == employees.length - 1 &&
                        currentPage < totalPages) {
                      _loadMoreEmployees();
                    }
                    return _buildEmployeeCard(employees[index], isAdmin);
                  }, childCount: employees.length),
                ),
              ),
              if (isLoadingMore)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: _addEmployee,
              child: const Icon(Icons.add),
            )
          : null,
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
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: 'pdf',
          child: Row(
            children: [
              Icon(Icons.picture_as_pdf, color: Colors.red, size: 20),
              SizedBox(width: 12),
              Text('Export as PDF'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'excel',
          child: Row(
            children: [
              Icon(Icons.table_chart, color: Colors.green, size: 20),
              SizedBox(width: 12),
              Text('Export as Excel'),
            ],
          ),
        ),
        PopupMenuDivider(),
        PopupMenuItem(
          value: 'email',
          child: Row(
            children: [
              Icon(Icons.email, color: Colors.blue, size: 20),
              SizedBox(width: 12),
              Text('Send via Email'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmployeeCard(Map<String, dynamic> employee, bool isAdmin) {
    final name = employee['name']?.toString() ?? 'Unknown';
    final role =
        employee['position']?.toString() ??
        employee['role']?.toString() ??
        'N/A';
    final department = employee['department']?.toString() ?? 'N/A';
    final isOnline =
        employee['is_online'] == true || employee['status'] == 'active';

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
              border: Border.all(
                color: Theme.of(context).dividerColor,
                width: 1.5,
              ),
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
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              backgroundImage: employee['avatar'] != null
                                  ? NetworkImage(employee['avatar'])
                                  : null,
                              child: employee['avatar'] == null
                                  ? Text(
                                      name.isNotEmpty
                                          ? name.substring(0, 1).toUpperCase()
                                          : 'U',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    )
                                  : null,
                            ),
                            if (isOnline)
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
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          name,
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
                          role,
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            department,
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
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _editEmployee(employee),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(16),
                            ),
                            child: Container(
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.edit,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: 1,
                          color: Theme.of(context).dividerColor,
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () => _deleteEmployee(employee),
                            borderRadius: const BorderRadius.only(
                              bottomRight: Radius.circular(16),
                            ),
                            child: Container(
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.delete,
                                size: 16,
                                color: Colors.red,
                              ),
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
    final name = employee['name']?.toString() ?? 'Unknown';
    final empId =
        employee['emp_id']?.toString() ?? employee['id']?.toString() ?? 'N/A';
    final role =
        employee['position']?.toString() ??
        employee['role']?.toString() ??
        'N/A';
    final department = employee['department']?.toString() ?? 'N/A';
    final email = employee['email']?.toString() ?? 'N/A';
    final phone = employee['phone']?.toString() ?? 'N/A';
    final isOnline =
        employee['is_online'] == true || employee['status'] == 'active';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              backgroundImage: employee['avatar'] != null
                  ? NetworkImage(employee['avatar'])
                  : null,
              child: employee['avatar'] == null
                  ? Text(
                      name.isNotEmpty
                          ? name.substring(0, 1).toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(name)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('Employee ID', empId),
              _buildInfoRow('Role', role),
              _buildInfoRow('Department', department),
              _buildInfoRow('Email', email),
              _buildInfoRow('Phone', phone),
              _buildInfoRow('Status', isOnline ? '🟢 Online' : '⚪ Offline'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
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
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Future<void> _addEmployee() async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    String selectedDept = departments.length > 1 ? departments[1] : 'IT';
    String selectedPosition = 'Employee';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Employee'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedDept,
                decoration: const InputDecoration(labelText: 'Department'),
                items: departments.where((d) => d != 'All').map((d) {
                  return DropdownMenuItem(value: d, child: Text(d));
                }).toList(),
                onChanged: (value) => selectedDept = value ?? selectedDept,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      final response = await ApiService.createEmployee(
        name: nameController.text,
        email: emailController.text,
        phone: phoneController.text,
        department: selectedDept,
        position: selectedPosition,
        hireDate: DateTime.now().toIso8601String().split('T')[0],
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response.success
                  ? '✅ Employee added!'
                  : response.message ?? 'Failed',
            ),
            backgroundColor: response.success ? Colors.green : Colors.red,
          ),
        );
        if (response.success) _loadEmployees(refresh: true);
      }
    }
  }

  Future<void> _editEmployee(Map<String, dynamic> employee) async {
    final nameController = TextEditingController(
      text: employee['name']?.toString() ?? '',
    );
    final emailController = TextEditingController(
      text: employee['email']?.toString() ?? '',
    );
    final phoneController = TextEditingController(
      text: employee['phone']?.toString() ?? '',
    );
    String selectedDept = employee['department']?.toString() ?? 'IT';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${employee['name']}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: departments.contains(selectedDept) ? selectedDept : null,
                decoration: const InputDecoration(labelText: 'Department'),
                items: departments.where((d) => d != 'All').map((d) {
                  return DropdownMenuItem(value: d, child: Text(d));
                }).toList(),
                onChanged: (value) => selectedDept = value ?? selectedDept,
              ),
            ],
          ),
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
      final response = await ApiService.updateEmployee(
        employeeId: employee['id'],
        name: nameController.text,
        email: emailController.text,
        phone: phoneController.text,
        department: selectedDept,
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
        if (response.success) _loadEmployees(refresh: true);
      }
    }
  }

  Future<void> _deleteEmployee(Map<String, dynamic> employee) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Employee'),
        content: Text('Are you sure you want to delete ${employee['name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final response = await ApiService.deleteEmployee(employee['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response.success ? '✅ Deleted!' : response.message ?? 'Failed',
            ),
            backgroundColor: response.success ? Colors.green : Colors.red,
          ),
        );
        if (response.success) _loadEmployees(refresh: true);
      }
    }
  }

  Future<void> _exportToPDF() async {
    final response = await ApiService.exportReportPdf(
      reportType: 'employees',
      startDate: DateTime.now()
          .subtract(const Duration(days: 365))
          .toIso8601String()
          .split('T')[0],
      endDate: DateTime.now().toIso8601String().split('T')[0],
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          response.success ? '✅ PDF exported!' : response.message ?? 'Failed',
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

  Future<void> _exportToExcel() async {
    final response = await ApiService.exportReportExcel(
      reportType: 'employees',
      startDate: DateTime.now()
          .subtract(const Duration(days: 365))
          .toIso8601String()
          .split('T')[0],
      endDate: DateTime.now().toIso8601String().split('T')[0],
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          response.success ? '✅ Excel exported!' : response.message ?? 'Failed',
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

  Future<void> _sendEmail() async {
    final emailController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Report'),
        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(
            labelText: 'Email',
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

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Email sent!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
