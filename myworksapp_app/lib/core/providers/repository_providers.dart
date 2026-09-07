import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/repositories/admin_repository.dart';
import '../database/repositories/dispute_repository.dart';
import '../database/repositories/job_repository.dart';
import '../database/repositories/notification_repository.dart';
import '../database/repositories/payment_repository.dart';
import '../database/repositories/user_repository.dart';
import '../database/repositories/worker_repository.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

final jobRepositoryProvider = Provider<JobRepository>((ref) {
  return JobRepository();
});

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository();
});

final workerRepositoryProvider = Provider<WorkerRepository>((ref) {
  return WorkerRepository();
});

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository();
});

final disputeRepositoryProvider = Provider<DisputeRepository>((ref) {
  return DisputeRepository();
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});
