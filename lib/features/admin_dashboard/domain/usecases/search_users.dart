import 'package:attendance_tracker/core/error/result.dart';
import 'package:attendance_tracker/features/admin_dashboard/domain/entities/admin_data.dart';
import 'package:attendance_tracker/features/admin_dashboard/domain/repositories/admin_repository.dart';

final class SearchUsers {
  const SearchUsers(this._repository);
  final AdminRepository _repository;
  Future<Result<UsersPageData>> call({
    required String search,
    required bool byEmail,
    PageCursor? after,
  }) => _repository.users(
    search: search.trim().toLowerCase(),
    byEmail: byEmail,
    after: after,
  );
}
