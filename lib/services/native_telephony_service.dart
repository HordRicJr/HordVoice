import 'dart:async';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

/// Service de téléphonie natif pour HordVoice
/// Utilise les APIs Android natives via platform channels
class NativeTelephonyService {
  static final NativeTelephonyService _instance =
      NativeTelephonyService._internal();
  factory NativeTelephonyService() => _instance;
  NativeTelephonyService._internal();

  static const MethodChannel _channel = MethodChannel('hordvoice/telephony');
  final Logger _logger = Logger();

  /// Envoie un SMS via l'API native Android
  Future<bool> sendSMS(String phoneNumber, String message) async {
    try {
      final result = await _channel.invokeMethod('sendSMS', {
        'phoneNumber': phoneNumber,
        'message': message,
      });

      _logger.i('SMS envoyé avec succès: $result');
      return true;
    } catch (e) {
      _logger.e('Erreur envoi SMS: $e');
      return false;
    }
  }

  /// Initie un appel téléphonique via l'API native Android
  Future<bool> makeCall(String phoneNumber) async {
    try {
      final result = await _channel.invokeMethod('makeCall', {
        'phoneNumber': phoneNumber,
      });

      _logger.i('Appel initié: $result');
      return true;
    } catch (e) {
      _logger.e('Erreur appel: $e');
      return false;
    }
  }

  /// Récupère le journal des appels
  Future<List<CallLogEntry>> getCallLog() async {
    try {
      final result = await _channel.invokeMethod('getCallLog');

      if (result is List) {
        return result
            .map(
              (call) => CallLogEntry.fromMap(Map<String, dynamic>.from(call)),
            )
            .toList();
      }

      return [];
    } catch (e) {
      _logger.e('Erreur lecture journal appels: $e');
      return [];
    }
  }

  /// Récupère l'état du téléphone
  Future<PhoneState?> getPhoneState() async {
    try {
      final result = await _channel.invokeMethod('getPhoneState');

      if (result is Map) {
        return PhoneState.fromMap(Map<String, dynamic>.from(result));
      }

      return null;
    } catch (e) {
      _logger.e('Erreur lecture état téléphone: $e');
      return null;
    }
  }

  /// Envoie un SMS avec commande vocale
  Future<bool> sendSMSWithVoiceCommand(String contact, String message) async {
    try {
      // Ici on pourrait rechercher le contact dans la liste de contacts
      // Pour l'instant, on utilise directement le numéro
      final phoneNumber = _extractPhoneNumber(contact);
      if (phoneNumber != null) {
        return await sendSMS(phoneNumber, message);
      }
      return false;
    } catch (e) {
      _logger.e('Erreur envoi SMS vocal: $e');
      return false;
    }
  }

  /// Initie un appel avec commande vocale
  Future<bool> callWithVoiceCommand(String contact) async {
    try {
      final phoneNumber = _extractPhoneNumber(contact);
      if (phoneNumber != null) {
        return await makeCall(phoneNumber);
      }
      return false;
    } catch (e) {
      _logger.e('Erreur appel vocal: $e');
      return false;
    }
  }

  /// Extrait un numéro de téléphone d'un contact ou texte
  String? _extractPhoneNumber(String input) {
    // Regex pour détecter un numéro de téléphone
    final phoneRegex = RegExp(r'[\+]?[0-9]{8,15}');
    final match = phoneRegex.firstMatch(input);
    return match?.group(0);
  }

  /// Traite les commandes vocales de téléphonie
  Future<String> processVoiceCommand(String command) async {
    try {
      final commandLower = command.toLowerCase();

      if (commandLower.contains('appel') || commandLower.contains('appeler')) {
        // Commande d'appel
        final phoneNumber = _extractPhoneNumber(command);
        if (phoneNumber != null) {
          final success = await makeCall(phoneNumber);
          return success
              ? 'Appel en cours vers $phoneNumber'
              : 'Impossible d\'initier l\'appel';
        }
        return 'Numéro de téléphone non trouvé dans la commande';
      }

      if (commandLower.contains('sms') || commandLower.contains('message')) {
        // Commande SMS
        final parts = command.split(' ');
        if (parts.length >= 3) {
          final phoneNumber = _extractPhoneNumber(command);
          final messageStart = command.indexOf('message') + 7;
          if (phoneNumber != null && messageStart < command.length) {
            final message = command.substring(messageStart).trim();
            final success = await sendSMS(phoneNumber, message);
            return success
                ? 'SMS envoyé à $phoneNumber'
                : 'Impossible d\'envoyer le SMS';
          }
        }
        return 'Format de commande SMS incorrect';
      }

      if (commandLower.contains('journal') ||
          commandLower.contains('historique')) {
        // Récupérer l'historique des appels
        final callLog = await getCallLog();
        if (callLog.isNotEmpty) {
          final recent = callLog.take(3).map((call) => call.number).join(', ');
          return 'Derniers appels: $recent';
        }
        return 'Aucun appel dans l\'historique';
      }

      return 'Commande de téléphonie non reconnue';
    } catch (e) {
      _logger.e('Erreur traitement commande vocale: $e');
      return 'Erreur lors du traitement de la commande';
    }
  }
}

/// Modèle pour une entrée du journal des appels
class CallLogEntry {
  final String number;
  final int type; // 1=incoming, 2=outgoing, 3=missed
  final DateTime date;
  final int duration;

  CallLogEntry({
    required this.number,
    required this.type,
    required this.date,
    required this.duration,
  });

  factory CallLogEntry.fromMap(Map<String, dynamic> map) {
    return CallLogEntry(
      number: map['number'] ?? '',
      type: map['type'] ?? 0,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] ?? 0),
      duration: map['duration'] ?? 0,
    );
  }

  String get typeString {
    switch (type) {
      case 1:
        return 'Entrant';
      case 2:
        return 'Sortant';
      case 3:
        return 'Manqué';
      default:
        return 'Inconnu';
    }
  }
}

/// Modèle pour l'état du téléphone
class PhoneState {
  final int simState;
  final String networkOperatorName;
  final bool isNetworkRoaming;

  PhoneState({
    required this.simState,
    required this.networkOperatorName,
    required this.isNetworkRoaming,
  });

  factory PhoneState.fromMap(Map<String, dynamic> map) {
    return PhoneState(
      simState: map['simState'] ?? 0,
      networkOperatorName: map['networkOperatorName'] ?? '',
      isNetworkRoaming: map['isNetworkRoaming'] ?? false,
    );
  }

  String get simStateString {
    switch (simState) {
      case 1:
        return 'Absent';
      case 2:
        return 'Code PIN requis';
      case 3:
        return 'Code PUK requis';
      case 4:
        return 'Verrouillé réseau';
      case 5:
        return 'Prêt';
      case 6:
        return 'Non prêt';
      case 7:
        return 'Code PUK2 requis';
      case 8:
        return 'Code PIN2 requis';
      case 9:
        return 'Verrouillé réseau PUK';
      case 10:
        return 'Verrouillé réseau PIN';
      default:
        return 'Inconnu';
    }
  }
}
