import 'package:flutter/material.dart';

class DetailHistoryPage extends StatelessWidget {
  final Map<String, String> deliveryData;

  const DetailHistoryPage({super.key, required this.deliveryData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xff003366),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Detail Pengiriman',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kotak Detail Informasi Paket
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xff0044aa), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xff0066cc).withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Status Pengiriman',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xffe6f7ed),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Selesai',
                          style: TextStyle(color: Color(0xff22bb66), fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24, thickness: 1),
                  
                  const Text('Waktu Selesai', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(deliveryData['waktu']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  
                  const SizedBox(height: 16),
                  const Text('Nama Penerima', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(deliveryData['penerima']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  
                  const SizedBox(height: 16),
                  const Text('Alamat Tujuan', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(
                    deliveryData['alamat']!, 
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, height: 1.3),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 28),
            
            // Bagian Ruang (Space) Bukti Pengiriman Foto
            const Text(
              'Bukti Pengiriman',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 12),
            
            Container(
              width: double.infinity,
              height: 220,
              decoration: BoxDecoration(
                color: const Color(0xfff5f9ff),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xff0066cc).withValues(alpha: 0.3), width: 1.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(19),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Opacity(
                      opacity: 0.04,
                      child: Image.asset(
                        'assets/logo_arkadaya.png',
                        fit: BoxFit.none,
                        scale: 0.5,
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image_outlined, size: 48, color: const Color(0xff0044aa).withValues(alpha: 0.6)),
                        const SizedBox(height: 8),
                        Text(
                          'Foto Bukti Digital Terlampir',
                          style: TextStyle(
                            color: const Color(0xff0044aa).withValues(alpha: 0.7),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Disimpan dengan enkripsi sistem',
                          style: TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}