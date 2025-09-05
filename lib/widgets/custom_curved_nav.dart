import 'package:flutter/material.dart';
import 'package:bus_desk_pro/config/globals.dart';
import 'package:bus_desk_pro/libaries/logs.dart';

class CustomCurvedNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final bool showChat;
  final bool showDocuments;

  const CustomCurvedNavigation({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    this.showChat = false,
    this.showDocuments = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<NavItem> navItems = [
      NavItem(icon: Icons.home_rounded, label: 'Home'),
      NavItem(icon: Icons.info_rounded, label: 'Dienste'),
    ];

    if (showChat) {
      navItems.add(NavItem(icon: Icons.chat_rounded, label: 'Chat'));
    }

    if (showDocuments) {
      navItems.add(NavItem(icon: Icons.book_rounded, label: 'Dok'));
    }

    navItems.addAll([
      NavItem(icon: Icons.person_rounded, label: 'Profil'),
      NavItem(icon: Icons.settings_rounded, label: 'Mehr'),
    ]);

    return Container(
      height: 80,
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
        children: navItems.asMap().entries.map((entry) {
          int index = entry.key;
          NavItem item = entry.value;
          bool isActive = index == currentIndex;

          return GestureDetector(
            onTap: () => onTap(index),
            child: Container(
              width: 60,
              height: 60,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    padding: EdgeInsets.all(isActive ? 8 : 6),
                    decoration: BoxDecoration(
                      color: isActive 
                        ? HexColor.fromHex(getColor('primary')).withOpacity(0.1)
                        : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      item.icon,
                      color: isActive 
                        ? HexColor.fromHex(getColor('primary'))
                        : Colors.grey.shade400,
                      size: isActive ? 26 : 24,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    item.label,
                    style: TextStyle(
                      color: isActive 
                        ? HexColor.fromHex(getColor('primary'))
                        : Colors.grey.shade400,
                      fontSize: 10,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class NavItem {
  final IconData icon;
  final String label;

  NavItem({required this.icon, required this.label});
}
