import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:attendance_tracker/features/attendance/domain/entities/attendance_record.dart';

final class AttendanceRecordModel {
  const AttendanceRecordModel({
    required this.date,
    required this.checkIn,
    required this.checkOut,
    this.latitude,
    this.longitude,
    this.pendingSync = false,
  });

  final String date;
  final String checkIn;
  final String checkOut;
  final double? latitude;
  final double? longitude;
  final bool pendingSync;

  AttendanceRecord toEntity() {
    return AttendanceRecord(
      date: date,
      checkIn: checkIn,
      checkOut: checkOut,
      latitude: latitude,
      longitude: longitude,
      pendingSync: pendingSync,
    );
  }

  factory AttendanceRecordModel.fromEntity(AttendanceRecord record) {
    return AttendanceRecordModel(
      date: record.date,
      checkIn: record.checkIn,
      checkOut: record.checkOut,
      latitude: record.latitude,
      longitude: record.longitude,
      pendingSync: record.pendingSync,
    );
  }

  factory AttendanceRecordModel.fromMap(Map<String, dynamic> map) {
    final location = map['location'];
    return AttendanceRecordModel(
      date: _string(map['date']),
      checkIn: _string(map['checkin']),
      checkOut: _string(map['checkout']),
      latitude: location is GeoPoint
          ? location.latitude
          : _double(map['latitude']),
      longitude: location is GeoPoint
          ? location.longitude
          : _double(map['longitude']),
    );
  }

  Map<String, Object?> toCacheMap() {
    return <String, Object?>{
      'date': date,
      'checkin': checkIn,
      'checkout': checkOut,
      'latitude': latitude,
      'longitude': longitude,
    };
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
