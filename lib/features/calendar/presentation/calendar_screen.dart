import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/services/providers.dart';
import '../../generator/domain/content_model.dart';
import '../../scheduler/domain/schedule_model.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDate = DateTime.now();
  String _currentView = 'month'; // month | week | day

  // Navigation helpers
  void _nextPeriod() {
    setState(() {
      if (_currentView == 'month') {
        _focusedDate = DateTime(_focusedDate.year, _focusedDate.month + 1, 1);
      } else if (_currentView == 'week') {
        _focusedDate = _focusedDate.add(const Duration(days: 7));
      } else {
        _focusedDate = _focusedDate.add(const Duration(days: 1));
      }
    });
  }

  void _prevPeriod() {
    setState(() {
      if (_currentView == 'month') {
        _focusedDate = DateTime(_focusedDate.year, _focusedDate.month - 1, 1);
      } else if (_currentView == 'week') {
        _focusedDate = _focusedDate.subtract(const Duration(days: 7));
      } else {
        _focusedDate = _focusedDate.subtract(const Duration(days: 1));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final contentsAsync = ref.watch(contentListProvider);
    final schedulesAsync = ref.watch(schedulesListProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header panel
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Content Calendar',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                      ),
                    ),
                    // const SizedBox(height: 4),
                    // Month/Week/Day tabs selector
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF101018),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.panelBorder),
                        ),
                        child: Row(
                          children: ['month', 'week', 'day'].map((v) {
                            final active = _currentView == v;
                            return InkWell(
                              onTap: () => setState(() => _currentView = v),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: active ? AppTheme.neonPurple.withOpacity(0.15) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  v.toUpperCase(),
                                  style: TextStyle(
                                    color: active ? AppTheme.textPrimary : AppTheme.textSecondary,
                                    fontWeight: active ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
                const Text(
                  'Monitor schedule plans, dates, and live publishing times.',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Date selector navigation controls
            Row(
              children: [
                IconButton(
                  onPressed: _prevPeriod,
                  icon: const Icon(Icons.chevron_left),
                  style: IconButton.styleFrom(backgroundColor: const Color(0xFF101018)),
                ),
                const SizedBox(width: 4),
                Text(
                  _getTitleText(),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                IconButton(
                  onPressed: _nextPeriod,
                  icon: const Icon(Icons.chevron_right),
                  style: IconButton.styleFrom(backgroundColor: const Color(0xFF101018)),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => setState(() => _focusedDate = DateTime.now()),
                  icon: const Icon(Icons.today_outlined, size: 16),
                  label: const Text('Today'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    backgroundColor: const Color(0xFF101018),
                    foregroundColor: AppTheme.textPrimary,
                    side: const BorderSide(color: AppTheme.panelBorder),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Main calendar grid/content
            Expanded(
              child: contentsAsync.when(
                data: (contents) {
                  return schedulesAsync.when(
                    data: (schedules) {
                      if (_currentView == 'month') {
                        return _buildMonthGrid(contents, schedules);
                      } else if (_currentView == 'week') {
                        return _buildWeekView(contents, schedules);
                      } else {
                        return _buildDayView(contents, schedules);
                      }
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Text('Error loading calendar: $err'),
                  );
                },
                loading: () => const SizedBox(),
                error: (err, _) => const SizedBox(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTitleText() {
    if (_currentView == 'month') {
      return DateFormat('MMMM yyyy').format(_focusedDate);
    } else if (_currentView == 'week') {
      final start = _focusedDate.subtract(Duration(days: _focusedDate.weekday - 1));
      final end = start.add(const Duration(days: 6));
      return '${DateFormat('MMM d').format(start)} - ${DateFormat('MMM d, yyyy').format(end)}';
    } else {
      return DateFormat('EEEE, MMMM d, yyyy').format(_focusedDate);
    }
  }

  // Monthly grid view generator
  Widget _buildMonthGrid(List<ContentItem> contents, List<ScheduleItem> schedules) {
    final year = _focusedDate.year;
    final month = _focusedDate.month;

    // First day of month & number of days
    final firstDayOfMonth = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final startWeekday = firstDayOfMonth.weekday; // 1 = Monday, 7 = Sunday

    // Total cells to display: prepend spaces for weekday alignment
    final totalCells = startWeekday - 1 + daysInMonth;
    final rowsCount = (totalCells / 7).ceil();

    return Column(
      children: [
        // Week headers
        Row(
          children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((day) {
            return Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                child: Text(
                  day,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary, fontSize: 13),
                ),
              ),
            );
          }).toList(),
        ),
        const Divider(),

        // Days Grid
        Expanded(
          child: GridView.builder(
            itemCount: rowsCount * 7,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisExtent: 120, // increase as needed
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              final cellDayIndex = index - (startWeekday - 2);
              final isValidDay = cellDayIndex > 0 && cellDayIndex <= daysInMonth;

              if (!isValidDay) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                );
              }

              final cellDate = DateTime(year, month, cellDayIndex);
              final isToday = cellDate.day == DateTime.now().day &&
                  cellDate.month == DateTime.now().month &&
                  cellDate.year == DateTime.now().year;

              // Filter schedules for this day
              final daySchedules = schedules.where((s) =>
                  s.scheduledTime.day == cellDate.day &&
                  s.scheduledTime.month == cellDate.month &&
                  s.scheduledTime.year == cellDate.year).toList();

              return GlassCard(
                padding: const EdgeInsets.all(8),
                borderColor: isToday ? AppTheme.neonCyan.withOpacity(0.4) : Colors.white.withOpacity(0.05),
                color: isToday ? AppTheme.neonCyan.withOpacity(0.04) : Colors.white.withOpacity(0.02),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Text(
                      cellDayIndex.toString(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isToday ? AppTheme.neonCyan : AppTheme.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: daySchedules.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 4),
                        itemBuilder: (context, sIndex) {
                          final sched = daySchedules[sIndex];
                          final item = contents.firstWhere((c) => c.id == sched.contentId,
                              orElse: () => ContentItem(
                                    id: '',
                                    title: 'Deleted Content',
                                    body: '',
                                    caption: '',
                                    hashtags: [],
                                    mediaUrls: [],
                                    mediaType: MediaType.feedPost,
                                    createdAt: DateTime.now(),
                                    status: ContentStatus.failed,
                                  ));

                          Color badgeColor = AppTheme.neonPurple;
                          if (sched.status == ContentStatus.published) {
                            badgeColor = AppTheme.neonGreen;
                          } else if (sched.status == ContentStatus.failed) {
                            badgeColor = AppTheme.neonPink;
                          }

                          return InkWell(
                            onTap: () => _showScheduleDetailDialog(context, item, sched),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: badgeColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: badgeColor.withOpacity(0.3)),
                              ),
                              child: Text(
                                '${DateFormat('h:mm a').format(sched.scheduledTime)} - ${item.title}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.w600),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Weekly view
  Widget _buildWeekView(List<ContentItem> contents, List<ScheduleItem> schedules) {
    final startOfWeek = _focusedDate.subtract(Duration(days: _focusedDate.weekday - 1));

    return Row(
      children: List.generate(7, (i) {
        final dayDate = startOfWeek.add(Duration(days: i));
        final isToday = dayDate.day == DateTime.now().day &&
            dayDate.month == DateTime.now().month &&
            dayDate.year == DateTime.now().year;

        final daySchedules = schedules.where((s) =>
            s.scheduledTime.day == dayDate.day &&
            s.scheduledTime.month == dayDate.month &&
            s.scheduledTime.year == dayDate.year).toList();

        return Expanded(
          child: GlassCard(
            margin: const EdgeInsets.symmetric(horizontal: 4.0),
            padding: const EdgeInsets.all(12),
            borderColor: isToday ? AppTheme.neonPurple.withOpacity(0.3) : Colors.white.withOpacity(0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEE d').format(dayDate),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isToday ? AppTheme.neonPurple : AppTheme.textPrimary,
                  ),
                ),
                const Divider(),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.separated(
                    itemCount: daySchedules.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, idx) {
                      final sched = daySchedules[idx];
                      final item = contents.firstWhere((c) => c.id == sched.contentId);

                      Color accentColor = AppTheme.neonPurple;
                      if (sched.status == ContentStatus.published) {
                        accentColor = AppTheme.neonGreen;
                      } else if (sched.status == ContentStatus.failed) {
                        accentColor = AppTheme.neonPink;
                      }

                      return InkWell(
                        onTap: () => _showScheduleDetailDialog(context, item, sched),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF101018),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: accentColor.withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormat('h:mm a').format(sched.scheduledTime),
                                style: TextStyle(fontSize: 10, color: accentColor, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  // Daily timeline list
  Widget _buildDayView(List<ContentItem> contents, List<ScheduleItem> schedules) {
    final daySchedules = schedules.where((s) =>
        s.scheduledTime.day == _focusedDate.day &&
        s.focusedDateMonthMatch(s, _focusedDate) &&
        s.scheduledTime.year == _focusedDate.year).toList();

    if (daySchedules.isEmpty) {
      return GlassCard(
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_month_outlined, size: 48, color: AppTheme.textSecondary),
              SizedBox(height: 16),
              Text('No content scheduled for this date.', style: TextStyle(color: AppTheme.textSecondary)),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: daySchedules.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, idx) {
        final sched = daySchedules[idx];
        final item = contents.firstWhere((c) => c.id == sched.contentId);
        
        Color badgeColor = AppTheme.neonPurple;
        if (sched.status == ContentStatus.published) {
          badgeColor = AppTheme.neonGreen;
        } else if (sched.status == ContentStatus.failed) {
          badgeColor = AppTheme.neonPink;
        }

        return GlassCard(
          padding: const EdgeInsets.all(16),
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Container(
                width: 50,
                height: 50,
                color: const Color(0xFF101018),
                child: item.mediaUrls.isNotEmpty
                    ? Image.network(item.mediaUrls[0], fit: BoxFit.cover)
                    : const Icon(Icons.image, size: 20),
              ),
            ),
            title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Format: ${item.mediaType.displayName} • Scheduled for ${DateFormat('h:mm a').format(sched.scheduledTime)}'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: badgeColor.withOpacity(0.3)),
              ),
              child: Text(
                sched.status.name.toUpperCase(),
                style: TextStyle(color: badgeColor, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
            onTap: () => _showScheduleDetailDialog(context, item, sched),
          ),
        );
      },
    );
  }

  // Opens schedule detail card dialog

  void _showScheduleDetailDialog(BuildContext context, ContentItem item, ScheduleItem schedule) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF101018),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(
              color: AppTheme.panelBorder,
            ),
          ),

          title: Text(
            item.title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Content Image
                  if (item.mediaUrls.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        item.mediaUrls.first,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (
                            context,
                            error,
                            stackTrace,
                            ) {
                          return Container(
                            height: 180,
                            alignment: Alignment.center,
                            color: Colors.grey.shade900,
                            child: const Icon(
                              Icons.broken_image,
                              color: Colors.white54,
                              size: 40,
                            ),
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 16),

                  /// Format
                  Text(
                    'Format: ${item.mediaType.displayName}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.neonCyan,
                    ),
                  ),

                  const SizedBox(height: 8),

                  /// Caption
                  Text(
                    item.caption,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 12),

                  /// Hashtags
                  if (item.hashtags.isNotEmpty)
                    Text(
                      item.hashtags.join(' '),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.neonPurple,
                      ),
                    ),

                  const Divider(height: 24),

                  /// Status
                  Text(
                    'Schedule Status: ${schedule.status.name.toUpperCase()}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: schedule.status == ContentStatus.published
                          ? AppTheme.neonGreen
                          : schedule.status == ContentStatus.failed
                          ? AppTheme.neonPink
                          : AppTheme.neonPurple,
                    ),
                  ),

                  const SizedBox(height: 8),

                  /// Schedule Time
                  Text(
                    'Scheduled Time: ${DateFormat('MMMM d, yyyy • h:mm a').format(schedule.scheduledTime)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Close'),
            ),

            if (schedule.status != ContentStatus.published)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.neonCyan,
                  foregroundColor: Colors.black,
                ),
                onPressed: () async {
                  Navigator.of(dialogContext).pop();

                  try {
                    await ref
                        .read(schedulerRepositoryProvider)
                        .publishNow(item.id);

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Publishing content...'),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Failed to publish: $e',
                          ),
                        ),
                      );
                    }
                  }
                },
                child: const Text('Publish Now'),
              ),
          ],
        );
      },
    );
  }
}

// Inline helper for match
extension ScheduleItemExtension on ScheduleItem {
  bool focusedDateMonthMatch(ScheduleItem item, DateTime target) {
    return item.scheduledTime.month == target.month;
  }
}
