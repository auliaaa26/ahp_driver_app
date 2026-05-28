import 'package:flutter/material.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    // Mengambil ukuran lebar layar untuk kalkulasi ukuran lingkaran
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // -----------------------------------------------------------------
            // HEADER DENGAN ORNAMEN LINGKARAN BERTUMPUK (PERSIS FIGMA)
            // -----------------------------------------------------------------
            SizedBox(
              height: 280, // Tinggi area header
              width: double.infinity,
              child: Stack(
                children: [
                  // 1. Lingkaran Besar Utama (Latar Belakang Kiri-Tengah)
                  Positioned(
                    top: -120,
                    left: -80,
                    child: Container(
                      width: screenWidth * 0.9,
                      height: screenWidth * 0.9,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xff0052cc), // Biru gelap ornamen kiri
                      ),
                    ),
                  ),

                  // 2. Lingkaran Kedua (Tumpukan Kanan Atas dengan Gradasi Lebih Terang)
                  Positioned(
                    top: -100,
                    right: -100,
                    child: Container(
                      width: screenWidth * 0.8,
                      height: screenWidth * 0.8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xff3399ff), // Biru muda figma
                            Color(0xff0066cc), // Biru medium figma
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 3. Teks Welcome di atas Lapisan Lingkaran
                  Positioned(
                    top: 80,
                    left: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 45,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Arkadaya Logistic Driver App',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // -----------------------------------------------------------------
            // AREA FORM LOGIN
            // -----------------------------------------------------------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Sign In',
                    style: TextStyle(
                      fontSize: 24, 
                      fontWeight: FontWeight.bold, 
                      color: Color(0xff003366),
                    ),
                  ),
                  const SizedBox(height: 35),

                  // Input Username / Email
                  TextField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.person_outline, color: Colors.grey, size: 26),
                      hintText: 'Username atau Email',
                      hintStyle: const TextStyle(color: Colors.grey, fontSize: 15),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xff003366), width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xff0052cc), width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Input Password
                  TextField(
                    obscureText: _obscureText,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey, size: 26),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined, 
                          color: Colors.grey,
                        ),
                        onPressed: () => setState(() => _obscureText = !_obscureText),
                      ),
                      hintText: 'Password',
                      hintStyle: const TextStyle(color: Colors.grey, fontSize: 15),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xff003366), width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xff0052cc), width: 2),
                      ),
                    ),
                  ),

                  // Tombol Forgot Password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      child: const Text(
                        'Forgot Password?', 
                        style: TextStyle(color: Colors.orange, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),

                  // Tombol Sign In Berwarna Biru Gelap Solid
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 0, 64, 128),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const MainNavigation()),
                        );
                      },
                      child: const Text(
                        'Sign In', 
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
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