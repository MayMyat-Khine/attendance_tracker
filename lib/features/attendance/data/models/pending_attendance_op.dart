final class PendingAttendanceOp {
  const PendingAttendanceOp({
    required this.id,
    required this.email,
    required this.type,
    required this.date,
    required this.time,
    required this.createdAt,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String email;
  final String type;
  final String date;
  final String time;
  final int createdAt;
  final double? latitude;
  final double? longitude;

  bool get isCheckIn => type == 'checkIn';

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'email': email,
      'type': type,
      'date': date,
      'time': time,
      'createdAt': createdAt,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory PendingAttendanceOp.fromMap(Map<String, dynamic> map) {
    return PendingAttendanceOp(
      id: _string(map['id']),
      email: _string(map['email']),
      type: _string(map['type']),
      date: _string(map['date']),
      time: _string(map['time']),
      createdAt: map['createdAt'] is int ? map['createdAt'] as int : 0,
      latitude: _double(map['latitude']),
      longitude: _double(map['longitude']),
    );
  }

  static String _string(Object? value) {
    if (value is! String) {
      return '';
    }
    return value;
  }

  static double? _double(Object? value) {
    if (value is double) {
      return value;
    }
    if (value is int) {
      return value.toDouble();
    }
    return null;
  }
}
