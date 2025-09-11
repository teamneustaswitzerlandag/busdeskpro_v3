import 'package:bus_desk_pro/config/globals.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:bus_desk_pro/libaries/logs.dart';

class NewsBoardPopup extends StatefulWidget {
  @override
  _NewsBoardPopupState createState() => _NewsBoardPopupState();
}

class _NewsBoardPopupState extends State<NewsBoardPopup> with TickerProviderStateMixin {
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

  Future<void> _fetchNews() async {
    try {
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
      } else {
        throw Exception('Fehler beim Abrufen der Nachrichten');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

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
    return Column(
      children: [
        // Moderner Header
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: HexColor.fromHex(getColor('primary')),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.newspaper_rounded, color: Colors.white, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Schwarzes Brett",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Refresh Button
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                    });
                    _fetchNews();
                  },
                  padding: EdgeInsets.all(8),
                  constraints: BoxConstraints(minWidth: 40, minHeight: 40),
                ),
              ),
              SizedBox(width: 4),
              // Counter
              if (_loadedCount > 0)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$_loadedCount',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              SizedBox(width: 4),
              // Close Button
              IconButton(
                icon: Icon(Icons.close_rounded, color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.all(8),
                constraints: BoxConstraints(minWidth: 40, minHeight: 40),
              ),
            ],
          ),
        ),
        // Content
        Expanded(
          child: _isLoading
              ? _buildLoadingState()
              : _news.isEmpty
                  ? _buildEmptyState()
                  : FadeTransition(
                      opacity: _fadeAnimation,
                      child: ListView.builder(
                        padding: EdgeInsets.all(12),
                        itemCount: _news.length,
                        itemBuilder: (context, index) {
                          return _buildNewsCard(_news[index], index);
                        },
                      ),
                    ),
        ),
      ],
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
            size: 60,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            "Keine Nachrichten verfügbar",
            style: TextStyle(
              fontSize: 16,
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
        ],
      ),
    );
  }

  Widget _buildNewsCard(Map<String, dynamic> newsItem, int index) {
    final isExpanded = newsItem['isExpanded'] as bool;
    final messagePreview = newsItem['message'].length > 100
        ? newsItem['message'].substring(0, 100) + '...'
        : newsItem['message'];

    return Container(
      margin: EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: HexColor.fromHex(getColor('primary')).withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.article_rounded,
                      color: HexColor.fromHex(getColor('primary')),
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        newsItem['title'],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      color: Colors.grey[600],
                      size: 14,
                    ),
                    SizedBox(width: 4),
                    Text(
                      _formatDate(newsItem['createdon']),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: HexColor.fromHex(getColor('primary')).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getRelativeTime(newsItem['createdon']),
                        style: TextStyle(
                          fontSize: 10,
                          color: HexColor.fromHex(getColor('primary')),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedCrossFade(
                  duration: Duration(milliseconds: 300),
                  crossFadeState: isExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  firstChild: Text(
                    messagePreview,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                  ),
                  secondChild: Text(
                    newsItem['message'],
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                  ),
                ),
                SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      newsItem['isExpanded'] = !newsItem['isExpanded'];
                    });
                  },
                  icon: Icon(
                    isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    size: 16,
                    color: HexColor.fromHex(getColor('primary')),
                  ),
                  label: Text(
                    isExpanded ? 'Weniger anzeigen' : 'Mehr anzeigen',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: HexColor.fromHex(getColor('primary')),
                      fontSize: 12,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
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
