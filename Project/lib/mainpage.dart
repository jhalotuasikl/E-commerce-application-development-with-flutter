import 'package:flutter/material.dart';
import 'package:project_application/pages/addproduk_page.dart';
import 'package:project_application/pages/buyproduk_page.dart';
import 'package:project_application/pages/beranda.dart';
import 'package:project_application/pages/live_page.dart';
import 'package:project_application/pages/notifikasi_page.dart';
import 'package:project_application/pages/favorites_page.dart';
import 'package:project_application/pages/profile_page.dart';
import 'package:project_application/pages/component/custombottom.dart';
import 'package:project_application/pages/loginregister.dart'; // WelcomePage
import 'package:shared_preferences/shared_preferences.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 2; // default ke Home
  bool _isLoggedIn = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool('is_logged_in') ?? false; // key sama dengan LoginPage
    setState(() {
      _isLoggedIn = loggedIn;
      _loading = false;
    });
  }

  void _onItemTapped(int index) {
    // menu yang harus login
    if ((index == 0 || index == 3 || index == 4 || index == 5 || index == 6) && !_isLoggedIn) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const WelcomePage()), // ganti ke WelcomePage
      );
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final List<Widget> _pages = [
      AddProductPage(), // SELL
      BuyProdukPage(),  // BUY
      BerandaPage(),    // HOME
      LivePage(),       // LIVE
      NotifikasiPage(), // NOTIFICATIONS
      FavoritesPage(),  // FAVORITES
      ProfilePage(),    // PROFILE
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        notifCount: 3,
        favoriteCount: 5,
      ),
    );
  }
}
