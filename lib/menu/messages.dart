import 'dart:async';
import 'dart:convert';
import 'package:bus_desk_pro/config/globals.dart';
import 'package:bus_desk_pro/libaries/logs.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

class MessagesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LiveChatView(); // Entferne MaterialApp hier
  }
}

class LiveChatView extends StatefulWidget {
  @override
  _LiveChatViewState createState() => _LiveChatViewState();
}

class _LiveChatViewState extends State<LiveChatView> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  late Future<void> _fetchMessagesFuture;
  final _storage = FlutterSecureStorage();
  Timer? _timer;
  int _countdown = 10;
  bool reload = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _fetchMessagesFuture = _fetchMessages();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchMessages() async {
    final cachedMessages = await _storage.read(key: 'cachedMessages');

    if (cachedMessages != null && reload == false) {
      final List<dynamic> data = json.decode(cachedMessages);
      if (mounted) {
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
      }
    } else {
      reload = false;
      final url = Uri.parse((getUrl('get-messages')).replaceAll('USER', (AllToursGbl.length > 0 ? AllToursGbl[0]['general']['driver'] : '')));
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (mounted) {
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
        }
        await _storage.write(key: 'cachedMessages', value: response.body);
      } else {
        print('Failed to fetch messages');
      }
    }
    
    // Starte Animation nur wenn sie initialisiert ist
    if (mounted) {
      _animationController.forward();
    }
  }

  String _removeHtmlTags(String htmlString) {
    final RegExp exp = RegExp(r'<[^>]*>', multiLine: true, caseSensitive: true);
    return htmlString.replaceAll(exp, '');
  }

  void _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    if (mounted) {
      setState(() {
        _messages.add({"type": "user", "text": ("Fahrer: " + message), "created": DateTime.now().toIso8601String()});
      });
    }

    _messageController.clear();
    
    // Scroll to bottom after sending
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    await _sendToApi(("Fahrer: " + message));
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

  String _formatTime(String dateTime) {
    try {
      final parsedDate = DateTime.parse(dateTime);
      return DateFormat('HH:mm').format(parsedDate);
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: HexColor.fromHex(getColor('primary')),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Icon(Icons.chat, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              'Live Chat',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() {
                reload = true;
              });
              _fetchMessages();
            },
            tooltip: 'Nachrichten aktualisieren',
          ),
        ],
      ),
      body: FutureBuilder<void>(
        future: _fetchMessagesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState();
          } else if (snapshot.hasError) {
            return _buildErrorState();
          } else {
            return _buildChatInterface();
          }
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              HexColor.fromHex(getColor('primary')),
            ),
            strokeWidth: 3,
          ),
          SizedBox(height: 16),
          Text(
            "Nachrichten werden geladen...",
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[400],
          ),
          SizedBox(height: 16),
          Text(
            "Fehler beim Laden der Nachrichten",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Bitte versuche es erneut",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                reload = true;
              });
              _fetchMessages();
            },
            icon: Icon(Icons.refresh),
            label: Text('Erneut versuchen'),
            style: ElevatedButton.styleFrom(
              backgroundColor: HexColor.fromHex(getColor('primary')),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatInterface() {
    return Column(
      children: [
        Expanded(
          child: _messages.isEmpty
              ? _buildEmptyState()
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return RepaintBoundary(
                        child: _buildMessageBubble(_messages[index], index),
                      );
                    },
                  ),
                ),
        ),
        _buildMessageInput(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            "Noch keine Nachrichten",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Starte eine Unterhaltung!",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, String> message, int index) {
    final isUserMessage = message["type"] == "user";
    final time = _formatTime(message["created"] ?? "");

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUserMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUserMessage) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: HexColor.fromHex(getColor('primary')).withOpacity(0.1),
              child: Icon(
                Icons.support_agent,
                size: 16,
                color: HexColor.fromHex(getColor('primary')),
              ),
            ),
            SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUserMessage 
                    ? HexColor.fromHex(getColor('primary'))
                    : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: isUserMessage ? Radius.circular(20) : Radius.circular(4),
                  bottomRight: isUserMessage ? Radius.circular(4) : Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message["text"]!,
                    style: TextStyle(
                      fontSize: 16,
                      color: isUserMessage ? Colors.white : Colors.grey[800],
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 12,
                      color: isUserMessage 
                          ? Colors.white.withOpacity(0.7)
                          : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUserMessage) ...[
            SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: HexColor.fromHex(getColor('primary')),
              child: Icon(
                Icons.person,
                size: 16,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: Colors.grey[300]!,
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Nachricht eingeben...',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
          ),
          SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: HexColor.fromHex(getColor('primary')),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: () => _sendMessage(_messageController.text),
              icon: Icon(
                Icons.send,
                color: Colors.white,
                size: 20,
              ),
              padding: EdgeInsets.all(12),
              constraints: BoxConstraints(),
            ),
          ),
        ],
      ),
    );
  }
}