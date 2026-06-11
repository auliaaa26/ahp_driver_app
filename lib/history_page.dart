import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'core/supabase/supabase_service.dart';
import 'features/deliveries/delivery_repository.dart';
import 'features/deliveries/delivery_task.dart';
import 'features/profile/profile_repository.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

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

  Future<void> _openProof(String url) async {
    final uri = Uri.parse(url);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak bisa membuka bukti pengiriman.')),
      );
    }
  }

  String _formatTimestamp(DateTime? dateTime) {
    if (dateTime == null) {
      return '-';
    }

    return DateFormat('dd MMM yyyy, HH:mm').format(dateTime.toLocal());
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
        titleSpacing: 16,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xff003366),
        elevation: 0,
      ),
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
            else
              ..._history.map(
                (task) => _HistoryTaskCard(
                  task: task,
                  timestampText: _formatTimestamp(
                    task.deliveredAt ?? task.createdAt,
                  ),
                  onOpenProof: task.proofImageUrl == null
                      ? null
                      : () => _openProof(task.proofImageUrl!),
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
    this.onOpenProof,
  });

  final DeliveryTask task;
  final String timestampText;
  final VoidCallback? onOpenProof;

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
          if (onOpenProof != null) ...[
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onOpenProof,
                icon: const Icon(Icons.photo_outlined),
                label: const Text('Lihat Bukti'),
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
