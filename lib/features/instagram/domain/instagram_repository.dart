import 'instagram_account.dart';
import 'app_settings.dart';

abstract class InstagramRepository {
  Future<InstagramAccount> getConnectedAccount();
  Stream<InstagramAccount> watchConnectedAccount();
  Future<void> connectAccount(InstagramAccount account);
  Future<void> disconnectAccount();
  Future<AppSettings> getSettings();
  Future<void> saveSettings(AppSettings settings);
}
