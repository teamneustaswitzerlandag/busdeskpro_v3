import 'package:bus_desk_pro/config/globals.dart';
import 'package:bus_desk_pro/libaries/logs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class RadienzeitenScreen extends StatefulWidget {
  @override
  _RadienzeitenScreenState createState() => _RadienzeitenScreenState();
}

class _RadienzeitenScreenState extends State<RadienzeitenScreen> {

  bool showSent = true;
  bool isSending = false;
  final _storage = FlutterSecureStorage();

  List<String> sendItems = [];
  List<String> notSendItems = [];

  @override
  void initState() {
    setBufferLogsFromStorage();
    super.initState();
  }

  Map<String, dynamic> parseEvent(String event) {
    print('AAA');
    print(event);
    if (event != '') {
      final parts = event.split("_");
      return {
        "stationId": parts[0],
        "planzeit": parts[1],
        "lastname": parts[2],
        "firstname": parts[3],
        "isostring": parts[4],
        "tourname": parts[5],
        "mandant": parts[6],
        "ankunftszeit": parts[7],
      };
    } else {
      return {
        "stationId": "",
        "planzeit": "",
        "lastname": "",
        "firstname": "",
        "isostring": "1970-01-01",
        "tourname": "",
        "mandant": "",
        "ankunftszeit": "",
      };
    }
  }

  Future<void> sendUnsentLogs() async {
    setState(() => isSending = true);

    // Kopie, damit wir während des Loops Einträge entfernen können
    final List<String> toSend = List.from(notSendItems);

    for (var log in toSend) {
      if (log != "" && log != " " && log != null && log != "," && log != " ,") {
        try {
          final url =
              "http://bus-dashboard.dxp.azure.neusta.cloud:7698/arrivedInRadius?query=$log";
          final response = await http.get(Uri.parse(url));

          if (response.statusCode == 200) {
            setState(() async {
              notSendItems.remove(log);
              var bufferOfLogTimesNotSendString = await _storage.read(
                  key: 'bufferOfLogTimesNotSend');
              bufferOfLogTimesNotSend = bufferOfLogTimesNotSendString == null
                  ? []
                  : bufferOfLogTimesNotSendString.split('||');
              bufferOfLogTimesNotSend.remove(log);
              await _storage.write(key: 'bufferOfLogTimesNotSend',
                  value: bufferOfLogTimesNotSend.join('||'));

              sendItems.add(log);
              var bufferOfLogTimesSendString = await _storage.read(
                  key: 'bufferOfLogTimesSend');
              bufferOfLogTimesSend = bufferOfLogTimesSendString == null
                  ? []
                  : bufferOfLogTimesSendString.split('||');
              bufferOfLogTimesSend.add(log);
              await _storage.write(key: 'bufferOfLogTimesSend',
                  value: bufferOfLogTimesSend.join('||'));
            });
          } else {
            debugPrint(
                "⚠️ Fehler beim Senden von $log: ${response.statusCode}");
          }
        } catch (e) {
          debugPrint("❌ Netzwerkfehler: $e");
        }
      }
    }

    setState(() => isSending = false);
  }

  Future<void> setBufferLogsFromStorage() async {
    var bufferOfLogTimesSendString = await _storage.read(key: 'bufferOfLogTimesSend');
    bufferOfLogTimesSend = bufferOfLogTimesSendString == null ? [] : bufferOfLogTimesSendString.split('||');

    var bufferOfLogTimesNotSendString = await _storage.read(key: 'bufferOfLogTimesNotSend');
    bufferOfLogTimesNotSend = bufferOfLogTimesNotSendString == null ? [] : bufferOfLogTimesNotSendString.split('||');

    setState(() {
      sendItems = bufferOfLogTimesSend;
      notSendItems = bufferOfLogTimesNotSend;
    });
  }

  @override
  Widget build(BuildContext context) {

    final events = showSent ? sendItems : notSendItems;
print('BBB');
print(events);
    final parsed = events.map(parseEvent).toList()
      ..sort((a, b) {
        // Erst nach isostring (Datum) vergleichen
        int dateComparison = b["isostring"].compareTo(a["isostring"]);
        if (dateComparison != 0) {
          return dateComparison; // Wenn Datum unterschiedlich ist, danach sortieren
        }

        // Bei gleichem Datum nach Ankunftszeit sortieren
        String timeA = a["ankunftszeit"].toString().replaceAll('CUR', '');
        String timeB = b["ankunftszeit"].toString().replaceAll('CUR', '');
        return timeB.compareTo(timeA);
      });

    return Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: HexColor.fromHex(getColor('primary')),
          iconTheme: const IconThemeData(
            color: Colors.white, // Farbe des Zurückpfeils
          ),
          title: Text(
            'Logs Geo- Radien',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 20.0,
            ),
          ),
          centerTitle: true,
        ),
        body: Stack(
          children: [
            // Inhalt
            Column(
              children: [
                // 🔴 Toggle
                Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: HexColor.fromHex(getColor('primary')),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => showSent = true),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: showSent ? HexColor.fromHex(getColor('primary')) : Colors.transparent,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Center(
                              child: Text(
                                "Gesendet",
                                style: TextStyle(
                                    decoration: TextDecoration.none,
                                    color: showSent ? Colors.white : Colors.white70,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => showSent = false),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color:
                              !showSent ? HexColor.fromHex(getColor('primary')) : Colors.transparent,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Center(
                              child:  Text(
                                "Nicht gesendet",
                                style: TextStyle(
                                    decoration: TextDecoration.none,
                                    color: !showSent ? Colors.white : Colors.white70,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 📋 Liste
                Expanded(
                  child: Container(
                    color: Colors.white,
                    child: ListView(
                      children: (() {
                        // Daten nach Datum gruppieren
                        Map<String, List<Map<String, dynamic>>> grouped = {};
                        for (var e in parsed) {
                          if (e["isostring"] != "1970-01-01") {
                            final date = DateFormat("yyyy-MM-dd")
                                .format(DateTime.parse(e["isostring"]));
                            if (!grouped.containsKey(date)) grouped[date] = [];
                            grouped[date]!.add(e);
                          }
                        }

                        // Liste der Widgets aufbauen
                        List<Widget> widgets = [];
                        // absteigend sortieren nach Datum
                        var sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

                        for (var date in sortedKeys) {
                          widgets.add(
                            ExpansionTile(
                              backgroundColor: Colors.white,
                              collapsedBackgroundColor: Colors.white,
                              tilePadding: EdgeInsets.symmetric(horizontal: 8),
                              childrenPadding: EdgeInsets.zero,
                              title: Text(
                                date,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.black87),
                              ),
                              children: grouped[date]!.map((e) {
                                return Card(
                                  color: Colors.white,
                                  elevation: 0, // Kein Schatten
                                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                  child: ListTile(
                                    title: Text("${e["tourname"]}"),
                                    subtitle: Text(
                                        "${e["firstname"]}, ${e["lastname"]}\nPlanzeit: ${e["planzeit"]}\nAnkunftszeit: ${e["ankunftszeit"].replaceAll('CUR', '')}"),
                                  ),
                                );
                              }).toList(),
                            ),
                          );
                        }

                        return widgets;
                      })(),
                    ),
                  ),
                ),
              ],
            ),

            // ⬇️ Button nur bei "Nicht gesendet"
            if (!showSent)
              Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: HexColor.fromHex(getColor('primary')),
                      padding: const EdgeInsets.all(16),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    onPressed: isSending ? null : sendUnsentLogs,
                    child: isSending
                        ? const CircularProgressIndicator(
                      color: Colors.white,
                    )
                        : const Text(
                      "Zeiten senden",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              ),
          ],
    ));
  }
}
