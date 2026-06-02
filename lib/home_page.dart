import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  
  // 1. PERUBAHAN: Ubah dari single File menjadi List untuk menampung banyak foto
  final List<File> _uploadedImages = [];
  final ImagePicker _picker = ImagePicker();

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

  // 2. PERUBAHAN: Fungsi mengambil gambar sekarang menambahkan (add) ke dalam List
  Future<void> _getImage(ImageSource source) async {
    Navigator.pop(context); 
    final XFile? pickedFile = await _picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _uploadedImages.add(File(pickedFile.path)); // Menambahkan foto baru ke daftar
      });
    }
  }

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
                onTap: () => _getImage(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo),
                title: const Text('Photos'),
                onTap: () => _getImage(ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );
  }

  // 3. PERUBAHAN: Preview sekarang menerima file foto yang spesifik saat diklik
  void _showImagePreview(File imageFile) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Stack(
            alignment: Alignment.center,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    imageFile,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Image.asset(
          'assets/logo_arkadaya.png',
          height: 80,
          fit: BoxFit.contain,
        ),
        titleSpacing: 20,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xff003366),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
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
              
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xff0044aa),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
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
                    
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff003366),
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
                    ),

                    // -----------------------------------------------------------------
                    // 4. PERUBAHAN: TAMPILAN GRID BANYAK FOTO DI BAWAH TOMBOL
                    // -----------------------------------------------------------------
                    if (_uploadedImages.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Bukti Foto Tersimpan (${_uploadedImages.length}):',
                        style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      
                      // Menggunakan Wrap agar jika foto lebih dari 3, otomatis turun ke bawahnya berjejer rapi
                      Wrap(
                        spacing: 10, // Jarak horizontal antar kotak foto
                        runSpacing: 10, // Jarak vertikal jika baris baru
                        children: _uploadedImages.map((imageFile) {
                          return GestureDetector(
                            onTap: () => _showImagePreview(imageFile), // Kirim data file spesifik yang diklik
                            child: Stack(
                              children: [
                                Container(
                                  width: 80, // Ukuran sedikit diperkecil agar pas berjejer 3-4 foto
                                  height: 80,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(11),
                                    child: Opacity(
                                      opacity: 0.4, // Tetap mempertahankan efek samar pesananmu
                                      child: Image.file(
                                        imageFile,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                                // BONUS: Tombol hapus kecil di pojok kanan atas tiap foto jika salah upload
                                Positioned(
                                  top: 2,
                                  right: 2,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _uploadedImages.remove(imageFile);
                                      });
                                    },
                                    child: const CircleAvatar(
                                      radius: 9,
                                      backgroundColor: Colors.red,
                                      child: Icon(Icons.close, size: 10, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    // -----------------------------------------------------------------
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}