import 'package:flutter/material.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Data dummy riwayat sesuai di video
    final List<Map<String, String>> historyData = [
      {'penerima': 'Aulia Rachmah', 'alamat': 'Ruko ITC BSD, Tangerang Selatan', 'waktu': '12 Jan 2024, 09:45 WIB'},
      {'penerima': 'Lailan Nayra', 'alamat': 'Pamulang, Tangerang Selatan', 'waktu': '13 Jan 2024, 10:40 WIB'},
      {'penerima': 'Siti Alyana', 'alamat': 'Jl. Kebayoran Lama', 'waktu': '13 Jan 2024, 11:45 WIB'},
    ];

    return Scaffold(
      backgroundColor: Colors.white, // Latar belakang halaman putih bersih
      appBar: AppBar(
        title: Image.asset(
          'assets/logo_arkadaya.png', 
          height: 80,                 
          fit: BoxFit.contain,
        ),
        titleSpacing: 16,             
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xff003366),
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 20.0, top: 16.0, right: 16.0, bottom: 12.0),
            child: Text(
              'Riwayat Pengiriman', 
              style: TextStyle(
                fontSize: 22, 
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          
          // Daftar Riwayat Kartu
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: historyData.length,
              itemBuilder: (context, index) {
                final item = historyData[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 20), // Jarak antar kartu
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white, // Latar belakang kotak putih solid
                    borderRadius: BorderRadius.circular(24), 
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
                      // 1. BAGIAN PALING ATAS: Tanggal & Label Status SELESAI
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item['waktu']!, 
                            style: const TextStyle(
                              color: Colors.black, 
                              fontWeight: FontWeight.bold, 
                              fontSize: 13,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xffe6f7ed), // Hijau pastel lembut
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle, color: Color(0xff22bb66), size: 14),
                                SizedBox(width: 6),
                                Text(
                                  'SELESAI', 
                                  style: TextStyle(
                                    color: Color(0xff22bb66), 
                                    fontSize: 11, 
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                      
                      const SizedBox(height: 16), // Jarak antara tanggal ke detail info
                      
                      // 2. BAGIAN TENGAH: Nama Penerima
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Penerima : ', 
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black),
                          ),
                          Expanded(
                            child: Text(
                              '${item['penerima']}', 
                              style: const TextStyle(fontSize: 15, color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 6),
                      
                      // 3. BAGIAN BAWAH: Alamat Penerima
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Alamat     : ', 
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black),
                          ),
                          Expanded(
                            child: Text(
                              '${item['alamat']}', 
                              style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.2),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}