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

  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;
  late TextEditingController birthPlaceController;
  late TextEditingController birthDateController;

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

  // ============================================================
  // WARNA TEMA
  // ============================================================

  static const Color primaryColor = Color.fromARGB(255, 104, 209, 217);
  static const Color primaryDark = Color.fromARGB(255, 83, 181, 198);
  static const Color backgroundColor = Color.fromARGB(255, 248, 254, 255);
  static const Color textPrimary = Color.fromARGB(255, 52, 63, 61);
  static const Color textSecondary = Color.fromARGB(255, 125, 141, 142);
  static const Color borderColor = Color.fromARGB(255, 218, 234, 232);

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    final profile = widget.profile ?? {};

    nameController = TextEditingController(
      text: profile['name']?.toString() ?? '',
    );

    emailController = TextEditingController(
      text: profile['email']?.toString() ?? '',
    );

    phoneController = TextEditingController(
      text: profile['phone']?.toString() ?? '',
    );

    birthPlaceController = TextEditingController(
      text: profile['birth_place']?.toString() ?? '',
    );

    // ==========================================================
    // JENIS KELAMIN
    // ==========================================================

    if (profile['gender'] != null) {
      final g = profile['gender'].toString().toLowerCase();

      if (g.startsWith('l')) {
        gender = 'L';
      } else if (g.startsWith('p')) {
        gender = 'P';
      } else if (g == 'l') {
        gender = 'L';
      } else if (g == 'p') {
        gender = 'P';
      }
    }

    // ==========================================================
    // TANGGAL LAHIR
    // ==========================================================

    String displayBirthDate = '';

    final rawDate = profile['birth_date']?.toString();

    if (rawDate != null && rawDate.isNotEmpty) {
      try {
        DateTime? parsedDate;

        final parts = rawDate.split('-');

        if (parts.length == 3) {
          // YYYY-MM-DD
          if (parts[0].length == 4) {
            parsedDate = DateTime.parse(rawDate);
          }

          // DD-MM-YYYY
          else {
            final day = int.parse(parts[0]);

            final month = int.parse(parts[1]);

            final year = int.parse(parts[2]);

            parsedDate = DateTime(
              year,
              month,
              day,
            );
          }
        }

        if (parsedDate != null) {
          final day = parsedDate.day
              .toString()
              .padLeft(2, '0');

          final month = parsedDate.month
              .toString()
              .padLeft(2, '0');

          final year = parsedDate.year.toString();

          displayBirthDate =
              '$day-$month-$year';

          apiBirthDate =
              '$year-$month-$day';
        } else {
          displayBirthDate = rawDate;
          apiBirthDate = rawDate;
        }
      } catch (_) {
        displayBirthDate = rawDate;
        apiBirthDate = rawDate;
      }
    }

    birthDateController = TextEditingController(
      text: displayBirthDate,
    );

    // ==========================================================
    // FOTO LAMA
    // ==========================================================

    final oldPhoto = profile['photo']?.toString();

    if (oldPhoto != null && oldPhoto.isNotEmpty) {
      oldProfileImageFuture =
          fetchProfileImage(oldPhoto);
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    birthPlaceController.dispose();
    birthDateController.dispose();

    super.dispose();
  }

  // ============================================================
  // JSON
  // ============================================================

  dynamic safeJsonDecode(
    String body,
  ) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // PILIH FOTO
  // ============================================================

  Future<void> pickImage() async {
    try {
      final picker = ImagePicker();

      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        return;
      }

      final bytes = await pickedFile.readAsBytes();

      if (!mounted) return;

      setState(() {
        selectedImage = pickedFile;

        selectedImageBytes = bytes;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'Gagal mengambil gambar dari galeri.',
          ),
          backgroundColor: Color.fromARGB(255, 54, 244, 228),
        ),
      );
    }
  }

  // ============================================================
  // FOTO LAMA
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
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
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
  // PILIH TANGGAL LAHIR
  // ============================================================

  Future<void> selectBirthDate() async {
    DateTime initialDate =
        DateTime.now().subtract(
      const Duration(
        days: 365 * 10,
      ),
    );

    if (apiBirthDate != null &&
        apiBirthDate!.isNotEmpty) {
      try {
        initialDate = DateTime.parse(
          apiBirthDate!,
        );
      } catch (_) {}
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now().subtract(
        const Duration(
          days: 1,
        ),
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryColor,
              onPrimary: Color.fromARGB(255, 255, 255, 255),
              surface: Color.fromARGB(255, 255, 255, 255),
              onSurface: textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) {
      return;
    }

    final day = picked.day
        .toString()
        .padLeft(2, '0');

    final month = picked.month
        .toString()
        .padLeft(2, '0');

    final year = picked.year.toString();

    setState(() {
      birthDateController.text =
          '$day-$month-$year';

      apiBirthDate =
          '$year-$month-$day';
    });
  }

  // ============================================================
  // SIMPAN PROFILE
  // ============================================================

  Future<void> saveProfile() async {
    // Validasi
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (gender == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'Silakan pilih jenis kelamin.',
          ),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final prefs =
          await SharedPreferences.getInstance();

      final token =
          prefs.getString('token');

      // ========================================================
      // TOKEN TIDAK ADA
      // ========================================================

      if (token == null || token.isEmpty) {
        await prefs.remove('user');
        await prefs.remove('email');

        if (!mounted) return;

        context.go(
          AppRouter.login,
        );

        return;
      }

      // ========================================================
      // MULTIPART REQUEST
      // ========================================================

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(
          profileUpdateEndpoint,
        ),
      );

      request.headers['Accept'] =
          'application/json';

      request.headers['Authorization'] =
          'Bearer $token';

      // ========================================================
      // DATA
      // ========================================================

      request.fields['name'] =
          nameController.text.trim();

      request.fields['email'] =
          emailController.text.trim();

      request.fields['phone'] =
          phoneController.text.trim();

      request.fields['gender'] =
          gender!;

      request.fields['birth_place'] =
          birthPlaceController.text.trim();

      if (apiBirthDate != null &&
          apiBirthDate!.isNotEmpty) {
        request.fields['birth_date'] =
            apiBirthDate!;
      }

      // ========================================================
      // FOTO
      // ========================================================

      if (selectedImage != null &&
          selectedImageBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'photo',
            selectedImageBytes!,
            filename: selectedImage!.name,
          ),
        );
      }

      // ========================================================
      // KIRIM
      // ========================================================

      final streamedResponse =
          await request.send().timeout(
        const Duration(
          seconds: 30,
        ),
      );

      final response =
          await http.Response.fromStream(
        streamedResponse,
      );

      final data = safeJsonDecode(
        response.body,
      );

      print(
        'UPDATE PROFILE STATUS: ${response.statusCode}',
      );

      print(
        'UPDATE PROFILE RESPONSE: ${response.body}',
      );

      // ========================================================
      // BERHASIL
      // ========================================================

      if (response.statusCode == 200) {
        if (data != null &&
            data['status'] == true) {
          // Simpan data terbaru
          if (data['data'] != null) {
            await prefs.setString(
              'user',
              jsonEncode(
                data['data'],
              ),
            );
          }

          if (!mounted) return;

          ScaffoldMessenger.of(
            context,
          ).showSnackBar(
            const SnackBar(
              content: Text(
                'Profil berhasil diperbarui.',
              ),
              backgroundColor: Colors.green,
            ),
          );

          // ====================================================
          // KEMBALI KE PROFILE
          // ====================================================

          context.pop(true);

          return;
        }

        throw Exception(
          data?['message'] ??
              'Gagal memperbarui profil.',
        );
      }

      // ========================================================
      // VALIDASI 422
      // ========================================================

      if (response.statusCode == 422) {
        String validationErrors = '';

        if (data != null &&
            data['errors'] != null &&
            data['errors'] is Map) {
          final errorsMap =
              data['errors'] as Map;

          for (final key in errorsMap.keys) {
            final messages = errorsMap[key];

            if (messages is List) {
              for (final msg in messages) {
                validationErrors +=
                    '$msg\n';
              }
            }
          }
        }

        if (validationErrors.isEmpty) {
          validationErrors =
              data?['message'] ??
                  'Validasi gagal.';
        }

        throw Exception(
          validationErrors.trim(),
        );
      }

      // ========================================================
      // UNAUTHORIZED
      // ========================================================

      if (response.statusCode == 401) {
        await prefs.remove('token');

        await prefs.remove('user');

        await prefs.remove('email');

        if (!mounted) return;

        context.go(
          AppRouter.login,
        );

        return;
      }

      // ========================================================
      // ERROR LAIN
      // ========================================================

      throw Exception(
        'Gagal memperbarui profil. '
        'Error Code: ${response.statusCode}',
      );
    } catch (e) {
      if (!mounted) return;

      String message =
          e.toString().replaceFirst(
        'Exception: ',
        '',
      );

      if (message
              .toLowerCase()
              .contains('socket') ||
          message
              .toLowerCase()
              .contains(
                'failed to connect',
              ) ||
          message
              .toLowerCase()
              .contains(
                'clientexception',
              )) {
        message =
            'Tidak dapat terhubung ke server. '
            'Periksa koneksi internet Anda.';
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            message,
          ),
          backgroundColor: const Color.fromARGB(255, 54, 244, 219),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // CARD DECORATION
  // ============================================================

  static BoxDecoration cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: primaryColor.withOpacity(0.08),
          blurRadius: 18,
          offset: const Offset(0, 7),
        ),
      ],
    );
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration inputDecoration({
    required String hintText,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: textSecondary,
        fontSize: 14,
      ),
      prefixIcon: Icon(
        icon,
        color: primaryColor,
      ),
      filled: true,
      fillColor: const Color(0xFFFFFAFA),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 15,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(
          color: borderColor,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(
          color: borderColor,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(
          color: primaryColor,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(
          color: Color.fromARGB(255, 54, 244, 228),
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(
          color: Color.fromARGB(255, 54, 231, 244),
          width: 1.5,
        ),
      ),
    );
  }

  // ============================================================
  // LABEL FORM
  // ============================================================

  Widget formLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final oldPhoto =
        widget.profile?['photo']?.toString();

    return Scaffold(
      backgroundColor: backgroundColor,

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: textPrimary,
          ),
          onPressed: () {
            context.pop();
          },
        ),

        title: const Text(
          'Edit Profil',
          style: TextStyle(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),

        centerTitle: true,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            16,
            8,
            16,
            30,
          ),

          child: Form(
            key: _formKey,

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,

              children: [
                // ==================================================
                // HEADER
                // ==================================================

                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 20,
                  ),

                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color.fromARGB(255, 104, 217, 217),
                        Color.fromARGB(255, 138, 233, 233),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius:
                        BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor
                            .withOpacity(0.20),
                        blurRadius: 18,
                        offset:
                            const Offset(0, 8),
                      ),
                    ],
                  ),

                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,

                        decoration:
                            BoxDecoration(
                          color: Colors.white
                              .withOpacity(0.20),
                          borderRadius:
                              BorderRadius.circular(
                            15,
                          ),
                        ),

                        child: const Icon(
                          Icons.edit_rounded,
                          color: Colors.white,
                          size: 25,
                        ),
                      ),

                      const SizedBox(width: 14),

                      const Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Edit Profil',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight:
                                    FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Perbarui informasi akun Anda',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // ==================================================
                // FOTO
                // ==================================================

                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 22,
                    horizontal: 18,
                  ),

                  decoration:
                      cardDecoration(),

                  child: Column(
                    children: [
                      Stack(
                        alignment:
                            Alignment.bottomRight,
                        children: [
                          Container(
                            padding:
                                const EdgeInsets.all(
                              4,
                            ),

                            decoration:
                                BoxDecoration(
                              shape:
                                  BoxShape.circle,
                              border: Border.all(
                                color:
                                    primaryColor,
                                width: 2,
                              ),
                            ),

                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor:
                                  const Color(
                                0xFFFFEEEE,
                              ),

                              backgroundImage:
                                  selectedImageBytes !=
                                          null
                                      ? MemoryImage(
                                          selectedImageBytes!,
                                        )
                                      : null,

                              child:
                                  selectedImageBytes ==
                                          null
                                      ? (
                                          oldPhoto !=
                                                      null &&
                                                  oldPhoto
                                                      .isNotEmpty
                                              ? FutureBuilder<
                                                  Uint8List?>(
                                                  future:
                                                      oldProfileImageFuture,
                                                  builder:
                                                      (
                                                    context,
                                                    snapshot,
                                                  ) {
                                                    if (snapshot.connectionState ==
                                                        ConnectionState.waiting) {
                                                      return const CircularProgressIndicator(
                                                        strokeWidth:
                                                            2,
                                                        color:
                                                            primaryColor,
                                                      );
                                                    }

                                                    if (snapshot.hasData &&
                                                        snapshot.data !=
                                                            null) {
                                                      return ClipOval(
                                                        child:
                                                            Image.memory(
                                                          snapshot.data!,
                                                          width:
                                                              100,
                                                          height:
                                                              100,
                                                          fit:
                                                              BoxFit.cover,
                                                        ),
                                                      );
                                                    }

                                                    return const Icon(
                                                      Icons.person_rounded,
                                                      size:
                                                          50,
                                                      color:
                                                          primaryColor,
                                                    );
                                                  },
                                                )
                                              : const Icon(
                                                  Icons.person_rounded,
                                                  size:
                                                      50,
                                                  color:
                                                      primaryColor,
                                                )
                                        )
                                      : null,
                            ),
                          ),

                          Container(
                            width: 34,
                            height: 34,

                            decoration:
                                BoxDecoration(
                              color:
                                  primaryColor,
                              shape:
                                  BoxShape.circle,
                              border: Border.all(
                                color:
                                    Colors.white,
                                width: 2,
                              ),
                            ),

                            child: const Icon(
                              Icons.camera_alt_rounded,
                              color:
                                  Colors.white,
                              size: 17,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 13),

                      TextButton(
                        onPressed:
                            isLoading
                                ? null
                                : pickImage,

                        style:
                            TextButton.styleFrom(
                          foregroundColor:
                              primaryColor,
                        ),

                        child: const Text(
                          'Ubah Foto Profil',
                          style: TextStyle(
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // ==================================================
                // FORM CARD
                // ==================================================

                Container(
                  padding:
                      const EdgeInsets.all(20),

                  decoration:
                      cardDecoration(),

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [
                      const Text(
                        'Informasi Pribadi',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight:
                              FontWeight.w800,
                          color:
                              textPrimary,
                        ),
                      ),

                      const SizedBox(height: 4),

                      const Text(
                        'Lengkapi data diri Anda dengan benar.',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              textSecondary,
                        ),
                      ),

                      const SizedBox(height: 22),

                      // ==================================================
                      // NAMA
                      // ==================================================

                      formLabel('Nama'),

                      const SizedBox(height: 7),

                      TextFormField(
                        controller:
                            nameController,

                        textInputAction:
                            TextInputAction.next,

                        decoration:
                            inputDecoration(
                          hintText:
                              'Nama Lengkap Anda',
                          icon:
                              Icons.person_outline_rounded,
                        ),

                        validator: (value) {
                          if (value == null ||
                              value
                                  .trim()
                                  .isEmpty) {
                            return 'Nama wajib diisi';
                          }

                          if (value
                                  .trim()
                                  .length >
                              255) {
                            return 'Nama maksimal 255 karakter';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 17),

                      // ==================================================
                      // EMAIL
                      // ==================================================

                      formLabel('Email'),

                      const SizedBox(height: 7),

                      TextFormField(
                        controller:
                            emailController,

                        keyboardType:
                            TextInputType.emailAddress,

                        textInputAction:
                            TextInputAction.next,

                        decoration:
                            inputDecoration(
                          hintText:
                              'alamat@email.com',
                          icon:
                              Icons.email_outlined,
                        ),

                        validator: (value) {
                          if (value == null ||
                              value
                                  .trim()
                                  .isEmpty) {
                            return 'Email wajib diisi';
                          }

                          if (!value.contains('@')) {
                            return 'Format email tidak valid';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 17),

                      // ==================================================
                      // NOMOR HP
                      // ==================================================

                      formLabel('Nomor HP'),

                      const SizedBox(height: 7),

                      TextFormField(
                        controller:
                            phoneController,

                        keyboardType:
                            TextInputType.phone,

                        textInputAction:
                            TextInputAction.next,

                        decoration:
                            inputDecoration(
                          hintText:
                              '08xxxxxxxxxx',
                          icon:
                              Icons.phone_outlined,
                        ),

                        validator: (value) {
                          if (value == null ||
                              value
                                  .trim()
                                  .isEmpty) {
                            return 'Nomor HP wajib diisi';
                          }

                          final number =
                              value.trim();

                          if (number.length < 10) {
                            return 'Nomor HP minimal 10 digit';
                          }

                          if (number.length > 15) {
                            return 'Nomor HP maksimal 15 digit';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 17),

                      // ==================================================
                      // JENIS KELAMIN
                      // ==================================================

                      formLabel('Jenis Kelamin'),

                      const SizedBox(height: 7),

                      DropdownButtonFormField<String>(
                        value: gender,

                        decoration:
                            inputDecoration(
                          hintText:
                              'Pilih jenis kelamin',
                          icon:
                              Icons.wc_outlined,
                        ),

                        items: const [
                          DropdownMenuItem(
                            value: 'L',
                            child:
                                Text('Laki-laki'),
                          ),
                          DropdownMenuItem(
                            value: 'P',
                            child:
                                Text('Perempuan'),
                          ),
                        ],

                        onChanged:
                            isLoading
                                ? null
                                : (value) {
                                    setState(
                                      () {
                                        gender =
                                            value;
                                      },
                                    );
                                  },

                        validator: (value) {
                          if (value == null) {
                            return 'Jenis kelamin wajib dipilih';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 17),

                      // ==================================================
                      // TEMPAT LAHIR
                      // ==================================================

                      formLabel('Tempat Lahir'),

                      const SizedBox(height: 7),

                      TextFormField(
                        controller:
                            birthPlaceController,

                        textInputAction:
                            TextInputAction.next,

                        decoration:
                            inputDecoration(
                          hintText:
                              'Kota tempat Anda lahir',
                          icon: Icons
                              .location_on_outlined,
                        ),

                        validator: (value) {
                          if (value != null &&
                              value
                                  .trim()
                                  .length >
                                  100) {
                            return 'Tempat lahir maksimal 100 karakter';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 17),

                      // ==================================================
                      // TANGGAL LAHIR
                      // ==================================================

                      formLabel('Tanggal Lahir'),

                      const SizedBox(height: 7),

                      TextFormField(
                        controller:
                            birthDateController,

                        readOnly: true,

                        onTap:
                            isLoading
                                ? null
                                : selectBirthDate,

                        decoration:
                            inputDecoration(
                          hintText:
                              'Pilih tanggal lahir Anda',
                          icon: Icons
                              .calendar_today_outlined,
                        ),
                        validator: (value) {
                          if (value == null ||
                              value.isEmpty) {
                            return 'Tanggal lahir wajib dipilih';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 27),

                      // ==================================================
                      // SIMPAN
                      // ==================================================

                      SizedBox(
                        height: 52,
                        width: double.infinity,

                        child:
                            ElevatedButton(
                          onPressed:
                              isLoading
                                  ? null
                                  : saveProfile,

                          style:
                              ElevatedButton
                                  .styleFrom(
                            backgroundColor:
                                primaryColor,
                            disabledBackgroundColor:
                                primaryColor
                                    .withOpacity(
                              0.5,
                            ),
                            foregroundColor:
                                Colors.white,
                            elevation: 3,
                            shadowColor:
                                primaryColor
                                    .withOpacity(
                              0.25,
                            ),
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                14,
                              ),
                            ),
                          ),

                          child: isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth:
                                        2,
                                    color:
                                        Colors.white,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment
                                          .center,
                                  children: [
                                    Icon(
                                      Icons
                                          .save_rounded,
                                      size: 20,
                                    ),
                                    SizedBox(
                                      width: 9,
                                    ),
                                    Text(
                                      'SIMPAN PERUBAHAN',
                                      style:
                                          TextStyle(
                                        fontSize:
                                            15,
                                        fontWeight:
                                            FontWeight
                                                .w800,
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