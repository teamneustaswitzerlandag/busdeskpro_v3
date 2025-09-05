library busdeskpro.tour;
import 'dart:convert';
import 'package:bus_desk_pro/config/globals.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

getTextOfStoppType(int type) {
  String text = '';
  switch(type) {
    case 10: text = 'Start Mitarbeiter';
      break;
    case 15: text = 'Einstieg Begleitperson';
      break;
    case 17: text = 'Bereitstellung';
      break;
    case 18: text = 'Einstieg Einrichtung';
      break;
    case 20: text = 'Einstieg';
      break;
    case 25: text = 'Einstieg Umsetzer';
      break;
    case 75: text = 'Ausstieg Umsetzer';
      break;
    case 80: text = 'Ausstieg';
      break;
    case 82: text = 'Ausstieg Einrichtung';
      break;
    case 83: text = 'Abfahrt';
      break;
    case 85: text = 'Ausstieg Begleitperson';
      break;
    case 90: text = 'Ziel Mitarbeiter';
      break;
  }
  return text;
}

getArrivalTimes() async {
  String waypointstring = "";
  for (var i = 0; i < GblStops.length; i++) {
    if (i != 0 && i != GblStops.length - 1) {
      waypointstring += "via:" + GblStops[i]['lat'] + ',' + GblStops[i]['long'] + '|';
    }
  }
  final String url = 'https://maps.googleapis.com/maps/api/directions/json?departure_time=now&destination=${GblStops[GblStops.length - 1]['lat']},${GblStops[GblStops.length - 1]['long']}&origin=${GblStops[0]['lat']},${GblStops[0]['long']}&waypoints=${waypointstring}&key=AIzaSyDjIyOeJktq5NohQimw-EPbirdPQwfOfHg';
  final response = await http.get(Uri.parse(url));
  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    // Abfahrtszeit (jetzt)
    DateTime departureTime = DateTime.now();

    // Liste der Ankunftszeiten initialisieren
    List<DateTime> arrivalTimes = [];

    // Ankunftszeiten für die Wegpunkte berechnen
    List<String> waypointTimes = [];
    int temp_arrivaltime = 0;
    int startIndex = 0;
    int lastStepIndex = 0;
    DateTime now = DateTime.now();
    for (var j = 0; j < data['routes'][0]['legs'][0]['via_waypoint'].length; j++) {
      var wayPoint = data['routes'][0]['legs'][0]['via_waypoint'][j];
      int stepIndex = wayPoint['step_index'];
      for (var i = lastStepIndex; i <= stepIndex; i++) {
        temp_arrivaltime += int.parse(data['routes'][0]['legs'][0]['steps'][i]['duration']['value'].toString());
      }
      lastStepIndex = stepIndex;
      DateTime waypointTime = now.add(Duration(seconds: (temp_arrivaltime + 180)));
      String formattedTime = DateFormat('HH:mm:ss').format(waypointTime);
      waypointTimes.add(formattedTime);
      temp_arrivaltime = 0;
      now = waypointTime;
    }
    print('START2');
    print(waypointTimes);
    ArrivalTimesReal = waypointTimes;
    return waypointTimes;
  }
}