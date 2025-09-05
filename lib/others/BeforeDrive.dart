import 'package:bus_desk_pro/config/globals.dart';
import 'package:bus_desk_pro/libaries/logs.dart';
import 'package:bus_desk_pro/maps/mapEngine.dart';
import 'package:bus_desk_pro/maps/maps.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class BeforeDriveView extends StatefulWidget {
  final double? lat;
  final double? long;
  final List? stops;

  const BeforeDriveView({super.key, this.lat, this.long, this.stops});

  @override
  _BeforeDriveViewState createState() => _BeforeDriveViewState();
}

class _BeforeDriveViewState extends State<BeforeDriveView> {
  List<dynamic> questions = [];
  Map<String, bool> questionStatus = {};
  Map<String, Map<String, bool>> subQuestionStatus = {};
  String? expandedParentId;

  @override
  void initState() {
    super.initState();
    fetchQuestions();
  }

  Future<void> fetchQuestions() async {
    String jsonString = await rootBundle.loadString('lib/config/apis.json');
    Map<String, dynamic> parsedJson = json.decode(jsonString);
    final response = await http.get(Uri.parse(getUrl('get-checkuplist')));
    if (response.statusCode == 200) {
      setState(() {
        questions = json.decode(response.body);
        initializeQuestionStatus();
      });
    } else {
      throw Exception('Failed to load questions');
    }
  }

  void initializeQuestionStatus() {
    for (var question in questions) {
      questionStatus[question['id']] = true;
      if (question['parent'] != null) {
        if (!subQuestionStatus.containsKey(question['parent'])) {
          subQuestionStatus[question['parent']] = {};
        }
        subQuestionStatus[question['parent']]![question['id']] = true;
      }
    }
  }

  void updateQuestionStatus(String id, bool value) {
    setState(() {
      questionStatus[id] = value;
    });
  }

  void updateSubQuestionStatus(String parentId, String id, bool value) {
    setState(() {
      subQuestionStatus[parentId]![id] = value;
    });
  }

  void toggleExpansion(String parentId) {
    setState(() {
      if (expandedParentId == parentId) {
        expandedParentId = null;
      } else {
        expandedParentId = parentId;
      }
    });
  }

  String generateJsonString() {
    Map<String, dynamic> result = {};

    for (var question in questions) {
      if (question['parent'] == null) {
        result[question['name']] = questionStatus[question['id']];
        var subQuestions = questions.where((q) => q['parent'] == question['id']).toList();
        if (subQuestions.isNotEmpty) {
          result[question['name']] = {};
          for (var subQuestion in subQuestions) {
            result[question['name']][subQuestion['name']] = subQuestionStatus[question['id']]![subQuestion['id']];
            var subSubQuestions = questions.where((q) => q['parent'] == subQuestion['id']).toList();
            if (subSubQuestions.isNotEmpty) {
              result[question['name']][subQuestion['name']] = {};
              for (var subSubQuestion in subSubQuestions) {
                result[question['name']][subQuestion['name']][subSubQuestion['name']] = subQuestionStatus[subQuestion['id']]![subSubQuestion['id']];
              }
            }
          }
        }
      }
    }

    return json.encode(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: HexColor.fromHex(getColor('primary')),
        title: Text(
          'Abfahrkontrolle',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20.0,
          ),
        ),
        centerTitle: true,
      ),
      body: questions.isEmpty ? Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16), // Abstand zwischen dem Spinner und dem Text
                Text(
                  "Checkliste wird geladen...",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ) : ListView(
        padding: EdgeInsets.all(16.0),
        children: [
          ...questions.where((q) => q['parent'] == null).map<Widget>((question) {
            return ExpansionTile(
              key: Key(question['id']),
              title: Text(question['name']),
              initiallyExpanded: expandedParentId == question['id'],
              onExpansionChanged: (expanded) {
                if (expanded) {
                  toggleExpansion(question['id']);
                } else {
                  toggleExpansion('');
                }
              },
              children: questions.where((q) => q['parent'] == question['id']).map<Widget>((subQuestion) {
                return ExpansionTile(
                  key: Key(subQuestion['id']),
                  title: Text(subQuestion['name']),
                  children: questions.where((q) => q['parent'] == subQuestion['id']).map<Widget>((subSubQuestion) {
                    return CheckboxListTile(
                      title: Text(subSubQuestion['name']),
                      value: subQuestionStatus[subQuestion['id']]![subSubQuestion['id']],
                      onChanged: (value) {
                        if (value != null) updateSubQuestionStatus(subQuestion['id'], subSubQuestion['id'], value);
                      },
                    );
                  }).toList(),
                );
              }).toList(),
            );
          }).toList(),
          SizedBox(height: 8.0),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: HexColor.fromHex(getColor('primary')),
            ),
            onPressed: () {
              String jsonString = generateJsonString();
              sendLogs('beforedrive_check', jsonString);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => InitNavigationMap(
                    lat: widget.lat,
                    long: widget.long,
                    isFreeDrive: false,
                  ),
                ),
              );
            },
            child: Text('Ich bin bestätige meine Eingabe verbindlich', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}