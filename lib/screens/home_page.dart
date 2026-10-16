import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const Color primaryColor = Color.fromARGB(255, 104, 217, 183);
  static const Color backgroundColor = Color.fromARGB(255, 248, 255, 254);
  static const Color textPrimary = Color.fromARGB(255, 52, 63, 63);
  static const Color textSecondary = Color.fromARGB(255, 125, 142, 140);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // =========================
              // HEADER HOME
              // =========================
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 104, 217, 198),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.home_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Home',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 52, 63, 62),
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Beranda Field Survey',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color.fromARGB(255, 125, 142, 142),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFF0DADA),
                      ),
                    ),
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      color: Color.fromARGB(255, 104, 217, 202),
                      size: 24,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // =========================
              // WELCOME CARD
              // =========================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color.fromARGB(255, 104, 213, 217),
                      Color.fromARGB(255, 135, 229, 232),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromARGB(255, 104, 213, 217).withOpacity(0.18),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selamat Datang 👋',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Field Survey',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Kelola dan pantau kegiatan survey dengan mudah.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.assignment_turned_in_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // =========================
              // JUDUL BAGIAN
              // =========================
              const Text(
                'Beranda',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'Ini adalah halaman utama aplikasi Field Survey.',
                style: TextStyle(
                  fontSize: 13,
                  color: textSecondary,
                ),
              ),

              const SizedBox(height: 18),

              // =========================
              // MENU UTAMA
              // =========================
              Row(
                children: [
                  Expanded(
                    child: _menuCard(
                      icon: Icons.assignment_outlined,
                      title: 'Survey',
                      subtitle: 'Lihat hasil survey',
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _menuCard(
                      icon: Icons.location_on_outlined,
                      title: 'Lokasi',
                      subtitle: 'Data lokasi survey',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: _menuCard(
                      icon: Icons.bar_chart_rounded,
                      title: 'Aktivitas',
                      subtitle: 'Ringkasan aktivitas',
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _menuCard(
                      icon: Icons.person_outline_rounded,
                      title: 'Profil',
                      subtitle: 'Kelola profil',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // =========================
              // INFORMASI
              // =========================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFFF0DADA),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.035),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEDEE),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.info_outline_rounded,
                        color: Color.fromARGB(255, 104, 217, 217),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Informasi',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 52, 63, 62),
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Gunakan menu Survey untuk melihat data hasil survey yang tersedia.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color.fromARGB(255, 125, 142, 140),
                              height: 1.4,
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

  // =========================
  // CARD MENU
  // =========================
  Widget _menuCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      height: 130,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFF0DADA),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 237, 253, 255),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: const Color.fromARGB(255, 104, 217, 202),
              size: 23,
            ),
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}