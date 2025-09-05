import 'package:bus_desk_pro/libaries/logs.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert'; // Für JSON und Base64-Codierung

class LostAndFoundForm extends StatefulWidget {
  @override
  _LostAndFoundFormState createState() => _LostAndFoundFormState();
}

class _LostAndFoundFormState extends State<LostAndFoundForm> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  File? _photo;

  // Variablen für Formulareingaben
  final TextEditingController _fundortController = TextEditingController();
  final TextEditingController _beschreibungController = TextEditingController();
  final TextEditingController _ablageortController = TextEditingController();
  final TextEditingController _tourController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: HexColor.fromHex(getColor('primary')),
        title: Text(
          'Lost + Found Meldung',
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
                // Fundort
                buildTextField(
                  label: 'Fundort (Sitzreihe)',
                  controller: _fundortController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Dieses Feld ist erforderlich.';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                // Beschreibung
                buildTextField(
                  label: 'Beschreibung',
                  controller: _beschreibungController,
                  maxLines: 4,
                  isOptional: true,
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
                      style: TextStyle(color: Colors.black, fontSize: 12),
                    ),
                  ),
                SizedBox(height: 16),
                // Ablageort
                buildTextField(
                  label: 'Ablageort',
                  controller: _ablageortController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Dieses Feld ist erforderlich.';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                // Tour
                buildTextField(
                  label: 'Tour',
                  controller: _tourController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Dieses Feld ist erforderlich.';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 32),
                // Abschicken-Button
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate() && _photo != null) {
                        // Base64-Codierung des Fotos
                        String base64Photo = base64Encode(_photo!.readAsBytesSync());

                        // JSON-String generieren
                        String jsonString = jsonEncode({
                          'fundort': _fundortController.text,
                          'beschreibung': _beschreibungController.text,
                          'ablageort': _ablageortController.text,
                          'tour': _tourController.text,
                          'fotoBase64': base64Photo,
                        });

                        // Ausgabe in der Konsole
                        sendLogs("submit_lostandfound", jsonString);

                        Navigator.pop(context);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Lost + Found abgeschickt')),
                        );
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
    required TextEditingController controller,
    int maxLines = 1,
    String? Function(String?)? validator,
    bool isOptional = false,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: isOptional ? null : validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.black),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Colors.black),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Colors.black, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Colors.black),
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
}