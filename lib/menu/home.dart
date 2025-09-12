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
    final url = Uri.parse((getUrl('get-tours')).replaceAll("{phonenumber}", PhoneNumberAuth));
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
          FilteredToursGbl = AllToursGbl.where((tour) => isToday(tour['date'])).toList();
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

  void filterTours() {
    setState(() {
      List<dynamic> filtered = [];
      if (_selectedFilter == 'Gestern') {
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
              onPressed: null, // AdressPicker: Old Logic
              child: Icon(
                  Icons.route,
                  color: Colors.white
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: ['Gestern', 'Heute', 'Morgen'].map((filter) {
                        final isSelected = _selectedFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isSelected
                                  ? HexColor.fromHex(getColor('primary'))
                                  : Colors.white,
                            ),
                            onPressed: () {
                              setState(() {
                                _selectedFilter = filter;
                              });
                              filterTours();
                            },
                            child: Text(filter, style: TextStyle(color: isSelected
                                ? Colors.white
                                : HexColor.fromHex(getColor('primary')),)),
                          )/*GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedFilter = filter;
                              });
                              filterTours();
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? HexColor.fromHex(getColor('primary')).shade200
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(25.0),
                                border: Border.all(
                                  color: HexColor.fromHex(getColor('primary')),
                                  width: 1,
                                ),
                              ),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 20.0, vertical: 10.0),
                              child: Text(
                                filter,
                                style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : HexColor.fromHex(getColor('primary')),
                                    fontWeight: FontWeight.normal,
                                    fontSize: 14.0
                                ),
                              ),
                            ),
                          ),*/
                        );
                      }).toList(),
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
                                            fontSize: 12)),
                                    Padding(
                                      padding: EdgeInsets.only(right: 60), // <— hier Abstand einstellen
                                      child: Text(tour['start'],
                                          style: TextStyle(
                                              color: Colors.black87,
                                              fontSize: 12)),
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
                                            fontSize: 12)),
                                    Padding(
                                      padding: EdgeInsets.only(right: 60),
                                      child: Text(tour['destination'],
                                          style: TextStyle(
                                              color: Colors.black87,
                                              fontSize: 12)),
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
                                            fontSize: 12)),
                                    Padding(
                                      padding: EdgeInsets.only(right: 60),
                                      child: Text(tour['end'],
                                          style: TextStyle(
                                              color: Colors.black87,
                                              fontSize: 12)),
                                    ),
                                  ],
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
                                ListTile(
                                  title: Text(
                                      'Tour\n${tour['tour']}\n\n'
                                          'Fahrer\n${tour['general']['driver']}\n\n'
                                          'Fahrertelefon\n ${tour['general']['phone']}\n\n'
                                          'Fahrzeugtelefon\n ${tour['general']['vehiclephone']}\n\n'
                                          'Begleitperson\n ${tour['general']['guide']}\n\n'
                                          'Begleitpersontelefon\n ${tour['general']['guidephone']}\n\n',
                                      style: TextStyle(
                                          color: Colors.black87, fontSize: 12)
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
                              child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                                    child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: minOneAddressNoLatLng == true ? Colors.grey.shade300 : ((currentStoppIndex == 1 && TourNameGbl == tour['tour']) || TourNameGbl != tour['tour']
                                          ? HexColor.fromHex(getColor('primary'))
                                          : Colors.white),
                                      maximumSize: Size(100, 100),
                                    ),
                                    onPressed: minOneAddressNoLatLng == true ? null : () {
                                      showCustomDialog(
                                          context,
                                          "Tour starten",
                                          "Möchtest Du die Tour starten?",
                                          [
                                            Builder(
                                              builder: (context) =>
                                                Container(
                                                  width: double.infinity, // Setzt die Breite auf die volle verfügbare Breite
                                                  child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: HexColor.fromHex(getColor('primary')),),
                                                    child: Text("Tour starten", style: TextStyle(color: Colors.white)),
                                                    onPressed: () {
                                                      Navigator.pop(context);
                                                      sendLogs("log_tour_started", tour['tour']);
                                                      
                                                      // Android Auto Navigation starten
                                                      _startAndroidAutoNavigation(tour);
                                                      
                                                      // Normale App-Navigation starten
                                                      for (var i = 0; i < GblStops.length; i++) {
                                                        if (GblStops[i]['canceled'] != null && GblStops[i]['canceled'] == true) {
                                                          GblStops[i]['canceled'] = false;
                                                        }
                                                      }
                                                      GblStops = tour['stops'];
                                                      TourNameGbl = tour['tour'];
                                                      ArrivalTimesReal = [];
                                                      currentStoppIndex = 1;
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
                                                    }
                                                ))
                                            ),
                                            if (checkIfAnyModuleIsActive('BeforeDriveCheck') == true)
                                              Container(
                                                width: double.infinity, // Setzt die Breite auf die volle verfügbare Breite
                                                child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: HexColor.fromHex(getColor('primary')),),
                                                  child: Text("Abfahrkontrolle", style: TextStyle(color: Colors.white)),
                                                  onPressed: () {
                                                    sendLogs("log_tour_beforecheck_started", tour['tour']);
                                                    GblStops = tour['stops'];
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            BeforeDriveView(
                                                                lat: tour['lat'],
                                                                long: tour['long'],
                                                                stops: tour['stops']
                                                            ),
                                                      ),
                                                    );
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
                                        style: TextStyle(color: (currentStoppIndex == 1 && TourNameGbl == tour['tour']) || TourNameGbl != tour['tour']
                                            ? Colors.white
                                            : HexColor.fromHex(getColor('primary')), fontSize: 12,)),
                                  )),
                                  Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 2.0),
                                      child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: currentStoppIndex > 1 && TourNameGbl == tour['tour']
                                          ? HexColor.fromHex(getColor('primary'))
                                          : Colors.white,
                                      maximumSize: Size(100, 100),
                                    ),
                                    onPressed: () {
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
                                    child: Text("fortsetz.", style: TextStyle(color: currentStoppIndex > 1 && TourNameGbl == tour['tour']
                                        ? Colors.white
                                        : HexColor.fromHex(getColor('primary')), fontSize: 12,)),
                                  )),
                                  Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 2.0),
                                      child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: currentStoppIndex > 1 && TourNameGbl == tour['tour']
                                          ? HexColor.fromHex(getColor('primary'))
                                          : Colors.white,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        currentStoppIndex = 1;
                                      });
                                    },
                                    child: Text("beenden", style: TextStyle(color: currentStoppIndex > 1 && TourNameGbl == tour['tour']
                                        ? Colors.white
                                        : HexColor.fromHex(getColor('primary')), fontSize: 12,)),
                                  ))
                                ])
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