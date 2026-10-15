import 'package:attendance_tracker/core/error/result.dart';
import 'package:attendance_tracker/features/admin_dashboard/domain/entities/admin_data.dart';
import 'package:attendance_tracker/features/admin_dashboard/domain/repositories/admin_repository.dart';

final class GetDashboardSummary {
  const GetDashboardSummary(this._repository);
  final AdminRepository _repository;
  Future<Result<DashboardSummary>> call() => _repository.summary();
}
