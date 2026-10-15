import 'package:attendance_tracker/core/network/network_info.dart';
import 'package:attendance_tracker/features/attendance/data/datasources/connectivity_network_info.dart';
import 'package:attendance_tracker/features/attendance/data/datasources/firebase_attendance_remote_data_source.dart';
import 'package:attendance_tracker/features/attendance/data/datasources/geolocator_location_data_source.dart';
import 'package:attendance_tracker/features/attendance/data/datasources/pending_attendance_store.dart';
import 'package:attendance_tracker/features/attendance/data/repositories/attendance_repository_impl.dart';
import 'package:attendance_tracker/features/attendance/data/repositories/location_repository_impl.dart';
import 'package:attendance_tracker/features/attendance/domain/usecases/check_in.dart';
import 'package:attendance_tracker/features/attendance/domain/usecases/check_out.dart';
import 'package:attendance_tracker/features/attendance/domain/usecases/get_current_location.dart';
import 'package:attendance_tracker/features/attendance/domain/usecases/get_user_history.dart';
import 'package:attendance_tracker/features/attendance/domain/usecases/sync_pending_logs.dart';
import 'package:attendance_tracker/features/auth/data/datasources/firebase_auth_remote_data_source.dart';
import 'package:attendance_tracker/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:attendance_tracker/features/auth/domain/usecases/get_signed_in_user.dart';
import 'package:attendance_tracker/features/auth/domain/usecases/register_account.dart';
import 'package:attendance_tracker/features/auth/domain/usecases/send_password_reset.dart';
import 'package:attendance_tracker/features/auth/domain/usecases/sign_in.dart';
import 'package:attendance_tracker/features/auth/domain/usecases/sign_out.dart';

final class AppDependencies {
  const AppDependencies({
    required this.signIn,
    required this.registerAccount,
    required this.sendPasswordReset,
    required this.signOut,
    required this.getSignedInUser,
    required this.checkIn,
    required this.checkOut,
    required this.getUserHistory,
    required this.getCurrentLocation,
    required this.syncPendingLogs,
    required this.networkInfo,
  });

  factory AppDependencies.firebase() {
    final authRepository = AuthRepositoryImpl(FirebaseAuthRemoteDataSource());
    final networkInfo = ConnectivityNetworkInfo();
    final attendanceRepository = AttendanceRepositoryImpl(
      remote: FirebaseAttendanceRemoteDataSource(),
      store: PendingAttendanceStore(),
      networkInfo: networkInfo,
    );
    return AppDependencies(
      signIn: SignIn(authRepository),
      registerAccount: RegisterAccount(authRepository),
      sendPasswordReset: SendPasswordReset(authRepository),
      signOut: SignOut(authRepository),
      getSignedInUser: GetSignedInUser(authRepository),
      checkIn: CheckIn(attendanceRepository),
      checkOut: CheckOut(attendanceRepository),
      getUserHistory: GetUserHistory(attendanceRepository),
      getCurrentLocation: GetCurrentLocation(
        LocationRepositoryImpl(GeolocatorLocationDataSource()),
      ),
      syncPendingLogs: SyncPendingLogs(attendanceRepository),
      networkInfo: networkInfo,
    );
  }

  final SignIn signIn;
  final RegisterAccount registerAccount;
  final SendPasswordReset sendPasswordReset;
  final SignOut signOut;
  final GetSignedInUser getSignedInUser;
  final CheckIn checkIn;
  final CheckOut checkOut;
  final GetUserHistory getUserHistory;
  final GetCurrentLocation getCurrentLocation;
  final SyncPendingLogs syncPendingLogs;
  final NetworkInfo networkInfo;
}
