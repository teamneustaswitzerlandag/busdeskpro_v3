import 'package:flutter/material.dart';
import 'package:bus_desk_pro/config/globals.dart';
import 'package:bus_desk_pro/libaries/logs.dart';

class CurvedBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final bool showChat;
  final bool showDocuments;

  const CurvedBottomNavigationBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    this.showChat = false,
    this.showDocuments = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _buildNavItems(),
      ),
    );
  }

  int _getItemCount() {
    int count = 2; // Home + Dienste
    if (showChat) count++;
    if (showDocuments) count++;
    count += 2; // Profil + Mehr
    return count;
  }

  List<Widget> _buildNavItems() {
    List<Widget> items = [];
    int index = 0;

    // Home
    items.add(_buildNavItem(Icons.home, index++));
    
    // Dienste
    items.add(_buildNavItem(Icons.info, index++));
    
    // Chat (optional)
    if (showChat) {
      items.add(_buildNavItem(Icons.chat, index++));
    }
    
    // Documents (optional)
    if (showDocuments) {
      items.add(_buildNavItem(Icons.book, index++));
    }
    
    // Profil
    items.add(_buildNavItem(Icons.person, index++));
    
    // Mehr
    items.add(_buildNavItem(Icons.settings, index++));

    return items;
  }

  Widget _buildNavItem(IconData icon, int index) {
    final isActive = currentIndex == index;
    
    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        width: 50,
        height: 50,
        child: Center(
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isActive ? HexColor.fromHex(getColor('primary')) : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.white : Colors.grey[600],
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}
