import 'package:bus_desk_pro/config/globals.dart';
import 'package:bus_desk_pro/libaries/logs.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert'; // Für Base64
import 'dart:io'; // Für das Öffnen von Dateien
import 'package:http/http.dart' as http;
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'dart:typed_data';

import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

class DocumentListPage extends StatefulWidget {
  @override
  _DocumentListPageState createState() => _DocumentListPageState();
}

class _DocumentListPageState extends State<DocumentListPage> {
  List<dynamic> documents = [];

  @override
  void initState() {
    super.initState();
    _fetchDocuments();
  }

  Future<void> _fetchDocuments() async {
    String jsonString = await rootBundle.loadString('lib/config/apis.json');
    Map<String, dynamic> parsedJson = json.decode(jsonString);
    print(getUrl('get-documents'));
    final url = Uri.parse(getUrl('get-documents'));

    final response = await http.get(url);

    if (response.statusCode == 200) {
      debugPrint(response.body);
      setState(() {
        documents = json.decode(response.body);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Laden der Dokumente.')),
      );
    }
  }

  /*void _openDocument(String base64EncodedPdf) {
    //print(base64EncodedPdf);
    List<int> bytes = base64Decode(base64EncodedPdf);
    //String dataUrl = "data:application/pdf;base64,$base64EncodedPdf";
    //launchUrlString(dataUrl);
    //html.window.open(dataUrl, "_blank");
    final file = File('${Directory.systemTemp.path}/document.pdf');
    file.writeAsBytesSync(bytes);
    print(Directory.systemTemp.path);
    // Hier kannst du den PDF-Viewer aufrufen, um das PDF zu öffnen.
    // Zum Beispiel: openPdf(file.path);
  }*/

  void _openDocument(BuildContext context, String base64EncodedPdf) {
    Uint8List decodedBytes = base64.decode(base64EncodedPdf);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.all(0),
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: Stack(
              children: [
                PDFView(
                  pdfData: decodedBytes,
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /*appBar: AppBar(
        elevation: 0,
        backgroundColor: HexColor.fromHex(getColor('primary')),
        title: Text(
          'Dokumentenliste',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20.0,
          ),
        ),
        centerTitle: true,
      ),*/
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: documents.isEmpty
            ? Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16), // Abstand zwischen dem Spinner und dem Text
                        Text(
                          "Dokumente werden geladen...",
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
          itemCount: documents.length,
          itemBuilder: (context, index) {
            final document = documents[index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0),
                  color: Colors.white,
                  border: Border.all(color: Colors.black),
                ),
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf, color: HexColor.fromHex(getColor('primary')), size: 40),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        document['title'] ?? 'Unbenanntes Dokument',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    ),
                    SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        sendLogs("log_open_document", "${PhoneNumberAuth}_${document['title']}");
                        _openDocument(context, document['PdfBase64file']);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: HexColor.fromHex(getColor('primary')),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                      ),
                      child: Text(
                        'Öffnen',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}