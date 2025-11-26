import 'package:flutter/material.dart';
import 'package:bus_desk_pro/libaries/logs.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:bus_desk_pro/config/globals.dart';

// Datenmodell für Chat
class TravelChat {
  final String id;
  final String travelId;
  final String title;
  final List<ChatParticipant> participants;
  final List<ChatMessage> messages;
  final DateTime createdAt;
  DateTime? lastMessageAt;
  DateTime? lastReadAt; // Zeitstempel der letzten gelesenen Nachricht

  TravelChat({
    required this.id,
    required this.travelId,
    required this.title,
    required this.participants,
    required this.messages,
    required this.createdAt,
    this.lastMessageAt,
    this.lastReadAt,
  });

  // Erstelle eine Kopie mit aktualisiertem lastReadAt
  TravelChat copyWith({DateTime? lastReadAt}) {
    return TravelChat(
      id: id,
      travelId: travelId,
      title: title,
      participants: participants,
      messages: messages,
      createdAt: createdAt,
      lastMessageAt: lastMessageAt,
      lastReadAt: lastReadAt ?? this.lastReadAt,
    );
  }

  // Zähle ungelesene Nachrichten für einen Benutzer
  int getUnreadCount(String currentUserPhone) {
    if (lastReadAt == null) {
      // Wenn noch nie gelesen, alle Nachrichten zählen, die nicht vom aktuellen Benutzer sind
      return messages.where((m) => m.senderPhone != currentUserPhone).length;
    }
    
    // Zähle Nachrichten nach dem letzten gelesenen Zeitstempel
    return messages.where((m) => 
      m.senderPhone != currentUserPhone && 
      m.timestamp.isAfter(lastReadAt!)
    ).length;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'travelId': travelId,
      'title': title,
      'participants': participants.map((p) => p.toJson()).toList(),
      'messages': messages.map((m) => m.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'lastMessageAt': lastMessageAt?.toIso8601String(),
      'lastReadAt': lastReadAt?.toIso8601String(),
    };
  }

  factory TravelChat.fromJson(Map<String, dynamic> json) {
    return TravelChat(
      id: json['id'],
      travelId: json['travelId'],
      title: json['title'],
      participants: (json['participants'] as List)
          .map((p) => ChatParticipant.fromJson(p))
          .toList(),
      messages: (json['messages'] as List)
          .map((m) => ChatMessage.fromJson(m))
          .toList(),
      createdAt: DateTime.parse(json['createdAt']),
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.parse(json['lastMessageAt'])
          : null,
      lastReadAt: json['lastReadAt'] != null
          ? DateTime.parse(json['lastReadAt'])
          : null,
    );
  }
}

class ChatParticipant {
  final String name;
  final String phoneNumber;

  ChatParticipant({required this.name, required this.phoneNumber});

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
    };
  }

  factory ChatParticipant.fromJson(Map<String, dynamic> json) {
    return ChatParticipant(
      name: json['name'],
      phoneNumber: json['phoneNumber'],
    );
  }
}

class ChatMessage {
  final String id;
  final String senderName;
  final String senderPhone;
  final String text;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.senderName,
    required this.senderPhone,
    required this.text,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderName': senderName,
      'senderPhone': senderPhone,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      senderName: json['senderName'],
      senderPhone: json['senderPhone'],
      text: json['text'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

class TravelChatModule {
  // Lade alle Chats für eine Reise
  static Future<List<TravelChat>> getChatsForTravel(String travelId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'travel_chats_$travelId';
      final chatsJson = prefs.getString(key);
      
      if (chatsJson == null) {
        return [];
      }

      final List<dynamic> chatsList = json.decode(chatsJson);
      return chatsList.map((chat) => TravelChat.fromJson(chat)).toList()
        ..sort((a, b) {
          final aTime = a.lastMessageAt ?? a.createdAt;
          final bTime = b.lastMessageAt ?? b.createdAt;
          return bTime.compareTo(aTime); // Neueste zuerst
        });
    } catch (e) {
      print('Fehler beim Laden der Chats: $e');
      return [];
    }
  }

  // Speichere Chats für eine Reise
  static Future<void> saveChatsForTravel(String travelId, List<TravelChat> chats) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'travel_chats_$travelId';
      final chatsJson = json.encode(chats.map((chat) => chat.toJson()).toList());
      await prefs.setString(key, chatsJson);
    } catch (e) {
      print('Fehler beim Speichern der Chats: $e');
    }
  }

  // Lade Chats von der API für einen Teilnehmer
  static Future<List<TravelChat>> getChatsFromApi(String phoneNumber, {String? travelId}) async {
    try {
      final apiUrl = getUrl('travel-chat-get');
      if (apiUrl.isEmpty) {
        print('Travel-Chat-Get API nicht konfiguriert');
        return [];
      }

      String urlString = '$apiUrl?phone_number=${Uri.encodeComponent(phoneNumber)}';
      if (travelId != null) {
        urlString += '&travel_id=${Uri.encodeComponent(travelId)}';
      }

      final url = Uri.parse(urlString);
      print('Lade Chats von API: $url');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> chatsList = json.decode(response.body);
        final chats = chatsList.map((chat) => TravelChat.fromJson(chat)).toList();
        
        // Lade lastReadAt aus lokalem Speicher
        final localChats = await getChatsForTravel(travelId ?? '');
        for (int i = 0; i < chats.length; i++) {
          final localChat = localChats.firstWhere(
            (c) => c.id == chats[i].id,
            orElse: () => chats[i],
          );
          if (localChat.lastReadAt != null) {
            chats[i] = chats[i].copyWith(lastReadAt: localChat.lastReadAt);
          }
        }
        
        print('${chats.length} Chats von API geladen');
        return chats;
      } else {
        print('Fehler beim Laden der Chats: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Fehler beim Laden der Chats von API: $e');
      return [];
    }
  }

  // Markiere Chat als gelesen
  static Future<void> markChatAsRead(String travelId, String chatId) async {
    try {
      final chats = await getChatsForTravel(travelId);
      final chatIndex = chats.indexWhere((chat) => chat.id == chatId);
      
      if (chatIndex != -1) {
        chats[chatIndex] = chats[chatIndex].copyWith(lastReadAt: DateTime.now());
        await saveChatsForTravel(travelId, chats);
      }
    } catch (e) {
      print('Fehler beim Markieren als gelesen: $e');
    }
  }

  // Erstelle einen neuen Chat
  static Future<TravelChat> createChat({
    required String travelId,
    required String title,
    required List<ChatParticipant> participants,
  }) async {
    final chat = TravelChat(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      travelId: travelId,
      title: title,
      participants: participants,
      messages: [],
      createdAt: DateTime.now(),
    );

    final chats = await getChatsForTravel(travelId);
    chats.add(chat);
    await saveChatsForTravel(travelId, chats);

    // Sende Chat an Backend (falls API konfiguriert ist)
    await _sendChatToBackend(chat);

    return chat;
  }

  // Sende Chat an Backend API
  static Future<void> _sendChatToBackend(TravelChat chat) async {
    try {
      final apiUrl = getUrl('travel-chat-create');
      if (apiUrl.isEmpty) {
        print('Travel-Chat API nicht konfiguriert, Chat nur lokal gespeichert');
        print('Chat JSON: ${json.encode(chat.toJson())}');
        return;
      }

      final url = Uri.parse(apiUrl);
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'chat_id': chat.id,
          'travel_id': chat.travelId,
          'title': chat.title,
          'participants': chat.participants.map((p) => p.toJson()).toList(),
          'created_at': chat.createdAt.toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        print('Chat erfolgreich an Backend gesendet');
      } else {
        print('Fehler beim Senden des Chats: ${response.statusCode}');
      }
    } catch (e) {
      print('Fehler beim Senden des Chats an Backend: $e');
    }
  }

  // Füge eine Nachricht zu einem Chat hinzu
  static Future<void> addMessageToChat({
    required String travelId,
    required String chatId,
    required ChatMessage message,
  }) async {
    final chats = await getChatsForTravel(travelId);
    final chatIndex = chats.indexWhere((chat) => chat.id == chatId);
    
    if (chatIndex != -1) {
      chats[chatIndex].messages.add(message);
      chats[chatIndex].lastMessageAt = DateTime.now();
      await saveChatsForTravel(travelId, chats);
      
      // Sende Nachricht an Backend (falls API konfiguriert ist)
      await _sendMessageToBackend(chatId, message);
    }
  }

  // Sende Nachricht an Backend API
  static Future<void> _sendMessageToBackend(String chatId, ChatMessage message) async {
    try {
      final apiUrl = getUrl('travel-chat-message');
      if (apiUrl.isEmpty) {
        print('Travel-Chat-Message API nicht konfiguriert, Nachricht nur lokal gespeichert');
        return;
      }

      final url = Uri.parse(apiUrl);
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'chat_id': chatId,
          'message_id': message.id,
          'sender_name': message.senderName,
          'sender_phone': message.senderPhone,
          'text': message.text,
          'timestamp': message.timestamp.toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        print('Nachricht erfolgreich an Backend gesendet');
      } else {
        print('Fehler beim Senden der Nachricht: ${response.statusCode}');
      }
    } catch (e) {
      print('Fehler beim Senden der Nachricht an Backend: $e');
    }
  }

  // Zeige Chat-Liste für eine Reise
  static void showChatList(BuildContext context, String travelId, String travelTitle) {
    showDialog(
      context: context,
      builder: (context) => _ChatListDialog(travelId: travelId, travelTitle: travelTitle),
    );
  }

  // Zeige Chat-Ansicht
  static void showChatView(BuildContext context, TravelChat chat, String travelTitle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _ChatViewScreen(chat: chat, travelTitle: travelTitle),
      ),
    );
  }
}

// Chat-Liste Dialog
class _ChatListDialog extends StatefulWidget {
  final String travelId;
  final String travelTitle;

  const _ChatListDialog({required this.travelId, required this.travelTitle});

  @override
  State<_ChatListDialog> createState() => _ChatListDialogState();
}

class _ChatListDialogState extends State<_ChatListDialog> {
  List<TravelChat> _chats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    setState(() => _isLoading = true);
    
    // Lade lokale Chats
    final localChats = await TravelChatModule.getChatsForTravel(widget.travelId);
    
    // Lade Chats von API (falls konfiguriert)
    try {
      final apiChats = await TravelChatModule.getChatsFromApi(
        PhoneNumberAuth,
        travelId: widget.travelId,
      );
      
      // Merge: API-Chats haben Priorität, lokale als Fallback
      if (apiChats.isNotEmpty) {
        setState(() {
          _chats = apiChats;
          _isLoading = false;
        });
        // Speichere auch lokal als Cache
        await TravelChatModule.saveChatsForTravel(widget.travelId, apiChats);
      } else {
        setState(() {
          _chats = localChats;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Fallback auf lokale Chats bei Fehler
      print('Fehler beim Laden von API-Chats, verwende lokale: $e');
      setState(() {
        _chats = localChats;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: HexColor.fromHex(getColor('primary')),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.chat_bubble_outline, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chats',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.travelTitle,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.refresh, color: Colors.white),
                    onPressed: _loadChats,
                    tooltip: 'Chats aktualisieren',
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Chat-Liste
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _chats.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
                              SizedBox(height: 16),
                              Text(
                                'Noch keine Chats',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Erstellen Sie einen neuen Chat',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.all(8),
                          itemCount: _chats.length,
                          itemBuilder: (context, index) {
                            final chat = _chats[index];
                            final lastMessage = chat.messages.isNotEmpty
                                ? chat.messages.last
                                : null;
                            final unreadCount = chat.getUnreadCount(PhoneNumberAuth);
                            
                            return Card(
                              margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                              elevation: unreadCount > 0 ? 2 : 0,
                              color: unreadCount > 0
                                  ? HexColor.fromHex(getColor('primary')).withOpacity(0.05)
                                  : null,
                              child: ListTile(
                                leading: Stack(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: HexColor.fromHex(getColor('primary')),
                                      child: Icon(Icons.chat, color: Colors.white),
                                    ),
                                    // Badge für ungelesene Nachrichten
                                    if (unreadCount > 0)
                                      Positioned(
                                        right: 0,
                                        top: 0,
                                        child: Container(
                                          padding: EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white, width: 2),
                                          ),
                                          constraints: BoxConstraints(
                                            minWidth: 18,
                                            minHeight: 18,
                                          ),
                                          child: Text(
                                            unreadCount > 99 ? '99+' : '$unreadCount',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                title: Text(
                                  chat.title,
                                  style: TextStyle(
                                    fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (lastMessage != null)
                                      Text(
                                        lastMessage.text,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                                        ),
                                      )
                                    else
                                      Text('Keine Nachrichten'),
                                    SizedBox(height: 4),
                                    Text(
                                      lastMessage != null
                                          ? DateFormat('dd.MM.yyyy HH:mm').format(lastMessage.timestamp)
                                          : DateFormat('dd.MM.yyyy').format(chat.createdAt),
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                                trailing: Icon(Icons.chevron_right),
                                onTap: () async {
                                  // Markiere als gelesen beim Öffnen
                                  final updatedChat = chat.copyWith(lastReadAt: DateTime.now());
                                  await TravelChatModule.markChatAsRead(widget.travelId, chat.id);
                                  Navigator.pop(context);
                                  TravelChatModule.showChatView(context, updatedChat, widget.travelTitle);
                                },
                              ),
                            );
                          },
                        ),
            ),
            // Neuer Chat Button
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _showCreateChatDialog(context);
                    _loadChats();
                  },
                  icon: Icon(Icons.add),
                  label: Text('Neuer Chat'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HexColor.fromHex(getColor('primary')),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreateChatDialog(BuildContext context) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _CreateChatDialog(travelId: widget.travelId),
    );

    if (result != null) {
      await TravelChatModule.createChat(
        travelId: widget.travelId,
        title: result['title'],
        participants: result['participants'],
      );
    }
  }
}

// Dialog zum Erstellen eines neuen Chats
class _CreateChatDialog extends StatefulWidget {
  final String travelId;

  const _CreateChatDialog({required this.travelId});

  @override
  State<_CreateChatDialog> createState() => _CreateChatDialogState();
}

class _CreateChatDialogState extends State<_CreateChatDialog> {
  final TextEditingController _titleController = TextEditingController();
  List<ChatParticipant> _selectedParticipants = [];
  List<Contact> _contacts = [];
  bool _isLoadingContacts = false;
  String _searchQuery = '';
  bool _showFullList = false; // Toggle zwischen Suche und vollständiger Liste

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    setState(() => _isLoadingContacts = true);
    
    try {
      print('=== KONTAKTE LADEN ===');
      
      // Prüfe Berechtigung
      final permission = await Permission.contacts.status;
      print('Berechtigungsstatus: $permission');
      
      if (!permission.isGranted) {
        print('Berechtigung nicht erteilt, frage an...');
        
        // Prüfe ob Berechtigung permanent verweigert wurde
        if (permission.isPermanentlyDenied) {
          print('Berechtigung permanent verweigert, öffne Einstellungen');
          setState(() => _isLoadingContacts = false);
          if (mounted) {
            final shouldOpen = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Kontaktzugriff erforderlich'),
                content: Text('Um Kontakte auszuwählen, benötigt die App Zugriff auf Ihr Kontaktbuch. Bitte aktivieren Sie die Berechtigung in den Einstellungen.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text('Abbrechen'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text('Einstellungen öffnen'),
                  ),
                ],
              ),
            );
            
            if (shouldOpen == true) {
              await openAppSettings();
            }
          }
          return;
        }
        
        // Frage nach Berechtigung
        final result = await Permission.contacts.request();
        print('Berechtigungsanfrage Ergebnis: $result');
        
        if (!result.isGranted) {
          print('Berechtigung wurde verweigert');
          setState(() => _isLoadingContacts = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Kontaktzugriff wurde verweigert. Bitte in den Einstellungen aktivieren.'),
                duration: Duration(seconds: 4),
                action: SnackBarAction(
                  label: 'Einstellungen',
                  onPressed: () => openAppSettings(),
                ),
              ),
            );
          }
          return;
        }
      }

      print('Berechtigung vorhanden, lade Kontakte...');
      
      // Lade Kontakte
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withThumbnail: false,
      );
      
      print('Geladene Kontakte: ${contacts.length}');
      print('Kontakte mit Telefonnummer: ${contacts.where((c) => c.phones.isNotEmpty).length}');
      
      if (contacts.isEmpty) {
        print('WARNUNG: Keine Kontakte gefunden!');
      }
      
      setState(() {
        _contacts = contacts;
        _isLoadingContacts = false;
      });
      
      print('Kontakte erfolgreich geladen');
    } catch (e, stackTrace) {
      print('FEHLER beim Laden der Kontakte: $e');
      print('Stack Trace: $stackTrace');
      setState(() => _isLoadingContacts = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Laden der Kontakte: $e'),
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  List<Contact> get _filteredContacts {
    // Sortiere Kontakte alphabetisch nach Namen
    final contactsWithPhone = _contacts.where((c) => c.phones.isNotEmpty).toList();
    contactsWithPhone.sort((a, b) => a.displayName.compareTo(b.displayName));
    
    // Wenn Suche aktiv ist, filtere
    if (_searchQuery.isNotEmpty) {
      return contactsWithPhone.where((contact) {
        final name = contact.displayName.toLowerCase();
        final phones = contact.phones.map((p) => p.number).join(' ').toLowerCase();
        final query = _searchQuery.toLowerCase();
        return name.contains(query) || phones.contains(query);
      }).toList();
    }
    
    // Wenn vollständige Liste angezeigt werden soll oder Suche leer ist
    return contactsWithPhone;
  }

  void _toggleParticipant(Contact contact) {
    final phone = contact.phones.isNotEmpty ? contact.phones.first.number : '';
    if (phone.isEmpty) return;

    final participant = ChatParticipant(
      name: contact.displayName,
      phoneNumber: phone,
    );

    setState(() {
      if (_selectedParticipants.any((p) => p.phoneNumber == phone)) {
        _selectedParticipants.removeWhere((p) => p.phoneNumber == phone);
      } else {
        _selectedParticipants.add(participant);
      }
    });
  }

  bool _isParticipantSelected(Contact contact) {
    if (contact.phones.isEmpty) return false;
    final phone = contact.phones.first.number;
    return _selectedParticipants.any((p) => p.phoneNumber == phone);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: HexColor.fromHex(getColor('primary')),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.add_circle_outline, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Neuer Chat',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Titel-Eingabe
            Padding(
              padding: EdgeInsets.all(16),
              child: TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Chat-Name / Titel',
                  hintText: 'z.B. Reiseleitung, Hotel, Busfahrer...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
              ),
            ),
            // Suchfeld und Toggle
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'Kontakte suchen',
                        hintText: 'Name oder Telefonnummer eingeben...',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear),
                                onPressed: () {
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                          _showFullList = false; // Bei Suche automatisch auf Suchmodus
                        });
                      },
                    ),
                  ),
                  SizedBox(width: 8),
                  // Toggle Button für vollständige Liste
                  Tooltip(
                    message: _showFullList ? 'Suchmodus' : 'Alle Kontakte',
                    child: IconButton(
                      icon: Icon(_showFullList ? Icons.search : Icons.list),
                      onPressed: () {
                        setState(() {
                          _showFullList = !_showFullList;
                          if (_showFullList) {
                            _searchQuery = ''; // Suche zurücksetzen wenn Liste angezeigt wird
                          }
                        });
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: _showFullList
                            ? HexColor.fromHex(getColor('primary'))
                            : Colors.grey[300],
                        foregroundColor: _showFullList ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8),
            // Ausgewählte Teilnehmer
            if (_selectedParticipants.isNotEmpty)
              Container(
                height: 60,
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedParticipants.length,
                  itemBuilder: (context, index) {
                    final participant = _selectedParticipants[index];
                    return Chip(
                      label: Text(participant.name),
                      avatar: CircleAvatar(
                        backgroundColor: HexColor.fromHex(getColor('primary')),
                        child: Icon(Icons.person, size: 16, color: Colors.white),
                      ),
                      onDeleted: () {
                        setState(() {
                          _selectedParticipants.removeAt(index);
                        });
                      },
                    );
                  },
                ),
              ),
            // Kontaktliste
            Expanded(
              child: _isLoadingContacts
                  ? Center(child: CircularProgressIndicator())
                  : _filteredContacts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.contacts_outlined, size: 64, color: Colors.grey[400]),
                              SizedBox(height: 16),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'Keine Kontakte gefunden'
                                    : 'Keine Kontakte verfügbar',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (_searchQuery.isNotEmpty) ...[
                                SizedBox(height: 8),
                                Text(
                                  'Versuchen Sie eine andere Suche',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        )
                      : Column(
                          children: [
                            // Info-Banner
                            if (_showFullList || _searchQuery.isEmpty)
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                color: Colors.blue[50],
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${_filteredContacts.length} Kontakte',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.blue[700],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            // Kontaktliste
                            Expanded(
                              child: ListView.builder(
                                padding: EdgeInsets.all(8),
                                itemCount: _filteredContacts.length,
                                itemBuilder: (context, index) {
                                  final contact = _filteredContacts[index];
                                  final hasPhone = contact.phones.isNotEmpty;
                                  final isSelected = _isParticipantSelected(contact);
                                  
                                  if (!hasPhone) return SizedBox.shrink();

                                  return Card(
                                    margin: EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                                    elevation: isSelected ? 2 : 0,
                                    color: isSelected
                                        ? HexColor.fromHex(getColor('primary')).withOpacity(0.1)
                                        : null,
                                    child: CheckboxListTile(
                                      value: isSelected,
                                      onChanged: (value) => _toggleParticipant(contact),
                                      title: Text(
                                        contact.displayName,
                                        style: TextStyle(
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                      subtitle: Text(
                                        contact.phones.first.number,
                                        style: TextStyle(fontSize: 12),
                                      ),
                                      secondary: CircleAvatar(
                                        backgroundColor: isSelected
                                            ? HexColor.fromHex(getColor('primary'))
                                            : Colors.grey[300],
                                        child: Text(
                                          contact.displayName.isNotEmpty
                                              ? contact.displayName[0].toUpperCase()
                                              : '?',
                                          style: TextStyle(
                                            color: isSelected ? Colors.white : Colors.black87,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
            ),
            // Buttons
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Abbrechen'),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _titleController.text.trim().isEmpty ||
                              _selectedParticipants.isEmpty
                          ? null
                          : () {
                              Navigator.pop(
                                context,
                                {
                                  'title': _titleController.text.trim(),
                                  'participants': _selectedParticipants,
                                },
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: HexColor.fromHex(getColor('primary')),
                        foregroundColor: Colors.white,
                      ),
                      child: Text('Erstellen'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Chat-Ansicht Screen
class _ChatViewScreen extends StatefulWidget {
  final TravelChat chat;
  final String travelTitle;

  const _ChatViewScreen({required this.chat, required this.travelTitle});

  @override
  State<_ChatViewScreen> createState() => _ChatViewScreenState();
}

class _ChatViewScreenState extends State<_ChatViewScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late TravelChat _chat;
  String? _currentUserPhone; // Sollte aus der App-Konfiguration kommen

  @override
  void initState() {
    super.initState();
    _chat = widget.chat;
    // Aktuelle Benutzer-Telefonnummer aus App-Konfiguration
    _currentUserPhone = PhoneNumberAuth;
    
    // Markiere Chat als gelesen beim Öffnen
    _chat = _chat.copyWith(lastReadAt: DateTime.now());
    TravelChatModule.markChatAsRead(_chat.travelId, _chat.id);
    
    // Lade Chat-Daten beim Öffnen
    _loadChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderName: 'Ich', // TODO: Echter Benutzername
      senderPhone: _currentUserPhone ?? '',
      text: _messageController.text.trim(),
      timestamp: DateTime.now(),
    );

    await TravelChatModule.addMessageToChat(
      travelId: _chat.travelId,
      chatId: _chat.id,
      message: message,
    );

    _messageController.clear();
    _loadChat();
    _scrollToBottom();
  }

  Future<void> _loadChat() async {
    // Lade von API, falls verfügbar
    try {
      final apiChats = await TravelChatModule.getChatsFromApi(
        PhoneNumberAuth ?? '',
        travelId: _chat.travelId,
      );
      if (apiChats.isNotEmpty) {
        final updatedChat = apiChats.firstWhere(
          (c) => c.id == _chat.id,
          orElse: () => _chat,
        );
        // Behalte lastReadAt wenn vorhanden
        var finalChat = updatedChat;
        if (_chat.lastReadAt != null) {
          finalChat = updatedChat.copyWith(lastReadAt: _chat.lastReadAt);
        }
        setState(() => _chat = finalChat);
        return;
      }
    } catch (e) {
      print('Fehler beim Laden von API, verwende lokale: $e');
    }
    
    // Fallback auf lokale Chats
    final chats = await TravelChatModule.getChatsForTravel(_chat.travelId);
    final updatedChat = chats.firstWhere((c) => c.id == _chat.id);
    setState(() => _chat = updatedChat);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: HexColor.fromHex(getColor('primary')),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_chat.title),
            Text(
              '${_chat.participants.length} Teilnehmer',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          PopupMenuButton(
            icon: Icon(Icons.more_vert),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: Row(
                  children: [
                    Icon(Icons.info_outline),
                    SizedBox(width: 8),
                    Text('Chat-Info'),
                  ],
                ),
                onTap: () {
                  // TODO: Chat-Info Dialog
                },
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Nachrichtenliste
          Expanded(
            child: _chat.messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
                        SizedBox(height: 16),
                        Text(
                          'Noch keine Nachrichten',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(16),
                    itemCount: _chat.messages.length,
                    itemBuilder: (context, index) {
                      final message = _chat.messages[index];
                      final isOwnMessage = message.senderPhone == _currentUserPhone;
                      
                      return Align(
                        alignment: isOwnMessage ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: EdgeInsets.only(bottom: 8),
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.7,
                          ),
                          decoration: BoxDecoration(
                            color: isOwnMessage
                                ? HexColor.fromHex(getColor('primary'))
                                : Colors.grey[300],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!isOwnMessage)
                                Text(
                                  message.senderName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              SizedBox(height: 4),
                              Text(
                                message.text,
                                style: TextStyle(
                                  color: isOwnMessage ? Colors.white : Colors.black87,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                DateFormat('HH:mm').format(message.timestamp),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isOwnMessage ? Colors.white70 : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          // Eingabefeld
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
              color: Colors.white,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Nachricht eingeben...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.send, color: HexColor.fromHex(getColor('primary'))),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

