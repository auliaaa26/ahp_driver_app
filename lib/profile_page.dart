import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  File? _image; // Variabel untuk menyimpan file gambar yang dipilih
  final ImagePicker _picker = ImagePicker();

  // Fungsi untuk mengambil gambar dari galeri
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // -----------------------------------------------------------------
              // BAGIAN FOTO PROFIL DENGAN TOMBOL EDIT (PENCIL)
              // -----------------------------------------------------------------
              Center(
                child: Stack(
                  children: [
                    // Lingkaran Foto
                    CircleAvatar(
                      radius: 70,
                      backgroundColor: const Color(0xff0066cc),
                      backgroundImage: _image != null ? FileImage(_image!) : null,
                      child: _image == null
                          ? const Icon(Icons.person, size: 90, color: Colors.white)
                          : null,
                    ),
                    // Tombol Edit (Pensil) di posisi bawah kanan
                    Positioned(
                      bottom: 5,
                      right: 5,
                      child: GestureDetector(
                        onTap: _pickImage, // Klik untuk ganti foto
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xff4488cc),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              const Text(
                'Fauzan Al-fahrizi',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff003366)),
              ),
              const Text(
                'Supir Pengiriman',
                style: TextStyle(color: Colors.black54, fontSize: 16),
              ),

              const SizedBox(height: 30),

              // -----------------------------------------------------------------
              // KOTAK INFORMASI KONTAK (WARNA BIRU MUDA)
              // -----------------------------------------------------------------
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xff99bbdd), // Warna biru background sesuai mockup
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Informasi Kontak',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    
                    // Row No. Telp
                    _buildInfoRow('No. Telp', '08123456789'),
                    const SizedBox(height: 15),
                    
                    // Row Email
                    _buildInfoRow('Email', 'fauzan@arkadaya.com'),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // -----------------------------------------------------------------
              // TOMBOL KELUAR (ORANGE)
              // -----------------------------------------------------------------
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: 130,
                  height: 45,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginPage()),
                        (route) => false,
                      );
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout, color: Colors.black, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Keluar',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Widget bantuan untuk membuat baris informasi (Label & TextField putih)
  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        Expanded(
          child: Container(
            height: 35,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: const TextStyle(color: Colors.black87),
              ),
            ),
          ),
        ),
      ],
    );
  }
}