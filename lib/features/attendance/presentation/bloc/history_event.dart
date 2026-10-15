sealed class HistoryEvent {
  const HistoryEvent();
}

final class HistoryStarted extends HistoryEvent {
  const HistoryStarted();
}

final class HistoryRefreshed extends HistoryEvent {
  const HistoryRefreshed();
}
