import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/sidebar_layout.dart';
import '../../../core/services/providers.dart';
import '../../generator/domain/content_model.dart';
import '../../scheduler/domain/schedule_model.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentsAsync = ref.watch(contentListProvider);
    final schedulesAsync = ref.watch(schedulesListProvider);
    final size = MediaQuery.of(context).size;
    final isWide = size.width >= 1100;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dashboard Header
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Admin Console',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                      ),
                    ),
                    Text(
                      DateFormat('EEE, MMM d, yyyy').format(DateTime.now()),
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Welcome back! Here is your automated publishing overview.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),

            const SizedBox(height: 36),

            // Statistics Grid (Reactive Counters)
            contentsAsync.when(
              data: (contents) {
                final scheduledCount = contents.where((c) => c.status == ContentStatus.scheduled).length;
                final publishedCount = contents.where((c) => c.status == ContentStatus.published).length;
                final failedCount = contents.where((c) => c.status == ContentStatus.failed).length;
                final totalDrafts = contents.where((c) => c.status == ContentStatus.draft).length;

                return GridView.count(
                  crossAxisCount: size.width < 600
                      ? 1
                      : size.width < 1000
                          ? 2
                          : 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.8,
                  children: [
                    _buildStatCard(
                      context,
                      'Scheduled Posts',
                      scheduledCount.toString(),
                      Icons.calendar_today_outlined,
                      AppTheme.neonPurple,
                    ),
                    _buildStatCard(
                      context,
                      'Published Posts',
                      publishedCount.toString(),
                      Icons.check_circle_outline,
                      AppTheme.neonGreen,
                    ),
                    _buildStatCard(
                      context,
                      'Failed Publishes',
                      failedCount.toString(),
                      Icons.error_outline,
                      AppTheme.neonPink,
                    ),
                    _buildStatCard(
                      context,
                      'Content Drafts',
                      totalDrafts.toString(),
                      Icons.article_outlined,
                      AppTheme.neonCyan,
                    ),
                  ],
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, stack) => Text('Error loading stats: $err', style: const TextStyle(color: AppTheme.neonPink)),
            ),
            const SizedBox(height: 32),

            // Layout split for Activity Feed vs Connect Account Status
            Flex(
              direction: isWide ? Axis.horizontal : Axis.vertical,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Upcoming Queue (Left pane)
                Expanded(
                  flex: isWide ? 2 : 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          'Upcoming Queue & Recent Logs',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      contentsAsync.when(
                        data: (contents) {
                          if (contents.isEmpty) {
                            return GlassCard(
                              padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
                              child: Center(
                                child: Column(
                                  children: [
                                    const Icon(Icons.post_add, size: 48, color: AppTheme.textSecondary),
                                    const SizedBox(height: 16),
                                    const Text('No content created yet.', style: TextStyle(fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 8),
                                    TextButton(
                                      onPressed: () => ref.read(navigationIndexProvider.notifier).state = 1,
                                      child: const Text('Generate your first post'),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          // Get active schedules to cross reference time
                          return schedulesAsync.when(
                            data: (schedules) {
                              return ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: contents.length > 5 ? 5 : contents.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 16),
                                itemBuilder: (context, index) {
                                  final item = contents[index];
                                  final sched = schedules.firstWhere((s) => s.contentId == item.id,
                                      orElse: () => ScheduleItem(
                                            id: '',
                                            contentId: '',
                                            scheduledTime: DateTime.now(),
                                            status: ContentStatus.draft,
                                          ));

                                  return _buildContentListItem(context, ref, item, sched);
                                },
                              );
                            },
                            loading: () => const CircularProgressIndicator(),
                            error: (err, _) => Text('Error loading schedules: $err'),
                          );
                        },
                        loading: () => const SizedBox(),
                        error: (err, _) => const SizedBox(),
                      ),
                    ],
                  ),
                ),

                if (isWide) const SizedBox(width: 32) else const SizedBox(height: 32),

                // Right Pane: Profile Link Status + Quick Actions
                Expanded(
                  flex: isWide ? 1 : 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          'Connection Profile',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      // Instagram Profile Status
                      _buildInstagramStatusCard(context, ref),
                      const SizedBox(height: 32),
                      
                      // Quick actions
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          'Quick Actions',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      _buildQuickActionsCard(context, ref),
                    ],
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String count,
    IconData icon,
    Color accentColor,
  ) {
    return GlassCard(
      animateHover: true,
      padding: const EdgeInsets.all(24),
      borderColor: accentColor.withOpacity(0.15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  count,
                  style: const TextStyle(
                    fontSize: 28,
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: accentColor,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentListItem(
    BuildContext context,
    WidgetRef ref,
    ContentItem item,
    ScheduleItem schedule,
  ) {
    Color badgeColor = Colors.grey;
    IconData statusIcon = Icons.drafts_outlined;

    switch (item.status) {
      case ContentStatus.draft:
        badgeColor = AppTheme.textSecondary;
        statusIcon = Icons.article_outlined;
        break;
      case ContentStatus.scheduled:
        badgeColor = AppTheme.neonPurple;
        statusIcon = Icons.schedule;
        break;
      case ContentStatus.published:
        badgeColor = AppTheme.neonGreen;
        statusIcon = Icons.check_circle;
        break;
      case ContentStatus.failed:
        badgeColor = AppTheme.neonPink;
        statusIcon = Icons.error;
        break;
    }

    final hasImage = item.mediaUrls.isNotEmpty;
    final imageUrl = hasImage ? item.mediaUrls[0] : '';

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Graphic thumbnail / preview
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 60,
              height: 60,
              color: const Color(0xFF101018),
              child: hasImage
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, _, __) => const Icon(Icons.image, color: AppTheme.textSecondary),
                    )
                  : Icon(
                      item.mediaType == MediaType.reel
                          ? Icons.video_library_outlined
                          : Icons.text_snippet_outlined,
                      color: AppTheme.textSecondary,
                    ),
            ),
          ),
          const SizedBox(width: 16),

          // Content info details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      item.mediaType.displayName,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.neonCyan,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: badgeColor.withOpacity(0.3), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 10, color: badgeColor),
                          const SizedBox(width: 4),
                          Text(
                            item.status.name.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9,
                              color: badgeColor,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item.title.isNotEmpty ? item.title : 'Untitled Post',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.status == ContentStatus.scheduled
                      ? 'Publishes: ${DateFormat('MMM d, h:mm a').format(schedule.scheduledTime)}'
                      : item.status == ContentStatus.published
                          ? 'Published successfully'
                          : item.errorMessage ?? 'No schedule set yet',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Action buttons
          if (item.status == ContentStatus.scheduled)
            IconButton(
              icon: const Icon(Icons.send_sharp, color: AppTheme.neonCyan),
              tooltip: 'Publish Now',
              onPressed: () => _triggerPublish(context, ref, item.id),
            ),
          if (item.status == ContentStatus.failed)
            IconButton(
              icon: const Icon(Icons.refresh_outlined, color: AppTheme.neonPink),
              tooltip: 'Retry Publish',
              onPressed: () => _triggerRetry(context, ref, schedule.id),
            ),
        ],
      ),
    );
  }

  Widget _buildInstagramStatusCard(BuildContext context, WidgetRef ref) {
    final accountAsync = ref.watch(instagramAccountProvider);

    return GlassCard(
      borderColor: AppTheme.neonCyan.withOpacity(0.1),
      child: accountAsync.when(
        data: (account) {
          if (!account.isConnected) {
            return Column(
              children: [
                const Icon(Icons.link_off_outlined, size: 40, color: AppTheme.neonPink),
                const SizedBox(height: 16),
                const Text(
                  'No Profile Connected',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Connect your Instagram Business Account to automate publishing.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => ref.read(navigationIndexProvider.notifier).state = 4,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.neonCyan.withOpacity(0.12),
                    foregroundColor: AppTheme.neonCyan,
                    side: const BorderSide(color: AppTheme.neonCyan),
                  ),
                  child: const Text('Connect Account'),
                ),
              ],
            );
          }

          return Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.transparent,
                    child: ClipOval(
                      child: Image.network(
                        account.profilePictureUrl,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (context, _, __) => CircleAvatar(
                          radius: 28,
                          backgroundColor: AppTheme.neonPurple.withOpacity(0.2),
                          child: const Icon(Icons.person, color: AppTheme.neonPurple),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account.pageName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          '@${account.username}',
                          style: const TextStyle(color: AppTheme.neonCyan, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppTheme.neonGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, size: 12, color: Colors.black),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Integration status', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  Text(
                    'Active',
                    style: TextStyle(fontSize: 12, color: AppTheme.neonGreen.withOpacity(0.9), fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Text('Error loading status: $err'),
      ),
    );
  }

  Widget _buildQuickActionsCard(BuildContext context, WidgetRef ref) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildActionButton(
            context,
            'Generate Content',
            Icons.auto_awesome,
            AppTheme.neonPurple,
            () => ref.read(navigationIndexProvider.notifier).state = 1,
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            context,
            'Content Calendar',
            Icons.calendar_month,
            AppTheme.neonCyan,
            () => ref.read(navigationIndexProvider.notifier).state = 2,
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            context,
            'Manage Scheduler',
            Icons.schedule,
            AppTheme.neonPink,
            () => ref.read(navigationIndexProvider.notifier).state = 3,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white.withOpacity(0.06)),
          borderRadius: BorderRadius.circular(8),
          color: Colors.white.withOpacity(0.02),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: AppTheme.textSecondary, size: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _triggerPublish(BuildContext context, WidgetRef ref, String contentId) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Publishing post to Instagram...'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    try {
      final success = await ref.read(schedulerRepositoryProvider).publishNow(contentId);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Published successfully! 🎉'),
            backgroundColor: AppTheme.neonGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Publishing failed: ${e.toString()}'),
          backgroundColor: AppTheme.neonPink,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _triggerRetry(BuildContext context, WidgetRef ref, String scheduleId) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Retrying scheduled publishing...'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    await ref.read(schedulerRepositoryProvider).retryFailedSchedule(scheduleId);
  }
}
