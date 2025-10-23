import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  /// jumlah notifikasi (misal dari API / state)
  final int notifCount;
  final int favoriteCount;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.notifCount = 0,
    this.favoriteCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: Colors.white54,
      selectedItemColor: Colors.blueAccent,
      unselectedItemColor: Colors.black54,
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      onTap: onTap,
      items: [
        const BottomNavigationBarItem(icon: Icon(Icons.sell), label: 'SELL'),
        const BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'BUY'),
        const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'HOME'),
        const BottomNavigationBarItem(icon: Icon(Icons.live_tv), label: 'LIVE'),

        /// Notifikasi pakai badge
        BottomNavigationBarItem(
          icon: badges.Badge(
            showBadge: notifCount > 0,
            badgeContent: Text(
              notifCount.toString(),
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
            badgeStyle: const badges.BadgeStyle(
              badgeColor: Colors.red,
              padding: EdgeInsets.all(6),
            ),
            child: const Icon(Icons.notifications),
          ),
          label: 'NOTIFICATIONS',
        ),

        /// Favorites juga pakai badge
        BottomNavigationBarItem(
          icon: badges.Badge(
            showBadge: favoriteCount > 0,
            badgeContent: Text(
              favoriteCount.toString(),
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
            badgeStyle: const badges.BadgeStyle(
              badgeColor: Colors.deepOrange,
              padding: EdgeInsets.all(6),
            ),
            child: const Icon(Icons.shopping_cart),
          ),
          label: 'FAVORITES',
        ),

        const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'PROFILE'),
      ],
    );
  }
}
