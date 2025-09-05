import 'package:flutter/material.dart';
import 'package:sliding_clipped_nav_bar/sliding_clipped_nav_bar.dart';
import 'package:bus_desk_pro/config/globals.dart';
import 'package:bus_desk_pro/libaries/logs.dart'; // NEU: HexColor import

class ModernBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final bool showChat;
  final bool showDocuments;

  const ModernBottomNavigation({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    this.showChat = false,
    this.showDocuments = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<BarItem> barItems = [
      BarItem(
        icon: Icons.home_rounded,
        title: 'Home',
      ),
      BarItem(
        icon: Icons.info_rounded,
        title: 'Dienste',
      ),
    ];

    if (showChat) {
      barItems.add(
        BarItem(
          icon: Icons.chat_rounded,
          title: 'Chat',
        ),
      );
    }

    if (showDocuments) {
      barItems.add(
        BarItem(
          icon: Icons.book_rounded,
          title: 'Dok',
        ),
      );
    }

    barItems.addAll([
      BarItem(
        icon: Icons.person_rounded,
        title: 'Profil',
      ),
      BarItem(
        icon: Icons.settings_rounded,
        title: 'Mehr',
      ),
    ]);

    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SlidingClippedNavBar(
        backgroundColor: Colors.white,
        onButtonPressed: onTap,
        iconSize: 28,
        activeColor: HexColor.fromHex(getColor('primary')),
        inactiveColor: Colors.grey.shade400,
        selectedIndex: currentIndex,
        barItems: barItems,
      ),
    );
  }
}
