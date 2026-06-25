import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'core/supabase/supabase_service.dart';
import 'core/utils/location_service.dart';
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
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  AppBar? _buildAppBar() {
    if (_currentIndex == 2) {
      return AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      );
    }

    if (_isSearching) {
      return AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xff003366),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              _isSearching = false;
              _searchQuery = '';
              _searchController.clear();
            });
          },
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Cari...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey),
          ),
          style: const TextStyle(color: Colors.black, fontSize: 16),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
        actions: [
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _searchController.clear();
                });
              },
            ),
        ],
      );
    }

    return AppBar(
      title: Image.asset(
        'assets/logo_arkadaya.png',
        height: 80,
        fit: BoxFit.contain,
      ),
      titleSpacing: _currentIndex == 0 ? 20 : 16,
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xff003366),
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            setState(() {
              _isSearching = true;
            });
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = <Widget>[
      HomePage(searchQuery: _searchQuery),
      HistoryPage(searchQuery: _searchQuery),
      const ProfilePage(),
    ];

    return Scaffold(
      appBar: _buildAppBar(),
      body: children[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xff0066cc),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            _isSearching = false;
            _searchQuery = '';
            _searchController.clear();
          });
        },
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
  final String searchQuery;
  const HomePage({super.key, this.searchQuery = ''});

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

  @override
  void dispose() {
    // LocationService().stopTracking(); // keep tracking active
    super.dispose();
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

      if (task != null) {
        LocationService().startTracking(driverProfile.id);
      } else {
        LocationService().stopTracking();
      }
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

      if (status == DeliveryStatus.completed ||
          status == DeliveryStatus.delivered) {
        LocationService().stopTracking();
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

    final file = File(pickedFile.path);
    final fileSize = await file.length();
    const maxFileSize = 3 * 1024 * 1024;

    if (fileSize > maxFileSize) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ukuran bukti pengiriman maksimal 3 MB.'),
        ),
      );
      return;
    }

    setState(() => _isUploadingProof = true);

    try {
      await _deliveryRepository.uploadProof(
        task: task,
        driver: driverProfile,
        file: file,
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
    final task = _currentTask;
    if (task != null && task.proofCount >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maksimal 3 foto bukti pengiriman per tugas.'),
        ),
      );
      return;
    }

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

  void _showProofGallery(List<String> imageUrls, int initialIndex) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(20),
          child: _ProofGalleryViewer(
            imageUrls: imageUrls,
            initialIndex: initialIndex,
          ),
        );
      },
    );
  }

  bool _isTaskMatching(DeliveryTask task, String query) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    return task.trackingNumber.toLowerCase().contains(q) ||
        task.recipientName.toLowerCase().contains(q) ||
        task.itemName.toLowerCase().contains(q) ||
        task.recipientAddress.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final task = _currentTask;
    final isMatching = task == null || widget.searchQuery.isEmpty || _isTaskMatching(task, widget.searchQuery);

    return Scaffold(
      backgroundColor: Colors.white,
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
            else if (task == null)
              _InfoCard(
                title: 'Belum ada tugas aktif',
                description:
                    'Tugas yang masih berjalan akan muncul di halaman ini.',
                actionLabel: 'Refresh',
                onPressed: _loadCurrentTask,
              )
            else if (!isMatching)
              _InfoCard(
                title: 'Pencarian tidak ditemukan',
                description: 'Tidak ada tugas aktif yang cocok dengan pencarian "${widget.searchQuery}".',
                actionLabel: 'Refresh',
                onPressed: _loadCurrentTask,
              )
            else
              _TaskCard(
                task: task,
                isUpdatingStatus: _isUpdatingStatus,
                isUploadingProof: _isUploadingProof,
                onOpenMaps: _openMaps,
                onChangeStatus: _showStatusDialog,
                onUploadProof: _showUploadOptions,
                onViewProof: (index) =>
                    _showProofGallery(task.proofImageUrls, index),
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
    required this.onViewProof,
  });

  final DeliveryTask task;
  final bool isUpdatingStatus;
  final bool isUploadingProof;
  final VoidCallback onOpenMaps;
  final VoidCallback onChangeStatus;
  final VoidCallback onUploadProof;
  final void Function(int index) onViewProof;

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
              onPressed:
                  isUploadingProof || task.proofCount >= 3 ? null : onUploadProof,
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
                task.proofCount >= 3
                    ? 'Maksimal 3 Bukti'
                    : task.hasProofs
                        ? 'Tambah Bukti Pengiriman'
                        : 'Upload Bukti Pengiriman',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          if (task.hasProofs) ...[
            const SizedBox(height: 14),
            SizedBox(
              height: 92,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: task.proofImageUrls.length,
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => onViewProof(index),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: SizedBox(
                        width: 120,
                        child: Image.network(
                          task.proofImageUrls[index],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: const Color(0xffeef4fb),
                              alignment: Alignment.center,
                              child: const Text('Preview tidak tersedia'),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => onViewProof(0),
                icon: const Icon(Icons.visibility_outlined),
                label: Text('Lihat Bukti (${task.proofCount}/3)'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xff0044aa),
                ),
              ),
            ),
          ],
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

class _ProofGalleryViewer extends StatefulWidget {
  const _ProofGalleryViewer({
    required this.imageUrls,
    required this.initialIndex,
  });

  final List<String> imageUrls;
  final int initialIndex;

  @override
  State<_ProofGalleryViewer> createState() => _ProofGalleryViewerState();
}

class _ProofGalleryViewerState extends State<_ProofGalleryViewer> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 420,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Bukti ${_currentIndex + 1}/${widget.imageUrls.length}'),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.imageUrls.length,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
              },
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  child: Image.network(
                    widget.imageUrls[index],
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Text('Gagal menampilkan bukti pengiriman.'),
                      );
                    },
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
