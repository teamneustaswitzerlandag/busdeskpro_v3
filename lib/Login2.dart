import 'package:bus_desk_pro/LandingPage.dart';
import 'package:bus_desk_pro/config/globals.dart';
import 'package:bus_desk_pro/libaries/logs.dart';
import 'package:bus_desk_pro/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CodeInputScreen extends StatefulWidget {

  const CodeInputScreen({super.key});
  //const CodeInputScreen({Key? key}) : super(key: key);

  @override
  _CodeInputScreenState createState() => _CodeInputScreenState();
}

class _CodeInputScreenState extends State<CodeInputScreen> {
  // Erstelle TextEditingController für jedes Textfeld
  final List<TextEditingController> controllers = List.generate(6, (_) => TextEditingController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /*appBar: AppBar(
        backgroundColor: Colors.white,
        //backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        automaticallyImplyLeading: false,
        elevation: 0,
        title: Row(
          children: [
            //Text(widget.title),
            Image.asset(
                'lib/assets/app_logo.png',
                fit: BoxFit.contain,
                width: 200,
                height: 50
            )
          ],
        ),
        actions: [],
      ),*/
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'lib/assets/app_tile_2.png', // Dein Hintergrundbild hier
              fit: BoxFit.cover,
            ),
          ),
          // Weißes Overlay
          Positioned.fill(
            child: Container(
              color: Colors.white.withOpacity(0.9), // Halbtransparentes weißes Overlay
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Titel
                const Text(
                  "Geben den 4-stelligen Code ein",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                // 6 Eingabefelder
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey),
                        ),
                        child: TextField(
                          controller: controllers[index],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          maxLength: 1,
                          decoration: const InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            counterText: "",
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          ),
                          onChanged: (value) {
                            // Fokus auf das nächste Textfeld setzen
                            if (value.isNotEmpty && index < 3) {
                              FocusScope.of(context).nextFocus();
                            }
                          },
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 24),
                // Einloggen Button
                /*Container(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Clipboard.getData(Clipboard.kTextPlain).then((clipboardData) {
                        if (clipboardData != null && clipboardData.text != null) {
                          final clipboardText = clipboardData.text!;
                          for (int i = 0; i < controllers.length && i < clipboardText.length; i++) {
                            controllers[i].text = clipboardText[i];
                          }
                        }
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white, // Hintergrundfarbe
                      foregroundColor: Colors.red,   // Textfarbe
                      side: const BorderSide(color: Colors.red), // Rahmenfarbe
                    ),
                    child: const Text("Code einfügen"),
                  ),
                ),
                const SizedBox(height: 10),*/
                // Einloggen Button
                Container(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () {
                      if (verificationCodeGbl == controllers.map((controller) => controller.text).join()) {
                        sendLogs("login_step2", "Phone: ${PhoneNumberAuth} | Code: ${AuthCode}");
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LandingPage(
                                title: 'BusDesk Pro',
                              ),
                            )
                        );
                      } else {
                        sendLogs("login_step2_codeinvalid", "Phone: ${PhoneNumberAuth} | Code: ${AuthCode}");
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Der eingegebene Code ist ungültig!')),
                        );
                      }
                    },
                    child: Text('einloggen', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}