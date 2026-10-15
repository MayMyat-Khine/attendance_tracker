import 'package:attendance_tracker/core/error/result.dart';
import 'package:attendance_tracker/features/admin_dashboard/domain/entities/admin_data.dart';

abstract class AdminRepository {
  Future<Result<DashboardSummary>> summary();
  Future<Result<UsersPageData>> users({
    required String search,
    required bool byEmail,
    PageCursor? after,
  });
  Future<Result<LogsPageData>> history({
    String? userId,
    required DateTime from,
    required DateTime to,
    PageCursor? after,
  });
}
