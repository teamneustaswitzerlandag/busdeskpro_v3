library busdeskpro.logs;
import 'dart:async';
import 'dart:ui';

import 'package:bus_desk_pro/config/globals.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'dart:convert';
//import 'package:geolocator/geolocator.dart';

Future<void> sendLogs(String type, String bodyText) async {
  final uri = Uri.parse("https://prod-40.westeurope.logic.azure.com:443/workflows/58251dad66394f29b52076e1b8a83f82/triggers/BusDeskProLog/paths/invoke?api-version=2016-10-01&sp=%2Ftriggers%2FBusDeskProLog%2Frun&sv=1.0&sig=6BxiTIxY4jrdNbVO-G0pp2-ZQYvdmdcfUOgeuEV6Rdc");

  // Request-Header
  final headers = {
    'Content-Type': 'application/json',
  };

  // JSON-Body
  final body = jsonEncode({
    "mandant": MandantAuth,
    "appId": AppUserId,
    "type": type,
    "body": bodyText,
  });

  /*try {
    final response = await http.post(uri, headers: headers, body: body);

    if (response.statusCode == 200) {
      print("Logs erfolgreich gesendet: ${response.body}");
    } else {
      print("Fehler beim Senden der Logs: ${response.statusCode} - ${response.body}");
    }
  } catch (e) {
    print("Es ist ein Fehler aufgetreten: $e");
  }*/

  try {
    http.get(Uri.parse("http://bus-dashboard.dxp.azure.neusta.cloud:7698/log?query=${"${body}"}"));
  } catch (e) {}
}

Future<void> InitUniqueAppUserId() async {
  final storage = FlutterSecureStorage();
  // Lese die ID aus dem sicheren Speicher
  AppUserId = await storage.read(key: 'unique_app_id');

  // Wenn keine ID vorhanden ist, generiere eine neue
  if (AppUserId == null || AppUserId == "") {
    var uuid = Uuid();
    AppUserId = uuid.v4(); // Generiere eine zufällige UUID
    await storage.write(key: 'unique_app_id', value: AppUserId);
  }
}

bool checkIfAnyModuleIsActive(String name) {
  List<dynamic> modules = GblTenant['modules'];
  return modules.any((module) => module['active'] == true && module['module'] == name);
}

String getUrl(String name) {
  List<dynamic> modules = GblTenant['apis'];
  for (var module in modules) {
    if (module['api'] == name) {
      return module['url'];
    }
  }
  return '';
}

String getColor(name) {
  List<dynamic> modules = GblTenant['colors'];
  for (var module in modules) {
    if (module['name'] == name) {
      return module['value'];
    }
  }
  return '';
}

String getLogo(name) {
  List<dynamic> modules = GblTenant['logos'];
  for (var module in modules) {
    if (module['name'] == name) {
      return module['value']['\$content'];
    }
  }
  return '';
}

String getLanguage(name) {
  List<dynamic> modules = GblTenant['languages'];
  for (var module in modules) {
    if (module['name'] == name) {
      return module['value'];
    }
  }
  return '';
}

extension HexColor on Color {
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}

Future<int> fetchNewsCount() async {
  String jsonString = await rootBundle.loadString('lib/config/apis.json');
  Map<String, dynamic> parsedJson = json.decode(jsonString);
  final url = Uri.parse(getUrl('get-notifications'));

  final response = await http.get(url);

  if (response.statusCode == 200) {
    final List<dynamic> data = json.decode(response.body);
    return data.length;
  } else {
    throw Exception('Fehler beim Abrufen der Nachrichten');
  }
}

void startLocationUpdates() {
  Timer.periodic(Duration(seconds: 10), (timer) async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Location services are disabled.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Location permissions are denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('Location permissions are permanently denied, we cannot request permissions.');
      return;
    }

    Position position = await Geolocator.getCurrentPosition();
    currentPosition = position;
    //print('Latitude: ${position.latitude}, Longitude: ${position.longitude}');
    sendLogs("login_step1", "${PhoneNumberAuth}_lat_${position.latitude}_long_${position.longitude}_${TourNameGbl}");
  });
}