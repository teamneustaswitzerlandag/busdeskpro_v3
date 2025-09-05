import 'package:bus_desk_pro/libaries/logs.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert'; // Für Base64
import 'dart:io';

class Servicerepair extends StatefulWidget {
  @override
  _ServicerepairState createState() => _ServicerepairState();
}

class _ServicerepairState extends State<Servicerepair> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  File? _photo;
  final TextEditingController _descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: HexColor.fromHex(getColor('primary')),
        title: Text(
          'Servicereparatur',
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
                // Beschreibung
                buildTextField(
                  label: 'Beschreibung',
                  maxLines: 4,
                  isOptional: true,
                  controller: _descriptionController,
                ),
                SizedBox(height: 16),
                // Foto
                Text(
                  'Foto aufnehmen:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: Colors.black),
                ),
                SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _takePhoto(),
                  child: Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black), // Schwarzer Rahmen
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: _photo == null
                        ? Center(
                      child: Icon(
                        Icons.camera_alt,
                        size: 50,
                        color: Colors.black, // Schwarze Farbe für das Kamera-Icon
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
                SizedBox(height: 32),
                // Abschicken-Button
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate() && _photo != null) {
                        final jsonString = _generateJson();
                        sendLogs("submit_servicerepair", jsonString);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Serviceantrag wurde abgeschickt!')),
                        );
                        Navigator.pop(context);
                      } else if (_photo == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Bitte ein Foto hinzufügen.')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: HexColor.fromHex(getColor('primary')),
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

  Widget buildTextField({
    required String label,
    int maxLines = 1,
    String? Function(String?)? validator,
    bool isOptional = false,
    TextEditingController? controller,
  }) {
    return TextFormField(
      maxLines: maxLines,
      controller: controller,
      validator: isOptional ? null : validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.black), // Schwarzes Label
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Colors.black), // Schwarzer Rahmen
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Colors.black, width: 2), // Schwarzer Rahmen bei Fokus
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: HexColor.fromHex(getColor('primary'))),
        ),
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
      'beschreibung': _descriptionController.text,
      'photo': base64Image,
    };

    return jsonEncode(jsonData); // JSON-String generieren
  }
}