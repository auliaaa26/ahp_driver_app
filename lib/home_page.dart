import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'core/supabase/supabase_service.dart';
import 'core/utils/maps_launcher.dart';
import 'features/deliveries/delivery_repository.dart';
import 'features/deliveries/delivery_status.dart';
import 'features/deliveries/delivery_task.dart';
import 'features/profile/driver_profile.dart';
import 'features/profile/profile_repository.dart';
import 'history_page.dart';
import 'profile_page.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = <Widget>[
      const HomePage(),
      const HistoryPage(),
      const ProfilePage(),
    ];

    return Scaffold(
      body: children[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xff0066cc),
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time_filled),
            label: 'Tugas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Riwayat',
          ),
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
  final DeliveryRepository _deliveryRepository = const DeliveryRepository();
  final ProfileRepository _profileRepository = const ProfileRepository();
  final ImagePicker _imagePicker = ImagePicker();

  DriverProfile? _driverProfile;
  DeliveryTask? _currentTask;
  bool _isLoading = true;
  bool _isUpdatingStatus = false;
  bool _isUploadingProof = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCurrentTask();
  }

  Future<void> _loadCurrentTask() async {
    final currentUser = SupabaseService.currentUser;

    if (currentUser == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Session login tidak ditemukan.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = currentUser.email;
      if (email == null || email.isEmpty) {
        throw StateError('Email akun tidak ditemukan.');
      }

      final driverProfile = await _profileRepository.fetchProfileByEmail(email);
      final task = await _deliveryRepository.fetchCurrentTask(driverProfile);

      if (!mounted) {
        return;
      }

      setState(() {
        _driverProfile = driverProfile;
        _currentTask = task;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'Gagal memuat tugas: $error';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateStatus(DeliveryStatus status) async {
    final task = _currentTask;
    final driverProfile = _driverProfile;
    if (task == null || driverProfile == null) {
      return;
    }

    setState(() => _isUpdatingStatus = true);

    try {
      await _deliveryRepository.updateStatus(
        task: task,
        driver: driverProfile,
        status: status,
      );

      if (!mounted) {
        return;
      }

      await _loadCurrentTask();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status diperbarui ke "${status.label}".')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui status: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdatingStatus = false);
      }
    }
  }

  Future<void> _showStatusDialog() async {
    final selectedStatus = await showDialog<DeliveryStatus>(
      context: context,
      builder: (context) {
        final statusOptions = DeliveryStatus.values
            .where((status) => status != DeliveryStatus.delivered)
            .toList();

        return AlertDialog(
          title: const Text('Pilih Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: statusOptions.map((status) {
              return ListTile(
                title: Text(status.label),
                onTap: () => Navigator.pop(context, status),
              );
            }).toList(),
          ),
        );
      },
    );

    if (selectedStatus != null) {
      await _updateStatus(selectedStatus);
    }
  }

  Future<void> _uploadProof(ImageSource source) async {
    final task = _currentTask;
    final driverProfile = _driverProfile;
    if (task == null || driverProfile == null) {
      return;
    }

    final pickedFile = await _imagePicker.pickImage(
      source: source,
      imageQuality: 80,
    );

    if (pickedFile == null) {
      return;
    }

    setState(() => _isUploadingProof = true);

    try {
      await _deliveryRepository.uploadProof(
        task: task,
        driver: driverProfile,
        file: File(pickedFile.path),
      );

      if (!mounted) {
        return;
      }

      await _loadCurrentTask();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bukti pengiriman berhasil diunggah.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload bukti gagal: $error')));
    } finally {
      if (mounted) {
        setState(() => _isUploadingProof = false);
      }
    }
  }

  Future<void> _showUploadOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _uploadProof(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo),
                title: const Text('Photos'),
                onTap: () {
                  Navigator.pop(context);
                  _uploadProof(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openMaps() async {
    final task = _currentTask;
    if (task == null) {
      return;
    }

    final launched = await MapsLauncher.openRoute(
      latitude: task.destinationLatitude,
      longitude: task.destinationLongitude,
      address: task.destinationLabel ?? task.recipientAddress,
    );

    if (!launched && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Tidak bisa membuka Maps.')));
    }
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
      body: RefreshIndicator(
        onRefresh: _loadCurrentTask,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 4.0, bottom: 12.0, top: 8.0),
              child: Text(
                'Tugas saat ini',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorMessage != null)
              _InfoCard(
                title: 'Gagal memuat tugas',
                description: _errorMessage!,
                actionLabel: 'Coba lagi',
                onPressed: _loadCurrentTask,
              )
            else if (_currentTask == null)
              _InfoCard(
                title: 'Belum ada tugas aktif',
                description:
                    'Tugas yang masih berjalan akan muncul di halaman ini.',
                actionLabel: 'Refresh',
                onPressed: _loadCurrentTask,
              )
            else
              _TaskCard(
                task: _currentTask!,
                isUpdatingStatus: _isUpdatingStatus,
                isUploadingProof: _isUploadingProof,
                onOpenMaps: _openMaps,
                onChangeStatus: _showStatusDialog,
                onUploadProof: _showUploadOptions,
              ),
          ],
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.isUpdatingStatus,
    required this.isUploadingProof,
    required this.onOpenMaps,
    required this.onChangeStatus,
    required this.onUploadProof,
  });

  final DeliveryTask task;
  final bool isUpdatingStatus;
  final bool isUploadingProof;
  final VoidCallback onOpenMaps;
  final VoidCallback onChangeStatus;
  final VoidCallback onUploadProof;

  @override
  Widget build(BuildContext context) {
    final String distanceText = task.distanceKm == null
        ? '-'
        : '${task.distanceKm!.toStringAsFixed(task.distanceKm! >= 10 ? 0 : 1)} KM';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xff0044aa), width: 1.5),
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
          Text(
            '${task.itemName} (${task.trackingNumber})',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Penerima : ',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              Expanded(
                child: Text(
                  task.recipientName,
                  style: const TextStyle(fontSize: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Alamat     : ',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              Expanded(
                child: Text(
                  task.recipientAddress,
                  style: const TextStyle(fontSize: 15, height: 1.2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.location_on, color: Color(0xff0066cc), size: 30),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sisa Jarak',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  Text(
                    distanceText,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (task.weightKg != null || task.itemType != null)
                    Text(
                      [
                        if (task.weightKg != null)
                          '${task.weightKg!.toStringAsFixed(1)} kg',
                        if (task.itemType != null) task.itemType!,
                      ].join(' • '),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onOpenMaps,
                  icon: const Icon(
                    Icons.map_outlined,
                    color: Color(0xff0044aa),
                  ),
                  label: const Text(
                    'Maps',
                    style: TextStyle(
                      color: Color(0xff0044aa),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: Color(0xff0044aa),
                      width: 1.2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isUpdatingStatus ? null : onChangeStatus,
                  icon: isUpdatingStatus
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.sync, color: Color(0xff0044aa)),
                  label: Text(
                    task.status.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xff0044aa),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: Color(0xff0044aa),
                      width: 1.2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: isUploadingProof ? null : onUploadProof,
              icon: isUploadingProof
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.camera_alt, color: Colors.white, size: 20),
              label: Text(
                task.proofImageUrl == null
                    ? 'Upload Bukti Pengiriman'
                    : 'Upload Ulang Bukti Pengiriman',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onPressed,
  });

  final String title;
  final String description;
  final String actionLabel;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xffd9e5f5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xff003366),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff0066cc),
              foregroundColor: Colors.white,
            ),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}
