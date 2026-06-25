import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'core/supabase/supabase_service.dart';
import 'core/utils/location_service.dart';
import 'features/profile/driver_profile.dart';
import 'features/profile/profile_repository.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ProfileRepository _profileRepository = const ProfileRepository();
  final ImagePicker _picker = ImagePicker();

  File? _localImage;
  DriverProfile? _profile;
  bool _isLoading = true;
  bool _isUploadingAvatar = false;
  bool _isSigningOut = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
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

      if (!mounted) return;

      setState(() {
        _profile = profile;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Gagal memuat profil: $error';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickImage() async {
    final profile = _profile;
    if (profile == null) return;

    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile == null) return;

    final file = File(pickedFile.path);
    final fileSize = await file.length();
    const maxFileSize = 3 * 1024 * 1024;

    if (fileSize > maxFileSize) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ukuran foto maksimal 3 MB.'),
        ),
      );
      return;
    }

    setState(() {
      _localImage = file;
      _isUploadingAvatar = true;
    });

    try {
      final updatedProfile = await _profileRepository.uploadAvatar(
        profile: profile,
        file: file,
      );

      if (!mounted) return;

      setState(() {
        _profile = updatedProfile;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto profil berhasil diperbarui.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _localImage = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengunggah foto profil: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
      }
    }
  }

  Future<void> _handleSignOut() async {
    setState(() => _isSigningOut = true);

    try {
      // ✅ STOP LOCATION TRACKING sebelum logout
      LocationService().stopTracking();

      await SupabaseService.signOut();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    } finally {
      if (mounted) {
        setState(() => _isSigningOut = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = SupabaseService.currentUser;
    final profile = _profile;
    final String? metadataFullName =
        currentUser?.userMetadata?['full_name'] as String?;
    final profileName =
        profile?.name ?? metadataFullName ?? currentUser?.email ?? 'Driver';
    final profileEmail = profile?.email ?? currentUser?.email ?? '-';
    final profilePhone = profile?.phone ?? '-';
    final profileRole = profile?.role ?? 'Supir Pengiriman';
    final avatarUrl = profile?.avatarUrl;

    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          children: [
            const SizedBox(height: 20),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorMessage != null)
              _ProfileInfoCard(
                message: _errorMessage!,
                actionLabel: 'Coba lagi',
                onPressed: _loadProfile,
              )
            else ...[
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 70,
                      backgroundColor: const Color(0xff0066cc),
                      backgroundImage: _localImage != null
                          ? FileImage(_localImage!)
                          : (avatarUrl != null
                              ? NetworkImage(avatarUrl)
                              : null),
                      child: _localImage == null && avatarUrl == null
                          ? const Icon(
                              Icons.person,
                              size: 90,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 5,
                      right: 5,
                      child: GestureDetector(
                        onTap: _isUploadingAvatar ? null : _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xff4488cc),
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: Colors.white, width: 2),
                          ),
                          child: _isUploadingAvatar
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(
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
              Text(
                profileName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff003366),
                ),
              ),
              Text(
                profileRole,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(color: Colors.black54, fontSize: 16),
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xff99bbdd),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Informasi Kontak',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildInfoRow('No. Telp', profilePhone),
                    const SizedBox(height: 15),
                    _buildInfoRow('Email', profileEmail),
                  ],
                ),
              ),
              const SizedBox(height: 40),
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
                    onPressed: _isSigningOut ? null : _handleSignOut,
                    child: _isSigningOut
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.black,
                              ),
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.logout,
                                  color: Colors.black, size: 20),
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
          ],
        ),
      ),
    );
  }

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
            constraints: const BoxConstraints(minHeight: 35),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

class _ProfileInfoCard extends StatelessWidget {
  const _ProfileInfoCard({
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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