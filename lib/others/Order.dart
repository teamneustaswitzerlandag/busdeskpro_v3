import 'package:bus_desk_pro/config/globals.dart';
import 'package:bus_desk_pro/libaries/logs.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class OrderPage extends StatefulWidget {
  @override
  _OrderWidgetState createState() => _OrderWidgetState();
}

class _OrderWidgetState extends State<OrderPage> {
  List<DropdownItem> dropdownItems = [];
  String? selectedClothesId;

  @override
  void initState() {
    super.initState();
    fetchDropdownItems();
  }

  Future<void> fetchDropdownItems() async {
    final response = await http.get(Uri.parse(getUrl('get-clothlist')));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      setState(() {
        dropdownItems = data.map((json) => DropdownItem.fromJson(json)).toList();
      });
    } else {
      throw Exception('Failed to load dropdown items');
    }
  }

  Future<void> placeOrder() async {
    final response = await http.post(
      Uri.parse(getUrl('send-clothorder')),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'clothesId': selectedClothesId ?? '',
        'phone': PhoneNumberAuth
      }),
    );

    if (response.statusCode == 200) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Bestellung erfolgreich'),
            content: Text('Die Bestellung wurde erfolgreich aufgegeben.'),
            actions: <Widget>[
            Container(
              width: double.infinity, // Setzt die Breite auf die volle verfügbare Breite
              child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: HexColor.fromHex(getColor('primary')),),
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK', style: TextStyle(color: Colors.white)),
              )),
            ],
          );
        },
      );
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Bestellung fehlgeschlagen'),
            content: Text('Die Bestellung konnte nicht aufgegeben werden.'),
            actions: <Widget>[
            Container(
              width: double.infinity, // Setzt die Breite auf die volle verfügbare Breite
              child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: HexColor.fromHex(getColor('primary')),),
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK', style: TextStyle(color: Colors.white)),
              )),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Kleiderbestellung',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: HexColor.fromHex(getColor('primary')),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              hint: Text('Wähle ein Kleidungsstück'),
              value: selectedClothesId,
              onChanged: (String? newValue) {
                setState(() {
                  selectedClothesId = newValue;
                });
              },
              items: dropdownItems.map((DropdownItem item) {
                return DropdownMenuItem<String>(
                  value: item.value,
                  child: Text(item.name),
                );
              }).toList(),
            ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: HexColor.fromHex(getColor('primary')),
                ),
                onPressed: () async {
                  final bool? confirm = await showDialog<bool>(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Bestellung bestätigen'),
                        content: Text('Möchtest du wirklich bestellen?'),
                        actions: <Widget>[
                        Container(
                          width: double.infinity, // Setzt die Breite auf die volle verfügbare Breite
                          child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: HexColor.fromHex(getColor('primary')),),
                            onPressed: () => Navigator.of(context).pop(false),
                            child: Text('Nein'),
                          )),
                        Container(
                          width: double.infinity, // Setzt die Breite auf die volle verfügbare Breite
                          child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: HexColor.fromHex(getColor('primary')),),
                            onPressed: () => Navigator.of(context).pop(true),
                            child: Text('Ja'),
                          )),
                        ],
                      );
                    },
                  );

                  if (confirm == true) {
                    placeOrder();
                  }
                },
                child: Text('Bestellen', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DropdownItem {
  final String value;
  final String name;

  DropdownItem({required this.value, required this.name});

  factory DropdownItem.fromJson(Map<String, dynamic> json) {
    return DropdownItem(
      value: json['value'],
      name: json['name'],
    );
  }
}