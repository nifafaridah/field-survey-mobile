
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const String baseUrl = 'https://sijala.biz.id/api/v1';

  static const Color primaryColor = Color(0xFF087F8C);
  static const Color backgroundColor = Color(0xFFF4F8FA);
  static const Color textPrimary = Color(0xFF34434A);
  static const Color textSecondary = Color(0xFF7D8B94);

  String nama = 'Pengguna';
  String email = '';
  int jumlahSurvey = 0;
  int jumlahKategori = 0;

  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      // Ambil data akun yang sudah tersimpan.
      final savedUser = prefs.getString('user');

      if (savedUser != null) {
        final user = jsonDecode(savedUser);

        if (user is Map) {
          nama = (user['name'] ??
                  user['nama'] ??
                  user['username'] ??
                  'Pengguna')
              .toString();

          email = (user['email'] ?? '').toString();
        }
      }

      if (token == null || token.isEmpty) {
        throw Exception('Sesi login tidak ditemukan. Silakan login kembali.');
      }

      final headers = {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      // Ambil ringkasan dashboard dari API.
      final dashboardResponse = await http
          .get(
            Uri.parse('$baseUrl/dashboard'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 20));

      if (dashboardResponse.statusCode == 401) {
        throw Exception('Sesi login berakhir. Silakan login kembali.');
      }

      if (dashboardResponse.statusCode != 200) {
        throw Exception(
          'Gagal mengambil dashboard (${dashboardResponse.statusCode}).',
        );
      }

      final dashboardJson = jsonDecode(dashboardResponse.body);

      if (dashboardJson is! Map ||
          dashboardJson['status'] != true) {
        throw Exception(
          dashboardJson is Map
              ? dashboardJson['message'] ?? 'Gagal memuat dashboard.'
              : 'Format respons dashboard tidak sesuai.',
        );
      }

      final dashboardData = dashboardJson['data'];

      // Cari jumlah survei dari data dashboard.
      final surveyCount = findNumber(dashboardData, [
        'jumlah_survey',
        'jumlah_survei',
        'total_survey',
        'total_surveys',
        'survey_count',
        'surveys_count',
      ]);

      // Ambil kategori melalui endpoint resmi soal.
      final categoryResponse = await http
          .get(
            Uri.parse('$baseUrl/categories'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 20));

      if (categoryResponse.statusCode == 401) {
        throw Exception('Sesi login berakhir. Silakan login kembali.');
      }

      if (categoryResponse.statusCode != 200) {
        throw Exception(
          'Gagal mengambil kategori (${categoryResponse.statusCode}).',
        );
      }

      final categoryJson = jsonDecode(categoryResponse.body);

      if (categoryJson is! Map ||
          categoryJson['status'] != true) {
        throw Exception(
          categoryJson is Map
              ? categoryJson['message'] ?? 'Gagal memuat kategori.'
              : 'Format respons kategori tidak sesuai.',
        );
      }

      final categoryData = categoryJson['data'];
      final categoryCount = findListLength(categoryData, [
        'categories',
        'kategori',
        'data',
      ]);

      // Beberapa API mengirimkan informasi pengguna di dashboard.
      final dashboardUser = dashboardData is Map
          ? (dashboardData['user'] ?? dashboardData['profile'])
          : null;

      if (dashboardUser is Map) {
        nama = (dashboardUser['name'] ??
                dashboardUser['nama'] ??
                dashboardUser['username'] ??
                nama)
            .toString();

        email = (dashboardUser['email'] ?? email).toString();
      }

      if (!mounted) return;

      setState(() {
        if (surveyCount != null) {
          jumlahSurvey = surveyCount;
        }

        jumlahKategori = categoryCount ?? 0;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  int? findNumber(dynamic data, List<String> keys) {
    if (data is Map) {
      for (final key in keys) {
        final value = data[key];

        if (value is num) return value.toInt();

        if (value is String) {
          final number = int.tryParse(value);
          if (number != null) return number;
        }
      }

      for (final value in data.values) {
        final result = findNumber(value, keys);
        if (result != null) return result;
      }
    }

    return null;
  }

  int? findListLength(dynamic data, List<String> keys) {
    if (data is List) return data.length;

    if (data is Map) {
      for (final key in keys) {
        final value = data[key];

        if (value is List) return value.length;
      }

      for (final value in data.values) {
        final result = findListLength(value, keys);
        if (result != null) return result;
      }
    }

    return null;
  }

  Widget statCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.07),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: primaryColor, size: 28),
            const SizedBox(height: 14),
            Text(
              value,
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget menuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 125,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE6EEF1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: primaryColor, size: 28),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: loadDashboard,
          color: primaryColor,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'FIELD SURVEY',
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.4,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Dashboard',
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 20),

              // Informasi akun yang sedang login.
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF087F8C), Color(0xFF36B8B0)],
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.white24,
                      child: Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Selamat datang,',
                            style: TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            nama,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (email.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              email,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),
              const Text(
                'Ringkasan Data',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 14),

              if (isLoading)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                      TextButton.icon(
                        onPressed: loadDashboard,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Coba lagi'),
                      ),
                    ],
                  ),
                )
              else
                Row(
                  children: [
                    statCard(
                      title: 'Jumlah Survei',
                      value: '$jumlahSurvey',
                      icon: Icons.assignment_outlined,
                    ),
                    const SizedBox(width: 12),
                    statCard(
                      title: 'Kategori Survei',
                      value: '$jumlahKategori',
                      icon: Icons.category_outlined,
                    ),
                  ],
                ),

              const SizedBox(height: 26),
              const Text(
                'Menu Utama',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 14),

              // Navigasi tab diatur oleh DashboardPage.
              Row(
                children: [
                  Expanded(
                    child: menuCard(
                      icon: Icons.assignment_outlined,
                      title: 'Survey',
                      subtitle: 'Daftar dan kelola survei',
                      onTap: () => ScaffoldMessenger.of(context)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Pilih tab Survey di bagian bawah.',
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: menuCard(
                      icon: Icons.person_outline_rounded,
                      title: 'Profil',
                      subtitle: 'Informasi akun',
                      onTap: () => ScaffoldMessenger.of(context)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Pilih tab Profile di bagian bawah.',
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE6EEF1)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: primaryColor, size: 26),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Informasi',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: textPrimary,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Gunakan menu Survey untuk melihat dan mengelola data survei dari server.',
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
