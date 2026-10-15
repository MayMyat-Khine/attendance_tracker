import 'package:attendance_tracker/core/error/result.dart';
import 'package:attendance_tracker/core/error/failure.dart';
import 'package:attendance_tracker/features/admin_dashboard/domain/entities/admin_data.dart';
import 'package:attendance_tracker/features/admin_dashboard/domain/repositories/admin_repository.dart';

final class GetAdminHistory {
  const GetAdminHistory(this._repository);
  final AdminRepository _repository;
  Future<Result<LogsPageData>> call({
    String? userId,
    required DateTime from,
    required DateTime to,
    PageCursor? after,
  }) {
    final start = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day);
    if (end.isBefore(start)) {
      return Future.value(
        const ResultFailure(
          ValidationFailure('Choose an end date on or after the start date.'),
        ),
      );
    }
    return _repository.history(
      userId: userId,
      from: start,
      to: end,
      after: after,
    );
  }
}
