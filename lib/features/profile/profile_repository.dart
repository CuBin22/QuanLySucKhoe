import 'profile.dart';

abstract class ProfileRepository {
  Future<Profile?> load();
  Future<void> save(Profile profile);
}
