library busdeskpro.globals;

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

String MandantAuth = "";
String PhoneNumberAuth = "";
String AuthCode = "";
String GoogleKey = "AIzaSyDjIyOeJktq5NohQimw-EPbirdPQwfOfHg";
String AppVersion = "3.0.9";
String AppVersionDashed = "3-0-9";
String? AppUserId = "";
var GblTenant = null;

List<dynamic> AllToursGbl = [];
List<dynamic> FilteredToursGbl = [];
List<bool> ExpandedToursGbl = [];
bool cacheTourList = false;
bool isLoading = true;
String loadingText = '';
List<dynamic> GblStops = [];
String TourNameGbl = '';
var CurrentTourData = null; // Speichert die kompletten Tour-Daten
List<dynamic> ArrivalTimesReal = [];

var GlobalMapView = null;
var GlobalMapController = null;
var currentStoppIndex = 1;

var GblBusQR = '';
var GblMaterialQR = '';

int newsCount = 0;

var currentPosition = null;

var test2 = 'test';

var hereSDKInit = false;

var routeWaypointController;

String statusMessageGbl = "";
String verificationCodeGbl = "";

List<String> bufferOfLogTimesSend = [];
List<String> bufferOfLogTimesNotSend = [];
bool isConnectedToInternet = false;

bool isAndroidAutoConnected = false;

// Speichert durchgeführte Abfahrtskontrollen: Key = "YYYY-MM-DD_Kennzeichen", Value = DateTime der Kontrolle
Map<String, DateTime> completedBeforeDriveChecks = {};

// Hilfsfunktion: Prüft ob heute bereits eine Abfahrtskontrolle für ein Fahrzeug durchgeführt wurde
bool hasCompletedBeforeDriveCheckToday(String? vehicleLicensePlate) {
  if (vehicleLicensePlate == null || vehicleLicensePlate.isEmpty) return false;
  
  final today = DateTime.now();
  final todayKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}_$vehicleLicensePlate';
  
  return completedBeforeDriveChecks.containsKey(todayKey);
}

// Hilfsfunktion: Speichert eine durchgeführte Abfahrtskontrolle (persistent)
Future<void> saveCompletedBeforeDriveCheck(String? vehicleLicensePlate) async {
  if (vehicleLicensePlate == null || vehicleLicensePlate.isEmpty) return;
  
  final today = DateTime.now();
  final todayKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}_$vehicleLicensePlate';
  
  completedBeforeDriveChecks[todayKey] = DateTime.now();
  
  // Persistent speichern mit SharedPreferences
  await _saveBeforeDriveChecksToStorage();
}

// Speichert die Abfahrtskontrollen in SharedPreferences
Future<void> _saveBeforeDriveChecksToStorage() async {
  try {
    final prefs = await SharedPreferencesAsync();
    
    // Konvertiere Map zu JSON-String (nur heutige Einträge behalten)
    final today = DateTime.now();
    final todayPrefix = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    
    // Filtere nur heutige Einträge
    final todayChecks = <String, String>{};
    completedBeforeDriveChecks.forEach((key, value) {
      if (key.startsWith(todayPrefix)) {
        todayChecks[key] = value.toIso8601String();
      }
    });
    
    await prefs.setString('beforeDriveChecks', jsonEncode(todayChecks));
    print('Abfahrtskontrollen gespeichert: $todayChecks');
  } catch (e) {
    print('Fehler beim Speichern der Abfahrtskontrollen: $e');
  }
}

// Lädt die Abfahrtskontrollen aus SharedPreferences (beim App-Start aufrufen)
Future<void> loadBeforeDriveChecksFromStorage() async {
  try {
    final prefs = await SharedPreferencesAsync();
    final String? checksJson = await prefs.getString('beforeDriveChecks');
    
    if (checksJson != null && checksJson.isNotEmpty) {
      final Map<String, dynamic> checksMap = jsonDecode(checksJson);
      
      // Konvertiere zurück zu Map<String, DateTime>
      completedBeforeDriveChecks = {};
      checksMap.forEach((key, value) {
        completedBeforeDriveChecks[key] = DateTime.parse(value);
      });
      
      // Entferne alte Einträge (nicht von heute)
      final today = DateTime.now();
      final todayPrefix = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      completedBeforeDriveChecks.removeWhere((key, value) => !key.startsWith(todayPrefix));
      
      print('Abfahrtskontrollen geladen: $completedBeforeDriveChecks');
    }
  } catch (e) {
    print('Fehler beim Laden der Abfahrtskontrollen: $e');
  }
}