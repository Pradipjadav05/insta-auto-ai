import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/services/providers.dart';
import '../../generator/domain/content_model.dart';
import '../domain/schedule_model.dart';

class SchedulerScreen extends ConsumerStatefulWidget {
  const SchedulerScreen({super.key});

  @override
  ConsumerState<SchedulerScreen> createState() => _SchedulerScreenState();
}

class _SchedulerScreenState extends ConsumerState<SchedulerScreen> {
  String _activeTab = 'all'; // all | draft | scheduled | published | failed
  String _searchQuery = '';

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
            // Screen Header
            Text(
              'Scheduler Queue',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Manage and filter queued instagram posts, draft edits, and publish logs.',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 28),

            // Controls: Tabs & Search
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF101018),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.panelBorder),
                ),
                child: Row(
                  children: ['all', 'draft', 'scheduled', 'published', 'failed']
                      .map((tab) {
                    final active = _activeTab == tab;

                    return InkWell(
                      onTap: () => setState(() => _activeTab = tab),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        margin: const EdgeInsets.only(right: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: active
                              ? AppTheme.neonPurple.withOpacity(0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          tab.toUpperCase(),
                          style: TextStyle(
                            color: active
                                ? AppTheme.textPrimary
                                : AppTheme.textSecondary,
                            fontWeight:
                            active ? FontWeight.bold : FontWeight.normal,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Search Box
            TextField(
              onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search queue by title...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                fillColor: const Color(0xFF101018),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppTheme.panelBorder),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Queue List
            Expanded(
              child: contentsAsync.when(
                data: (contents) {
                  return schedulesAsync.when(
                    data: (schedules) {
                      // Apply Filters
                      var filteredContents = contents;
                      if (_activeTab != 'all') {
                        filteredContents = contents.where((c) => c.status.name == _activeTab).toList();
                      }
                      if (_searchQuery.isNotEmpty) {
                        filteredContents = filteredContents
                            .where((c) => c.title.toLowerCase().contains(_searchQuery))
                            .toList();
                      }

                      if (filteredContents.isEmpty) {
                        return GlassCard(
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inventory_2_outlined, size: 40, color: AppTheme.textSecondary),
                                SizedBox(height: 16),
                                Text('No content found matching filter criteria.', style: TextStyle(color: AppTheme.textSecondary)),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        itemCount: filteredContents.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final item = filteredContents[index];
                          final sched = schedules.firstWhere((s) => s.contentId == item.id,
                              orElse: () => ScheduleItem(
                                    id: '',
                                    contentId: '',
                                    scheduledTime: DateTime.now(),
                                    status: ContentStatus.draft,
                                  ));

                          return _buildQueueCard(context, ref, item, sched);
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Text('Error: $err'),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Text('Error: $err'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQueueCard(BuildContext context, WidgetRef ref, ContentItem item, ScheduleItem schedule) {
    Color statusColor = Colors.grey;
    switch (item.status) {
      case ContentStatus.draft:
        statusColor = AppTheme.textSecondary;
        break;
      case ContentStatus.scheduled:
        statusColor = AppTheme.neonPurple;
        break;
      case ContentStatus.published:
        statusColor = AppTheme.neonGreen;
        break;
      case ContentStatus.failed:
        statusColor = AppTheme.neonPink;
        break;
    }

    final hasImage = item.mediaUrls.isNotEmpty;
    final imageUrl = hasImage ? item.mediaUrls[0] : '';

    return GlassCard(
      borderColor: statusColor.withOpacity(0.12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 80,
                  height: 80,
                  color: const Color(0xFF101018),
                  child: hasImage
                      ? Image.network(imageUrl, fit: BoxFit.cover)
                      : const Icon(Icons.image, color: AppTheme.textSecondary, size: 24),
                ),
              ),
              const SizedBox(width: 20),

              // Title and details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          item.mediaType.displayName,
                          style: const TextStyle(color: AppTheme.neonCyan, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        // Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: statusColor.withOpacity(0.3)),
                          ),
                          child: Text(
                            item.status.name.toUpperCase(),
                            style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.title.isNotEmpty ? item.title : 'Untitled Content',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),

              // Operations Panel
              Column(
                children: [
                  if (item.status == ContentStatus.scheduled)
                    Text(
                      DateFormat('MMM d, h:mm a').format(schedule.scheduledTime),
                      style: const TextStyle(fontSize: 12, color: AppTheme.neonPurple, fontWeight: FontWeight.bold),
                    ),
                  if (item.status == ContentStatus.published)
                    const Text(
                      'Published',
                      style: TextStyle(fontSize: 12, color: AppTheme.neonGreen, fontWeight: FontWeight.bold),
                    ),
                  if (item.status == ContentStatus.failed)
                    const Text(
                      'Publish Failed',
                      style: TextStyle(fontSize: 12, color: AppTheme.neonPink, fontWeight: FontWeight.bold),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Trigger publish now
                      if (item.status == ContentStatus.scheduled || item.status == ContentStatus.draft)
                        IconButton(
                          icon: const Icon(Icons.send_sharp, color: AppTheme.neonCyan, size: 18),
                          tooltip: 'Publish Now',
                          onPressed: () => _triggerManualPublish(context, ref, item.id),
                        ),
                      // Trigger retry
                      if (item.status == ContentStatus.failed)
                        IconButton(
                          icon: const Icon(Icons.refresh, color: AppTheme.neonCyan, size: 18),
                          tooltip: 'Retry Publish',
                          onPressed: () => ref.read(schedulerRepositoryProvider).retryFailedSchedule(schedule.id),
                        ),
                      // Trigger delete
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppTheme.neonPink, size: 18),
                        tooltip: 'Delete Post',
                        onPressed: () => _confirmDelete(context, ref, item.id, schedule.id),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          if (item.status == ContentStatus.failed && item.errorMessage != null) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppTheme.neonPink, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Error: ${item.errorMessage}',
                    style: const TextStyle(fontSize: 11, color: AppTheme.neonPink, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ]
        ],
      ),
    );
  }

  void _triggerManualPublish(BuildContext context, WidgetRef ref, String contentId) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Starting manual Instagram publish...'), behavior: SnackBarBehavior.floating),
    );
    ref.read(schedulerRepositoryProvider).publishNow(contentId).then((success) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Published successfully! 🎉'),
            backgroundColor: AppTheme.neonGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }).catchError((err) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Manual publish failed: $err'),
          backgroundColor: AppTheme.neonPink,
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String contentId, String scheduleId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF101018),
          title: const Text('Delete Post?'),
          content: const Text('This will permanently delete the generated content and remove any schedules associated with it.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                if (scheduleId.isNotEmpty) {
                  await ref.read(schedulerRepositoryProvider).deleteSchedule(scheduleId);
                }
                await ref.read(aiRepositoryProvider).deleteContent(contentId);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Content deleted successfully.')),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonPink),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
