import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/repositories/admin_repository.dart';
import '../database/repositories/job_repository.dart';
import '../database/repositories/user_repository.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

final jobRepositoryProvider = Provider<JobRepository>((ref) {
  return JobRepository();
});

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository();
});
