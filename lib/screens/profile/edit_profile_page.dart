
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

import '../../routes/app_router.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic>? profile;

  const EditProfilePage({
    super.key,
    this.profile,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController nameController;
  late final TextEditingController emailController;
  late final TextEditingController phoneController;
  late final TextEditingController birthPlaceController;
  late final TextEditingController birthDateController;

  String? gender;
  String? apiBirthDate;

  XFile? selectedImage;
  Uint8List? selectedImageBytes;
  Future<Uint8List?>? oldProfileImageFuture;

  bool isLoading = false;

  static const String baseUrl =
      'https://sijala.biz.id/api/v1';

  static const String profileUpdateEndpoint =
      '$baseUrl/profile/update';

  static const String imageEndpoint =
      'https://sijala.biz.id/api/image';

  static const Color primaryColor = Color(0xFF20A99A);
  static const Color backgroundColor = Color(0xFFF5FAFA);
  static const Color textPrimary = Color(0xFF263238);
  static const Color textSecondary = Color(0xFF7B8A8B);
  static const Color borderColor = Color(0xFFD9E8E7);

  @override
  void initState() {
    super.initState();

    final data = widget.profile ?? {};

    nameController = TextEditingController(
      text: data['name']?.toString() ?? '',
    );

    // Email hanya ditampilkan. Tidak diubah oleh halaman ini.
    emailController = TextEditingController(
      text: data['email']?.toString() ?? '',
    );

    phoneController = TextEditingController(
      text: data['phone']?.toString() ?? '',
    );

    birthPlaceController = TextEditingController(
      text: data['birth_place']?.toString() ?? '',
    );

    final rawGender = data['gender']?.toString().toLowerCase();

    if (rawGender == 'l' || rawGender == 'laki-laki') {
      gender = 'L';
    } else if (rawGender == 'p' ||
        rawGender == 'perempuan') {
      gender = 'P';
    }

    final rawDate = data['birth_date']?.toString();

    if (rawDate != null && rawDate.isNotEmpty) {
      try {
        DateTime? date;

        final parts = rawDate.split('-');

        if (parts.length == 3) {
          if (parts[0].length == 4) {
            date = DateTime.parse(rawDate);
          } else {
            date = DateTime(
              int.parse(parts[2]),
              int.parse(parts[1]),
              int.parse(parts[0]),
            );
          }
        }

        if (date != null) {
          birthDateController = TextEditingController(
            text:
                '${date.day.toString().padLeft(2, '0')}-'
                '${date.month.toString().padLeft(2, '0')}-'
                '${date.year}',
          );

          apiBirthDate =
              '${date.year.toString().padLeft(4, '0')}-'
              '${date.month.toString().padLeft(2, '0')}-'
              '${date.day.toString().padLeft(2, '0')}';
        } else {
          birthDateController = TextEditingController(
            text: rawDate,
          );
          apiBirthDate = rawDate;
        }
      } catch (_) {
        birthDateController = TextEditingController(
          text: rawDate,
        );
        apiBirthDate = rawDate;
      }
    } else {
      birthDateController = TextEditingController();
    }

    final oldPhoto = data['photo']?.toString();

    if (oldPhoto != null && oldPhoto.isNotEmpty) {
      oldProfileImageFuture = fetchProfileImage(oldPhoto);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    birthPlaceController.dispose();
    birthDateController.dispose();
    super.dispose();
  }

  dynamic safeJsonDecode(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  void showMessage(
    String message, {
    Color color = primaryColor,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // =========================================================
  // PILIH FOTO
  // =========================================================

  Future<void> pickImage() async {
    try {
      final picker = ImagePicker();

      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );

      if (image == null) return;

      final bytes = await image.readAsBytes();

      if (!mounted) return;

      setState(() {
        selectedImage = image;
        selectedImageBytes = bytes;
      });
    } catch (_) {
      showMessage(
        'Gagal mengambil gambar dari galeri.',
        color: Colors.redAccent,
      );
    }
  }

  // =========================================================
  // FOTO PROFIL LAMA
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
  // PILIH TANGGAL LAHIR
  // =========================================================

  Future<void> selectBirthDate() async {
    DateTime initialDate = DateTime(2000, 1, 1);

    if (apiBirthDate != null) {
      try {
        initialDate = DateTime.parse(apiBirthDate!);
      } catch (_) {}
    }

    final now = DateTime.now();

    if (initialDate.isAfter(now)) {
      initialDate = DateTime(now.year - 10, now.month, now.day);
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    setState(() {
      birthDateController.text =
          '${picked.day.toString().padLeft(2, '0')}-'
          '${picked.month.toString().padLeft(2, '0')}-'
          '${picked.year}';

      apiBirthDate =
          '${picked.year.toString().padLeft(4, '0')}-'
          '${picked.month.toString().padLeft(2, '0')}-'
          '${picked.day.toString().padLeft(2, '0')}';
    });
  }

  // =========================================================
  // SIMPAN PROFIL
  // =========================================================

  Future<void> saveProfile() async {
    if (isLoading) return;

    if (!_formKey.currentState!.validate()) return;

    if (gender == null) {
      showMessage(
        'Silakan pilih jenis kelamin.',
        color: Colors.redAccent,
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        await prefs.remove('user');

        if (mounted) {
          context.go(AppRouter.login);
        }
        return;
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(profileUpdateEndpoint),
      );

      request.headers['Accept'] = 'application/json';
      request.headers['Authorization'] = 'Bearer $token';

      // Data profil yang dapat diperbarui.
      request.fields['name'] = nameController.text.trim();
      request.fields['phone'] = phoneController.text.trim();
      request.fields['gender'] = gender!;
      request.fields['birth_place'] =
          birthPlaceController.text.trim();

      if (apiBirthDate != null && apiBirthDate!.isNotEmpty) {
        request.fields['birth_date'] = apiBirthDate!;
      }

      // Email sengaja TIDAK dikirim.
      // Dengan demikian form ini tidak meminta perubahan email.

      if (selectedImage != null && selectedImageBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'photo',
            selectedImageBytes!,
            filename: selectedImage!.name,
          ),
        );
      }

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );

      final response = await http.Response.fromStream(
        streamedResponse,
      );

      final data = safeJsonDecode(response.body);

      debugPrint('UPDATE PROFILE STATUS: ${response.statusCode}');
      debugPrint('UPDATE PROFILE RESPONSE: ${response.body}');

      if (response.statusCode == 401) {
        await prefs.remove('token');
        await prefs.remove('user');

        if (mounted) {
          context.go(AppRouter.login);
        }
        return;
      }

      if (response.statusCode == 200 &&
          data is Map &&
          data['status'] == true) {
        // Perbarui cache lokal tanpa mengganti email.
        final cachedUser = Map<String, dynamic>.from(
          widget.profile ?? {},
        );

        if (data['data'] is Map) {
          cachedUser.addAll(
            Map<String, dynamic>.from(data['data'] as Map),
          );
        }

        // Pertahankan email lama di cache.
        if (widget.profile?['email'] != null) {
          cachedUser['email'] = widget.profile!['email'];
        }

        await prefs.setString('user', jsonEncode(cachedUser));

        if (!mounted) return;

        showMessage('Profil berhasil diperbarui.');
        context.pop(true);
        return;
      }

      String message = 'Gagal memperbarui profil.';

      if (data is Map && data['message'] != null) {
        message = data['message'].toString();
      }

      if (response.statusCode == 422 &&
          data is Map &&
          data['errors'] is Map) {
        final errors = data['errors'] as Map;
        final messages = <String>[];

        for (final value in errors.values) {
          if (value is List) {
            messages.addAll(value.map((e) => e.toString()));
          } else {
            messages.add(value.toString());
          }
        }

        if (messages.isNotEmpty) {
          message = messages.join('\n');
        }
      }

      throw Exception(message);
    } catch (e) {
      if (!mounted) return;

      var message = e.toString().replaceFirst('Exception: ', '');

      if (message.toLowerCase().contains('socket') ||
          message.toLowerCase().contains('clientexception') ||
          message.toLowerCase().contains('timed out')) {
        message =
            'Tidak dapat terhubung ke server. Periksa koneksi internet.';
      }

      showMessage(message, color: Colors.redAccent);
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // =========================================================
  // DESAIN FORM
  // =========================================================

  InputDecoration inputDecoration({
    required String hintText,
    required IconData icon,
    bool locked = false,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(
        icon,
        color: locked ? textSecondary : primaryColor,
      ),
      suffixIcon: locked
          ? const Icon(Icons.lock_outline, color: textSecondary)
          : null,
      filled: true,
      fillColor: locked ? const Color(0xFFEDF1F1) : Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 15,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(
          color: primaryColor,
          width: 1.5,
        ),
      ),
    );
  }

  Widget formLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
      ),
    );
  }

  Widget buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    bool readOnly = false,
    bool locked = false,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        formLabel(label),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          onTap: onTap,
          keyboardType: keyboardType,
          validator: validator,
          decoration: inputDecoration(
            hintText: hint,
            icon: icon,
            locked: locked,
          ),
        ),
      ],
    );
  }

  BoxDecoration cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFEDF2F2)),
      boxShadow: [
        BoxShadow(
          color: primaryColor.withOpacity(0.07),
          blurRadius: 16,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final oldPhoto = widget.profile?['photo']?.toString();

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Edit Profil',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: isLoading ? null : () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // HEADER
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF159D91),
                        Color(0xFF55C8B9),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.edit_note_rounded,
                        size: 38,
                        color: Colors.white,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Edit Profil',
                              style: TextStyle(
                                fontSize: 19,
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Perbarui informasi data diri Anda',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // FOTO PROFIL
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: cardDecoration(),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 53,
                        backgroundColor: const Color(0xFFE5F5F2),
                        backgroundImage: selectedImageBytes != null
                            ? MemoryImage(selectedImageBytes!)
                            : null,
                        child: selectedImageBytes != null
                            ? null
                            : oldPhoto != null && oldPhoto.isNotEmpty
                                ? FutureBuilder<Uint8List?>(
                                    future: oldProfileImageFuture,
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData &&
                                          snapshot.data != null) {
                                        return ClipOval(
                                          child: Image.memory(
                                            snapshot.data!,
                                            width: 106,
                                            height: 106,
                                            fit: BoxFit.cover,
                                          ),
                                        );
                                      }

                                      return const Icon(
                                        Icons.person_rounded,
                                        size: 54,
                                        color: primaryColor,
                                      );
                                    },
                                  )
                                : const Icon(
                                    Icons.person_rounded,
                                    size: 54,
                                    color: primaryColor,
                                  ),
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: isLoading ? null : pickImage,
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: const Text('Ubah Foto Profil'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // FORM
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: cardDecoration(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Informasi Pribadi',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 20),

                      buildTextField(
                        label: 'Nama Lengkap',
                        controller: nameController,
                        hint: 'Masukkan nama lengkap',
                        icon: Icons.person_outline,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nama wajib diisi';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 17),

                      // EMAIL TERKUNCI: TIDAK DAPAT DIEDIT
                      buildTextField(
                        label: 'Email Akun',
                        controller: emailController,
                        hint: 'Email akun',
                        icon: Icons.email_outlined,
                        readOnly: true,
                        locked: true,
                      ),

                      const SizedBox(height: 17),

                      buildTextField(
                        label: 'Nomor HP',
                        controller: phoneController,
                        hint: 'Masukkan nomor HP',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nomor HP wajib diisi';
                          }
                          if (value.trim().length < 10 ||
                              value.trim().length > 15) {
                            return 'Nomor HP harus 10–15 karakter';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 17),

                      formLabel('Jenis Kelamin'),
                      DropdownButtonFormField<String>(
                        value: gender,
                        decoration: inputDecoration(
                          hintText: 'Pilih jenis kelamin',
                          icon: Icons.wc_outlined,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'L',
                            child: Text('Laki-laki'),
                          ),
                          DropdownMenuItem(
                            value: 'P',
                            child: Text('Perempuan'),
                          ),
                        ],
                        onChanged: isLoading
                            ? null
                            : (value) {
                                setState(() => gender = value);
                              },
                        validator: (value) {
                          if (value == null) {
                            return 'Pilih jenis kelamin';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 17),

                      buildTextField(
                        label: 'Tempat Lahir',
                        controller: birthPlaceController,
                        hint: 'Masukkan tempat lahir',
                        icon: Icons.location_on_outlined,
                      ),

                      const SizedBox(height: 17),

                      buildTextField(
                        label: 'Tanggal Lahir',
                        controller: birthDateController,
                        hint: 'Pilih tanggal lahir',
                        icon: Icons.calendar_today_outlined,
                        readOnly: true,
                        onTap: isLoading ? null : selectBirthDate,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Tanggal lahir wajib dipilih';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 25),

                      SizedBox(
                        height: 52,
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                primaryColor.withOpacity(0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 23,
                                  height: 23,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.save_rounded),
                                    SizedBox(width: 9),
                                    Text(
                                      'SIMPAN PERUBAHAN',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
