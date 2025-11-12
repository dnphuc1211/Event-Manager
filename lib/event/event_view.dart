import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import '../l10n/app_localizations.dart';
import 'event_model.dart';
import 'event_service.dart';
import 'event_data_source.dart';
import 'event_detail_view.dart';

class EventView extends StatefulWidget {
  final VoidCallback? onToggleTheme; //  Thêm callback đổi theme

  const EventView({super.key, this.onToggleTheme});

  @override
  State<EventView> createState() => _EventViewState();
}

class _EventViewState extends State<EventView> {
  final eventService = EventService();

  // Danh sách sự kiện gốc
  List<EventModel> masterEventList = [];

  // DataSource cố định
  late EventDataSource _dataSource;

  // Trạng thái tìm kiếm
  bool isSearching = false;
  final searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  final calendarController = CalendarController();

  @override
  void initState() {
    super.initState();
    _dataSource = EventDataSource([]);
    calendarController.view = CalendarView.day;
    loadEvents();
    searchController.addListener(_filterEvents);
  }

  @override
  void dispose() {
    searchController.removeListener(_filterEvents);
    searchController.dispose();
    _searchFocusNode.dispose();
    calendarController.dispose();
    super.dispose();
  }

  Future<void> loadEvents() async {
    final events = await eventService.getAllEvents();
    masterEventList = events;
    _filterEvents();
  }

  void _filterEvents() {
    final query = searchController.text.toLowerCase();

    final List<EventModel> filteredList = query.isEmpty
        ? List<EventModel>.from(masterEventList)
        : masterEventList.where((event) {
            final subjectLower = event.subject.toLowerCase();
            final notesLower = event.notes?.toLowerCase() ?? '';
            return subjectLower.contains(query) || notesLower.contains(query);
          }).toList();

    _dataSource.appointments = List<EventModel>.from(filteredList);
    _dataSource.notifyListeners(
        CalendarDataSourceAction.reset, _dataSource.appointments!);
    setState(() {});
  }

  Widget _buildSearchIcon(BuildContext context) {
    return IconButton(
      icon: Icon(isSearching ? Icons.close : Icons.search),
      onPressed: () {
        setState(() {
          isSearching = !isSearching;
          if (!isSearching) {
            searchController.clear();
          } else {
            Future.delayed(const Duration(milliseconds: 50), () {
              _searchFocusNode.requestFocus();
            });
          }
        });
      },
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return TextField(
      controller: searchController,
      focusNode: _searchFocusNode,
      decoration: InputDecoration(
        hintText: 'Tìm theo tên hoặc ghi chú...',
        border: InputBorder.none,
        hintStyle: TextStyle(
          color: Theme.of(context)
              .appBarTheme
              .foregroundColor
              ?.withValues(alpha: 0.7),
        ),
      ),
      style: TextStyle(
        color: Theme.of(context).appBarTheme.foregroundColor,
        fontSize: 18,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final al = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: isSearching ? _buildSearchField(context) : Text(al.appTitle),
        actions: [
          _buildSearchIcon(context),
          IconButton(
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
            tooltip: isDarkMode ? 'Chuyển sang chế độ sáng' : 'Chuyển sang tối',
            onPressed: widget.onToggleTheme, //  Gọi hàm đổi theme từ main
          ),
          PopupMenuButton<CalendarView>(
            onSelected: (value) {
              setState(() {
                calendarController.view = value;
              });
            },
            itemBuilder: (context) => CalendarView.values.map((view) {
              return PopupMenuItem<CalendarView>(
                value: view,
                child: ListTile(title: Text(view.name)),
              );
            }).toList(),
            icon: getCalendarViewIcon(calendarController.view!),
          ),
          IconButton(
            onPressed: () {
              calendarController.displayDate = DateTime.now();
            },
            icon: const Icon(Icons.today_outlined),
          ),
          IconButton(onPressed: loadEvents, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: SfCalendar(
        controller: calendarController,
        dataSource: _dataSource,
        monthViewSettings: const MonthViewSettings(
          appointmentDisplayMode: MonthAppointmentDisplayMode.appointment,
        ),
        onLongPress: (details) {
          if (details.targetElement == CalendarElement.calendarCell) {
            final newEvent = EventModel(
              startTime: details.date!,
              endTime: details.date!.add(const Duration(hours: 1)),
              subject: 'Sự kiện mới',
            );
            Navigator.of(context)
                .push(MaterialPageRoute(
              builder: (context) => EventDetailView(event: newEvent),
            ))
                .then((value) async {
              if (value == true) await loadEvents();
            });
          }
        },
        onTap: (details) {
          if (details.targetElement == CalendarElement.appointment) {
            final EventModel event = details.appointments!.first;
            final eventToEdit = masterEventList.firstWhere(
              (e) => e.id == event.id,
              orElse: () => event,
            );
            Navigator.of(context)
                .push(MaterialPageRoute(
              builder: (context) => EventDetailView(event: eventToEdit),
            ))
                .then((value) async {
              if (value == true) await loadEvents();
            });
          }
        },
      ),
    );
  }

  Icon getCalendarViewIcon(CalendarView view) {
    switch (view) {
      case CalendarView.day:
        return const Icon(Icons.calendar_view_day_outlined);
      case CalendarView.week:
        return const Icon(Icons.calendar_view_week_outlined);
      case CalendarView.workWeek:
        return const Icon(Icons.work_history_outlined);
      case CalendarView.month:
        return const Icon(Icons.calendar_view_month_outlined);
      case CalendarView.schedule:
        return const Icon(Icons.schedule_outlined);
      default:
        return const Icon(Icons.calendar_today_outlined);
    }
  }
}
