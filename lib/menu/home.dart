import 'package:bus_desk_pro/libaries/logs.dart';
import 'package:bus_desk_pro/libaries/tour.dart';
import 'package:bus_desk_pro/main.dart';
import 'package:bus_desk_pro/maps/here_new/routing/routing_screen.dart';
import 'package:bus_desk_pro/maps/here_new/routing/waypoint_info.dart';
import 'package:bus_desk_pro/maps/maps.dart';
//import 'package:bus_desk_pro/maps/mapEmbedded.dart';
import 'package:bus_desk_pro/others/BeforeDrive.dart';
import 'package:flutter/material.dart';
import 'package:here_sdk/core.dart';
import 'package:intl/intl.dart';
import '../maps/mapEngine.dart';
import '../maps/adresspicker.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;
import 'package:bus_desk_pro/config/globals.dart';
import 'package:bus_desk_pro/libaries/popup.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';

class TourListScreen extends StatefulWidget {

  final String? phonenumber;

  TourListScreen({super.key, this.phonenumber});

  @override
  _TourListScreenState createState() => _TourListScreenState();
}

class _TourListScreenState extends State<TourListScreen> {
  String? _selectedFilter = 'Heute';
  String? _selectedTourType = 'Gesamtübersicht';

  bool minOneAddressNoLatLng = false;
  List<dynamic> noLatLngIndexes = [];

  //List<dynamic> AllToursGbl = [];
  //List<dynamic> FilteredToursGbl = [];

  String _yesterday = '';
  String _today = '';
  String _tomorrow = '';
  DateTime? _selectedDate; // Ausgewähltes Datum für DatePicker

  //List<dynamic> data = [];

  Future<void> fetchData() async {
    minOneAddressNoLatLng = false;
    noLatLngIndexes.clear();
    setState(() {
      loadingText = 'Tourdaten abrufen.\nDieser Vorgang kann\nein paar Minuten beanspruchen.';
    });
    String jsonString = await rootBundle.loadString('lib/config/apis.json');
    print(jsonString);
    Map<String, dynamic> parsedJson = json.decode(jsonString);
    String urlString = (getUrl('get-tours')).replaceAll("{phonenumber}", PhoneNumberAuth).replaceAll("{deviceId}", AppUserId ?? '');
    
    // Füge Datum-Parameter hinzu, wenn DatePicker-Modul aktiv ist und ein Datum ausgewählt wurde
    if (checkIfAnyModuleIsActive('home_datepicker') == true && _selectedDate != null) {
      final dateString = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      urlString += '&date=$dateString';
    }
    
    final url = Uri.parse(urlString);
    print(url);
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body); // JSON-Daten parsen

        for (int i = 0; i < jsonData.length; i++) {
          for (int j = 0; j < jsonData[i]['stops'].length; j++) {
            if (jsonData[i]['stops'][j]['lng'] != null) {
              jsonData[i]['stops'][j]['long'] = jsonData[i]['stops'][j]['lng'];
            }
            jsonData[i]['stops'][j]['long'] = jsonData[i]['stops'][j]['long'].toString();
            jsonData[i]['stops'][j]['lat'] = jsonData[i]['stops'][j]['lat'].toString();
            if (
              jsonData[i]['stops'][j]['lat'] == null || jsonData[i]['stops'][j]['lat'].trim() == "" || jsonData[i]['stops'][j]['lat'].trim() == "0" || jsonData[i]['stops'][j]['lat'] == "null" ||
                  jsonData[i]['stops'][j]['long'] == null || jsonData[i]['stops'][j]['long'].trim() == "" || jsonData[i]['stops'][j]['long'].trim() == "0" || jsonData[i]['stops'][j]['long'] == "null"
            ) {
              // TEMP Workaround set to false
              minOneAddressNoLatLng = false;
              noLatLngIndexes.add(j);
              setState(() {
                loadingText = 'Ermittle Geokoordinaten von Tour ${i + 1} / ${jsonData.length}\n(Stopp ${j + 1} / ${jsonData[i]['stops'].length})';
              });
              // Currently no geocoding from address
              final String url =
                  'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent( jsonData[i]['stops'][j]['address'])}&key=$GoogleKey';
              try {
                final response = await http.get(Uri.parse(url));
                if (response.statusCode == 200) {
                  final data = json.decode(response.body);
                  if (data['status'] == 'OK') {
                    final location = data['results'][0]['geometry']['location'];
                      jsonData[i]['stops'][j]['lat'] = location['lat'].toString();
                      jsonData[i]['stops'][j]['long'] = location['lng'].toString();
                  } else {}
                } else {}
              } catch (e) {}
            }
          }
          jsonData[i]['stops'].sort((a, b) => (a['order'] as double).compareTo(b['order'] as double));
        }
        print('__T');
        print(jsonData.length);
        setState(() {
          AllToursGbl = jsonData;
          isLoading = false;
          // Wenn ein Datum ausgewählt ist, zeige alle geladenen Touren (bereits von API gefiltert)
          // Ansonsten filtere nach "Heute"
          if (_selectedDate != null) {
            FilteredToursGbl = AllToursGbl;
          } else {
            FilteredToursGbl = AllToursGbl.where((tour) => isToday(tour['date'])).toList();
          }
          ExpandedToursGbl.addAll(List.filled(FilteredToursGbl.length, false));
          cacheTourList = true;
          filterTours();
        });
      } else {
        throw Exception('Failed to load data.');
      }
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      print('Error: $error');
    }
  }

  @override
  void initState() {
    super.initState();

    _yesterday = DateFormat('yyyy-MM-dd')
        .format(DateTime.now().subtract(Duration(days: 1)));
    _today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _tomorrow =
        DateFormat('yyyy-MM-dd').format(DateTime.now().add(Duration(days: 1)));

    if (cacheTourList == false) {
      fetchData();
    }

  }

  bool isYesterday(String datestring) {
    final now = DateTime.now();
    print('Datum');
    print(datestring);
    DateTime date = DateTime.parse(datestring);
    final yesterday = now.subtract(Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  bool isToday(String datestring) {
    final now = DateTime.now();
    print(datestring);
    DateTime date = DateTime.parse(datestring);
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool isTomorrow(String datestring) {
    final now = DateTime.now();
    print(datestring);
    DateTime date = DateTime.parse(datestring);
    final tomorrow = now.add(Duration(days: 1));
    return date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day;
  }

  // Prüft, ob eine Tour Stops hat
  bool _hasStops(Map<String, dynamic> tour) {
    final stops = tour['stops'];
    if (stops == null) return false;
    if (stops is! List) return false;
    return stops.isNotEmpty;
  }

  // Entfernt HTML-Tags aus einem String
  String _stripHtmlTags(String htmlString) {
    // Entferne HTML-Tags mit RegExp
    String text = htmlString.replaceAll(RegExp(r'<[^>]*>'), '');
    // Entferne HTML-Entities
    text = text.replaceAll('&nbsp;', ' ');
    text = text.replaceAll('&amp;', '&');
    text = text.replaceAll('&lt;', '<');
    text = text.replaceAll('&gt;', '>');
    text = text.replaceAll('&quot;', '"');
    text = text.replaceAll('&#39;', "'");
    // Entferne mehrfache Leerzeichen und Zeilenumbrüche
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return text;
  }

  // Öffnet den DatePicker für die Datumsauswahl
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('de', 'DE'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: HexColor.fromHex(getColor('primary')),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: HexColor.fromHex(getColor('primary')),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedFilter = null; // Filter zurücksetzen wenn Datum gewählt wird
        isLoading = true; // Loading-Indikator anzeigen
        loadingText = 'Lade Touren für ${DateFormat('dd.MM.yyyy').format(picked)}...';
      });
      // Daten mit dem ausgewählten Datum neu laden
      fetchData();
    }
  }

  void filterTours() {
    setState(() {
      List<dynamic> filtered = [];
      // Wenn ein Datum ausgewählt ist, überspringe die Filterung (Daten sind bereits von API gefiltert)
      if (_selectedDate != null) {
        filtered = AllToursGbl;
      } else if (_selectedFilter == 'Gestern') {
        filtered =
            AllToursGbl.where((tour) => isYesterday(tour['date'])).toList();
      } else if (_selectedFilter == 'Heute') {
        filtered = AllToursGbl.where((tour) => isToday(tour['date'])).toList();
      } else if (_selectedFilter == 'Morgen') {
        filtered = AllToursGbl.where((tour) => isTomorrow(tour['date'])).toList();
      }
      print(filtered.length);
      print(_selectedTourType);
      if (_selectedTourType != null && _selectedTourType != 'Gesamtübersicht') {
        filtered = filtered
            .where(
                (tour) => tour['hintour'] == _selectedTourType)
            .toList();
        /*filtered = filtered
            .where(
                (tour) => tour['hintour'] == (_selectedTourType == 'Hinfahrt'))
            .toList();*/
      } else {
        filtered = filtered;
      }
print(filtered.length);
      FilteredToursGbl = filtered;
      ExpandedToursGbl.clear();
      ExpandedToursGbl.addAll(List.filled(FilteredToursGbl.length, false));
    });
  }

  // Ruft offene Schäden für ein Fahrzeug von der API ab
  Future<List<Map<String, dynamic>>> _fetchOpenDamages(String licensePlate) async {
    try {
      // Kennzeichen URL-encodieren für die API
      final encodedPlate = Uri.encodeComponent(licensePlate);
      final url = 'https://ef24c3593e63ece0be27bab074268e.42.environment.api.powerplatform.com/powerautomate/automations/direct/workflows/7dbeb02b09a5415a8c1f0105f1277e28/triggers/manual/paths/invoke/$encodedPlate?api-version=1&sp=%2Ftriggers%2Fmanual%2Frun&sv=1.0&sig=uCrS33fSJR9b491p96FmBBDbfUqlTxTt2oMpwnPL-c0';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final List<dynamic> damages = jsonDecode(response.body);
        final damageList = damages.map((d) => d as Map<String, dynamic>).toList();
        
        // Nach Datum aufsteigend sortieren (älteste zuerst)
        damageList.sort((a, b) {
          final dateA = DateTime.tryParse(a['createdon'] ?? '') ?? DateTime(1970);
          final dateB = DateTime.tryParse(b['createdon'] ?? '') ?? DateTime(1970);
          return dateA.compareTo(dateB);
        });
        
        return damageList;
      } else {
        print('Fehler beim Abrufen der Schäden: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Fehler beim Abrufen der Schäden: $e');
      return [];
    }
  }

  // Zeigt Dialog mit offenen Schäden an und fragt ob fortgefahren werden soll
  Future<bool> _showOpenDamagesDialog(BuildContext context, String licensePlate, List<Map<String, dynamic>> damages) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Offene Schäden für $licensePlate',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Für dieses Fahrzeug sind ${damages.length} offene Schäden gemeldet:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: damages.length,
                  itemBuilder: (context, index) {
                    final damage = damages[index];
                    final damageName = damage['damage'] ?? 'Unbekannter Schaden';
                    final createdOn = damage['createdon'] != null 
                        ? DateTime.tryParse(damage['createdon'])
                        : null;
                    final driver = damage['driver'];
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.orange.shade700, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  damageName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (createdOn != null || driver != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                if (createdOn != null)
                                  Text(
                                    DateFormat('dd.MM.yyyy HH:mm').format(createdOn),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                if (createdOn != null && driver != null)
                                  Text(' • ', style: TextStyle(color: Colors.grey.shade600)),
                                if (driver != null)
                                  Expanded(
                                    child: Text(
                                      driver,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Diese Schäden müssen nicht mehr gemeldet werden.r',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: HexColor.fromHex(getColor('primary')),
            ),
            child: const Text('Verstanden, fortfahren', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;
  }

  // Startet die Abfahrtskontrolle mit Schadensprüfung und Touren-Aktualisierung
  Future<void> _startBeforeDriveCheck(BuildContext context, Map<String, dynamic> tour) async {
    // Zuerst Touren aktualisieren
    final updatedTour = await _refreshToursAndGetUpdated(context, tour['tour']);
    
    if (updatedTour == null) {
      // Fehler beim Aktualisieren - mit alter Tour fortfahren
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Touren konnten nicht aktualisiert werden. Verwende gespeicherte Daten.')),
      );
    }
    
    final tourToUse = updatedTour ?? tour;
    final vehicleLicensePlate = tourToUse['general']?['vehicle']?.toString();
    
    if (vehicleLicensePlate == null || vehicleLicensePlate.isEmpty) {
      // Kein Kennzeichen vorhanden, direkt starten
      _navigateToBeforeDriveView(context, tourToUse);
      return;
    }
    
    // Lade-Dialog anzeigen für Schadensprüfung
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Prüfe offene Schäden...'),
              ],
            ),
          ),
        ),
      ),
    );
    
    // Schäden abrufen
    final damages = await _fetchOpenDamages(vehicleLicensePlate);
    
    // Lade-Dialog schließen
    if (context.mounted) Navigator.pop(context);
    
    if (damages.isNotEmpty) {
      // Schäden-Dialog anzeigen
      final shouldContinue = await _showOpenDamagesDialog(context, vehicleLicensePlate, damages);
      if (!shouldContinue) return;
    }
    
    // Zur Abfahrtskontrolle navigieren
    _navigateToBeforeDriveView(context, tourToUse);
  }

  // Navigiert zur BeforeDriveView
  void _navigateToBeforeDriveView(BuildContext context, Map<String, dynamic> tour) {
    sendLogs("log_tour_beforecheck_started", tour['tour']);
    CurrentTourData = tour;
    GblStops = tour['stops'];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BeforeDriveView(
          lat: tour['lat'],
          long: tour['long'],
          stops: tour['stops'],
        ),
      ),
    );
  }

  // Aktualisiert die Touren und gibt die aktualisierte Tour zurück
  Future<Map<String, dynamic>?> _refreshToursAndGetUpdated(BuildContext context, String tourName) async {
    // Lade-Dialog anzeigen
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.download_rounded, size: 48, color: HexColor.fromHex(getColor('primary'))),
                const SizedBox(height: 16),
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text(
                  'Touren werden aktualisiert...',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Touren über fetchData() neu laden (gleiche Logik wie Refresh-Button)
      await fetchData();
      
      // Lade-Dialog schließen
      if (context.mounted) Navigator.pop(context);
      
      // Die aktualisierte Tour aus AllToursGbl finden
      for (var t in AllToursGbl) {
        if (t['tour'] == tourName) {
          return t as Map<String, dynamic>;
        }
      }
      
      // Tour nicht gefunden
      print('Tour "$tourName" wurde nach Refresh nicht gefunden');
      return null;
    } catch (e) {
      print('Fehler beim Aktualisieren der Touren: $e');
      // Lade-Dialog schließen
      if (context.mounted) Navigator.pop(context);
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Stack(
        children: [
          Positioned(
            bottom: 80, // Abstand vom unteren Rand
            right: 16,  // Abstand vom rechten Rand
            child: FloatingActionButton(
              onPressed: () {
                setState(() {
                  isLoading = true;
                });
                fetchData();
              },
              child: Icon(
                  Icons.refresh,
                  color: Colors.white
              ),
              backgroundColor: HexColor.fromHex(getColor('primary')),
            ),
          ),
          Positioned(
            bottom: 16, // Abstand vom unteren Rand
            right: 16,  // Abstand vom rechten Rand
            child: FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdressPicker(),
                  ),
                );
              },
              child: Transform.rotate(
                angle: 1.5708, // 90 Grad nach rechts drehen (π/2)
                child: Icon(
                    Icons.route,
                    color: Colors.white
                ),
              ),
              backgroundColor: HexColor.fromHex(getColor('primary')),
            ),
          ),
        ],
      ),
      /*appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: HexColor.fromHex(getColor('primary')),
        title: Text(
          'Übersicht verfügbarer Touren',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20.0,
          ),
        ),
        centerTitle: true,
      ),*/
      body: Stack(
        children: [
          // Hintergrundbild
          Positioned.fill(
            child: Image.asset(
              'lib/assets/app_tile_2.png', // Dein Hintergrundbild hier
              fit: BoxFit.cover,
            ),
          ),
          // Weißes Overlay
          Positioned.fill(
            child: Container(
              color: Colors.white.withOpacity(0.9), // Halbtransparentes weißes Overlay
            ),
          ),
          Column(
            children: [
              Container(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  children: [
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: [
                        // Filter-Buttons
                        ...['Gestern', 'Heute', 'Morgen'].map((filter) {
                          final isSelected = _selectedFilter == filter;
                          return ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isSelected
                                  ? HexColor.fromHex(getColor('primary'))
                                  : Colors.white,
                            ),
                            onPressed: () {
                              final wasDateSelected = _selectedDate != null;
                              setState(() {
                                _selectedFilter = filter;
                                _selectedDate = null; // Datum zurücksetzen wenn Filter gewählt wird
                                // Wenn vorher ein Datum ausgewählt war, müssen Daten neu geladen werden
                                if (wasDateSelected) {
                                  isLoading = true;
                                  loadingText = 'Lade Touren...';
                                }
                              });
                              // Wenn vorher ein Datum ausgewählt war, Daten neu laden
                              if (wasDateSelected) {
                                fetchData();
                              } else {
                                filterTours();
                              }
                            },
                            child: Text(filter, style: TextStyle(color: isSelected
                                ? Colors.white
                                : HexColor.fromHex(getColor('primary')),)),
                          );
                        }),
                        // DatePicker-Button, wenn Modul aktiv ist
                        if (checkIfAnyModuleIsActive('home_datepicker') == true)
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _selectedDate != null
                                  ? HexColor.fromHex(getColor('primary'))
                                  : Colors.white,
                              shape: CircleBorder(),
                              padding: EdgeInsets.all(12.0),
                              minimumSize: Size(48, 48),
                            ),
                            onPressed: () => _selectDate(context),
                            child: Icon(
                              Icons.calendar_today_rounded,
                              color: _selectedDate != null
                                  ? Colors.white
                                  : HexColor.fromHex(getColor('primary')),
                            ),
                          ),
                      ],
                    ),
                    // Zeige ausgewähltes Datum an, wenn vorhanden
                    if (checkIfAnyModuleIsActive('home_datepicker') == true && _selectedDate != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Ausgewähltes Datum: ${DateFormat('dd.MM.yyyy').format(_selectedDate!)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: HexColor.fromHex(getColor('primary')),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(width: 8),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _selectedDate = null;
                                });
                                fetchData(); // Daten neu laden ohne Datum
                              },
                              child: Text(
                                'Zurücksetzen',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    SizedBox(height: 8.0),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(25.0),
                      ),
                      margin: EdgeInsets.symmetric(horizontal: 10.0),
                      padding: EdgeInsets.symmetric(horizontal: 10.0),
                      //child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedTourType,
                          hint: Text(
                            'Bitte Tourrichtung wählen.',
                            style: TextStyle(color: HexColor.fromHex(getColor('primary'))),
                          ),
                          dropdownColor: Colors.white,
                          style: TextStyle(
                              color: HexColor.fromHex(getColor('primary')), fontWeight: FontWeight.bold),
                          items: ['Gesamtübersicht', 'Hinfahrt', 'Rückfahrt']
                              .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type == 'Gesamtübersicht' ? 'Alle Fahrten' : type),
                          ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedTourType = value;
                            });
                            filterTours();
                          },
                          icon: Icon(Icons.arrow_drop_down, color: HexColor.fromHex(getColor('primary'))),
                          isExpanded: true,
                        ),
                      //),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: isLoading ? Stack(
                  children: [
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16), // Abstand zwischen dem Spinner und dem Text
                          Text(
                            loadingText,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: HexColor.fromHex(getColor('primary')),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ) : (FilteredToursGbl.length == 0 ? Center(
                  child: Container(
                    margin: EdgeInsets.all(20),
                    padding: EdgeInsets.all(24),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.9,
                      maxHeight: MediaQuery.of(context).size.height * 0.8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: HexColor.fromHex(getColor('primary')).withOpacity(0.2),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                        // Icon Header
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: HexColor.fromHex(getColor('primary')).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Icon(
                            Icons.search_off_rounded,
                            size: 48,
                            color: HexColor.fromHex(getColor('primary')),
                          ),
                        ),
                        SizedBox(height: 20),
                        
                        // Title
                        Text(
                          "Keine Touren gefunden",
                          style: TextStyle(
                            fontSize: MediaQuery.of(context).orientation == Orientation.landscape ? 18 : 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 12),
                        
                        // Subtitle
                        Text(
                          "Es konnten keine Touren für Sie gefunden werden",
                          style: TextStyle(
                            fontSize: MediaQuery.of(context).orientation == Orientation.landscape ? 12 : 14,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 20),
                        
                        // Possible causes section
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline_rounded,
                                    size: 20,
                                    color: HexColor.fromHex(getColor('primary')),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "Mögliche Ursachen:",
                                    style: TextStyle(
                                      fontSize: MediaQuery.of(context).orientation == Orientation.landscape ? 12 : 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                              
                              // Cause 1
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    margin: EdgeInsets.only(top: 6),
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: HexColor.fromHex(getColor('primary')),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      "Eingegebene Rufnummer (${PhoneNumberAuth}) kann nicht mit einem Fahreraccount identifiziert werden",
                                      style: TextStyle(
                                        fontSize: MediaQuery.of(context).orientation == Orientation.landscape ? 11 : 13,
                                        color: Colors.grey[700],
                                        height: 1.4,
                                      ),
                                      softWrap: true,
                                      overflow: TextOverflow.visible,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              
                              // Cause 2
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    margin: EdgeInsets.only(top: 6),
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: HexColor.fromHex(getColor('primary')),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      "Keine Touren zu diesem Zeitraum hinterlegt",
                                      style: TextStyle(
                                        fontSize: MediaQuery.of(context).orientation == Orientation.landscape ? 11 : 13,
                                        color: Colors.grey[700],
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        ],
                      ),
                    ),
                  ),
                ) : ListView.builder(
                  itemCount: FilteredToursGbl.length,
                  itemBuilder: (context, index) {
                    final tour = FilteredToursGbl[index];
                    return Card(
                      margin: EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 16.0),
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                          side: new BorderSide(color: HexColor.fromHex(getColor('primary')), width: 1.0),
                          borderRadius: BorderRadius.circular(10.0)
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: Icon(Icons.directions_bus,
                                size: 40, color: Colors.black),
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment
                                      .spaceBetween,
                                  children: [
                                    Text('Start der Tour:',
                                        style:
                                        TextStyle(fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                            fontSize: checkIfAnyModuleIsActive('TourDisplayCustomization') ? 16 : 12)),
                                    Padding(
                                      padding: EdgeInsets.only(right: 60), // <— hier Abstand einstellen
                                      child: Text(tour['start'],
                                          style: TextStyle(
                                              color: Colors.black87,
                                              fontSize: checkIfAnyModuleIsActive('TourDisplayCustomization') ? 18 : 12)),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment
                                      .spaceBetween,
                                  children: [
                                    Text('Ankuft Ziel:',
                                        style:
                                        TextStyle(fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                            fontSize: checkIfAnyModuleIsActive('TourDisplayCustomization') ? 16 : 12)),
                                    Padding(
                                      padding: EdgeInsets.only(right: 60),
                                      child: Text(tour['destination'],
                                          style: TextStyle(
                                              color: Colors.black87,
                                              fontSize: checkIfAnyModuleIsActive('TourDisplayCustomization') ? 18 : 12)),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment
                                      .spaceBetween,
                                  children: [
                                    Text('Ende der Tour:',
                                        style:
                                        TextStyle(fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                            fontSize: checkIfAnyModuleIsActive('TourDisplayCustomization') ? 16 : 12)),
                                    Padding(
                                      padding: EdgeInsets.only(right: 60),
                                      child: Text(tour['end'],
                                          style: TextStyle(
                                              color: Colors.black87,
                                              fontSize: checkIfAnyModuleIsActive('TourDisplayCustomization') ? 18 : 12)),
                                    ),
                                  ],
                                ),
                                // Grüner Hinweis wenn Abfahrtskontrolle bereits durchgeführt
                                if (checkIfAnyModuleIsActive('BeforeDriveCheck') == true && 
                                    hasCompletedBeforeDriveCheckToday(tour['general']?['vehicle']?.toString()))
                                  Container(
                                    margin: const EdgeInsets.only(top: 8.0),
                                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(6.0),
                                      border: Border.all(color: Colors.green.shade300, width: 1.0),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.check_circle, color: Colors.green.shade700, size: 16.0),
                                        const SizedBox(width: 6.0),
                                        Flexible(
                                          child: Text(
                                            'Abfahrtskontrolle durchgeführt',
                                            style: TextStyle(
                                              color: Colors.green.shade700,
                                              fontSize: 11.0,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            /*trailing: IconButton(
                              onPressed: () {
                                setState(() {
                                  ExpandedToursGbl[index] =
                                  !ExpandedToursGbl[index];
                                });
                              },
                              color: HexColor.fromHex(getColor('primary')),
                              icon: Icon(
                                ExpandedToursGbl[index]
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                              ),
                            ),*/
                          ),
                          if (ExpandedToursGbl[index])
                            Column(
                              children: [
                                // Detaillierte Fahrinformation (Details)
                                if (tour['details'] != null && 
                                    tour['details'].toString().trim().isNotEmpty)
                                  Container(
                                    padding: EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Detaillierte Fahrinformation',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                            fontSize: checkIfAnyModuleIsActive('TourDisplayCustomization') ? 18 : 14,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          _stripHtmlTags(tour['details'].toString()),
                                          style: TextStyle(
                                            fontSize: checkIfAnyModuleIsActive('TourDisplayCustomization') ? 16 : 12,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ListTile(
                                  title: Text(
                                      checkIfAnyModuleIsActive('TourDisplayCustomization')
                                          ? 'Tour\n${tour['tour']}\n\n'
                                          : 'Tour\n${tour['tour']}\n\n'
                                              'Fahrer\n${tour['general']['driver']}\n\n'
                                              'Fahrertelefon\n ${tour['general']['phone']}\n\n'
                                              'Fahrzeugtelefon\n ${tour['general']['vehiclephone']}\n\n'
                                              'Begleitperson\n${tour['general']['guide']}\n\n'
                                              'Begleitpersontelefon\n ${tour['general']['guidephone']}\n\n',
                                      style: TextStyle(
                                          color: Colors.black87, 
                                          fontSize: checkIfAnyModuleIsActive('TourDisplayCustomization') ? 16 : 12)
                                  ),
                                ),
                                ...tour['stops']
                                    .asMap()
                                    .entries
                                    .map<Widget>(
                                      (entry) {
                                    final index = entry.key;
                                    final stop = entry.value;

                                    // Definiere die Hintergrundfarbe basierend auf dem Index
                                    final backgroundColor = index % 2 == 0
                                        ? Colors.grey.shade200
                                        : Colors.white;

                                    return Container(
                                      color: backgroundColor,
                                      child: ListTile(
                                        title: Text(
                                          '${stop['time']}\n${(minOneAddressNoLatLng == true && noLatLngIndexes.contains(index) ? "\nKeine Geokoordinaten für diesen Stopp übermittelt\n\n" : "")}${getTextOfStoppType(
                                              stop['stopp_type'])}\n${'${stop['firstname'] ??
                                              ''} ${stop['lastname'] ?? ''}'
                                              .trim()}',
                                          style: TextStyle(
                                              color: Colors.black87),
                                        ),
                                        subtitle: Text(
                                          '${stop['address']}\n${stop['info'] !=
                                              null && stop['info'] != ''
                                              ? '(${stop['info']})'
                                              : ''}',
                                          style: TextStyle(
                                              color: Colors.black87),
                                        ),
                                      ),
                                    );
                                  },
                                )
                                    .toList(),
                                Divider(color: Colors.black87),
                              ],
                            ),
                          if (minOneAddressNoLatLng == true)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                "Keine Navigation möglich für diese Tour, vom Tourenplanungssystem wurden bei mind. einem Stopp keine Geokoordinaten (Lat/ Lng) übermittelt",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12
                                ),
                              ),
                            ),
                          if (_selectedFilter == "Heute")
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(
                                  left: 10.0, right: 10.0, bottom: 10.0),
                              child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                                    child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: (minOneAddressNoLatLng == true || !_hasStops(tour)) ? Colors.grey.shade300 : ((currentStoppIndex == 1 && TourNameGbl == tour['tour']) || TourNameGbl != tour['tour']
                                          ? HexColor.fromHex(getColor('primary'))
                                          : Colors.white),
                                      maximumSize: Size(100, 100),
                                    ),
                                    onPressed: (minOneAddressNoLatLng == true || !_hasStops(tour)) ? null : () {
                                      showCustomDialog(
                                          context,
                                          "Tour starten",
                                          "Möchtest Du die Tour starten?",
                                          [
                                            Builder(
                                              builder: (dialogContext) =>
                                                Container(
                                                  width: double.infinity, // Setzt die Breite auf die volle verfügbare Breite
                                                  child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: HexColor.fromHex(getColor('primary')),),
                                                    child: Text("Tour starten", style: TextStyle(color: Colors.white)),
                                                    onPressed: () async {
                                                      Navigator.pop(dialogContext);
                                                      
                                                      // Touren aktualisieren und aktualisierte Tour holen
                                                      final updatedTour = await _refreshToursAndGetUpdated(context, tour['tour']);
                                                      
                                                      if (updatedTour == null) {
                                                        // Fehler beim Aktualisieren - mit alter Tour fortfahren
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          const SnackBar(content: Text('Touren konnten nicht aktualisiert werden. Verwende gespeicherte Daten.')),
                                                        );
                                                      }
                                                      
                                                      final tourToUse = updatedTour ?? tour;
                                                      
                                                      sendLogs("log_tour_started", tourToUse['tour']);
                                                      
                                                      // Android Auto Navigation starten
                                                      _startAndroidAutoNavigation(tourToUse);
                                                      
                                                      // Normale App-Navigation starten
                                                      for (var i = 0; i < GblStops.length; i++) {
                                                        if (GblStops[i]['canceled'] != null && GblStops[i]['canceled'] == true) {
                                                          GblStops[i]['canceled'] = false;
                                                        }
                                                      }
                                                      GblStops = tourToUse['stops'];
                                                      TourNameGbl = tourToUse['tour'];
                                                      CurrentTourData = tourToUse;
                                                      ArrivalTimesReal = [];
                                                      currentStoppIndex = 1;
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              InitNavigationMap(
                                                                lat: tourToUse['lat'],
                                                                long: tourToUse['long'],
                                                                isFreeDrive: false,
                                                              ),
                                                        ),
                                                      );
                                                    }
                                                ))
                                            ),
                                            if (checkIfAnyModuleIsActive('BeforeDriveCheck') == true)
                                              Container(
                                                width: double.infinity, // Setzt die Breite auf die volle verfügbare Breite
                                                child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: HexColor.fromHex(getColor('primary')),),
                                                  child: Text("Abfahrkontrolle", style: TextStyle(color: Colors.white)),
                                                  onPressed: () async {
                                                    // Prüfen ob heute bereits eine Abfahrtskontrolle für dieses Fahrzeug durchgeführt wurde
                                                    final vehicleLicensePlate = tour['general']?['vehicle']?.toString();
                                                    final alreadyCheckedToday = hasCompletedBeforeDriveCheckToday(vehicleLicensePlate);
                                                    
                                                    // Dialog schließen
                                                    Navigator.pop(context);
                                                    
                                                    if (alreadyCheckedToday) {
                                                      // Dialog anzeigen: Kontrolle machen oder direkt starten
                                                      showDialog(
                                                        context: context,
                                                        builder: (dialogContext) => AlertDialog(
                                                          title: const Text('Abfahrtskontrolle bereits durchgeführt'),
                                                          content: Text(
                                                            'Für das Fahrzeug $vehicleLicensePlate wurde heute bereits eine Abfahrtskontrolle durchgeführt.\n\nMöchten Sie die Kontrolle erneut durchführen oder direkt die Tour starten?',
                                                          ),
                                                          actions: [
                                                            TextButton(
                                                              onPressed: () {
                                                                Navigator.pop(dialogContext);
                                                              },
                                                              child: const Text('Abbrechen'),
                                                            ),
                                                            ElevatedButton(
                                                              onPressed: () {
                                                                Navigator.pop(dialogContext);
                                                                sendLogs("log_tour_started_skip_beforecheck", tour['tour']);
                                                                
                                                                // Direkt Tour starten
                                                                for (var i = 0; i < GblStops.length; i++) {
                                                                  if (GblStops[i]['canceled'] != null && GblStops[i]['canceled'] == true) {
                                                                    GblStops[i]['canceled'] = false;
                                                                  }
                                                                }
                                                                GblStops = tour['stops'];
                                                                TourNameGbl = tour['tour'];
                                                                CurrentTourData = tour;
                                                                ArrivalTimesReal = [];
                                                                currentStoppIndex = 1;
                                                                Navigator.push(
                                                                  context,
                                                                  MaterialPageRoute(
                                                                    builder: (context) => InitNavigationMap(
                                                                      lat: tour['lat'],
                                                                      long: tour['long'],
                                                                      isFreeDrive: false,
                                                                    ),
                                                                  ),
                                                                );
                                                              },
                                                              style: ElevatedButton.styleFrom(
                                                                backgroundColor: Colors.green,
                                                              ),
                                                              child: const Text('Tour direkt starten', style: TextStyle(color: Colors.white)),
                                                            ),
                                                            ElevatedButton(
                                                              onPressed: () async {
                                                                Navigator.pop(dialogContext);
                                                                // Mit Schadensprüfung starten
                                                                await _startBeforeDriveCheck(context, tour);
                                                              },
                                                              style: ElevatedButton.styleFrom(
                                                                backgroundColor: HexColor.fromHex(getColor('primary')),
                                                              ),
                                                              child: const Text('Kontrolle erneut durchführen', style: TextStyle(color: Colors.white)),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    } else {
                                                      // Normale Abfahrtskontrolle mit Schadensprüfung starten
                                                      await _startBeforeDriveCheck(context, tour);
                                                    }
                                                  }
                                              )),
                                            StatefulBuilder(
                                              builder: (BuildContext context, StateSetter setModalState) {
                                                return Container(
                                                  width: double.infinity,
                                                  margin: const EdgeInsets.only(top: 16.0),
                                                  child: Column(
                                                    children: [
                                                      // Trennlinie
                                                      Divider(color: Colors.grey.shade300, thickness: 1),
                                                      
                                                      // Android Auto Toggle
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                                                        child: Row(
                                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                          children: [
                                                            Expanded( // Expanded hinzufügen für flexiblen Text
                                                              child: Text(
                                                                'Ist AndroidAuto verbunden?',
                                                                style: TextStyle(
                                                                  fontSize: 14,
                                                                  fontWeight: FontWeight.w500,
                                                                  color: Colors.black87,
                                                                ),
                                                              ),
                                                            ),
                                                            SizedBox(width: 8), // Kleiner Abstand zwischen Text und Switch
                                                            Switch(
                                                              value: isAndroidAutoConnected,
                                                              onChanged: (bool value) {
                                                                // Nur von false zu true erlauben
                                                                if (value == true) {
                                                                  _showAndroidAutoConfirmationDialog(context, setModalState);
                                                                } else {
                                                                  print('TEST');
                                                                  isAndroidAutoConnected = false;
                                                                  // Modal State aktualisieren
                                                                  setModalState(() {});
                                                                }
                                                                // Von true zu false nicht erlauben
                                                              },
                                                              activeColor: HexColor.fromHex(getColor('primary')),
                                                              activeTrackColor: HexColor.fromHex(getColor('primary')).withOpacity(0.3),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      
                                                      // Status-Text
                                                      if (isAndroidAutoConnected)
                                                        Container(
                                                          width: double.infinity,
                                                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                                                          child: Text(
                                                            'Android Auto ist aktiv verbunden',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: Colors.green.shade700,
                                                              fontStyle: FontStyle.italic,
                                                            ),
                                                            textAlign: TextAlign.center,
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
                                          ]
                                      );
                                    },
                                    child: Text('starten',
                                        style: TextStyle(color: (minOneAddressNoLatLng == true || !_hasStops(tour)) ? Colors.grey[600] : ((currentStoppIndex == 1 && TourNameGbl == tour['tour']) || TourNameGbl != tour['tour']
                                            ? Colors.white
                                            : HexColor.fromHex(getColor('primary'))), fontSize: 12,)),
                                  )),
                                  Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 2.0),
                                      child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: (!_hasStops(tour)) ? Colors.grey.shade300 : (currentStoppIndex > 1 && TourNameGbl == tour['tour']
                                          ? HexColor.fromHex(getColor('primary'))
                                          : Colors.white),
                                      maximumSize: Size(100, 100),
                                    ),
                                    onPressed: (!_hasStops(tour)) ? null : () {
                                      TourNameGbl = tour['tour'];
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              InitNavigationMap(
                                                lat: tour['lat'],
                                                long: tour['long'],
                                                isFreeDrive: false,
                                              ),
                                        ),
                                      );
                                    },
                                    child: Text("fortsetz.", style: TextStyle(color: (!_hasStops(tour)) ? Colors.grey[600] : (currentStoppIndex > 1 && TourNameGbl == tour['tour']
                                        ? Colors.white
                                        : HexColor.fromHex(getColor('primary'))), fontSize: 12,)),
                                  )),
                                  Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 2.0),
                                      child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: (!_hasStops(tour)) ? Colors.grey.shade300 : (currentStoppIndex > 1 && TourNameGbl == tour['tour']
                                          ? HexColor.fromHex(getColor('primary'))
                                          : Colors.white),
                                    ),
                                    onPressed: (!_hasStops(tour)) ? null : () {
                                      setState(() {
                                        currentStoppIndex = 1;
                                      });
                                    },
                                    child: Text("beenden", style: TextStyle(color: (!_hasStops(tour)) ? Colors.grey[600] : (currentStoppIndex > 1 && TourNameGbl == tour['tour']
                                        ? Colors.white
                                        : HexColor.fromHex(getColor('primary'))), fontSize: 12,)),
                                  ))
                                      ],
                                    ),
                                    // Hinweis wenn keine Stops vorhanden sind
                                    if (!_hasStops(tour))
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4.0),
                                        child: Text(
                                          'Keine Teilnehmer',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey[600],
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                  ],
                                ),
                            ),
                            Container(
                              decoration: const BoxDecoration(
                                  color: Colors.white,
                                  border: Border(
                                    top: BorderSide(color: Colors.grey, width: 1),
                                  ),
                              ),
                              width: double.infinity,
                              child: TextButton(
                                onPressed: () {
                                  setState(() {
                                    ExpandedToursGbl[index] =
                                    !ExpandedToursGbl[index];
                                  });
                                },
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.all(12),
                                  foregroundColor: HexColor.fromHex(getColor('primary')), // Textfarbe
                                  alignment: Alignment.center,
                                ),
                                child: Text(ExpandedToursGbl[index] ? "Weitere Infos verbergen" : "Weitere Infos anzeigen"),
                              ),
                            )
                        ],
                      ),
                    );
                  },
                )),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAndroidAutoConfirmationDialog(BuildContext context, StateSetter setModalState) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'AndroidAuto wirklich aktiv?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          content: Text(
            'Bitte bestätigen Sie nur wenn auch wirklich eine aktive Verbindung von Android Auto mit Ihrem Smartphone/Tablet besteht!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          actions: [
            // Nein Button
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Boolean bleibt false
              },
              child: Text(
                'Nein',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                ),
              ),
            ),
            
            // Ja Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: HexColor.fromHex(getColor('primary')),
              ),
              onPressed: () {
                // Boolean auf true setzen
                isAndroidAutoConnected = true;
                Navigator.of(context).pop();
                
                // Toggle aktualisieren
                setModalState(() {});
              },
              child: Text(
                'Ja, bestätigen',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        );
      },
    );
  }


  // Neue Funktion für Android Auto Navigation mit kompletten Wegpunkten
  void _startAndroidAutoNavigation(Map<String, dynamic> tour) async {
    try {
      print('=== ANDROID AUTO DEBUG ===');
      print('Tour: ${tour['tour']}');
      print('Anzahl Stopps: ${tour['stops'].length}');
      
      // Aktuellen Standort holen
      double? currentLat = currentPosition?.latitude;
      double? currentLong = currentPosition?.longitude;
      
      bool isAAConnected = await _isAndroidAutoConnected();

      if (isAndroidAutoConnected == true) {
        // Route mit allen Wegpunkten der Tour
        String waypoints = '';
        
        // Alle Stopps als Wegpunkte hinzufügen
        for (int i = 0; i < tour['stops'].length; i++) {
          var stop = tour['stops'][i];
          if (stop['lat'] != null && stop['long'] != null) {
            waypoints += '${stop['lat']},${stop['long']}|';
          }
        }
        
        // Letzten | entfernen
        if (waypoints.isNotEmpty) {
          waypoints = waypoints.substring(0, waypoints.length - 1);
        }
        
        print('Wegpunkte: $waypoints');
        
        // Navigation mit Wegpunkten
        final intent = AndroidIntent(
          action: 'android.intent.action.VIEW',
          data: 'google.navigation:q=${GblStops[currentStoppIndex]['lat']},${GblStops[currentStoppIndex]['long']}&mode=d',
          package: 'com.google.android.apps.maps',
          flags: [
            Flag.FLAG_ACTIVITY_NEW_TASK,
            Flag.FLAG_ACTIVITY_NO_ANIMATION,
            Flag.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS,
            Flag.FLAG_ACTIVITY_NO_USER_ACTION,     // Kein Benutzerinteraktion
            Flag.FLAG_ACTIVITY_SINGLE_TOP,         // Nur eine Instanz
            //Flag.FLAG_ACTIVITY_LAUNCH_ADJACENT // SplitScreen
          ],
        );
        
        print('Tour-Route-Intent wird gestartet...');
        await intent.launch();
        print('Tour-Route-Intent erfolgreich gestartet!');

        _bringAppToForeground();

      } else {
        print('Kein aktueller Standort verfügbar');
      }
      
    } catch (e) {
      print('=== ANDROID AUTO FEHLER ===');
      print('Fehler: $e');
      print('Fehler-Typ: ${e.runtimeType}');
    }
  }

  // Neue Funktion: App wieder in den Vordergrund bringen
  void _bringAppToForeground() {
    try {
      // Deine App wieder aktiv machen
      final intent = AndroidIntent(
        action: 'android.intent.action.MAIN',
        category: 'android.intent.category.LAUNCHER',
        package: 'com.example.busdeskpro', // Dein App-Package
        flags: [
          Flag.FLAG_ACTIVITY_NEW_TASK,
          Flag.FLAG_ACTIVITY_SINGLE_TOP,
          Flag.FLAG_ACTIVITY_CLEAR_TOP,
          Flag.FLAG_ACTIVITY_REORDER_TO_FRONT
        ],
      );
      
      intent.launch();
      print('App wurde in den Vordergrund gebracht');
      
    } catch (e) {
      print('Fehler beim Bringen der App in den Vordergrund: $e');
    }
  }

  // Einfache aber effektive Prüfung
Future<bool> _isAndroidAutoConnected() async {
    try {
      print('Prüfe Android Auto Verbindung...');
      
      // Prüfen ob Android Auto App installiert ist
      final intent = AndroidIntent(
        action: 'android.intent.action.VIEW',
        package: 'com.google.android.projection.gearhead',
      );
      
      // Wenn der Intent erfolgreich ist, ist Android Auto verfügbar
      print('Android Auto ist verfügbar');
      return true;
      
    } catch (e) {
      print('Android Auto nicht verfügbar: $e');
      return false;
    }
  }
}