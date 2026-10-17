
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../routes/app_router.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const String baseUrl =
      'https://sijala.biz.id/api/v1';

  static const String profileEndpoint = '$baseUrl/profile';
  static const String logoutEndpoint = '$baseUrl/logout';
  static const String imageEndpoint =
      'https://sijala.biz.id/api/image';

  static const Color primaryColor = Color(0xFF20A99A);
  static const Color backgroundColor = Color(0xFFF5FAFA);
  static const Color textPrimary = Color(0xFF263238);
  static const Color textSecondary = Color(0xFF7B8A8B);

  Map<String, dynamic>? profile;
  Future<Uint8List?>? profileImageFuture;

  bool isLoading = true;
  bool isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    getProfile();
  }

  // =========================================================
  // MENGAMBIL DATA PROFIL
  // =========================================================

  Future<void> getProfile() async {
    if (mounted) {
      setState(() => isLoading = true);
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        if (mounted) context.go(AppRouter.login);
        return;
      }

      final response = await http.get(
        Uri.parse(profileEndpoint),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('PROFILE STATUS: ${response.statusCode}');
      debugPrint('PROFILE RESPONSE: ${response.body}');

      if (response.statusCode == 401) {
        await prefs.remove('token');
        await prefs.remove('user');

        if (mounted) context.go(AppRouter.login);
        return;
      }

      final dynamic decoded = jsonDecode(response.body);

      if (response.statusCode == 200 &&
          decoded is Map &&
          decoded['status'] == true &&
          decoded['data'] is Map) {
        final profileData = Map<String, dynamic>.from(
          decoded['data'] as Map,
        );

        final photo = profileData['photo']?.toString();

        if (!mounted) return;

        setState(() {
          profile = profileData;
          profileImageFuture =
              photo != null && photo.isNotEmpty
                  ? fetchProfileImage(photo)
                  : null;
          isLoading = false;
        });

        await prefs.setString('user', jsonEncode(profileData));
      } else {
        final message = decoded is Map
            ? decoded['message']?.toString()
            : null;

        throw Exception(
          message ?? 'Gagal mengambil data profil.',
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => isLoading = false);
      showMessage(
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  // =========================================================
  // MENGAMBIL FOTO PROFIL
  // =========================================================

  Future<Uint8List?> fetchProfileImage(String fileName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.get(
        Uri.parse('$imageEndpoint/$fileName'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 &&
          response.bodyBytes.isNotEmpty) {
        return response.bodyBytes;
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  // =========================================================
  // LOGOUT
  // =========================================================

  Future<void> logout() async {
    if (isLoggingOut) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: primaryColor),
            SizedBox(width: 10),
            Expanded(child: Text('Konfirmasi Logout')),
          ],
        ),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari akun?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (result != true || !mounted) return;

    setState(() => isLoggingOut = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      // Memanggil API logout jika token tersedia.
      if (token != null && token.isNotEmpty) {
        try {
          final response = await http.post(
            Uri.parse(logoutEndpoint),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          );

          debugPrint('LOGOUT STATUS: ${response.statusCode}');
          debugPrint('LOGOUT RESPONSE: ${response.body}');
        } catch (e) {
          debugPrint('Logout API error: $e');
        }
      }

      // Menghapus sesi lokal, bukan mengubah email akun.
      await prefs.remove('token');
      await prefs.remove('user');

      if (mounted) {
        context.go(AppRouter.login);
      }
    } catch (e) {
      if (mounted) {
        showMessage('Gagal logout: $e');
        setState(() => isLoggingOut = false);
      }
    }
  }

  // =========================================================
  // PESAN
  // =========================================================

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: primaryColor,
      ),
    );
  }

  // =========================================================
  // BARIS INFORMASI PROFIL
  // =========================================================

  Widget infoRow(String label, String value, IconData icon) {
    final displayValue =
        value.trim().isEmpty ? '-' : value;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE8EEEE),
            width: 0.8,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: primaryColor, size: 20),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  displayValue,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // KARTU PROFIL
  // =========================================================

  Widget profileCard() {
    final data = profile;

    if (data == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Data profil belum tersedia.'),
        ),
      );
    }

    final name = data['name']?.toString() ?? '-';
    final username = data['username']?.toString() ?? '-';
    final email = data['email']?.toString() ?? '-';
    final phone = data['phone']?.toString() ?? '-';
    final gender = data['gender']?.toString() ?? '-';
    final birthPlace = data['birth_place']?.toString() ?? '-';
    final birthDate = data['birth_date']?.toString() ?? '-';

    return Column(
      children: [
        // HEADER PROFIL
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 28,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF159D91),
                Color(0xFF55C8B9),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.20),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: const Color(0xFFEAF7F5),
                  child: profileImageFuture == null
                      ? const Icon(
                          Icons.person_rounded,
                          size: 52,
                          color: primaryColor,
                        )
                      : FutureBuilder<Uint8List?>(
                          future: profileImageFuture,
                          builder: (context, snapshot) {
                            if (snapshot.hasData &&
                                snapshot.data != null) {
                              return ClipOval(
                                child: Image.memory(
                                  snapshot.data!,
                                  width: 96,
                                  height: 96,
                                  fit: BoxFit.cover,
                                ),
                              );
                            }

                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const SizedBox(
                                width: 25,
                                height: 25,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: primaryColor,
                                ),
                              );
                            }

                            return const Icon(
                              Icons.person_rounded,
                              size: 52,
                              color: primaryColor,
                            );
                          },
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.20),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '@$username',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // INFORMASI PROFIL
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.account_circle_outlined,
                    color: primaryColor,
                    size: 23,
                  ),
                  SizedBox(width: 9),
                  Text(
                    'Informasi Profil',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              infoRow('Username', username, Icons.person_outline),
              // Email hanya ditampilkan; tidak diubah di halaman ini.
              infoRow('Email', email, Icons.email_outlined),
              infoRow('Nomor HP', phone, Icons.phone_outlined),
              infoRow('Jenis Kelamin', gender, Icons.wc_outlined),
              infoRow(
                'Tempat Lahir',
                birthPlace,
                Icons.location_on_outlined,
              ),
              infoRow(
                'Tanggal Lahir',
                birthDate,
                Icons.calendar_today_outlined,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =========================================================
  // KARTU MENU
  // =========================================================

  Widget actionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    final color = isLogout ? Colors.redAccent : primaryColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: cardDecoration(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 23),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: isLogout ? Colors.redAccent : textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 15,
                  color: textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFEDF2F2)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.025),
          blurRadius: 14,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }

  // =========================================================
  // TAMPILAN UTAMA
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          'Profil Saya',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Muat ulang profil',
            onPressed: isLoading ? null : getProfile,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: primaryColor,
          onRefresh: getProfile,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isLoading)
                  const SizedBox(
                    height: 260,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: primaryColor,
                      ),
                    ),
                  )
                else
                  profileCard(),

                const SizedBox(height: 24),

                const Text(
                  'Pengaturan Akun',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),

                const SizedBox(height: 13),

                actionCard(
                  icon: Icons.edit_rounded,
                  title: 'Edit Profil',
                  subtitle: 'Perbarui informasi data diri',
                  onTap: () async {
                    final result = await context.push(
                      AppRouter.editProfile,
                      extra: profile,
                    );

                    if (result == true) {
                      await getProfile();
                    }
                  },
                ),

                actionCard(
                  icon: Icons.logout_rounded,
                  title: isLoggingOut ? 'Sedang keluar...' : 'Keluar',
                  subtitle: 'Keluar dari akun Anda',
                  isLogout: true,
                  onTap: isLoggingOut ? () {} : logout,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
