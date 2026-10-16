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

  static const String profileEndpoint =
      '$baseUrl/profile';

  static const String imageEndpoint =
      'https://sijala.biz.id/api/image';

  Map<String, dynamic>? profile;

  Future<Uint8List?>? profileImageFuture;

  bool isLoading = true;

  // ============================================================
  // WARNA TEMA
  // ============================================================

  static const Color primaryColor =
      Color.fromARGB(255, 104, 217, 202);

  static const Color primaryLight =
      Color.fromARGB(255, 138, 222, 233);

  static const Color backgroundColor =
      Color.fromARGB(255, 248, 255, 255);

  static const Color textPrimary =
      Color.fromARGB(255, 52, 62, 63);

  static const Color textSecondary =
      Color.fromARGB(255, 125, 142, 140);

  static const Color borderColor =
      Color.fromARGB(255, 218, 232, 234);

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    getProfile();
  }

  // ============================================================
  // GET PROFILE
  // ============================================================

  Future<void> getProfile() async {
    try {
      if (mounted) {
        setState(() {
          isLoading = true;
        });
      }

      final prefs =
          await SharedPreferences.getInstance();

      final token =
          prefs.getString('token');

      // Token tidak ada
      if (token == null || token.isEmpty) {
        if (!mounted) return;

        context.go(AppRouter.login);
        return;
      }

      // Request profile
      final response = await http.get(
        Uri.parse(profileEndpoint),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print(
        'PROFILE STATUS: ${response.statusCode}',
      );

      print(
        'PROFILE RESPONSE: ${response.body}',
      );

      final data =
          jsonDecode(response.body);

      // ========================================================
      // BERHASIL
      // ========================================================

      if (response.statusCode == 200 &&
          data['status'] == true) {
        if (data['data'] == null) {
          throw Exception(
            'Data profile tidak ditemukan.',
          );
        }

        final profileData =
            Map<String, dynamic>.from(
          data['data'],
        );

        final photo =
            profileData['photo']?.toString();

        if (!mounted) return;

        setState(() {
          profile = profileData;

          if (photo != null &&
              photo.isNotEmpty) {
            profileImageFuture =
                fetchProfileImage(photo);
          } else {
            profileImageFuture = null;
          }

          isLoading = false;
        });

        // Simpan data profile terbaru
        await prefs.setString(
          'user',
          jsonEncode(profileData),
        );

        return;
      }

      // ========================================================
      // TOKEN EXPIRED / UNAUTHORIZED
      // ========================================================

      if (response.statusCode == 401) {
        await prefs.remove('token');
        await prefs.remove('user');
        await prefs.remove('email');

        if (!mounted) return;

        context.go(AppRouter.login);
        return;
      }

      // ========================================================
      // ERROR
      // ========================================================

      throw Exception(
        data['message'] ??
            'Gagal mengambil data profile.',
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
          ),
          backgroundColor: const Color.fromARGB(255, 54, 244, 244),
          behavior:
              SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  // ============================================================
  // GET FOTO PROFILE
  // ============================================================

  Future<Uint8List?> fetchProfileImage(
    String fileName,
  ) async {
    try {
      final prefs =
          await SharedPreferences.getInstance();

      final token =
          prefs.getString('token') ?? '';

      final response = await http.get(
        Uri.parse(
          '$imageEndpoint/$fileName',
        ),
        headers: {
          'Authorization':
              'Bearer $token',
          'Accept':
              'application/json',
        },
      );

      if (response.statusCode == 200 &&
          response.bodyBytes.isNotEmpty) {
        return response.bodyBytes;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> logout() async {
    final result =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20),
          ),

          title: const Row(
            children: [
              Icon(
                Icons.logout_rounded,
                color: Color.fromARGB(255, 104, 209, 217),
              ),
              SizedBox(width: 10),
              Text(
                'Konfirmasi Logout',
                style: TextStyle(
                  fontWeight:
                      FontWeight.w800,
                  color: Color.fromARGB(255, 52, 63, 63),
                ),
              ),
            ],
          ),

          content: const Text(
            'Apakah Anda yakin ingin keluar dari akun?',
            style: TextStyle(
              color: Color.fromARGB(255, 125, 141, 142),
            ),
          ),

          actions: [
            // BATAL
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Batal',
                style: TextStyle(
                  color: Color.fromARGB(255, 125, 141, 142),
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),

            // KELUAR
            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    const Color.fromARGB(255, 104, 213, 217),
                foregroundColor:
                    Colors.white,
                elevation: 0,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                ),
              ),
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'Keluar',
                style: TextStyle(
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    // Jika pilih Batal
    if (result != true) {
      return;
    }

    try {
      final prefs =
          await SharedPreferences.getInstance();

      // Hapus token
      await prefs.remove('token');

      // Hapus data user
      await prefs.remove('user');

      // Hapus email
      await prefs.remove('email');

      if (!mounted) return;

      // ========================================================
      // LANGSUNG KE LOGIN
      // ========================================================

      context.go(AppRouter.login);
    } catch (e) {
      if (!mounted) return;

      context.go(AppRouter.login);
    }
  }

  // ============================================================
  // REFRESH PROFILE
  // ============================================================

  Future<void> handleRefresh() async {
    await getProfile();
  }

  // ============================================================
  // BARIS DATA PROFILE
  // ============================================================

  Widget infoRow(
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        vertical: 12,
      ),

      decoration:
          const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: borderColor,
            width: 0.8,
          ),
        ),
      ),

      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,

            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 104, 217, 211)
                  .withOpacity(0.09),
              borderRadius:
                  BorderRadius.circular(11),
            ),

            child: Icon(
              icon,
              size: 19,
              color: const Color.fromARGB(255, 104, 209, 217),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style:
                      const TextStyle(
                    fontSize: 11,
                    color:
                        Color.fromARGB(255, 125, 142, 141),
                    fontWeight:
                        FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  value,
                  style:
                      const TextStyle(
                    fontSize: 14,
                    color:
                        Color.fromARGB(255, 52, 63, 62),
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PROFILE CARD
  // ============================================================

  Widget profileCard() {
    if (profile == null) {
      return const Center(
        child: Text(
          'Data profile tidak ditemukan.',
        ),
      );
    }

    final name =
        profile!['name']?.toString() ?? '';

    final username =
        profile!['username']?.toString() ??
            '-';

    final email =
        profile!['email']?.toString() ?? '-';

    final phone =
        profile!['phone']?.toString() ?? '-';

    final gender =
        profile!['gender']?.toString() ?? '-';

    final birthPlace =
        profile!['birth_place']
                ?.toString() ??
            '-';

    final birthDate =
        profile!['birth_date']
                ?.toString() ??
            '-';

    final photo =
        profile!['photo']?.toString();

    return Column(
      children: [
        // ======================================================
        // PROFILE HEADER
        // ======================================================

        Container(
          width: double.infinity,

          padding:
              const EdgeInsets.fromLTRB(
            20,
            26,
            20,
            25,
          ),

          decoration: BoxDecoration(
            gradient:
                const LinearGradient(
              colors: [
                Color.fromARGB(255, 104, 204, 217),
                Color.fromARGB(255, 138, 230, 233),
              ],
              begin:
                  Alignment.topLeft,
              end:
                  Alignment.bottomRight,
            ),

            borderRadius:
                BorderRadius.circular(24),

            boxShadow: [
              BoxShadow(
                color: const Color.fromARGB(255, 104, 204, 217)
                    .withOpacity(0.22),
                blurRadius: 20,
                offset:
                    const Offset(0, 8),
              ),
            ],
          ),

          child: Column(
            children: [
              // FOTO
              Container(
                padding:
                    const EdgeInsets.all(4),

                decoration:
                    BoxDecoration(
                  shape:
                      BoxShape.circle,
                  color:
                      Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withOpacity(
                        0.10,
                      ),
                      blurRadius: 12,
                    ),
                  ],
                ),

                child: CircleAvatar(
                  radius: 47,

                  backgroundColor:
                      const Color(
                    0xFFFFEEEE,
                  ),

                  child:
                      photo != null &&
                              photo.isNotEmpty
                          ? FutureBuilder<
                              Uint8List?>(
                              future:
                                  profileImageFuture,

                              builder:
                                  (
                                context,
                                snapshot,
                              ) {
                                if (snapshot
                                        .connectionState ==
                                    ConnectionState
                                        .waiting) {
                                  return const SizedBox(
                                    width: 25,
                                    height: 25,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth:
                                          2,
                                      color:
                                          Color.fromARGB(255, 104, 209, 217),
                                    ),
                                  );
                                }

                                if (snapshot
                                        .hasData &&
                                    snapshot.data !=
                                        null) {
                                  return ClipOval(
                                    child:
                                        Image.memory(
                                      snapshot.data!,
                                      width:
                                          94,
                                      height:
                                          94,
                                      fit: BoxFit
                                          .cover,
                                    ),
                                  );
                                }

                                return const Icon(
                                  Icons
                                      .person_rounded,
                                  size: 48,
                                  color:
                                      Color.fromARGB(255, 104, 209, 217),
                                );
                              },
                            )
                          : const Icon(
                              Icons
                                  .person_rounded,
                              size: 48,
                              color:
                                  Color.fromARGB(255, 104, 204, 217),
                            ),
                ),
              ),

              const SizedBox(height: 15),

              // NAMA
              Text(
                name,
                textAlign:
                    TextAlign.center,
                style:
                    const TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),

              const SizedBox(height: 5),

              // USERNAME
              Container(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),

                decoration:
                    BoxDecoration(
                  color: Colors.white
                      .withOpacity(
                    0.18,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),
                ),

                child: Text(
                  '@$username',
                  style:
                      const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // ======================================================
        // DATA PROFILE
        // ======================================================

        Container(
          width: double.infinity,

          padding:
              const EdgeInsets.all(18),

          decoration:
              cardDecoration(),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              const Row(
                children: [
                  Icon(
                    Icons
                        .account_circle_outlined,
                    color:
                        Color.fromARGB(255, 104, 217, 211),
                    size: 22,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Informasi Profil',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight:
                          FontWeight.w800,
                      color:
                          Color.fromARGB(255, 52, 61, 63),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              infoRow(
                'Username',
                username,
                Icons
                    .person_outline_rounded,
              ),

              infoRow(
                'Email',
                email,
                Icons
                    .email_outlined,
              ),

              infoRow(
                'Nomor HP',
                phone,
                Icons
                    .phone_outlined,
              ),

              infoRow(
                'Jenis Kelamin',
                gender,
                Icons.wc_outlined,
              ),

              infoRow(
                'Tempat Lahir',
                birthPlace,
                Icons
                    .location_on_outlined,
              ),

              infoRow(
                'Tanggal Lahir',
                birthDate,
                Icons
                    .calendar_today_outlined,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ACTION CARD
  // ============================================================

  Widget actionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),

      decoration:
          cardDecoration(),

      child: Material(
        color: Colors.transparent,

        child: InkWell(
          borderRadius:
              BorderRadius.circular(18),

          onTap: onTap,

          child: Padding(
            padding:
                const EdgeInsets.all(15),

            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,

                  decoration:
                      BoxDecoration(
                    color: (isLogout
                            ? const Color.fromARGB(255, 54, 244, 219)
                            : const Color.fromARGB(255, 104, 213, 217))
                        .withOpacity(
                      0.09,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                  ),

                  child: Icon(
                    icon,
                    color: isLogout
                        ? const Color.fromARGB(255, 54, 216, 244)
                        : const Color.fromARGB(255, 104, 217, 217),
                    size: 22,
                  ),
                ),

                const SizedBox(width: 13),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              FontWeight.w800,
                          color: isLogout
                              ? const Color.fromARGB(255, 54, 244, 212)
                              : textPrimary,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        subtitle,
                        style:
                            const TextStyle(
                          fontSize: 12,
                          color:
                              textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                Icon(
                  Icons
                      .arrow_forward_ios_rounded,
                  size: 16,
                  color: isLogout
                      ? const Color.fromARGB(255, 54, 244, 235)
                          .withOpacity(0.7)
                      : textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CARD DECORATION
  // ============================================================

  static BoxDecoration cardDecoration() {
    return BoxDecoration(
      color: Colors.white,

      borderRadius:
          BorderRadius.circular(20),

      boxShadow: [
        BoxShadow(
          color: const Color.fromARGB(255, 104, 217, 211)
              .withOpacity(0.07),
          blurRadius: 18,
          offset:
              const Offset(0, 7),
        ),
      ],
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          backgroundColor,

      appBar: AppBar(
        backgroundColor:
            backgroundColor,

        elevation: 0,

        scrolledUnderElevation: 0,

        title: const Text(
          'Profile',
          style: TextStyle(
            color: Color.fromARGB(255, 52, 63, 62),
            fontSize: 20,
            fontWeight:
                FontWeight.w800,
          ),
        ),

        centerTitle: true,
      ),

      body: SafeArea(
        child: RefreshIndicator(
          color: const Color.fromARGB(255, 104, 217, 217),

          backgroundColor:
              Colors.white,

          onRefresh: handleRefresh,

          child:
              SingleChildScrollView(
            physics:
                const AlwaysScrollableScrollPhysics(),

            padding:
                const EdgeInsets.fromLTRB(
              16,
              8,
              16,
              30,
            ),

            child: Column(
              children: [
                // PROFILE
                if (isLoading)
                  const Padding(
                    padding:
                        EdgeInsets.all(50),

                    child:
                        CircularProgressIndicator(
                      color:
                          Color.fromARGB(255, 104, 209, 217),
                    ),
                  )
                else
                  profileCard(),

                const SizedBox(height: 20),

                // ==================================================
                // MENU
                // ==================================================

                const Align(
                  alignment:
                      Alignment.centerLeft,

                  child: Text(
                    'Pengaturan Akun',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight:
                          FontWeight.w800,
                      color:
                          Color.fromARGB(255, 52, 63, 63),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // EDIT PROFILE
                actionCard(
                  icon:
                      Icons.edit_rounded,

                  title:
                      'Edit Profil',

                  subtitle:
                      'Perbarui data diri Anda',

                  onTap: () async {
                    final result =
                        await context.push(
                      AppRouter.editProfile,
                      extra: profile,
                    );

                    // Setelah kembali
                    // dari Edit Profile
                    if (result == true) {
                      await getProfile();
                    }
                  },
                ),

                // LOGOUT
                actionCard(
                  icon:
                      Icons.logout_rounded,

                  title:
                      'Keluar',

                  subtitle:
                      'Logout dari akun',

                  isLogout: true,

                  onTap: logout,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}