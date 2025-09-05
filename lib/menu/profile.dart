import 'package:bus_desk_pro/config/globals.dart';
import 'package:bus_desk_pro/libaries/logs.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(ProfilePage());
}

class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: QuickLinksView(),
    );
  }
}

class QuickLinksView extends StatefulWidget {
  @override
  _QuickLinksViewState createState() => _QuickLinksViewState();
}

class _QuickLinksViewState extends State<QuickLinksView> {
  List<Knowledge> knowledgeList = [];
  List<ClothingOrder> clothingOrderList = [];

  @override
  void initState() {
    super.initState();
    fetchKnowledge();
    fetchClothingOrders();
  }

  Future<void> fetchKnowledge() async {
    print(getUrl('get-knowledge'));
    final response = await http.get(Uri.parse((getUrl('get-knowledge')).replaceAll('{fullname}', PhoneNumberAuth)));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      setState(() {
        knowledgeList = data.map((json) => Knowledge.fromJson(json)).toList();
      });
    } else {
      throw Exception('Failed to load knowledge');
    }
  }

  Future<void> fetchClothingOrders() async {
    final response = await http.get(Uri.parse(getUrl('get-orders').replaceAll('{fullname}', PhoneNumberAuth)));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      print(data);
      setState(() {
        clothingOrderList = data.map((json) => ClothingOrder.fromJson(json)).toList();
      });
    } else {
      throw Exception('Failed to load clothing orders');
    }
  }

  String formatDate(String? date) {
    if (date == null || date.isEmpty) {
      return 'nicht angegeben';
    }
    final DateTime parsedDate = DateTime.parse(date);
    return DateFormat('dd.MM.yyyy').format(parsedDate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Card(
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: EdgeInsets.all(14.0), // Set the desired margin here
                    child: Text(
                      'Fahrer:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.all(14.0), // Set the desired margin here
                    child: Text(AllToursGbl.length > 0 ? AllToursGbl[0]['general']['driver'] : '', style: TextStyle(fontSize: 16)),
                  ),
                  Divider(),
                  SizedBox(height: 16),
                  Container(
                    margin: EdgeInsets.all(14.0), // Set the desired margin here
                    child: Text(
                      'Rufnummer:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.all(14.0), // Set the desired margin here
                    child: Text(PhoneNumberAuth, style: TextStyle(fontSize: 16)),
                  ),
                  Divider(),
                  SizedBox(height: 16),
                  if (checkIfAnyModuleIsActive('Knowledge') == true)
                    Theme(
                      data: Theme.of(context).copyWith(
                        dividerColor: Colors.transparent,
                        unselectedWidgetColor: Colors.black,
                        colorScheme: ColorScheme.light(
                          primary: Colors.black,
                        ),
                      ),
                      child: ExpansionTile(
                        title: Text('Kenntnisse', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        children: knowledgeList.map((knowledge) {
                          return ListTile(
                            title: Text(knowledge.name),
                            subtitle: Text('Gültigkeit von: ${formatDate(knowledge.validityFrom)}\nGültigkeit bis: ${formatDate(knowledge.validityTo)}'),
                          );
                        }).toList(),
                      ),
                    ),
                  SizedBox(height: 16),
                  if (checkIfAnyModuleIsActive('ClothOrders') == true)
                    Theme(
                      data: Theme.of(context).copyWith(
                        dividerColor: Colors.transparent,
                        unselectedWidgetColor: Colors.black,
                        colorScheme: ColorScheme.light(
                          primary: Colors.black,
                        ),
                      ),
                      child: ExpansionTile(
                        title: Text('Kleiderbestellungen', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        children: clothingOrderList.map((order) {
                          return ListTile(
                            title: Text(order.clothes ?? 'nicht angegeben'),
                            subtitle: Text('Status: ${order.status ?? 'nicht angegeben'}'),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class Knowledge {
  final String name;
  final String? validityFrom;
  final String? validityTo;

  Knowledge({required this.name, this.validityFrom, this.validityTo});

  factory Knowledge.fromJson(Map<String, dynamic> json) {
    return Knowledge(
      name: json['knowledge'] ?? 'nicht angegeben',
      validityFrom: json['valid_from'],
      validityTo: json['valid_to'],
    );
  }
}

class ClothingOrder {
  final String? clothes;
  final String? status;

  ClothingOrder({this.clothes, this.status});

  factory ClothingOrder.fromJson(Map<String, dynamic> json) {
    return ClothingOrder(
      clothes: json['clothes'],
      status: json['status'],
    );
  }
}