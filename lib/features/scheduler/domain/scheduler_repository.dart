import 'schedule_model.dart';
import '../../generator/domain/content_model.dart';

abstract class SchedulerRepository {
  Future<void> schedulePost(ScheduleItem schedule);
  Future<void> updateScheduleStatus(String scheduleId, ContentStatus status);
  Stream<List<ScheduleItem>> getSchedules();
  Future<void> deleteSchedule(String scheduleId);
  Future<bool> publishNow(String contentId);
  Future<void> retryFailedSchedule(String scheduleId);
}
