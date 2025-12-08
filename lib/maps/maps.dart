import 'dart:convert';
import 'dart:io';

import 'package:bus_desk_pro/LandingPage.dart';
import 'package:bus_desk_pro/config/globals.dart';
import 'package:bus_desk_pro/libaries/blinking_point.dart';
import 'package:bus_desk_pro/libaries/logs.dart';
import 'package:bus_desk_pro/libaries/popup.dart';
import 'package:bus_desk_pro/maps/mapEngine.dart';
import 'package:bus_desk_pro/menu/home.dart';
import 'package:bus_desk_pro/menu/messages.dart';
import 'package:bus_desk_pro/others/newsboard.dart';
import 'package:bus_desk_pro/widgets/news_board_popup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/core.engine.dart';
import 'package:here_sdk/core.errors.dart';
import 'package:here_sdk/mapview.dart';
import 'package:here_sdk/maploader.dart';
import 'package:here_sdk/routing.dart' as Routing;
import 'package:here_sdk/search.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:bus_desk_pro/maps/here/AppLogic.dart';
import 'package:bus_desk_pro/maps/here/HEREPositioningTermsAndPrivacyHelper.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'here_new/common/application_preferences.dart';
import 'here_new/common/custom_map_style_settings.dart';
import 'here_new/common/ui_style.dart';
import 'here_new/download_maps/download_maps_screen.dart';
import 'here_new/download_maps/map_loader_controller.dart';
import 'here_new/download_maps/map_regions_list_screen.dart';
import 'here_new/landing_screen.dart';
import 'here_new/navigation/navigation_screen.dart';
import 'here_new/positioning/positioning_engine.dart';
import 'here_new/route_preferences/route_preferences_model.dart';
import 'here_new/routing/route_details_screen.dart';
import 'here_new/routing/routing_screen.dart';
import 'here_new/routing/waypoint_info.dart';
import 'here_new/routing/waypoints_controller.dart';
import 'here_new/search/recent_search_data_model.dart';
import 'here_new/search/search_results_screen.dart';
import 'environment.dart';
import 'here_new/positioning/no_location_warning_widget.dart';
import 'here_new/positioning/positioning.dart';
import 'here_new/positioning/positioning_engine.dart';
import 'package:http/http.dart' as http;

/// Application root widget.
class InitNavigationMap extends StatefulWidget {
  final double? lat;
  final double? long;
  final List? stop_;
  final bool? isFreeDrive;

  const InitNavigationMap({super.key, this.lat, this.long, this.stop_, this.isFreeDrive});

  @override
  State<InitNavigationMap> createState() => _InitMap();
}

class _InitMap extends State<InitNavigationMap> {

  bool isCollapsedStoppbar = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('LL1');
    return Scaffold(
        appBar: AppBar(
          backgroundColor: HexColor.fromHex(getColor('primary')),
          automaticallyImplyLeading: false,
          elevation: 0,
          title: Text(
            '',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 20.0,
            ),
          ),
          leading:
            Center(
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                  border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                ),
                child: Center(
              child: BlinkingPoint(
                    size: 12,
                color: Colors.white,
                    duration: Duration(milliseconds: 800),
                  ),
                ),
              ),
            ),
          actions: [
            if (checkIfAnyModuleIsActive('Chat') == true)
              Container(
                margin: EdgeInsets.symmetric(horizontal: 1),
                child: IconButton(
                  icon: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                    ),
                    child: Icon(
                      Icons.forum_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MessagesPage(),
                      ),
                    );
                  },
                ),
              ),
            if (checkIfAnyModuleIsActive('Notifications') == true)
              Container(
                margin: EdgeInsets.symmetric(horizontal: 1),
                child: IconButton(
                  icon: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                    ),
                    child: Icon(
                      Icons.notifications_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  onPressed: () {
                    _showNewsBoardPopup();
                  },
                ),
              ),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 1),
              child: IconButton(
                icon: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                  ),
                  child: Icon(
                    Icons.group_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                onPressed: () => {
                  _showPessengerPopUp()
                },
              ),
            ),
            if (checkIfAnyModuleIsActive('EmergencyPhonenumbers'))
              Container(
                margin: EdgeInsets.symmetric(horizontal: 1),
                child: IconButton(
                  icon: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                    ),
                    child: Icon(
                      Icons.phone_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  onPressed: () => {
                    openPhonembers(context)
                  },
                ),
              ),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 1),
              child: IconButton(
                icon: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                  ),
                  child: Icon(
                    Icons.route_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                onPressed: () async {

                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => const AlertDialog(
                      content: Row(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(width: 20),
                          Text("Warte einen Augenblick bis\ndie aktuellen ETAs vorliegen..."),
                        ],
                      ),
                    ),
                  );

                  const String apiKey = 'm_xqMoC6hEma5peZ929OSw4NTmX0d0XFKD4hsqwVhbQ';
                  GeoCoordinates pos = GeoCoordinates(currentPosition!.latitude, currentPosition!.longitude);
                  
                  // Startpunkt ist die aktuelle Position
                  String currentOrigin = "${pos.latitude},${pos.longitude}";
                  
                  List<Map<String, dynamic>> ergebnisse = [];
                  
                  // Kumulative Zeit ab jetzt
                  DateTime currentTime = DateTime.now();

                  for (int i = 0; i < GblStops.length; i++) {
                    var ziel = GblStops[i];
                    print('_A1 - Berechne Route zu Stopp ${i + 1}');
                    
                    final String destination = '${ziel["lat"]},${ziel["long"]}';
                    final String url =
                        'https://router.hereapi.com/v8/routes?transportMode=car&origin=$currentOrigin&destination=$destination&return=summary&apiKey=$apiKey';

                    final response = await http.get(Uri.parse(url));
                    print('_B1');
                    if (response.statusCode == 200) {
                      print('_C1');
                      final data = jsonDecode(response.body);
                      final route = data['routes']?[0];
                      final section = route?['sections']?[0];

                      if (section != null) {
                        final summary = section['summary'];
                        
                        // Fahrzeit in Sekunden zur aktuellen Zeit addieren
                        int durationInSeconds = summary['duration'] ?? 0;
                        currentTime = currentTime.add(Duration(seconds: durationInSeconds));
                        
                        // ETA formatieren (HH:mm:ss)
                        String etaFormatted = '${currentTime.hour.toString().padLeft(2, '0')}:${currentTime.minute.toString().padLeft(2, '0')}:${currentTime.second.toString().padLeft(2, '0')}';

                        ergebnisse.add({
                          "firstname": ziel["firstname"],
                          "lastname": ziel["lastname"],
                          "eta_arrival": etaFormatted
                        });
                        
                        // Nächster Startpunkt ist das aktuelle Ziel
                        currentOrigin = destination;
                      }
                    }
                  }

                  Navigator.of(context).pop();
                  if (ergebnisse.isNotEmpty) {
                    showStopListPopup(context, ergebnisse);
                  }
                },
              ),
            ),
            /*IconButton(
              icon: Icon(
                Icons.flag_rounded,
                color: Colors.white,
              ),
                onPressed: () async {}

              )*/
          ],
      ),
      body: MapsEngine(
        lat: widget.lat,
        long: widget.long,
        stop_: widget.stop_,
        isFreeDrive: widget.isFreeDrive,
      ),
    );
  }

  Future<void> _showPessengerPopUp() async {
    List stop_ = widget.stop_ ?? [];
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.95,
            height: MediaQuery.of(context).size.height * 0.85,
              child: Column(
              children: [
                // Moderner Header
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: HexColor.fromHex(getColor('primary')),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                children: [
                      Icon(Icons.group_rounded, color: Colors.white, size: 24),
                      SizedBox(width: 12),
                      Text(
                        "Passagiere & Stopps",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Spacer(),
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                // Kompakter Content
                  Expanded(
                    child: ListView.builder(
                    padding: EdgeInsets.all(8),
                      itemCount: GblStops.length,
                      itemBuilder: (context, index) {
                        final stop = GblStops[index];
                      return Container(
                        margin: EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: stop['canceled'] == true 
                            ? Colors.red.withOpacity(0.1) 
                            : Colors.grey.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: stop['canceled'] == true 
                              ? Colors.red.withOpacity(0.3) 
                              : Colors.grey.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                              // Name und Status
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                        "${stop['firstname'] ?? ''} ${stop['lastname'] ?? ''}",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: stop['canceled'] == true ? Colors.red : Colors.black87,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  if (stop['canceled'] == true)
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        "Abgemeldet",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              SizedBox(height: 8),
                              // Adresse und Info
                              Text(
                                "${stop['address'] ?? ''}",
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 14,
                                ),
                              ),
                              if (stop['info'] != null && stop['info'].toString().isNotEmpty) ...[
                                SizedBox(height: 4),
                                Text(
                                  "${stop['info']}",
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                              SizedBox(height: 12),
                              // Action Buttons - nur anzeigen wenn nicht "Ende der Fahrt"
                              if ((stop['canceled'] == null || stop['canceled'] == false) && 
                                  stop['firstname']?.toString().toLowerCase() != 'ende der fahrt' &&
                                  stop['lastname']?.toString().toLowerCase() != 'ende der fahrt')
                                Row(
                                        children: [
                                    // Telefon Button
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.green.withOpacity(0.3)),
                                      ),
                                      child: IconButton(
                                        icon: Icon(Icons.phone_rounded, color: Colors.green, size: 20),
                                        onPressed: () => launchUrlString("tel:${stop['phone']}"),
                                        padding: EdgeInsets.all(8),
                                        constraints: BoxConstraints(minWidth: 40, minHeight: 40),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    // Mobile Button
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                                      ),
                                      child: IconButton(
                                        icon: Icon(Icons.phone_android_rounded, color: Colors.blue, size: 20),
                                        onPressed: () => launchUrlString("tel:${stop['mobile']}"),
                                        padding: EdgeInsets.all(8),
                                        constraints: BoxConstraints(minWidth: 40, minHeight: 40),
                                      ),
                                    ),
                                    Spacer(),
                                    // Abmelden Button
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                                      ),
                                      child: IconButton(
                                        icon: Icon(Icons.person_remove_rounded, color: Colors.red, size: 20),
                                                onPressed: () {
                                                  showCustomDialog(
                                                      context,
                                            "Passagier abmelden",
                                            "Möchten Sie ${stop['firstname']} ${stop['lastname']} wirklich von der Fahrt abmelden?",
                                                      [
                                                        Container(
                                                width: double.infinity,
                                                child: ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: HexColor.fromHex(getColor('primary')),
                                                    padding: EdgeInsets.symmetric(vertical: 12),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                  ),
                                                              onPressed: () {
                                                                setState(() {
                                                                  GblStops[index]['canceled'] = true;
                                                                });
                                                                Navigator.pop(context);
                                                                Navigator.pop(context);
                                                                _showPessengerPopUp();
                                                              },
                                                  child: Text('Ja, abmelden', style: TextStyle(color: Colors.white)),
                                                ),
                                              ),
                                              SizedBox(height: 8),
                                                        Container(
                                                width: double.infinity,
                                                child: ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.grey[300],
                                                    padding: EdgeInsets.symmetric(vertical: 12),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                  ),
                                                  onPressed: () => Navigator.pop(context),
                                                  child: Text('Abbrechen', style: TextStyle(color: Colors.black87)),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                        padding: EdgeInsets.all(8),
                                        constraints: BoxConstraints(minWidth: 40, minHeight: 40),
                                      ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                        );
                      },
                    ),
                  ),
                ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showNewsBoardPopup() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.95,
            height: MediaQuery.of(context).size.height * 0.9,
            child: NewsBoardPopup(),
          ),
        );
      },
    );
  }
}

void openPhonembers(BuildContext context) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Center(
        child: CircularProgressIndicator(),
      );
    },
  );

  final response = await http.get(
    Uri.parse('${getUrl('get-emergencynumbers')}?phonenumber=$PhoneNumberAuth'),
  );

  Navigator.of(context).pop(); // Schließt den Ladekreis

  if (response.statusCode == 200) {
    List<dynamic> phoneNumbers = json.decode(response.body);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.7,
            child: Column(
              children: [
                // Moderner Header
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: HexColor.fromHex(getColor('primary')),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.emergency_rounded, color: Colors.white, size: 24),
                      SizedBox(width: 12),
                      Text(
                        "Notfallrufnummern",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Spacer(),
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                // Kompakter Content
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.all(12),
                    itemCount: phoneNumbers.length,
                    itemBuilder: (context, index) {
                      final phone = phoneNumbers[index];
                      return Container(
                        margin: EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // Icon
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.phone_rounded,
                                  color: Colors.red,
                                  size: 20,
                                ),
                              ),
                              SizedBox(width: 16),
                              // Text Content
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      phone['name'] ?? 'Unbekannt',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      phone['number'] ?? '',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Call Button
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                                ),
                                child: IconButton(
                                  icon: Icon(Icons.call_rounded, color: Colors.red, size: 20),
                    onPressed: () {
                      sendLogs("log_call_phonenumber", "tel:${phone['number']}");
                      launchUrlString('tel:${phone['number']}');
                                  },
                                  padding: EdgeInsets.all(8),
                                  constraints: BoxConstraints(minWidth: 40, minHeight: 40),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  } else {
    throw Exception('Failed to load phone numbers');
  }
}

void showStopListPopup(BuildContext context, List<Map<String, dynamic>> ergebnisse) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              // Moderner Header
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: HexColor.fromHex(getColor('primary')),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule_rounded, color: Colors.white, size: 24),
                    SizedBox(width: 12),
                    Text(
                      "Ankunftszeiten (ETA)",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Spacer(),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Kompakter Content
              Expanded(
          child: ListView.builder(
                  padding: EdgeInsets.all(12),
            itemCount: ergebnisse.length,
            itemBuilder: (context, index) {
              final stop = ergebnisse[index];
                    return Container(
                      margin: EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.blue.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Icon
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.directions_bus_rounded,
                                color: Colors.blue,
                                size: 20,
                              ),
                            ),
                            SizedBox(width: 16),
                            // Text Content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${stop["firstname"] == 'null' || stop["firstname"] == null ? '' : stop["firstname"]} ${stop["lastname"]}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time_rounded,
                                        color: Colors.blue,
                                        size: 16,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'ETA: ${stop["eta_arrival"]}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[700],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Status Badge
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue.withOpacity(0.3)),
                              ),
                              child: Text(
                                "Ankunft",
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              );
            },
          ),
        ),
            ],
          ),
        ),
      );
    },
  );
}


