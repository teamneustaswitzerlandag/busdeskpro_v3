import 'dart:async';
import 'dart:convert';
import 'package:bus_desk_pro/config/globals.dart';
import 'package:bus_desk_pro/libaries/logs.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class MessagesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: LiveChatView(),
    );
  }
}

class LiveChatView extends StatefulWidget {
  @override
  _LiveChatViewState createState() => _LiveChatViewState();
}

class _LiveChatViewState extends State<LiveChatView> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  late Future<void> _fetchMessagesFuture;
  final _storage = FlutterSecureStorage();
  Timer? _timer;
  int _countdown = 10; // Countdown in seconds
  bool reload = true;

  @override
  void initState() {
    super.initState();
    _fetchMessagesFuture = _fetchMessages();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _countdown--;
        if (_countdown == 1) {
          reload = true;
          _fetchMessages();
          _countdown = 10; // Reset countdown
        }
      });
    });
  }

  Future<void> _fetchMessages() async {
    final cachedMessages = await _storage.read(key: 'cachedMessages');

    if (cachedMessages != null && reload == false) {
      final List<dynamic> data = json.decode(cachedMessages);
      setState(() {
        _messages.clear();
        data.forEach((message) {
          final parsedMessage = _removeHtmlTags(message["message"]);
          _messages.add({
            "type": parsedMessage.contains("Fahrer:") ? "user" : "bot",
            "text": parsedMessage,
            "created": message["created"]
          });
        });
        _messages.sort((a, b) => a["created"]!.compareTo(b["created"]!));
      });
    } else {
      reload = false;
      final url = Uri.parse((getUrl('get-messages')).replaceAll('USER', (AllToursGbl.length > 0 ? AllToursGbl[0]['general']['driver'] : '')));
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _messages.clear();
          data.forEach((message) {
            final parsedMessage = _removeHtmlTags(message["message"]);
            _messages.add({
              "type": parsedMessage.contains("Fahrer:") ? "user" : "bot",
              "text": parsedMessage,
              "created": message["created"]
            });
          });
          _messages.sort((a, b) => a["created"]!.compareTo(b["created"]!));
        });
        await _storage.write(key: 'cachedMessages', value: response.body);
      } else {
        print('Failed to fetch messages');
      }
    }
  }

  String _removeHtmlTags(String htmlString) {
    final RegExp exp = RegExp(r'<[^>]*>', multiLine: true, caseSensitive: true);
    return htmlString.replaceAll(exp, '');
  }

  void _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    setState(() {
      _messages.add({"type": "user", "text": ("Fahrer: " + message), "created": DateTime.now().toIso8601String()});
    });

    _messageController.clear();

    // Send the message to the API
    await _sendToApi(("Fahrer: " + message));

    // Optionally, handle the response from the API
  }

  Future<void> _sendToApi(String message) async {
    final url = Uri.parse(getUrl('send-message'));
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'message': message, 'sender': (AllToursGbl.length > 0 ? AllToursGbl[0]['general']['driver'] : '')}),
    );

    if (response.statusCode == 200) {
      print('Message sent successfully');
    } else {
      print('Failed to send message');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<void>(
        future: _fetchMessagesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
              ),
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('Failed to load messages'));
          } else {
            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.all(8.0),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isUserMessage = message["type"] == "user";

                      return Align(
                        alignment: isUserMessage
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: EdgeInsets.symmetric(vertical: 4.0),
                          padding: EdgeInsets.all(10.0),
                          decoration: BoxDecoration(
                            color: isUserMessage ? Colors.red[100] : Colors.grey[300],
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: Text(
                            message["text"]!,
                            style: TextStyle(fontSize: 16.0),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'Nachricht eingeben...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8.0),
                      IconButton(
                        onPressed: () => _sendMessage(_messageController.text),
                        icon: Icon(
                          Icons.send,
                          color: HexColor.fromHex(getColor('primary')),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: Container(
                      padding: EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Text(
                        '$_countdown s',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}