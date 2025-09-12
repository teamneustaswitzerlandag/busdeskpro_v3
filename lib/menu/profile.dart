import 'package:bus_desk_pro/config/globals.dart';
import 'package:bus_desk_pro/libaries/logs.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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
  String? savedFirstName;
  String? savedLastName;

  @override
  void initState() {
    super.initState();
    fetchKnowledge();
    fetchClothingOrders();
    _loadSavedName();
  }

  Future<void> _loadSavedName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      savedFirstName = prefs.getString('driver_first_name');
      savedLastName = prefs.getString('driver_last_name');
    });
  }

  Future<void> _saveName(String firstName, String lastName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('driver_first_name', firstName);
    await prefs.setString('driver_last_name', lastName);
    setState(() {
      savedFirstName = firstName;
      savedLastName = lastName;
    });
  }

  void _showNameInputDialog() {
    final firstNameController = TextEditingController(text: savedFirstName ?? '');
    final lastNameController = TextEditingController(text: savedLastName ?? '');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: HexColor.fromHex(getColor('primary')).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.person_add_rounded,
                        color: HexColor.fromHex(getColor('primary')),
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Fahrername eingeben',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                
                // Input Fields
                TextField(
                  controller: firstNameController,
                  decoration: InputDecoration(
                    labelText: 'Vorname',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: HexColor.fromHex(getColor('primary')), width: 2),
                    ),
                    prefixIcon: Icon(Icons.person_outline_rounded, color: HexColor.fromHex(getColor('primary'))),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: lastNameController,
                  decoration: InputDecoration(
                    labelText: 'Nachname',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: HexColor.fromHex(getColor('primary')), width: 2),
                    ),
                    prefixIcon: Icon(Icons.person_outline_rounded, color: HexColor.fromHex(getColor('primary'))),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                SizedBox(height: 24),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Abbrechen',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (firstNameController.text.trim().isNotEmpty && 
                              lastNameController.text.trim().isNotEmpty) {
                            _saveName(
                              firstNameController.text.trim(),
                              lastNameController.text.trim(),
                            );
                            Navigator.of(context).pop();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Bitte geben Sie Vor- und Nachname ein'),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: HexColor.fromHex(getColor('primary')),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          'Speichern',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
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

  String _getDriverName() {
    // Zuerst prüfen ob ein Fahrername aus den Touren vorhanden ist
    if (AllToursGbl.length > 0 && 
        AllToursGbl[0]['general']['driver'] != null && 
        AllToursGbl[0]['general']['driver'].toString().isNotEmpty) {
      return AllToursGbl[0]['general']['driver'];
    }
    
    // Falls kein Fahrername aus Touren, dann gespeicherten Namen verwenden
    if (savedFirstName != null && savedLastName != null) {
      return '$savedFirstName $savedLastName';
    }
    
    // Falls nichts vorhanden, Hinweis anzeigen
    return 'Kein Fahrername hinterlegt';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Weißer Hintergrund
      appBar: AppBar(
        backgroundColor: HexColor.fromHex(getColor('primary')),
        automaticallyImplyLeading: false,
        elevation: 0,
        /*leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),*/
        title: Row(
          children: [
            Icon(Icons.person_rounded, color: Colors.white, size: 18),
            SizedBox(width: 6),
            Flexible(
              child: Text(
                'Profil',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Card(
            color: Colors.white, // Weiße Card-Farbe
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
                    margin: EdgeInsets.all(14.0),
                    child: Row(
                      children: [
                        Text(
                          'Fahrer:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Spacer(),
                        if (AllToursGbl.length == 0 || AllToursGbl[0]['general']['driver'] == null || AllToursGbl[0]['general']['driver'].toString().isEmpty)
                          IconButton(
                            onPressed: _showNameInputDialog,
                            icon: Icon(Icons.edit_rounded, color: HexColor.fromHex(getColor('primary'))),
                            tooltip: 'Fahrername eingeben',
                          ),
                      ],
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.all(14.0),
                    child: Text(
                      _getDriverName(),
                      style: TextStyle(fontSize: 16),
                    ),
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