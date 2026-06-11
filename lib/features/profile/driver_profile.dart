class DriverProfile {
  const DriverProfile({
    required this.id,
    required this.name,
    this.fullName,
    this.email,
    this.phone,
    this.role,
    this.avatarUrl,
  });

  final int id;
  final String name;
  final String? fullName;
  final String? email;
  final String? phone;
  final String? role;
  final String? avatarUrl;

  factory DriverProfile.fromMap(Map<String, dynamic> map) {
    return DriverProfile(
      id: map['id'] as int,
      name: (map['nama'] as String?) ?? 'Driver',
      fullName: map['nama'] as String?,
      email: map['email'] as String?,
      phone: map['no_hp'] as String?,
      role: map['role'] as String?,
      avatarUrl: map['avatar_url'] as String?,
    );
  }
}
