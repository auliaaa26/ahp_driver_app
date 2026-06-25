import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'core/supabase/supabase_service.dart';
import 'features/deliveries/delivery_repository.dart';
import 'features/deliveries/delivery_task.dart';
import 'features/profile/profile_repository.dart';

class HistoryPage extends StatefulWidget {
  final String searchQuery;
  const HistoryPage({super.key, this.searchQuery = ''});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final DeliveryRepository _deliveryRepository = const DeliveryRepository();
  final ProfileRepository _profileRepository = const ProfileRepository();

  bool _isLoading = true;
  String? _errorMessage;
  List<DeliveryTask> _history = const [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
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

      final profile = await _profileRepository.fetchProfileByEmail(email);
      final history = await _deliveryRepository.fetchHistory(profile);

      if (!mounted) {
        return;
      }

      setState(() {
        _history = history;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'Gagal memuat riwayat: $error';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openProofGallery(List<String> urls, int initialIndex) async {
    showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(20),
          child: _HistoryProofGalleryViewer(
            imageUrls: urls,
            initialIndex: initialIndex,
          ),
        );
      },
    );
  }

  String _formatTimestamp(DateTime? dateTime) {
    if (dateTime == null) {
      return '-';
    }

    return DateFormat('dd MMM yyyy, HH:mm').format(dateTime.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final filteredHistory = _history.where((task) {
      if (widget.searchQuery.isEmpty) return true;
      final q = widget.searchQuery.toLowerCase();
      return task.trackingNumber.toLowerCase().contains(q) ||
          task.recipientName.toLowerCase().contains(q) ||
          task.itemName.toLowerCase().contains(q) ||
          task.recipientAddress.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _loadHistory,
        child: ListView(
          children: [
            const Padding(
              padding: EdgeInsets.only(
                left: 20.0,
                top: 16.0,
                right: 16.0,
                bottom: 12.0,
              ),
              child: Text(
                'Riwayat Pengiriman',
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
              _HistoryInfoCard(
                message: _errorMessage!,
                actionLabel: 'Coba lagi',
                onPressed: _loadHistory,
              )
            else if (_history.isEmpty)
              _HistoryInfoCard(
                message: 'Belum ada pengiriman selesai untuk akun ini.',
                actionLabel: 'Refresh',
                onPressed: _loadHistory,
              )
            else if (filteredHistory.isEmpty)
              _HistoryInfoCard(
                message: 'Tidak ada riwayat pengiriman yang cocok dengan pencarian "${widget.searchQuery}".',
                actionLabel: 'Refresh',
                onPressed: _loadHistory,
              )
            else
              ...filteredHistory.map(
                (task) => _HistoryTaskCard(
                  task: task,
                  timestampText: _formatTimestamp(
                    task.deliveredAt ?? task.createdAt,
                  ),
                  onOpenProofGallery: task.hasProofs
                      ? (index) => _openProofGallery(task.proofImageUrls, index)
                      : null,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HistoryTaskCard extends StatelessWidget {
  const _HistoryTaskCard({
    required this.task,
    required this.timestampText,
    this.onOpenProofGallery,
  });

  final DeliveryTask task;
  final String timestampText;
  final void Function(int index)? onOpenProofGallery;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  timestampText,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xffe6f7ed),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Color(0xff22bb66),
                      size: 14,
                    ),
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
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${task.itemName} • ${task.trackingNumber}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Penerima : ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.black,
                ),
              ),
              Expanded(
                child: Text(
                  task.recipientName,
                  style: const TextStyle(fontSize: 15, color: Colors.black87),
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
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.black,
                ),
              ),
              Expanded(
                child: Text(
                  task.recipientAddress,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          if (task.hasProofs && onOpenProofGallery != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              height: 92,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: task.proofImageUrls.length,
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => onOpenProofGallery!(index),
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
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => onOpenProofGallery!(0),
                icon: const Icon(Icons.photo_outlined),
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

class _HistoryInfoCard extends StatelessWidget {
  const _HistoryInfoCard({
    required this.message,
    required this.actionLabel,
    required this.onPressed,
  });

  final String message;
  final String actionLabel;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
            message,
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

class _HistoryProofGalleryViewer extends StatefulWidget {
  const _HistoryProofGalleryViewer({
    required this.imageUrls,
    required this.initialIndex,
  });

  final List<String> imageUrls;
  final int initialIndex;

  @override
  State<_HistoryProofGalleryViewer> createState() =>
      _HistoryProofGalleryViewerState();
}

class _HistoryProofGalleryViewerState extends State<_HistoryProofGalleryViewer> {
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
                        child: Text('Tidak bisa menampilkan bukti pengiriman.'),
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
