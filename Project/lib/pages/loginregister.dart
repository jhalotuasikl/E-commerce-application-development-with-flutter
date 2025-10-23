import 'package:flutter/material.dart';
import 'login_page.dart'; // import login
import 'register_page.dart'; // import register
import 'package:project_application/mainpage.dart'; // import MainPage agar tombol back bisa kembali ke sini

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Welcome Page',
      home: const WelcomePage(),
    );
  }
}

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.blueAccent),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MainPage()),
            );
          },
        ),
      ),
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome to E-Commerce App',
              style: TextStyle(
                color: Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding:
                const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
              child: const Text('Sign In'),
            ),
            const SizedBox(height: 20),
            const Text(
              'or',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Don't have an account yet?",
              style: TextStyle(
                color: Colors.black,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding:
                const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const RegisterPage()),
                );
              },
              child: const Text('Register Now'),
            ),
          ],
        ),
      ),
    );
  }
}
