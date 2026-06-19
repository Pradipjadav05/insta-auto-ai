import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/domain/auth_repository.dart';
import '../../features/auth/data/auth_repository_impl.dart';
import '../../features/generator/domain/ai_repository.dart';
import '../../features/generator/data/ai_repository_impl.dart';
import '../../features/generator/domain/content_model.dart';
import '../../features/scheduler/domain/schedule_model.dart';
import '../../features/scheduler/domain/scheduler_repository.dart';
import '../../features/scheduler/data/scheduler_repository_impl.dart';
import '../../features/instagram/domain/instagram_account.dart';
import '../../features/instagram/domain/instagram_repository.dart';
import '../../features/instagram/data/instagram_repository_impl.dart';

// Repositories
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl();
});

final aiRepositoryProvider = Provider<AIRepository>((ref) {
  return AIRepositoryImpl();
});

final schedulerRepositoryProvider = Provider<SchedulerRepository>((ref) {
  return SchedulerRepositoryImpl();
});

final instagramRepositoryProvider = Provider<InstagramRepository>((ref) {
  return InstagramRepositoryImpl();
});

// Streams
final contentListProvider = StreamProvider<List<ContentItem>>((ref) {
  return ref.watch(aiRepositoryProvider).getContentList();
});

final schedulesListProvider = StreamProvider<List<ScheduleItem>>((ref) {
  return ref.watch(schedulerRepositoryProvider).getSchedules();
});

final instagramAccountProvider = StreamProvider<InstagramAccount>((ref) {
  return ref.watch(instagramRepositoryProvider).watchConnectedAccount();
});
