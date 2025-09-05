import 'dart:async';

import 'package:bus_desk_pro/LandingPage.dart';
import 'package:bus_desk_pro/config/globals.dart';
import 'package:bus_desk_pro/libaries/logs.dart';
import 'package:bus_desk_pro/libaries/popup.dart';
import 'package:bus_desk_pro/maps/maps.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Future<bool> reachedDestinationHandler(context) async {
    sendLogs("log_reached_stopp_manually_clicked", "${GblStops[currentStoppIndex]["tour"]}_${GblStops[currentStoppIndex]["isostring"]}_${GblStops[currentStoppIndex]["time"]}_${GblStops[currentStoppIndex]["stopp_type"]}");
    final Completer<bool> completer = Completer<bool>();
    void nextStep() async {
      print('VV1');
      var tourHasEnded = false;
      print(currentStoppIndex);
      for (int i = currentStoppIndex + 1; i < GblStops.length; i++) {
        if (GblStops[i]['canceled'] == false || GblStops[i]['canceled'] == null) {
          currentStoppIndex = i;
          print(i);
          break;
        }
      }
      if (currentStoppIndex + 1 <= (GblStops.length - 1)) {
        /*print("AA1");
        if (GblStops[currentStoppIndex + 1]['canceled'] == true) {
          print("BB1");
          currentStoppIndex = currentStoppIndex + 2;
          print(GblStops);
        } else {
          print("CC1");
          currentStoppIndex = currentStoppIndex + 1;
        }*/
      } else {
        print("DD1");
        tourHasEnded = true;
        /*setState(() {
                        currentStoppIndex = GblStops.length;
                      });*/
      }
      // currentStoppIndex < (GblStops.length - 1) || currentStoppIndex == (GblStops.length - 1)
      if (tourHasEnded == false) {
        print("FF1");
        sendLogs("log_started_stopp", "${GblStops[currentStoppIndex]["tour"]}_${GblStops[currentStoppIndex]["isostring"]}_${GblStops[currentStoppIndex]["time"]}_${GblStops[currentStoppIndex]["stopp_type"]}");
        Navigator.pop(context);
        completer.complete(false);

        ////
      } else {
        completer.complete(true);
        print("EE1");
        //Navigator.pop(context);
        showCustomDialog(
            context,
            "Letzter Stopp",
            "Du hast den letzten Stopp der Tour bereits ausgewählt",
            [
              Builder(builder: (context) =>
                Container(
                    width: double.infinity, // Setzt die Breite auf die volle verfügbare Breite
                    child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: HexColor.fromHex(getColor('primary')),),
                        child: Text("Zur Tourenübersicht", style: TextStyle(color: Colors.white)),
                        onPressed: () async {
                          currentStoppIndex = 1;
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (context) => LandingPage(title: "BusDesk Pro")),
                                (Route<dynamic> route) => false,
                          );
                          completer.complete(true);
                        }
                    )
                )
              )
            ]
        );
      }
    }

    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    switch(GblStops[currentStoppIndex]["stopp_type"]) {
      case 17:
      case 90:
      //SdkContext.release();
        showCustomDialog(
            context,
            "Bestätigen",
            "Ankunft am Ziel bestätigen?",
            [
              Builder(
                  builder: (context) =>
                    Container(
                        width: double.infinity, // Setzt die Breite auf die volle verfügbare Breite
                        child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: HexColor.fromHex(getColor('primary')),),
                            child: Text("bestätigen", style: TextStyle(color: Colors.white)),
                            onPressed: () async {
                              Navigator.pop(context);
                              nextStep();
                            }
                        ))
                  )
            ]
        );
        break;
      case 15: showCustomDialog(
          context,
          "Bestätigen",
          "Ist die Begleitperson eingestiegen?",
          [
            Builder(
                builder: (context) =>
                  Container(
                      width: double.infinity, // Setzt die Breite auf die volle verfügbare Breite
                      child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: HexColor.fromHex(getColor('primary')),),
                          child: Text("Ja", style: TextStyle(color: Colors.white)),
                          onPressed: () async {
                            sendLogs("log_guide_has_entered", "${GblStops[currentStoppIndex]["tour"]}_${GblStops[currentStoppIndex]["isostring"]}_${GblStops[currentStoppIndex]["time"]}_${GblStops[currentStoppIndex]["stopp_type"]}");
                            Navigator.pop(context);
                            nextStep();
                          }
                      ))
                ),
            Builder(
                builder: (context) =>
                  Container(
                      width: double.infinity, // Setzt die Breite auf die volle verfügbare Breite
                      child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: HexColor.fromHex(getColor('primary')),),
                          child: Text("nicht bestätigen", style: TextStyle(color: Colors.white)),
                          onPressed: () async {
                            sendLogs("log_guide_has_not_entered", "${GblStops[currentStoppIndex]["tour"]}_${GblStops[currentStoppIndex]["isostring"]}_${GblStops[currentStoppIndex]["time"]}_${GblStops[currentStoppIndex]["stopp_type"]}");
                            Navigator.pop(context);
                            showCustomDialog(
                                context,
                                "Bestätigen",
                                "Die Fahrt darf ohne Begleitperson nicht fortgesetzt werden.\n\nHast Du eine Genehmigung von der Dispo erhalten?",
                                [
                                  Builder(
                                    builder: (context) =>
                                      Container(
                                          width: double.infinity, // Setzt die Breite auf die volle verfügbare Breite
                                          child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: HexColor.fromHex(getColor('primary')),),
                                              child: Text("Ja, Genehmigung erhalten", style: TextStyle(color: Colors.white)),
                                              onPressed: () async {
                                                sendLogs("log_no_guide_approval", "${GblStops[currentStoppIndex]["tour"]}_${GblStops[currentStoppIndex]["isostring"]}_${GblStops[currentStoppIndex]["time"]}_${GblStops[currentStoppIndex]["stopp_type"]}");
                                                Navigator.pop(context);
                                                nextStep();
                                              }
                                          ))
                                  ),
                                  Builder(
                                    builder: (context) =>
                                        Container(
                                            width: double.infinity, // Setzt die Breite auf die volle verfügbare Breite
                                            child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: HexColor.fromHex(getColor('primary')),),
                                                child: Text("Nein, keine Genehmigung", style: TextStyle(color: Colors.white)),
                                                onPressed: () async {
                                                  sendLogs("log_no_guide_no_approval", "${GblStops[currentStoppIndex]["tour"]}_${GblStops[currentStoppIndex]["isostring"]}_${GblStops[currentStoppIndex]["time"]}_${GblStops[currentStoppIndex]["stopp_type"]}");
                                                  Navigator.pop(context);
                                                  Navigator.of(context).pushAndRemoveUntil(
                                                    MaterialPageRoute(builder: (context) => LandingPage(title: "BusDesk Pro")),
                                                        (Route<dynamic> route) => false,
                                                  );
                                                }
                                            ))
                                  )
                                ]
                            );
                          }
                      ))
                )
          ]
      );
      break;
      case 20:
      case 25: showCustomDialog(
          context,
          "Bestätigen",
          "Ist der Passagier eingestiegen.",
          [
            Builder(
                builder: (context) =>
                  Container(
                      width: double.infinity, // Setzt die Breite auf die volle verfügbare Breite
                      child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: HexColor.fromHex(getColor('primary')),),
                          child: Text("eingestiegen", style: TextStyle(color: Colors.white)),
                          onPressed: () async {
                              Navigator.pop(context);
                              showCustomDialog(
                                context,
                                "Bestätigen",
                                "Attribute: \n${GblStops[currentStoppIndex]["info"]}\n\nwurden beachtet und der Passagier ist korrekt angeschnallt",
                                [
                                  Builder(
                                    builder: (context) =>
                                      Container(
                                          width: double.infinity, // Setzt die Breite auf die volle verfügbare Breite
                                          child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: HexColor.fromHex(getColor('primary')),),
                                              child: Text("Ja", style: TextStyle(color: Colors.white)),
                                              onPressed: () async {
                                                sendLogs("log_passenger_has_entered", "${GblStops[currentStoppIndex]["tour"]}_${GblStops[currentStoppIndex]["isostring"]}_${GblStops[currentStoppIndex]["time"]}_${GblStops[currentStoppIndex]["stopp_type"]}");
                                                Navigator.pop(context);
                                                nextStep();
                                              }
                                          ))
                                  ),
                                  Builder(
                                    builder: (context) =>
                                      Container(
                                          width: double.infinity, // Setzt die Breite auf die volle verfügbare Breite
                                          child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: HexColor.fromHex(getColor('primary')),),
                                              child: Text("Nein", style: TextStyle(color: Colors.white)),
                                              onPressed: () async {
                                                sendLogs("log_passenger_has_not_entered", "${GblStops[currentStoppIndex]["tour"]}_${GblStops[currentStoppIndex]["isostring"]}_${GblStops[currentStoppIndex]["time"]}_${GblStops[currentStoppIndex]["stopp_type"]}");
                                                Navigator.pop(context);
                                                nextStep();
                                              }
                                          ))
                                  )
                                ]
                            );
                          }
                      ))
                ),
            Builder(
                builder: (context) =>
                  Container(
                      width: double.infinity, // Setzt die Breite auf die volle verfügbare Breite
                      child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: HexColor.fromHex(getColor('primary')),),
                          child: Text("nicht eingest. 3 Min. gewart.", style: TextStyle(color: Colors.white)),
                          onPressed: () async {
                            sendLogs("log_passenger_has_not_entered_3min", "${GblStops[currentStoppIndex]["tour"]}_${GblStops[currentStoppIndex]["isostring"]}_${GblStops[currentStoppIndex]["time"]}_${GblStops[currentStoppIndex]["stopp_type"]}");
                            Navigator.pop(context);
                            nextStep();
                          }
                      ))
                ),
            Builder(
                builder: (context) =>
                  Container(
                      width: double.infinity, // Setzt die Breite auf die volle verfügbare Breite
                      child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: HexColor.fromHex(getColor('primary')),),
                          child: Text("Abgemeldet nur Hinfahrt", style: TextStyle(color: Colors.white)),
                          onPressed: () async {
                            sendLogs("log_passenger_cancel_tour", "${GblStops[currentStoppIndex]["tour"]}_${GblStops[currentStoppIndex]["isostring"]}_${GblStops[currentStoppIndex]["time"]}_${GblStops[currentStoppIndex]["stopp_type"]}");
                            Navigator.pop(context);
                            nextStep();
                          }
                      ))
                )
          ]
      );
      break;
      case 18:
        List<bool> _selected = List<bool>.filled(GblStops.length, false);

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return AlertDialog(
                  title: Text('Passagiere eingestiegen'),
                  content: SingleChildScrollView(
                    child: ListBody(
                      children: GblStops
                          .asMap()
                          .entries
                          .where((entry) => entry.value['stopp_type'] == 80)
                          .map((entry) {
                        int index = entry.key;
                        Map<String, dynamic> stop = entry.value;
                        return CheckboxListTile(
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: HexColor.fromHex(getColor('primary')),
                          checkColor: Colors.white,
                          title: Text('${stop['firstname']} ${stop['lastname']}'),
                          subtitle: Text('${stop['info']}'),
                          value: _selected[index],
                          onChanged: (bool? value) {
                            setState(() {
                              _selected[index] = value!;
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  actions: <Widget>[
                    Container(
                        width: double.infinity, // Setzt die Breite auf die volle verfügbare Breite
                        child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: HexColor.fromHex(getColor('primary')),),
                          child: Text('bestätigen', style: TextStyle(color: Colors.white)),
                          onPressed: () {
                            print('INDEXES_0');
                            print(_selected);
                            List<int> notSelectedIndexes = [];
                            for (int i = 0; i < _selected.length; i++) {
                              if (!_selected[i]) {
                                notSelectedIndexes.add(i);
                              }
                            }
                            print('INDEXES_1');
                            print(notSelectedIndexes);
                            var tmp_canceled = [];
                            var passenger_notchecked = false;
                            for (var i = 0; i < notSelectedIndexes.length; i++) {
                              if (GblStops[notSelectedIndexes[i]]['stopp_type'] == 80) {
                                tmp_canceled.add(i);
                                passenger_notchecked = true;
                                setState(() {
                                  GblStops[notSelectedIndexes[i]]['canceled'] = true;
                                });
                              }
                            }
                            if (passenger_notchecked) {
                              Navigator.pop(context);
                              showCustomDialog(
                                  context,
                                  "Bestätigen",
                                  "Wurde die Dispo und/oder das Lehrpersonal über das Fehlen von Passagieren informiert?",
                                  [
                                    Builder(
                                      builder: (context) =>
                                        Container(
                                            width: double.infinity, // Setzt die Breite auf die volle verfügbare Breite
                                            child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: HexColor.fromHex(getColor('primary')),),
                                                child: Text("Lehrpersonal informiert", style: TextStyle(color: Colors.white)),
                                                onPressed: () async {
                                                  Navigator.pop(context);
                                                  sendLogs("log_pessenger_is_missing_teacher_inform", "${GblStops[currentStoppIndex]["tour"]}_${GblStops[currentStoppIndex]["isostring"]}_${GblStops[currentStoppIndex]["time"]}_${GblStops[currentStoppIndex]["stopp_type"]}");
                                                  nextStep();
                                                }
                                            ))
                                    ),
                                    Builder(
                                      builder: (context) =>
                                        Container(
                                            width: double.infinity, // Setzt die Breite auf die volle verfügbare Breite
                                            child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: HexColor.fromHex(getColor('primary')),),
                                                child: Text("Dispo informiert", style: TextStyle(color: Colors.white)),
                                                onPressed: () async {
                                                  Navigator.pop(context);
                                                  sendLogs("log_pessenger_is_missing_dispo_inform", "${GblStops[currentStoppIndex]["tour"]}_${GblStops[currentStoppIndex]["isostring"]}_${GblStops[currentStoppIndex]["time"]}_${GblStops[currentStoppIndex]["stopp_type"]}");
                                                  nextStep();
                                                }
                                            ))
                                    )
                                  ]
                              );
                            } else {
                              sendLogs("log_all_pessengers_has_entered", "${GblStops[currentStoppIndex]["tour"]}_${GblStops[currentStoppIndex]["isostring"]}_${GblStops[currentStoppIndex]["time"]}_${GblStops[currentStoppIndex]["stopp_type"]}");
                              Navigator.pop(context);
                              nextStep();
                            }
                          },
                        )),
                  ],
                );
              },
            );
          },
        );
        break;
      case 75:
      case 80: showCustomDialog(
          context,
          "Bestätigen",
          "${GblStops[currentStoppIndex]["info"].contains('L1') == false ? 'Der Passagier darf nicht alleine aussteigen, bitte bestätige den Ausstieg in Begleitung durch eine verantwortliche Person' : 'Der Passagier darf alleine aussteigen, bitte bestätige den Ausstieg.'}",
          [
            Builder(
                builder: (context) =>
                  Container(
                      width: double.infinity, // Setzt die Breite auf die volle verfügbare Breite
                      child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: HexColor.fromHex(getColor('primary')),),
                          child: Text("ausgestiegen", style: TextStyle(color: Colors.white)),
                          onPressed: () async {
                            //sendLogs("log_pessenger_left_bus", "${GblStops[currentStoppIndex]["tour"]}_${GblStops[currentStoppIndex]["isostring"]}_${GblStops[currentStoppIndex]["time"]}_${GblStops[currentStoppIndex]["stopp_type"]}");
                            //Navigator.pop(context);
                            //nextStep();
                            //NEW
                            var exitPassengerList = [];
                            for (var i = 0; i < GblStops.length; i++) {
                              if (GblStops[i]['stopp_type'] == 80 && (GblStops[i]['canceled'] == false || GblStops[i]['canceled'] == null)) {
                                exitPassengerList.add(GblStops[i]);
                              }
                            }
                            print('S1');
                            print(exitPassengerList);
                            if (exitPassengerList.length > 0) {
                              List<bool> _selected2 = List<bool>.filled(6, false);
                              if (GblStops[currentStoppIndex]["firstname"] == exitPassengerList[exitPassengerList.length - 1]['firstname'] && GblStops[currentStoppIndex]["lastname"] == exitPassengerList[exitPassengerList.length - 1]['lastname']) {
                                Navigator.pop(context);
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return StatefulBuilder(
                                        builder: (BuildContext context, StateSetter setState) {
                                          return AlertDialog(
                                            title: Text('Besondere Vorkommnisse'),
                                            content: SingleChildScrollView(
                                              child: ListBody(
                                                children: <String>[
                                                  'Alles war in Ordnung',
                                                  'Verspätung aufgrund von Verkehr',
                                                  'Verspätung aufgrund von Wartezeiten bei einem Schüler',
                                                  'Medizinischer Vorfall auf der Fahrt',
                                                  'Unfall mit Fremdverschulden',
                                                  'Unfall selbstverschuldet'
                                                ]
                                                    .asMap()
                                                    .entries
                                                    .map((entry) {
                                                  int index = entry.key;
                                                  return CheckboxListTile(
                                                    controlAffinity: ListTileControlAffinity.leading,
                                                    activeColor: HexColor.fromHex(getColor('primary')),
                                                    checkColor: Colors.white,
                                                    title: Text('${entry.value}'),
                                                    value: _selected2[index],
                                                    onChanged: (bool? value) {
                                                      setState(() {
                                                        _selected2[index] = value!;
                                                      });
                                                    },
                                                  );
                                                }).toList(),
                                              ),
                                            ),
                                            actions: <Widget>[
                                              Container(
                                                  width: double.infinity, // Setzt die Breite auf die volle verfügbare Breite
                                                  child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: HexColor.fromHex(getColor('primary')),),
                                                      child: Text("weiter", style: TextStyle(color: Colors.white)),
                                                      onPressed: () async {
                                                        sendLogs("log_pessenger_left_bus", "${GblStops[currentStoppIndex]["tour"]}_${GblStops[currentStoppIndex]["isostring"]}_${GblStops[currentStoppIndex]["time"]}_${GblStops[currentStoppIndex]["stopp_type"]}_${_selected2.join(',')}_${GblStops[currentStoppIndex]["info"].contains('L1') == false ? 'NotAlone' : 'Alone'}");
                                                        Navigator.pop(context);
                                                        showCustomDialog(
                                                            context,
                                                            "Bestätigen",
                                                            "Möchtest Du weiternavigieren oder zurück zur Tourenübersicht?",
                                                            [
                                                              Builder(
                                                                builder: (context) =>
                                                                  Container(
                                                                      width: double.infinity, // Setzt die Breite auf die volle verfügbare Breite
                                                                      child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: HexColor.fromHex(getColor('primary')),),
                                                                          child: Text("weiternavigieren", style: TextStyle(color: Colors.white)),
                                                                          onPressed: () async {
                                                                            //sendLogs("log_all_left_bus", "${GblStops[currentStoppIndex]["tour"]}_${GblStops[currentStoppIndex]["isostring"]}_${GblStops[currentStoppIndex]["time"]}_${GblStops[currentStoppIndex]["stopp_type"]}");
                                                                            Navigator.pop(context);
                                                                            nextStep();
                                                                          }
                                                                      ))
                                                              ),
                                                              Builder(
                                                                builder: (context) =>
                                                                  Container(
                                                                      width: double.infinity, // Setzt die Breite auf die volle verfügbare Breite
                                                                      child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: HexColor.fromHex(getColor('primary')),),
                                                                          child: Text("zur Tourenübersicht", style: TextStyle(color: Colors.white)),
                                                                          onPressed: () async {
                                                                            sendLogs("log_back_touroverview", "${PhoneNumberAuth}");
                                                                            //sendLogs("log_all_left_bus", "${GblStops[currentStoppIndex]["tour"]}_${GblStops[currentStoppIndex]["isostring"]}_${GblStops[currentStoppIndex]["time"]}_${GblStops[currentStoppIndex]["stopp_type"]}");
                                                                            Navigator.pop(context);
                                                                            currentStoppIndex = 1;
                                                                            Navigator.of(context).pushAndRemoveUntil(
                                                                              MaterialPageRoute(builder: (context) => LandingPage(title: "BusDesk Pro")),
                                                                                  (Route<dynamic> route) => false,
                                                                            );
                                                                          }
                                                                      ))
                                                              )
                                                            ]
                                                        );
                                                      }
                                                  )),
                                            ],
                                          );
                                        });
                                  },
                                );
                              } else {
                                sendLogs("log_pessenger_left_bus", "${GblStops[currentStoppIndex]["tour"]}_${GblStops[currentStoppIndex]["isostring"]}_${GblStops[currentStoppIndex]["time"]}_${GblStops[currentStoppIndex]["stopp_type"]}");
                                Navigator.pop(context);
                                nextStep();
                              }
                            } else {
                              sendLogs("log_pessenger_left_bus", "${GblStops[currentStoppIndex]["tour"]}_${GblStops[currentStoppIndex]["isostring"]}_${GblStops[currentStoppIndex]["time"]}_${GblStops[currentStoppIndex]["stopp_type"]}");
                              Navigator.pop(context);
                              nextStep();
                            }
                          }
                      ))
                ),
            Builder(
                builder: (context) =>
                  Container(
                      width: double.infinity, // Setzt die Breite auf die volle verfügbare Breite
                      child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: HexColor.fromHex(getColor('primary')),),
                          child: Text("nicht ausgestiegen", style: TextStyle(color: Colors.white)),
                          onPressed: () async {
                            //NEW
                            var exitPassengerList = [];
                            for (var i = 0; i < GblStops.length; i++) {
                              if (GblStops[i]['stopp_type'] == 80) {
                                exitPassengerList.add(GblStops[i]);
                              }
                            }
                            if (exitPassengerList.length > 0) {
                              List<bool> _selected2 = List<bool>.filled(6, false);
                              if (GblStops[currentStoppIndex]["firstname"] == exitPassengerList[exitPassengerList.length - 1]['firstname'] && GblStops[currentStoppIndex]["lastname"] == exitPassengerList[exitPassengerList.length - 1]['lastname']) {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return StatefulBuilder(
                                        builder: (BuildContext context, StateSetter setState) {
                                          return AlertDialog(
                                            title: Text('Besondere Vorkommnisse'),
                                            content: SingleChildScrollView(
                                              child: ListBody(
                                                children: <String>[
                                                  'Alles war in Ordnung',
                                                  'Verspätung aufgrund von Verkehr',
                                                  'Verspätung aufgrund von Wartezeiten bei einem Schüler',
                                                  'Medizinischer Vorfall auf der Fahrt',
                                                  'Unfall mit Fremdverschulden',
                                                  'Unfall selbstverschuldet'
                                                ]
                                                    .asMap()
                                                    .entries
                                                    .map((entry) {
                                                  int index = entry.key;
                                                  return CheckboxListTile(
                                                    controlAffinity: ListTileControlAffinity.leading,
                                                    activeColor: HexColor.fromHex(getColor('primary')),
                                                    checkColor: Colors.white,
                                                    title: Text('${entry.value}'),
                                                    value: _selected2[index],
                                                    onChanged: (bool? value) {
                                                      setState(() {
                                                        _selected2[index] = value!;
                                                      });
                                                    },
                                                  );
                                                }).toList(),
                                              ),
                                            ),
                                            actions: <Widget>[
                                              Container(
                                                  width: double.infinity, // Setzt die Breite auf die volle verfügbare Breite
                                                  child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: HexColor.fromHex(getColor('primary')),),
                                                      child: Text("weiter", style: TextStyle(color: Colors.white)),
                                                      onPressed: () async {
                                                        sendLogs("log_pessenger_not_left_bus", "${GblStops[currentStoppIndex]["tour"]}_${GblStops[currentStoppIndex]["isostring"]}_${GblStops[currentStoppIndex]["time"]}_${GblStops[currentStoppIndex]["stopp_type"]}_${_selected2.join(',')}");
                                                        showCustomDialog(
                                                            context,
                                                            "Bestätigen",
                                                            "Möchtest Du weiternavigieren oder zurück zur Tourenübersicht?",
                                                            [
                                                              Container(
                                                                  width: double.infinity, // Setzt die Breite auf die volle verfügbare Breite
                                                                  child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: HexColor.fromHex(getColor('primary')),),
                                                                      child: Text("weiternavigieren", style: TextStyle(color: Colors.white)),
                                                                      onPressed: () async {
                                                                        //sendLogs("log_all_left_bus", "${GblStops[currentStoppIndex]["tour"]}_${GblStops[currentStoppIndex]["isostring"]}_${GblStops[currentStoppIndex]["time"]}_${GblStops[currentStoppIndex]["stopp_type"]}");
                                                                        Navigator.pop(context);
                                                                        nextStep();
                                                                      }
                                                                  )),
                                                              Container(
                                                                  width: double.infinity, // Setzt die Breite auf die volle verfügbare Breite
                                                                  child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: HexColor.fromHex(getColor('primary')),),
                                                                      child: Text("zur Tourenübersicht", style: TextStyle(color: Colors.white)),
                                                                      onPressed: () async {
                                                                        sendLogs("log_back_touroverview", "${PhoneNumberAuth}");
                                                                        //sendLogs("log_all_left_bus", "${GblStops[currentStoppIndex]["tour"]}_${GblStops[currentStoppIndex]["isostring"]}_${GblStops[currentStoppIndex]["time"]}_${GblStops[currentStoppIndex]["stopp_type"]}");
                                                                        currentStoppIndex = 1;
                                                                        Navigator.pop(context);
                                                                        Navigator.of(context).pushAndRemoveUntil(
                                                                          MaterialPageRoute(builder: (context) => LandingPage(title: "BusDesk Pro")),
                                                                              (Route<dynamic> route) => false,
                                                                        );
                                                                      }
                                                                  ))
                                                            ]
                                                        );
                                                      }
                                                  )),
                                            ],
                                          );
                                        });
                                  },
                                );
                              } else {
                                sendLogs("log_pessenger_not_left_bus", "${GblStops[currentStoppIndex]["tour"]}_${GblStops[currentStoppIndex]["isostring"]}_${GblStops[currentStoppIndex]["time"]}_${GblStops[currentStoppIndex]["stopp_type"]}");
                                Navigator.pop(context);
                                nextStep();
                              }
                            } else {
                              sendLogs("log_pessenger_not_left_bus", "${GblStops[currentStoppIndex]["tour"]}_${GblStops[currentStoppIndex]["isostring"]}_${GblStops[currentStoppIndex]["time"]}_${GblStops[currentStoppIndex]["stopp_type"]}");
                              Navigator.pop(context);
                              nextStep();
                            }
                          }
                      ))
                )
          ]
      );
        break;
      case 85: showCustomDialog(
          context,
          "Bestätigen",
          "Ist die Begleitperson ausgestiegen?",
          [
            Builder(
                builder: (context) =>
                  Container(
                      width: double.infinity, // Setzt die Breite auf die volle verfügbare Breite
                      child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: HexColor.fromHex(getColor('primary')),),
                          child: Text("Ja", style: TextStyle(color: Colors.white)),
                          onPressed: () async {
                            sendLogs("log_guide_left_bus", "${GblStops[currentStoppIndex]["tour"]}_${GblStops[currentStoppIndex]["isostring"]}_${GblStops[currentStoppIndex]["time"]}_${GblStops[currentStoppIndex]["stopp_type"]}");
                            Navigator.pop(context);
                            nextStep();
                          }
                      ))
            ),
            Builder(
              builder: (context) =>
                Container(
                    width: double.infinity, // Setzt die Breite auf die volle verfügbare Breite
                    child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: HexColor.fromHex(getColor('primary')),),
                        child: Text("Nein", style: TextStyle(color: Colors.white)),
                        onPressed: () async {
                          sendLogs("log_guide_not_left_bus", "${GblStops[currentStoppIndex]["tour"]}_${GblStops[currentStoppIndex]["isostring"]}_${GblStops[currentStoppIndex]["time"]}_${GblStops[currentStoppIndex]["stopp_type"]}");
                          Navigator.pop(context);
                          nextStep();
                        }
                    ))
            )
          ]
      );
      break;
      case 82:
        List<bool> _selected2 = List<bool>.filled(6, false);
        showCustomDialog(
            context,
            "Bestätigen",
            "Bestätige, dass alle Passagiere ausgestiegen sind?",
            [
              Builder(
                  builder: (context) =>
                  Container(
                    width: double.infinity, // Setzt die Breite auf die volle verfügbare Breite
                    child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: HexColor.fromHex(getColor('primary')),),
                        child: Text("Ja, alle sind ausgestiegen", style: TextStyle(color: Colors.white)),
                        onPressed: () async {
                          List<bool> _selected2 = List<bool>.filled(6, false);
                          Navigator.pop(context);

                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return StatefulBuilder(
                                  builder: (BuildContext context, StateSetter setState) {
                                    return AlertDialog(
                                      title: Text('Besondere Vorkommnisse'),
                                      content: SingleChildScrollView(
                                        child: ListBody(
                                          children: <String>[
                                            'Alles war in Ordnung',
                                            'Verspätung aufgrund von Verkehr',
                                            'Verspätung aufgrund von Wartezeiten bei einem Schüler',
                                            'Medizinischer Vorfall auf der Fahrt',
                                            'Unfall mit Fremdverschulden',
                                            'Unfall selbstverschuldet'
                                          ]
                                              .asMap()
                                              .entries
                                              .map((entry) {
                                            int index = entry.key;
                                            return CheckboxListTile(
                                              controlAffinity: ListTileControlAffinity.leading,
                                              activeColor: HexColor.fromHex(getColor('primary')),
                                              checkColor: Colors.white,
                                              title: Text('${entry.value}'),
                                              value: _selected2[index],
                                              onChanged: (bool? value) {
                                                setState(() {
                                                  _selected2[index] = value!;
                                                });
                                              },
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                      actions: <Widget>[
                                        Container(
                                            width: double.infinity, // Setzt die Breite auf die volle verfügbare Breite
                                            child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: HexColor.fromHex(getColor('primary')),),
                                                child: Text("weiter", style: TextStyle(color: Colors.white)),
                                                onPressed: () async {
                                                  sendLogs("log_all_left_bus", "${GblStops[currentStoppIndex]["tour"]}_${GblStops[currentStoppIndex]["isostring"]}_${GblStops[currentStoppIndex]["time"]}_${GblStops[currentStoppIndex]["stopp_type"]}_${_selected2.join(',')}");
                                                  Navigator.pop(context);
                                                    showCustomDialog(
                                                      context,
                                                      "Bestätigen",
                                                      "Möchtest Du weiternavigieren oder zurück zur Tourenübersicht?",
                                                      [
                                                        Builder(
                                                            builder: (context) =>
                                                              Container(
                                                                  width: double.infinity, // Setzt die Breite auf die volle verfügbare Breite
                                                                  child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: HexColor.fromHex(getColor('primary')),),
                                                                      child: Text("weiternavigieren", style: TextStyle(color: Colors.white)),
                                                                      onPressed: () async {
                                                                        //sendLogs("log_all_left_bus", "${GblStops[currentStoppIndex]["tour"]}_${GblStops[currentStoppIndex]["isostring"]}_${GblStops[currentStoppIndex]["time"]}_${GblStops[currentStoppIndex]["stopp_type"]}");
                                                                        Navigator.pop(context);
                                                                        nextStep();
                                                                      }
                                                                  ))
                                                        ),
                                                        Builder(
                                                          builder: (context) =>
                                                            Container(
                                                                width: double.infinity, // Setzt die Breite auf die volle verfügbare Breite
                                                                child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: HexColor.fromHex(getColor('primary')),),
                                                                    child: Text("zur Tourenübersicht", style: TextStyle(color: Colors.white)),
                                                                    onPressed: () async {
                                                                      sendLogs("log_back_touroverview", "${PhoneNumberAuth}");
                                                                      sendLogs("log_all_left_bus", "${GblStops[currentStoppIndex]["tour"]}_${GblStops[currentStoppIndex]["isostring"]}_${GblStops[currentStoppIndex]["time"]}_${GblStops[currentStoppIndex]["stopp_type"]}");
                                                                      currentStoppIndex = 1;
                                                                      Navigator.pop(context);
                                                                      Navigator.of(context).pushAndRemoveUntil(
                                                                        MaterialPageRoute(builder: (context) => LandingPage(title: "BusDesk Pro")),
                                                                            (Route<dynamic> route) => false,
                                                                      );
                                                                    }
                                                                ))
                                                            )
                                                      ]
                                                  );
                                                }
                                            )),
                                      ],
                                    );
                                  });
                            },
                          );
                        }
                  ))
              ),
            ]
        );
        break;
      default:
        showCustomDialog(
            context,
            "Bestätigen",
            "Bestätige die Abfahrt",
            [
              Builder(
                  builder: (context) =>
                  Container(
                      width: double.infinity, // Setzt die Breite auf die volle verfügbare Breite
                      child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: HexColor.fromHex(getColor('primary')),),
                          child: Text("bestätigen", style: TextStyle(color: Colors.white)),
                          onPressed: () async {
                            sendLogs("log_confirm_drive", "${GblStops[currentStoppIndex]["tour"]}_${GblStops[currentStoppIndex]["isostring"]}_${GblStops[currentStoppIndex]["time"]}_${GblStops[currentStoppIndex]["stopp_type"]}");
                            Navigator.pop(context);
                            nextStep();
                          }
                      )),
              )
            ]
        );
        break;
    }
    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    return completer.future;
}