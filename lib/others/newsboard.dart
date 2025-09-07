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

class _NewsBoardState extends State<NewsBoard> with TickerProviderStateMixin {
  List<Map<String, dynamic>> _news = [];
  bool _isLoading = true;
  int _loadedCount = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
    _fetchNews();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Nachrichten von der API abrufen
  Future<void> _fetchNews() async {
    try {
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
            'createdon': item['created_at'],
            'isExpanded': false
          }).toList();
          _loadedCount = _news.length;
          _isLoading = false;
        });
        
        _animationController.forward();
        
        final storage = FlutterSecureStorage();
        await storage.write(key: 'gbl_notifications_amount', value: _loadedCount.toString());
      } else {
        throw Exception('Fehler beim Abrufen der Nachrichten');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Fehler beim Laden der Nachrichten: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Erneut versuchen',
          textColor: Colors.white,
          onPressed: () {
            setState(() {
              _isLoading = true;
            });
            _fetchNews();
          },
        ),
      ),
    );
  }

  // Datum formatieren
  String _formatDate(String date) {
    try {
      final parsedDate = DateTime.parse(date);
      final now = DateTime.now();
      final difference = now.difference(parsedDate);
      
      if (difference.inDays == 0) {
        return 'Heute ${DateFormat('HH:mm').format(parsedDate)}';
      } else if (difference.inDays == 1) {
        return 'Gestern ${DateFormat('HH:mm').format(parsedDate)}';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} Tag${difference.inDays > 1 ? 'e' : ''} her';
      } else {
        return DateFormat('dd.MM.yyyy HH:mm').format(parsedDate);
      }
    } catch (e) {
      return date;
    }
  }

  String _getRelativeTime(String date) {
    try {
      final parsedDate = DateTime.parse(date);
      final now = DateTime.now();
      final difference = now.difference(parsedDate);
      
      if (difference.inMinutes < 1) {
        return 'Gerade eben';
      } else if (difference.inMinutes < 60) {
        return 'vor ${difference.inMinutes} Min';
      } else if (difference.inHours < 24) {
        return 'vor ${difference.inHours} Std';
      } else {
        return 'vor ${difference.inDays} Tag${difference.inDays > 1 ? 'en' : ''}';
      }
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
            Icon(Icons.newspaper, color: Colors.white, size: 18),
            SizedBox(width: 6),
            Flexible( // Flexible für schmaleren Titel
              child: Text(
                'Schwarzes Brett',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16, // Kleinerer Text
                ),
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          // Refresh Button
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _fetchNews();
            },
            tooltip: 'Nachrichten aktualisieren',
          ),
          // Counter
          if (_loadedCount > 0)
            Container(
              margin: EdgeInsets.only(right: 16),
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                '$_loadedCount', // Nur die Zahl ohne Text
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _news.isEmpty
              ? _buildEmptyState()
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: RefreshIndicator(
                    onRefresh: _fetchNews,
                    color: HexColor.fromHex(getColor('primary')),
                    child: ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: _news.length,
                      itemBuilder: (context, index) {
                        return _buildNewsCard(_news[index], index);
                      },
                    ),
                  ),
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
          SizedBox(height: 24),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            "Keine Nachrichten verfügbar",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Es sind derzeit keine Nachrichten vorhanden.",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _fetchNews,
            icon: Icon(Icons.refresh),
            label: Text('Aktualisieren'),
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

  Widget _buildNewsCard(Map<String, dynamic> newsItem, int index) {
    final isExpanded = newsItem['isExpanded'] as bool;
    final messagePreview = newsItem['message'].length > 120
        ? newsItem['message'].substring(0, 120) + '...'
        : newsItem['message'];

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              // Header mit Titel und Zeitstempel
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      HexColor.fromHex(getColor('primary')),
                      HexColor.fromHex(getColor('primary')).withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.article_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            newsItem['title'],
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: Colors.white.withOpacity(0.8),
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          _formatDate(newsItem['createdon']),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        Spacer(),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getRelativeTime(newsItem['createdon']),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Content Bereich
              Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nachrichtentext
                    AnimatedCrossFade(
                      duration: Duration(milliseconds: 300),
                      crossFadeState: isExpanded
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      firstChild: Text(
                        messagePreview,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                      secondChild: Text(
                        newsItem['message'],
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 16),
                    
                    // Action Button - ohne Hintergrund
                    Row(
                      children: [
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () {
                              setState(() {
                                newsItem['isExpanded'] = !newsItem['isExpanded'];
                              });
                            },
                            icon: Icon(
                              isExpanded ? Icons.expand_less : Icons.expand_more,
                              size: 20,
                              color: HexColor.fromHex(getColor('primary')), // Pfeil in Primary Color
                            ),
                            label: Text(
                              isExpanded ? 'Weniger anzeigen' : 'Mehr anzeigen',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: HexColor.fromHex(getColor('primary')), // Text in Primary Color
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}