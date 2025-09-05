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
              child: BlinkingPoint(
                size: 15,
                color: Colors.white,
                duration: Duration(milliseconds: 500),
              ),
            ),
          actions: [
            if (checkIfAnyModuleIsActive('Chat') == true)
              IconButton(
                  icon: Icon(
                      Icons.chat_outlined,
                      color: Colors.white
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MessagesPage(),
                      ),
                    );
                  },
                  style: ButtonStyle(
                    iconSize: MaterialStateProperty.all(30.0),
                  )
              ),
            if (checkIfAnyModuleIsActive('Notifications') == true)
              IconButton(
                  icon: Icon(
                      Icons.info_outline,
                      color: Colors.white
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => NewsBoard(),
                      ),
                    );
                  },
                  style: ButtonStyle(
                    iconSize: MaterialStateProperty.all(30.0),
                  )
              ),
            IconButton(
                icon: Icon(
                    Icons.groups_3_outlined,
                    color: Colors.white
                ),
                onPressed: () => {
                  _showPessengerPopUp()
                },
                style: ButtonStyle(
                  iconSize: MaterialStateProperty.all(40.0),
                )
            ),
            if (checkIfAnyModuleIsActive('EmergencyPhonenumbers'))
              IconButton(
                  icon: Icon(
                      Icons.phone_outlined,
                      color: Colors.white
                  ),
                  onPressed: () => {
                    openPhonembers(context)
                  },
                  style: ButtonStyle(
                    iconSize: MaterialStateProperty.all(30.0),
                  )
              ),
            IconButton(
                icon: Icon(
                    Icons.airline_stops,
                    color: Colors.white
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
                  String origin = "${pos.latitude},${pos.longitude}";

                  List<Map<String, dynamic>> ergebnisse = [];

                  for (var ziel in GblStops) {
                    print('_A1');
                    final String destination = '${ziel["lat"]},${ziel["long"]}';
                    final String url =
                        'https://router.hereapi.com/v8/routes?transportMode=car&origin=$origin&destination=$destination&return=summary&apiKey=$apiKey';

                    final response = await http.get(Uri.parse(url));
                    print('_B1');
                    if (response.statusCode == 200) {
                      print('_C1');
                      final data = jsonDecode(response.body);
                      final route = data['routes']?[0];
                      final section = route?['sections']?[0];

                      if (section != null) {
                        final summary = section['summary'];
                        final arrival = section['arrival'];

                        ergebnisse.add({
                          "firstname": ziel["firstname"],
                          "lastname": ziel["lastname"],
                          "eta_arrival": arrival["time"].split("T")[1].split("+")[0]
                        });
                      }
                    }
                  }

                  Navigator.of(context).pop();
                  if (ergebnisse.isNotEmpty) {
                    showStopListPopup(context, ergebnisse);
                  }
                },
                style: ButtonStyle(
                  iconSize: MaterialStateProperty.all(30.0),
                )
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
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Passagiere"),
          content: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * 0.9,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: GblStops.length,
                      itemBuilder: (context, index) {
                        final stop = GblStops[index];
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                      children: [Text(
                                        "${stop['firstname'] ?? ''} ${stop['lastname'] ?? ''}",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: stop['canceled'] != null && stop['canceled'] == true ? Colors.red : Colors.black,
                                          fontSize: 16,
                                          //decoration: stop['canceled'] != null && stop['canceled'] == true ? TextDecoration.lineThrough : TextDecoration.none,
                                        ),
                                      )]
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Padding(
                                                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                                child:Text(
                                                  "${stop['address']}\n\n${(stop['info'] != null ? stop['info'] : '')}" ?? '',
                                                  softWrap: true,
                                                  overflow: TextOverflow.clip,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.normal,
                                                    color: stop['canceled'] != null && stop['canceled'] == true ? Colors.red : Colors.black,
                                                    fontSize: 14,
                                                  ),
                                                )
                                            ),
                                          )
                                        ],
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          if (stop['canceled'] == null || stop['canceled'] == false)
                                            IconButton(
                                                onPressed: () => {
                                                  launchUrlString("tel:${stop['phone']}")
                                                },
                                                icon: Icon(
                                                  Icons.phone,
                                                  color: Colors.green,
                                                )
                                            ),
                                          if (stop['canceled'] == null || stop['canceled'] == false)
                                            IconButton(
                                                onPressed: () => {
                                                  launchUrlString("tel:${stop['mobile']}")
                                                },
                                                icon: Icon(
                                                  Icons.phone_android,
                                                  color: Colors.green,
                                                )
                                            ),
                                          if (stop['canceled'] == null || stop['canceled'] == false)
                                            IconButton(
                                                onPressed: () {
                                                  showCustomDialog(
                                                      context,
                                                      "Wirklich abmelden",
                                                      "Ja, ich möchte den Passagier wirklich von der Fahrt abmelden?",
                                                      [
                                                        Container(
                                                            width: double.infinity, // Setzt die Breite auf die volle verfügbare Breite
                                                            child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: HexColor.fromHex(getColor('primary')),),
                                                              onPressed: () {
                                                                setState(() {
                                                                  GblStops[index]['canceled'] = true;
                                                                });
                                                                Navigator.pop(context);
                                                                Navigator.pop(context);
                                                                _showPessengerPopUp();
                                                              },
                                                              child: Text('Ja', style: TextStyle(color: Colors.white)),
                                                            )),
                                                        Container(
                                                            width: double.infinity, // Setzt die Breite auf die volle verfügbare Breite
                                                            child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: HexColor.fromHex(getColor('primary')),),
                                                              onPressed: () {
                                                                Navigator.pop(context);
                                                              },
                                                              child: Text('Nein', style: TextStyle(color: Colors.white)),
                                                            )),
                                                      ]
                                                  );
                                                },
                                                icon: Icon(
                                                  Icons.cancel,
                                                  color: Colors.red,
                                                )
                                            )
                                        ],
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8.0),
                                  Divider(
                                    color: Colors.black,  // Farbe der Linie
                                    thickness: 1,  // Dicke der Linie
                                    indent: 20,  // Abstand von links
                                    endIndent: 20,  // Abstand von rechts
                                  ),
                                  SizedBox(height: 8.0),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              )
          ),
          actions: [
            Container(
                width: double.infinity, // Setzt die Breite auf die volle verfügbare Breite
                child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: HexColor.fromHex(getColor('primary')),),
                    child: Text("schließen", style: TextStyle(color: Colors.white)),
                    onPressed: () => {
                      Navigator.pop(context)
                    }
                ))
          ],
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

  final response = await http.get(Uri.parse(getUrl('get-emergencynumbers')));

  Navigator.of(context).pop(); // Schließt den Ladekreis

  if (response.statusCode == 200) {
    List<dynamic> phoneNumbers = json.decode(response.body);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Notfallrufnummern'),
          content: SingleChildScrollView(
            child: ListBody(
              children: phoneNumbers.map((phone) {
                return ListTile(
                  title: Text(phone['name']),
                  subtitle: Text(phone['number']),
                  trailing: IconButton(
                    icon: Icon(Icons.phone, color: Colors.green),
                    onPressed: () {
                      sendLogs("log_call_phonenumber", "tel:${phone['number']}");
                      launchUrlString('tel:${phone['number']}');
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          actions: <Widget>[
            Container(
                width: double.infinity, // Setzt die Breite auf die volle verfügbare Breite
                child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: HexColor.fromHex(getColor('primary')),),
                  child: Text('Schließen', style: TextStyle(color: Colors.white)),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                )),
          ],
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
      return AlertDialog(
        title: const Text("Ankunftszeiten (ETA)"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: ergebnisse.length,
            itemBuilder: (context, index) {
              final stop = ergebnisse[index];
              return ListTile(
                leading: const Icon(Icons.directions_bus, color: Colors.blueAccent),
                title: Text('${stop["firstname"] == 'null' || stop["firstname"] == null ? '' : stop["firstname"]} ${stop["lastname"]}'),
                subtitle: Text('ETA: ${stop["eta_arrival"]}'),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            child: const Text("Schließen"),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      );
    },
  );
}


