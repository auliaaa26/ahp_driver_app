class DriverProfile {
  const DriverProfile({
    required this.id,
    required this.name,
    this.fullName,
    this.email,
    this.phone,
    this.role,
  });

  final int id;
  final String name;
  final String? fullName;
  final String? email;
  final String? phone;
  final String? role;

  factory DriverProfile.fromMap(Map<String, dynamic> map) {
    return DriverProfile(
      id: map['id'] as int,
      name: (map['nama'] as String?) ?? 'Driver',
      fullName: map['nama'] as String?,
      email: map['email'] as String?,
      phone: map['no_hp'] as String?,
      role: map['role'] as String?,
    );
  }
}
