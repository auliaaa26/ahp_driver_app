import 'package:flutter/material.dart';
import 'history_page.dart';
import 'profile_page.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  final List<Widget> _children = [
    const HomePage(),
    const HistoryPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _children[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xff0066cc),
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.access_time_filled), label: 'Tugas'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Riwayat'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String currentStatus = 'Dalam Perjalanan';

  // Fungsi memunculkan pop-up ganti status
  void _showStatusDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pilih Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: ['Dalam Perjalanan', 'Istirahat', 'Sampai'].map((status) {
              return ListTile(
                title: Text(status),
                onTap: () {
                  setState(() => currentStatus = status);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // Fungsi memunculkan opsi kamera / galeri
  void _showUploadOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.photo),
                title: const Text('Photos'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Latar belakang dasar halaman diubah menjadi putih solid
      appBar: AppBar(
        title: Image.asset(
          'assets/logo_arkadaya.png', 
          height: 80,                 // Diatur kembali ke ukuran ideal 32 agar proporsional di AppBar
          fit: BoxFit.contain,        
        ),
        titleSpacing: 20,             
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xff003366),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 4.0, bottom: 12.0, top: 8.0),
              child: Text(
                'Tugas saat ini', 
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
              ),
            ),
            
            // -----------------------------------------------------------------
            // CARD TUGAS DENGAN SHADOW DAN BORDER BIRU (PERSIS RIWAYAT)
            // -----------------------------------------------------------------
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white, // Latar belakang dalam kotak putih solid
                borderRadius: BorderRadius.circular(24), // Lengkungan 24 disamakan dengan halaman riwayat
                border: Border.all(
                  color: const Color(0xff0044aa), // Garis pinggir warna biru tua
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    // KODE BARU YANG REKOMENDASIKAN FLUTTER
color: const Color(0xff0066cc).withValues(alpha: 0.10),
                    blurRadius: 12, 
                    spreadRadius: 1, 
                    offset: const Offset(0, 4), 
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Paket (No. Resi)', 
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  const SizedBox(height: 12),
                  
                  // Struktur Row rapi agar titik dua sejajar lurus
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Penerima : ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Expanded(child: Text('Siti Alyana', style: TextStyle(fontSize: 15))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Alamat     : ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Expanded(child: Text('Jl. Kebayoran Lama', style: TextStyle(fontSize: 15, height: 1.2))),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Informasi Indikator Jarak
                  const Row(
                    children: [
                      Icon(Icons.location_on, color: Color(0xff0066cc), size: 30),
                      SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Sisa Jarak', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          Text('50 KM', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Tombol Aksi: Maps & Status
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.map_outlined, color: Color(0xff0044aa)),
                          label: const Text('Maps', style: TextStyle(color: Color(0xff0044aa), fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xff0044aa), width: 1.2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _showStatusDialog,
                          icon: const Icon(Icons.sync, color: Color(0xff0044aa)),
                          label: Text(
                            currentStatus, 
                            maxLines: 1, 
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Color(0xff0044aa), fontWeight: FontWeight.bold),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xff0044aa), width: 1.2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Tombol Utama: Upload Bukti Pengiriman
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff003366), // Warna tombol biru tua solid
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _showUploadOptions,
                      icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      label: const Text(
                        'Upload Bukti Pengiriman', 
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}