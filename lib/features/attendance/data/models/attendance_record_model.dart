import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:attendance_tracker/features/attendance/domain/entities/attendance_record.dart';

final class AttendanceRecordModel {
  const AttendanceRecordModel({
    required this.date,
    required this.checkIn,
    required this.checkOut,
    this.checkInAt,
    this.checkOutAt,
    this.checkOutLatitude,
    this.checkOutLongitude,
    this.latitude,
    this.longitude,
    this.pendingSync = false,
  });

  final DateTime? checkInAt;
  final DateTime? checkOutAt;
  final double? checkOutLatitude;
  final double? checkOutLongitude;
  final String date;
  final String checkIn;
  final String checkOut;
  final double? latitude;
  final double? longitude;
  final bool pendingSync;

  AttendanceRecord toEntity() {
    return AttendanceRecord(
      date: date,
      checkInAt: checkInAt,
      checkOutAt: checkOutAt,
      checkOutLatitude: checkOutLatitude,
      checkOutLongitude: checkOutLongitude,
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
      checkInAt: record.checkInAt,
      checkOutAt: record.checkOutAt,
      checkOutLatitude: record.checkOutLatitude,
      checkOutLongitude: record.checkOutLongitude,
      checkIn: record.checkIn,
      checkOut: record.checkOut,
      latitude: record.latitude,
      longitude: record.longitude,
      pendingSync: record.pendingSync,
    );
  }

  factory AttendanceRecordModel.fromMap(Map<String, dynamic> map) {
    final location = map['location'];
    final outLocation = map['checkOutLocation'];
    return AttendanceRecordModel(
      date: _string(map['date']),
      checkInAt: _timestamp(map['checkInAt']),
      checkOutAt: _timestamp(map['checkOutAt']),
      checkOutLatitude: outLocation is GeoPoint
          ? outLocation.latitude
          : _double(map['checkOutLatitude']),
      checkOutLongitude: outLocation is GeoPoint
          ? outLocation.longitude
          : _double(map['checkOutLongitude']),
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
      'checkInAt': checkInAt?.toUtc().toIso8601String(),
      'checkOutAt': checkOutAt?.toUtc().toIso8601String(),
      'checkOutLatitude': checkOutLatitude,
      'checkOutLongitude': checkOutLongitude,
      'checkin': checkIn,
      'checkout': checkOut,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  static DateTime? _timestamp(Object? value) => value is Timestamp
      ? value.toDate().toUtc()
      : value is String
      ? DateTime.tryParse(value)?.toUtc()
      : null;

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
