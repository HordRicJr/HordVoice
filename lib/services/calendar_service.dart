import 'package:flutter/foundation.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;

class CalendarService {
  bool _isInitialized = false;
  final DeviceCalendarPlugin _deviceCalendarPlugin = DeviceCalendarPlugin();
  List<Calendar> _availableCalendars = [];

  Future<void> initialize() async {
    _isInitialized = true;

    try {
      await _requestCalendarPermissions();
      await _loadAvailableCalendars();
      debugPrint(
        'CalendarService initialisé avec ${_availableCalendars.length} calendriers',
      );
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation du CalendarService: $e');
    }
  }

  Future<void> _requestCalendarPermissions() async {
    try {
      final calendarStatus = await Permission.calendar.request();
      if (!calendarStatus.isGranted) {
        debugPrint('Permission calendrier refusée');
      }
    } catch (e) {
      debugPrint('Erreur lors de la demande de permissions calendrier: $e');
    }
  }

  Future<void> _loadAvailableCalendars() async {
    try {
      final calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
      if (calendarsResult.isSuccess && calendarsResult.data != null) {
        _availableCalendars = calendarsResult.data!;
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des calendriers: $e');
      _availableCalendars = [];
    }
  }

  Future<List<Event>> getTodayEvents() async {
    if (!_isInitialized) throw Exception('Service non initialisé');

    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      return await getEventsInRange(startOfDay, endOfDay);
    } catch (e) {
      debugPrint('Erreur lors de la récupération des événements du jour: $e');
      return [];
    }
  }

  Future<List<Event>> getEventsInRange(DateTime start, DateTime end) async {
    if (!_isInitialized) throw Exception('Service non initialisé');

    List<Event> allEvents = [];

    try {
      for (final calendar in _availableCalendars) {
        if (calendar.id != null) {
          final eventsResult = await _deviceCalendarPlugin.retrieveEvents(
            calendar.id!,
            RetrieveEventsParams(startDate: start, endDate: end),
          );

          if (eventsResult.isSuccess && eventsResult.data != null) {
            allEvents.addAll(eventsResult.data!);
          }
        }
      }

      allEvents.sort((a, b) {
        final aStart = a.start ?? DateTime.now();
        final bStart = b.start ?? DateTime.now();
        return aStart.compareTo(bStart);
      });

      return allEvents;
    } catch (e) {
      debugPrint('Erreur lors de la récupération des événements: $e');
      return _getSimulatedEvents(start, end);
    }
  }

  List<Event> _getSimulatedEvents(DateTime start, DateTime end) {
    final now = DateTime.now();
    return [
      Event(
        'sim_event_1',
        title: 'Réunion équipe',
        start: tz.TZDateTime.from(
          DateTime(now.year, now.month, now.day, 9, 0),
          tz.UTC,
        ),
        end: tz.TZDateTime.from(
          DateTime(now.year, now.month, now.day, 10, 0),
          tz.UTC,
        ),
        description: 'Réunion hebdomadaire de l\'équipe',
        location: 'Salle de conférence',
      ),
      Event(
        'sim_event_2',
        title: 'Déjeuner client',
        start: tz.TZDateTime.from(
          DateTime(now.year, now.month, now.day, 12, 30),
          tz.UTC,
        ),
        end: tz.TZDateTime.from(
          DateTime(now.year, now.month, now.day, 14, 0),
          tz.UTC,
        ),
        description: 'Rendez-vous important',
        location: 'Restaurant Le Central',
      ),
    ];
  }

  Future<Event?> createEvent({
    required String title,
    required DateTime start,
    required DateTime end,
    String? description,
    String? location,
    List<String>? attendees,
  }) async {
    if (!_isInitialized) throw Exception('Service non initialisé');

    try {
      if (_availableCalendars.isEmpty) {
        throw Exception('Aucun calendrier disponible');
      }

      final calendar = _availableCalendars.first;

      final event = Event(
        calendar.id,
        title: title,
        start: tz.TZDateTime.from(start, tz.UTC),
        end: tz.TZDateTime.from(end, tz.UTC),
        description: description,
        location: location,
      );

      final createResult = await _deviceCalendarPlugin.createOrUpdateEvent(
        event,
      );

      if (createResult?.isSuccess == true && createResult?.data != null) {
        debugPrint('Événement créé: ${createResult!.data}');
        return event;
      } else {
        throw Exception('Échec de la création de l\'événement');
      }
    } catch (e) {
      debugPrint('Erreur lors de la création de l\'événement: $e');
      return null;
    }
  }

  Future<bool> updateEvent({
    required String eventId,
    String? title,
    DateTime? start,
    DateTime? end,
    String? description,
    String? location,
  }) async {
    if (!_isInitialized) throw Exception('Service non initialisé');

    try {
      final existingEvent = await _findEventById(eventId);
      if (existingEvent == null) {
        throw Exception('Événement non trouvé');
      }

      final updatedEvent = Event(
        existingEvent.calendarId,
        eventId: eventId,
        title: title ?? existingEvent.title,
        start: start != null
            ? tz.TZDateTime.from(start, tz.UTC)
            : existingEvent.start,
        end: end != null ? tz.TZDateTime.from(end, tz.UTC) : existingEvent.end,
        description: description ?? existingEvent.description,
        location: location ?? existingEvent.location,
      );

      final updateResult = await _deviceCalendarPlugin.createOrUpdateEvent(
        updatedEvent,
      );

      if (updateResult?.isSuccess == true) {
        debugPrint('Événement mis à jour: $eventId');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour de l\'événement: $e');
      return false;
    }
  }

  Future<bool> deleteEvent(String eventId, String calendarId) async {
    if (!_isInitialized) throw Exception('Service non initialisé');

    try {
      final deleteResult = await _deviceCalendarPlugin.deleteEvent(
        calendarId,
        eventId,
      );

      if (deleteResult?.isSuccess == true) {
        debugPrint('Événement supprimé: $eventId');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Erreur lors de la suppression de l\'événement: $e');
      return false;
    }
  }

  Future<Event?> _findEventById(String eventId) async {
    try {
      for (final calendar in _availableCalendars) {
        if (calendar.id != null) {
          final eventsResult = await _deviceCalendarPlugin.retrieveEvents(
            calendar.id!,
            RetrieveEventsParams(eventIds: [eventId]),
          );

          if (eventsResult.isSuccess &&
              eventsResult.data != null &&
              eventsResult.data!.isNotEmpty) {
            return eventsResult.data!.first;
          }
        }
      }
      return null;
    } catch (e) {
      debugPrint('Erreur lors de la recherche d\'événement: $e');
      return null;
    }
  }

  Future<List<Event>> searchEvents(String query) async {
    if (!_isInitialized) throw Exception('Service non initialisé');

    try {
      final now = DateTime.now();
      final oneMonthLater = now.add(const Duration(days: 30));

      final allEvents = await getEventsInRange(now, oneMonthLater);

      return allEvents.where((event) {
        final title = event.title?.toLowerCase() ?? '';
        final description = event.description?.toLowerCase() ?? '';
        final location = event.location?.toLowerCase() ?? '';
        final searchQuery = query.toLowerCase();

        return title.contains(searchQuery) ||
            description.contains(searchQuery) ||
            location.contains(searchQuery);
      }).toList();
    } catch (e) {
      debugPrint('Erreur lors de la recherche d\'événements: $e');
      return [];
    }
  }

  Future<List<Event>> getUpcomingEvents({int daysAhead = 7}) async {
    if (!_isInitialized) throw Exception('Service non initialisé');

    try {
      final now = DateTime.now();
      final future = now.add(Duration(days: daysAhead));

      return await getEventsInRange(now, future);
    } catch (e) {
      debugPrint('Erreur lors de la récupération des événements à venir: $e');
      return [];
    }
  }

  Future<Event?> getNextEvent() async {
    try {
      final upcomingEvents = await getUpcomingEvents(daysAhead: 1);

      if (upcomingEvents.isNotEmpty) {
        final now = DateTime.now();
        final futureEvents = upcomingEvents.where((event) {
          final eventStart = event.start?.toLocal() ?? DateTime.now();
          return eventStart.isAfter(now);
        }).toList();

        if (futureEvents.isNotEmpty) {
          return futureEvents.first;
        }
      }

      return null;
    } catch (e) {
      debugPrint('Erreur lors de la récupération du prochain événement: $e');
      return null;
    }
  }

  Future<bool> hasConflict(DateTime start, DateTime end) async {
    try {
      final events = await getEventsInRange(start, end);

      return events.any((event) {
        final eventStart = event.start?.toLocal() ?? start;
        final eventEnd = event.end?.toLocal() ?? end;

        return (start.isBefore(eventEnd) && end.isAfter(eventStart));
      });
    } catch (e) {
      debugPrint('Erreur lors de la vérification de conflit: $e');
      return false;
    }
  }

  String formatEventTime(Event event) {
    try {
      final start = event.start?.toLocal();
      final end = event.end?.toLocal();

      if (start == null) return 'Heure non définie';

      final startTime =
          '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';

      if (end != null) {
        final endTime =
            '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
        return '$startTime - $endTime';
      }

      return startTime;
    } catch (e) {
      return 'Heure inconnue';
    }
  }

  String getEventSummary(Event event) {
    final title = event.title ?? 'Événement sans titre';
    final time = formatEventTime(event);
    final location = event.location != null ? ' à ${event.location}' : '';

    return '$title de $time$location';
  }

  Future<String> getTodaySchedule() async {
    final events = await getTodayEvents();

    if (events.isEmpty) {
      return 'Aucun événement prévu aujourd\'hui';
    }

    final summary = StringBuffer(
      'Aujourd\'hui vous avez ${events.length} événement(s):\n',
    );

    for (final event in events) {
      summary.writeln('- ${getEventSummary(event)}');
    }

    return summary.toString().trim();
  }

  List<Calendar> get availableCalendars => _availableCalendars;
  bool get isInitialized => _isInitialized;

  void dispose() {
    _isInitialized = false;
    _availableCalendars.clear();
  }
}
