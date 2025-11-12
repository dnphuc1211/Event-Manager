import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'event_model.dart';

class EventDataSource extends CalendarDataSource {
  EventDataSource(List<EventModel> source) {
    appointments = source;
  }

  EventModel _getEvent(int index) => appointments![index] as EventModel;

  @override
  DateTime getStartTime(int index) => _getEvent(index).startTime;

  @override
  DateTime getEndTime(int index) => _getEvent(index).endTime;

  @override
  String getSubject(int index) => _getEvent(index).subject;

  @override
  String? getNotes(int index) => _getEvent(index).notes;

  @override
  bool isAllDay(int index) => _getEvent(index).isAllDay;

  @override
  String? getRecurrenceRule(int index) => _getEvent(index).recurrenceRule;

  @override
  Color getColor(int index) {
    final event = _getEvent(index);
    // Ưu tiên màu từ model, nếu không có thì dùng mặc định
    return event.isAllDay
      ? const Color(0xFF0F8644)
      : const Color(0xFF1565C0);
  }
}
