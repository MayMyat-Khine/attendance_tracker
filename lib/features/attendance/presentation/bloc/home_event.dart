sealed class HomeEvent {
  const HomeEvent();
}

final class HomeStarted extends HomeEvent {
  const HomeStarted();
}

final class HomeResumed extends HomeEvent {
  const HomeResumed();
}

final class HomeRefreshed extends HomeEvent {
  const HomeRefreshed();
}

final class CheckInRequested extends HomeEvent {
  const CheckInRequested({this.date});

  final String? date;
}

final class CheckOutRequested extends HomeEvent {
  const CheckOutRequested();
}
