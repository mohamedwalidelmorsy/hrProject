import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════
// Schedule Card Widget - كارت View Schedule
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
          color: const Color(0xFF1A2332),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF2A3441)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, color: Colors.white, size: 32),
            const SizedBox(height: 16),
            Text(
              'View Schedule',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
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
          return Container(
            decoration: BoxDecoration(
              color: Color(0xFF1A2332),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Handle Bar
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'My Schedule',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Content
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildScheduleItem(
                        day: 'Saturday',
                        date: 'Dec 21, 2024',
                        shift: 'Morning Shift',
                        startTime: '08:00 AM',
                        endTime: '04:00 PM',
                        status: 'Upcoming',
                        statusColor: Colors.blue,
                      ),
                      _buildScheduleItem(
                        day: 'Sunday',
                        date: 'Dec 22, 2024',
                        shift: 'Morning Shift',
                        startTime: '08:00 AM',
                        endTime: '04:00 PM',
                        status: 'Upcoming',
                        statusColor: Colors.blue,
                      ),
                      _buildScheduleItem(
                        day: 'Monday',
                        date: 'Dec 23, 2024',
                        shift: 'Morning Shift',
                        startTime: '08:00 AM',
                        endTime: '04:00 PM',
                        status: 'Upcoming',
                        statusColor: Colors.blue,
                      ),
                      _buildScheduleItem(
                        day: 'Tuesday',
                        date: 'Dec 24, 2024',
                        shift: 'Evening Shift',
                        startTime: '04:00 PM',
                        endTime: '12:00 AM',
                        status: 'Scheduled',
                        statusColor: Colors.orange,
                      ),
                      _buildScheduleItem(
                        day: 'Wednesday',
                        date: 'Dec 25, 2024',
                        shift: 'Day Off',
                        startTime: '--',
                        endTime: '--',
                        status: 'Holiday',
                        statusColor: Colors.green,
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
        backgroundColor: const Color(0xFF1A2332),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'My Schedule',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              Divider(color: Color(0xFF2A3441), height: 1),

              // Content
              Flexible(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  shrinkWrap: true,
                  children: [
                    _buildScheduleItem(
                      day: 'Saturday',
                      date: 'Dec 21, 2024',
                      shift: 'Morning Shift',
                      startTime: '08:00 AM',
                      endTime: '04:00 PM',
                      status: 'Upcoming',
                      statusColor: Colors.blue,
                    ),
                    _buildScheduleItem(
                      day: 'Sunday',
                      date: 'Dec 22, 2024',
                      shift: 'Morning Shift',
                      startTime: '08:00 AM',
                      endTime: '04:00 PM',
                      status: 'Upcoming',
                      statusColor: Colors.blue,
                    ),
                    _buildScheduleItem(
                      day: 'Monday',
                      date: 'Dec 23, 2024',
                      shift: 'Morning Shift',
                      startTime: '08:00 AM',
                      endTime: '04:00 PM',
                      status: 'Upcoming',
                      statusColor: Colors.blue,
                    ),
                    _buildScheduleItem(
                      day: 'Tuesday',
                      date: 'Dec 24, 2024',
                      shift: 'Evening Shift',
                      startTime: '04:00 PM',
                      endTime: '12:00 AM',
                      status: 'Scheduled',
                      statusColor: Colors.orange,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Schedule Item Widget
  // ═══════════════════════════════════════════════════════════════
  Widget _buildScheduleItem({
    required String day,
    required String date,
    required String shift,
    required String startTime,
    required String endTime,
    required String status,
    required Color statusColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1419),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A3441)),
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
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date,
                    style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
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
          Divider(color: Color(0xFF2A3441), height: 1),
          const SizedBox(height: 12),

          Row(
            children: [
              Icon(Icons.access_time, color: Color(0xFF5B9FED), size: 20),
              const SizedBox(width: 8),
              Text(
                shift,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF5B9FED),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              Icon(Icons.schedule, color: Color(0xFF9CA3AF), size: 18),
              const SizedBox(width: 8),
              Text(
                '$startTime - $endTime',
                style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
              ),
            ],
          ),
        ],
      ),
    );
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
