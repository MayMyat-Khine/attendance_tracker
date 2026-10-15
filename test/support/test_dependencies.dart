import 'package:attendance_tracker/app_dependencies.dart';
import 'package:attendance_tracker/core/error/result.dart';
import 'package:attendance_tracker/features/admin_dashboard/domain/entities/admin_data.dart';
import 'package:attendance_tracker/features/admin_dashboard/domain/repositories/admin_repository.dart';
import 'package:attendance_tracker/features/admin_dashboard/domain/usecases/get_dashboard_summary.dart';
import 'package:attendance_tracker/features/admin_dashboard/domain/usecases/get_admin_history.dart';
import 'package:attendance_tracker/features/admin_dashboard/domain/usecases/search_users.dart';
import 'package:attendance_tracker/features/attendance/data/repositories/attendance_repository_impl.dart';
import 'package:attendance_tracker/features/attendance/domain/entities/geo_location.dart';
import 'package:attendance_tracker/features/attendance/domain/repositories/location_repository.dart';
import 'package:attendance_tracker/features/attendance/domain/usecases/check_in.dart';
import 'package:attendance_tracker/features/attendance/domain/usecases/check_out.dart';
import 'package:attendance_tracker/features/attendance/domain/usecases/get_current_location.dart';
import 'package:attendance_tracker/features/attendance/domain/usecases/get_user_history.dart';
import 'package:attendance_tracker/features/attendance/domain/usecases/sync_pending_logs.dart';
import 'package:attendance_tracker/features/auth/domain/entities/profile_image.dart';
import 'package:attendance_tracker/features/auth/domain/repositories/profile_image_repository.dart';
import 'package:attendance_tracker/features/auth/domain/usecases/pick_profile_image.dart';
import 'package:attendance_tracker/features/auth/domain/usecases/get_signed_in_user.dart';
import 'package:attendance_tracker/features/auth/domain/usecases/register_account.dart';
import 'package:attendance_tracker/features/auth/domain/usecases/send_password_reset.dart';
import 'package:attendance_tracker/features/auth/domain/usecases/sign_in.dart';
import 'package:attendance_tracker/features/auth/domain/usecases/sign_out.dart';
import 'fake_auth_repository.dart';
import 'attendance_fakes.dart';

final class FakeAdmin implements AdminRepository {
  @override
  Future<Result<DashboardSummary>> summary() async =>
      const Success(DashboardSummary(3, 1, 0));
  @override
  Future<Result<UsersPageData>> users({
    required String search,
    required bool byEmail,
    PageCursor? after,
  }) async => const Success(UsersPageData([], null));
  @override
  Future<Result<LogsPageData>> history({
    String? userId,
    required DateTime from,
    required DateTime to,
    PageCursor? after,
  }) async => const Success(LogsPageData([], null));
}

final class FakeImages implements ProfileImageRepository {
  @override
  Future<Result<ProfileImage?>> pick() async => const Success(null);
}

final class FakeLocation implements LocationRepository {
  @override
  Future<Result<GeoLocation>> currentLocation() async =>
      const Success(GeoLocation(latitude: 16, longitude: 96));
}

AppDependencies testDependencies(FakeAuthRepository auth) {
  final network = FakeNetwork();
  final repo = AttendanceRepositoryImpl(
    remote: FakeAttendanceRemote(),
    store: MemoryAttendance().createStore(),
    networkInfo: network,
    authRepository: auth,
  );
  final admin = FakeAdmin();
  return AppDependencies(
    signIn: SignIn(auth),
    registerAccount: RegisterAccount(auth),
    sendPasswordReset: SendPasswordReset(auth),
    signOut: SignOut(auth),
    getSignedInUser: GetSignedInUser(auth),
    pickProfileImage: PickProfileImage(FakeImages()),
    getDashboardSummary: GetDashboardSummary(admin),
    searchUsers: SearchUsers(admin),
    getAdminHistory: GetAdminHistory(admin),
    checkIn: CheckIn(repo),
    checkOut: CheckOut(repo),
    getUserHistory: GetUserHistory(repo),
    getCurrentLocation: GetCurrentLocation(FakeLocation()),
    syncPendingLogs: SyncPendingLogs(repo),
    networkInfo: network,
  );
}
