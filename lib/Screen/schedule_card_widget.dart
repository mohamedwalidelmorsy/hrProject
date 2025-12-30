import 'package:flutter/material.dart';
import '../services/api_service.dart';

// ═══════════════════════════════════════════════════════════════
// Schedule Card Widget - كارت View Schedule مع API Integration
// ═══════════════════════════════════════════════════════════════

class ScheduleCard extends StatelessWidget {
  final bool useBottomSheet; // true = BottomSheet, false = Dialog

  const ScheduleCard({
    super.key,
    this.useBottomSheet = true, // Default: BottomSheet
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (useBottomSheet) {
          _showScheduleBottomSheet(context);
        } else {
          _showScheduleDialog(context);
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today,
              color: Theme.of(context).colorScheme.onSurface,
              size: 32,
            ),
            const SizedBox(height: 16),
            Text(
              'View Schedule',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Bottom Sheet - ينزل من تحت
  // ═══════════════════════════════════════════════════════════════
  void _showScheduleBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return _ScheduleContent(
            scrollController: scrollController,
            isBottomSheet: true,
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Dialog - يظهر في النص
  // ═══════════════════════════════════════════════════════════════
  void _showScheduleDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 600),
          child: const _ScheduleContent(isBottomSheet: false),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Schedule Content Widget - المحتوى المشترك
// ═══════════════════════════════════════════════════════════════
class _ScheduleContent extends StatefulWidget {
  final ScrollController? scrollController;
  final bool isBottomSheet;

  const _ScheduleContent({this.scrollController, required this.isBottomSheet});

  @override
  State<_ScheduleContent> createState() => _ScheduleContentState();
}

class _ScheduleContentState extends State<_ScheduleContent> {
  List<dynamic> scheduleList = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final response = await ApiService.getMyCurrentShift();

    if (mounted) {
      if (response.success && response.data != null) {
        // Try to get weekly schedule
        final weeklyResponse = await ApiService.getShifts();

        if (mounted) {
          setState(() {
            if (weeklyResponse.success && weeklyResponse.data != null) {
              scheduleList =
                  weeklyResponse.data['data'] ??
                  weeklyResponse.data['schedule'] ??
                  [];
            }
            // If no weekly schedule, use current shift
            if (scheduleList.isEmpty && response.data != null) {
              scheduleList = [response.data];
            }
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = response.message;
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: widget.isBottomSheet
            ? const BorderRadius.vertical(top: Radius.circular(24))
            : BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: widget.isBottomSheet
            ? MainAxisSize.max
            : MainAxisSize.min,
        children: [
          // Handle Bar (only for bottom sheet)
          if (widget.isBottomSheet)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'My Schedule',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.refresh,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      onPressed: _loadSchedule,
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (!widget.isBottomSheet)
            Divider(color: Theme.of(context).dividerColor, height: 1),

          const SizedBox(height: 8),

          // Content
          widget.isBottomSheet
              ? Expanded(child: _buildContent())
              : Flexible(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              errorMessage!,
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSchedule,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (scheduleList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 48,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            const SizedBox(height: 16),
            Text(
              'No schedule available',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(20),
      shrinkWrap: !widget.isBottomSheet,
      itemCount: scheduleList.length,
      itemBuilder: (context, index) {
        final schedule = scheduleList[index];
        return _buildScheduleItem(schedule);
      },
    );
  }

  Widget _buildScheduleItem(Map<String, dynamic> schedule) {
    final day =
        schedule['day']?.toString() ??
        _getDayName(schedule['date']?.toString());
    final date = _formatDate(schedule['date']?.toString() ?? '');
    final shift =
        schedule['shift_name']?.toString() ??
        schedule['name']?.toString() ??
        'N/A';
    final startTime = schedule['start_time']?.toString() ?? '--';
    final endTime = schedule['end_time']?.toString() ?? '--';
    final status = _getStatus(schedule);
    final statusColor = _getStatusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    day,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 26),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 77)),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          Divider(color: Theme.of(context).dividerColor, height: 1),
          const SizedBox(height: 12),

          Row(
            children: [
              Icon(
                Icons.access_time,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                shift,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              Icon(
                Icons.schedule,
                color: Theme.of(context).textTheme.bodySmall?.color,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                '$startTime - $endTime',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),

          // Show work days if available
          if (schedule['work_days'] != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.calendar_view_week,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _formatWorkDays(schedule['work_days']),
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _getDayName(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'Unknown';
    try {
      final date = DateTime.parse(dateStr);
      final days = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];
      return days[date.weekday - 1];
    } catch (e) {
      return 'Unknown';
    }
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '';
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

  String _getStatus(Map<String, dynamic> schedule) {
    final status = schedule['status']?.toString().toLowerCase();
    if (status != null) {
      if (status == 'holiday' || status == 'off') return 'Holiday';
      if (status == 'completed') return 'Completed';
      if (status == 'active') return 'Active';
    }

    // Check by date
    final dateStr = schedule['date']?.toString();
    if (dateStr != null && dateStr.isNotEmpty) {
      try {
        final date = DateTime.parse(dateStr);
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final scheduleDate = DateTime(date.year, date.month, date.day);

        if (scheduleDate.isBefore(today)) return 'Completed';
        if (scheduleDate.isAtSameMomentAs(today)) return 'Today';
        return 'Upcoming';
      } catch (e) {
        return 'Scheduled';
      }
    }

    return 'Scheduled';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'today':
      case 'active':
        return Colors.green;
      case 'upcoming':
        return Colors.blue;
      case 'completed':
        return Colors.grey;
      case 'holiday':
        return Colors.purple;
      default:
        return Colors.orange;
    }
  }

  String _formatWorkDays(dynamic workDays) {
    if (workDays == null) return '';
    if (workDays is String) return workDays;
    if (workDays is List) {
      return workDays.join(', ');
    }
    return workDays.toString();
  }
}

// ═══════════════════════════════════════════════════════════════
// مثال على الاستخدام
// ═══════════════════════════════════════════════════════════════

/*
// في Dashboard أو أي صفحة:

// طريقة 1: Bottom Sheet (من تحت)
ScheduleCard(useBottomSheet: true)

// طريقة 2: Dialog (في النص)
ScheduleCard(useBottomSheet: false)
*/
