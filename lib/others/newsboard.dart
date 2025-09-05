import 'package:bus_desk_pro/config/globals.dart';
import 'package:bus_desk_pro/libaries/logs.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class NewsBoard extends StatefulWidget {
  @override
  _NewsBoardState createState() => _NewsBoardState();
}

class _NewsBoardState extends State<NewsBoard> {
  List<Map<String, dynamic>> _news = [];
  bool _isLoading = true;
  int _loadedCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchNews();
  }

  // Nachrichten von der API abrufen
  Future<void> _fetchNews() async {
    String jsonString = await rootBundle.loadString('lib/config/apis.json');
    Map<String, dynamic> parsedJson = json.decode(jsonString);
    final url = Uri.parse(getUrl('get-notifications'));

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      setState(() {
        _news = data.map((item) => {
          'title': item['title'],
          'message': item['message'],
          'createdon': item['createdon'],
          'isExpanded': false
        }).toList();
        _loadedCount = _news.length;
        _isLoading = false;
      });
      final storage = FlutterSecureStorage();
      await storage.write(key: 'gbl_notifications_amount', value: _loadedCount.toString());
    } else {
      throw Exception('Fehler beim Abrufen der Nachrichten');
    }
  }

  // Datum formatieren
  String _formatDate(String date) {
    final parsedDate = DateTime.parse(date);
    final formatter = DateFormat('dd.MM.yyyy HH:mm');
    return formatter.format(parsedDate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: HexColor.fromHex(getColor('primary')),
        title: Text(
          'Aktuelle Nachrichten',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16), // Abstand zwischen dem Spinner und dem Text
                      Text(
                        "Bitte warten\nNachrichten werden geladen...",
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
            )
          : ListView.builder(
        itemCount: _news.length,
        itemBuilder: (context, index) {
          final newsItem = _news[index];
          final messagePreview = newsItem['message'].length > 100
              ? newsItem['message'].substring(0, 100) + '...'
              : newsItem['message'];

          return Card(
            margin: EdgeInsets.all(8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.transparent),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    newsItem['title'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Erstellt am: ${_formatDate(newsItem['createdon'])}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  // Nur die Vorschau anzeigen, wenn nicht ausgeklappt
                  if (!newsItem['isExpanded'])
                    Text(
                      messagePreview,
                      style: TextStyle(fontSize: 16),
                    ),

                  // Button für "Mehr anzeigen" und "Einklappen"
                  Column(
                    children: [
                      SizedBox(height: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: HexColor.fromHex(getColor('primary')),
                        ),
                        onPressed: () {
                          setState(() {
                            newsItem['isExpanded'] = !newsItem['isExpanded'];
                          });
                        },
                        child: Text(newsItem['isExpanded'] ? 'Einklappen' : 'Mehr anzeigen', style: TextStyle(color: Colors.white)),
                      ),
                      // Volle Nachricht anzeigen, wenn ausgeklappt
                      if (newsItem['isExpanded'])
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            newsItem['message'],
                            style: TextStyle(fontSize: 16),
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
    );
  }
}