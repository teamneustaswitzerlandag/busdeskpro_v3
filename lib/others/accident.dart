import 'package:bus_desk_pro/libaries/logs.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';

class EuropeanAccidentReport extends StatefulWidget {
  @override
  _EuropeanAccidentReportState createState() => _EuropeanAccidentReportState();
}

class _EuropeanAccidentReportState extends State<EuropeanAccidentReport> {
  final _formKey = GlobalKey<FormState>();
  bool _isVehicleACollapsed = true;
  bool _isVehicleBCollapsed = true;
  bool _isAccidentInfoCollapsed = true;
  bool _isAdditionalFieldsCollapsed = true;

  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _injuriesController = TextEditingController();
  final TextEditingController _witnessController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  File? _photo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: HexColor.fromHex(getColor('primary')),
        title: Text(
          'Unfallbericht',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20.0,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Unfallinformationen
                _buildCollapseSection(
                  title: 'Unfallinformationen',
                  isCollapsed: _isAccidentInfoCollapsed,
                  onToggle: () {
                    setState(() {
                      _isAccidentInfoCollapsed = !_isAccidentInfoCollapsed;
                    });
                  },
                  child: Column(
                    children: [
                      _buildTextField(label: 'Datum des Unfalls', controller: _dateController),
                      _buildTextField(label: 'Uhrzeit des Unfalls', controller: _timeController),
                      _buildTextField(label: 'Ort des Unfalls', controller: _locationController),
                      _buildTextField(label: 'Verletzte Personen (Ja/Nein)', controller: _injuriesController),
                      _buildTextField(label: 'Zeugen (Name, Adresse, Telefon)', controller: _witnessController),
                    ],
                  ),
                ),
                SizedBox(height: 16),

                // Fahrzeug A
                _buildCollapseSection(
                  title: 'Fahrzeug A',
                  isCollapsed: _isVehicleACollapsed,
                  onToggle: () {
                    setState(() {
                      _isVehicleACollapsed = !_isVehicleACollapsed;
                    });
                  },
                  child: Column(
                    children: [
                      _buildTextField(label: 'Versicherungsnehmer (Name, Adresse)'),
                      _buildTextField(label: 'Fahrzeug (Marke, Typ, Kennzeichen)'),
                      _buildTextField(label: 'Versicherer (Name der Gesellschaft)'),
                      _buildTextField(label: 'Fahrzeuglenker (Name, Telefon)'),
                      _buildTextField(label: 'Versicherungsnummer'),
                      _buildTextField(label: 'Führerschein-Nr.'),
                      _buildTextField(label: 'Versicherungspolice (Grüne Karte, Gültigkeit)'),
                    ],
                  ),
                ),
                SizedBox(height: 16),

                // Fahrzeug B
                _buildCollapseSection(
                  title: 'Fahrzeug B',
                  isCollapsed: _isVehicleBCollapsed,
                  onToggle: () {
                    setState(() {
                      _isVehicleBCollapsed = !_isVehicleBCollapsed;
                    });
                  },
                  child: Column(
                    children: [
                      _buildTextField(label: 'Versicherungsnehmer (Name, Adresse)'),
                      _buildTextField(label: 'Fahrzeug (Marke, Typ, Kennzeichen)'),
                      _buildTextField(label: 'Versicherer (Name der Gesellschaft)'),
                      _buildTextField(label: 'Fahrzeuglenker (Name, Telefon)'),
                      _buildTextField(label: 'Versicherungsnummer'),
                      _buildTextField(label: 'Führerschein-Nr.'),
                      _buildTextField(label: 'Versicherungspolice (Grüne Karte, Gültigkeit)'),
                    ],
                  ),
                ),
                SizedBox(height: 16),

                // Weitere Felder (Fotoaufnahme der Unfallskizze, Sachschäden, Bemerkungen)
                _buildCollapseSection(
                  title: 'Weitere Felder',
                  isCollapsed: _isAdditionalFieldsCollapsed,
                  onToggle: () {
                    setState(() {
                      _isAdditionalFieldsCollapsed = !_isAdditionalFieldsCollapsed;
                    });
                  },
                  child: Column(
                    children: [
                      // Foto aufnehmen für die Unfallskizze
                      Text(
                        'Unfallskizze (Foto aufnehmen):',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: Colors.black),
                      ),
                      SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _takePhoto(),
                        child: Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: _photo == null
                              ? Center(
                            child: Icon(
                              Icons.camera_alt,
                              size: 50,
                              color: Colors.black,
                            ),
                          )
                              : ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.file(
                              _photo!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          ),
                        ),
                      ),
                      if (_photo == null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Ein Foto ist erforderlich.',
                            style: TextStyle(color: HexColor.fromHex(getColor('primary')), fontSize: 12),
                          ),
                        ),
                      SizedBox(height: 16),

                      _buildTextField(label: 'Weitere Sachschäden'),
                      _buildTextField(label: 'Bemerkungen'),
                    ],
                  ),
                ),

                // Abschicken-Button (außerhalb der Gruppen)
                SizedBox(height: 32),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate() && _photo != null) {
                        final jsonString = _generateJson();
                        sendLogs("submit_europeanaccidentreport", jsonString);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Unfallbericht wurde abgeschickt!')),
                        );
                        Navigator.pop(context);
                      } else if (_photo == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Bitte ein Foto der Unfallskizze hinzufügen.')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: HexColor.fromHex(getColor('primary')), // Rote Farbe für den Button
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                    ),
                    child: Text(
                      'Abschicken',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapseSection({required String title, required bool isCollapsed, required VoidCallback onToggle, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onToggle,
          child: Row(
            children: [
              Icon(isCollapsed ? Icons.expand_more : Icons.expand_less),
              SizedBox(width: 8),
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ),
        if (!isCollapsed) child,
      ],
    );
  }

  Widget _buildTextField({required String label, TextEditingController? controller}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Dieses Feld ist erforderlich';
          }
          return null;
        },
      ),
    );
  }

  Future<void> _takePhoto() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _photo = File(pickedFile.path);
      });
    }
  }

  String _generateJson() {
    String base64Image = '';
    if (_photo != null) {
      List<int> imageBytes = _photo!.readAsBytesSync();
      base64Image = base64Encode(imageBytes);
    }

    final Map<String, dynamic> jsonData = {
      'datum': _dateController.text,
      'uhrzeit': _timeController.text,
      'ort': _locationController.text,
      'verletzte_personen': _injuriesController.text,
      'zeugen': _witnessController.text,
      'photo': base64Image,
      'weitere_sachschaden': '', // Weitere Felder hier hinzufügen
      'bemerkungen': '',
    };

    return jsonEncode(jsonData);
  }
}