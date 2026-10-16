import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:field_survey_nifaa/screens/auth/login_page.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SurveyFormPage extends StatefulWidget {
  // null  = Tambah
  // tidak null = Edit
  final Map<String, dynamic>? survey;

  const SurveyFormPage({
    super.key,
    this.survey,
  });

  @override
  State<SurveyFormPage> createState() => _SurveyFormPageState();
}

class _SurveyFormPageState extends State<SurveyFormPage> {
  // ============================================================
  // THEME
  // ============================================================

  static const Color primary = Color.fromARGB(255, 104, 217, 208);
  static const Color primaryLight = Color.fromARGB(255, 135, 228, 220);
  static const Color primaryDark = Color.fromARGB(255, 79, 178, 185);

  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);
  static const Color error = Color.fromARGB(255, 68, 213, 239);
  static const Color success = Color(0xFF10B981);

  // ============================================================
  // STATE
  // ============================================================

  final formKey = GlobalKey<FormState>();

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final latitudeController = TextEditingController();
  final longitudeController = TextEditingController();

  int? selectedCategoryId;
  List<Map<String, dynamic>> categories = [];
  bool isLoadingCategories = true;

  XFile? selectedImage;
  Uint8List? selectedImageBytes;
  Uint8List? existingImageBytes;

  bool isSubmitting = false;

  bool get isEdit => widget.survey != null;

  // ============================================================
  // LIFECYCLE
  // ============================================================

  @override
  void initState() {
    super.initState();

    if (isEdit) {
      final s = widget.survey!;

      titleController.text =
          s['title']?.toString() ?? '';

      final description =
          s['description']?.toString() ?? '';

      descriptionController.text =
          description == '-' ? '' : description;

      latitudeController.text =
          s['latitude']?.toString() ?? '';

      longitudeController.text =
          s['longitude']?.toString() ?? '';

      selectedCategoryId =
          int.tryParse(s['category_id']?.toString() ?? '');

      final photoName =
          s['photo']?.toString();

      if (photoName != null &&
          photoName.isNotEmpty &&
          photoName != 'placeholder.jpg') {
        fetchExistingImage(photoName);
      }
    }

    fetchCategories();
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
    super.dispose();
  }

  // ============================================================
  // GET CATEGORY
  // ============================================================

  Future<void> fetchCategories() async {
    try {
      final prefs =
          await SharedPreferences.getInstance();

      final token =
          prefs.getString('token') ?? '';

      final response = await http.get(
        Uri.parse(
          'https://sijala.biz.id/api/v1/categories',
        ),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decoded =
            jsonDecode(response.body);

        if (decoded is Map &&
            decoded['data'] is List) {
          final List rawList =
              decoded['data'];

          if (!mounted) return;

          setState(() {
            categories = rawList
                .whereType<Map>()
                .map(
                  (item) =>
                      Map<String, dynamic>.from(item),
                )
                .toList();

            isLoadingCategories = false;
          });

          return;
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        isLoadingCategories = false;
      });
    }
  }

  // ============================================================
  // GET EXISTING IMAGE
  // ============================================================

  Future<void> fetchExistingImage(
    String photoName,
  ) async {
    try {
      final prefs =
          await SharedPreferences.getInstance();

      final token =
          prefs.getString('token') ?? '';

      final fileName =
          photoName.contains('/')
              ? photoName.split('/').last
              : photoName;

      final response = await http.get(
        Uri.parse(
          'https://sijala.biz.id/api/image/$fileName',
        ),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 &&
          response.bodyBytes.isNotEmpty) {
        if (!mounted) return;

        setState(() {
          existingImageBytes =
              response.bodyBytes;
        });
      }
    } catch (_) {}
  }

  // ============================================================
  // IMAGE PICKER
  // ============================================================

  Future<void> pickImage(
    ImageSource source,
  ) async {
    try {
      final picker = ImagePicker();

      final pickedFile =
          await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final bytes =
            await pickedFile.readAsBytes();

        if (!mounted) return;

        setState(() {
          selectedImage = pickedFile;
          selectedImageBytes = bytes;
        });
      }
    } catch (_) {
      showErrorSnackBar(
        'Gagal memilih foto.',
      );
    }
  }

  void removeSelectedImage() {
    setState(() {
      selectedImage = null;
      selectedImageBytes = null;
      existingImageBytes = null;
    });
  }

  void showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(22),
        ),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: border,
                    borderRadius:
                        BorderRadius.circular(10),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Pilih Sumber Foto',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),

                const SizedBox(height: 16),

                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor:
                        Color(0xFFFDF0F0),
                    child: Icon(
                      Icons.photo_library_rounded,
                      color: primary,
                    ),
                  ),
                  title: const Text('Galeri'),
                  onTap: () {
                    Navigator.pop(ctx);
                    pickImage(
                      ImageSource.gallery,
                    );
                  },
                ),

                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor:
                        Color(0xFFFDF0F0),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      color: primary,
                    ),
                  ),
                  title: const Text('Kamera'),
                  onTap: () {
                    Navigator.pop(ctx);
                    pickImage(
                      ImageSource.camera,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // SAVE SURVEY
  // POST /surveys/save
  // EDIT menggunakan _method PUT
  // ============================================================

  Future<void> saveSurvey() async {
    if (!formKey.currentState!.validate()) {
      showErrorSnackBar(
        'Lengkapi data yang wajib diisi.',
      );
      return;
    }

    if (selectedCategoryId == null ||
        selectedCategoryId == 0) {
      showErrorSnackBar(
        'Kategori survey wajib dipilih.',
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      final prefs =
          await SharedPreferences.getInstance();

      final token =
          prefs.getString('token') ?? '';

      if (token.isEmpty) {
        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const LoginPage(),
          ),
          (route) => false,
        );

        return;
      }

      final uri = Uri.parse(
        'https://sijala.biz.id/api/v1/surveys/save',
      );

      final request =
          http.MultipartRequest(
        'POST',
        uri,
      );

      request.headers['Accept'] =
          'application/json';

      request.headers['Authorization'] =
          'Bearer $token';

      request.fields['title'] =
          titleController.text.trim();

      request.fields['category_id'] =
          selectedCategoryId.toString();

      request.fields['description'] =
          descriptionController.text.trim();

      if (latitudeController.text
          .trim()
          .isNotEmpty) {
        request.fields['latitude'] =
            latitudeController.text.trim();
      }

      if (longitudeController.text
          .trim()
          .isNotEmpty) {
        request.fields['longitude'] =
            longitudeController.text.trim();
      }

      // EDIT
      if (isEdit) {
        request.fields['id'] =
            widget.survey!['id'].toString();

        request.fields['_method'] = 'PUT';
      }

      // FOTO BARU
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

      final streamed =
          await request.send();

      final response =
          await http.Response.fromStream(
        streamed,
      );

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        if (!mounted) return;

        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              isEdit
                  ? 'Survey berhasil diperbarui!'
                  : 'Survey berhasil disimpan!',
            ),
            backgroundColor: success,
          ),
        );

        Navigator.pop(context, true);
        return;
      }

      if (response.statusCode == 422) {
        final decoded =
            jsonDecode(response.body);

        final message =
            decoded['message'] ??
                'Data yang dikirim tidak valid.';

        throw Exception(message);
      }

      throw Exception(
        'Gagal menyimpan survey '
        '(Kode: ${response.statusCode})',
      );
    } catch (e) {
      if (!mounted) return;

      showErrorSnackBar(
        e.toString()
            .replaceFirst(
              'Exception: ',
              '',
            ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  // ============================================================
  // ERROR
  // ============================================================

  void showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error,
        behavior:
            SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(12),
        ),
      ),
    );
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration inputDecoration({
    required String hint,
    IconData? icon,
    String? label,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon == null
          ? null
          : Icon(
              icon,
              color: primary,
              size: 20,
            ),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(12),
        borderSide:
            const BorderSide(
          color: border,
        ),
      ),
      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(12),
        borderSide:
            const BorderSide(
          color: border,
        ),
      ),
      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(12),
        borderSide:
            const BorderSide(
          color: primary,
          width: 1.5,
        ),
      ),
    );
  }

  // ============================================================
  // SECTION CARD
  // ============================================================

  Widget sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(alpha: 0.025),
            blurRadius: 16,
            offset:
                const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primary.withValues(
                    alpha: 0.09,
                  ),
                  borderRadius:
                      BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: primary,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight:
                      FontWeight.w700,
                  color: textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          child,
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        elevation: 0,
        foregroundColor: Colors.white,
        title: Text(
          isEdit
              ? 'Edit Survey'
              : 'Tambah Survey',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        flexibleSpace: Container(
          decoration:
              const BoxDecoration(
            gradient:
                LinearGradient(
              colors: [
                primaryLight,
                primaryDark,
              ],
            ),
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              // ==================================================
              // DATA UTAMA
              // ==================================================

              sectionCard(
                title: 'Data Utama Survey',
                icon: Icons.assignment_outlined,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Judul Survey *',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),

                    const SizedBox(height: 7),

                    TextFormField(
                      controller:
                          titleController,
                      decoration:
                          inputDecoration(
                        hint:
                            'Masukkan judul survey',
                        icon: Icons.title,
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.trim()
                                .isEmpty) {
                          return 'Judul wajib diisi';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      'Kategori Survey *',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),

                    const SizedBox(height: 7),

                    if (isLoadingCategories)
                      const LinearProgressIndicator(
                        color: primary,
                      )
                    else
                      DropdownButtonFormField<int>(
                        initialValue:
                            selectedCategoryId,
                        decoration:
                            inputDecoration(
                          hint:
                              'Pilih Kategori',
                          icon:
                              Icons.category_outlined,
                        ),
                        items: categories
                            .map((cat) {
                          final id =
                              int.tryParse(
                                    cat['id']
                                            ?.toString() ??
                                        '',
                                  ) ??
                                  0;

                          final name =
                              cat['name']
                                      ?.toString() ??
                                  '-';

                          return DropdownMenuItem<
                              int>(
                            value: id,
                            child: Text(name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedCategoryId =
                                value;
                          });
                        },
                        validator: (value) {
                          if (value == null ||
                              value == 0) {
                            return 'Kategori wajib dipilih';
                          }

                          return null;
                        },
                      ),

                    const SizedBox(height: 16),

                    const Text(
                      'Deskripsi Survey',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),

                    const SizedBox(height: 7),

                    TextFormField(
                      controller:
                          descriptionController,
                      maxLines: 4,
                      decoration:
                          inputDecoration(
                        hint:
                            'Keterangan atau catatan survey...',
                        icon:
                            Icons.notes_outlined,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ==================================================
              // FOTO
              // ==================================================

              sectionCard(
                title: 'Foto Survey',
                icon: Icons.photo_camera_outlined,
                child: Column(
                  children: [
                    if (selectedImageBytes !=
                            null ||
                        existingImageBytes !=
                            null)
                      Column(
                        children: [
                          ClipRRect(
                            borderRadius:
                                BorderRadius.circular(
                                    14),
                            child: Image.memory(
                              selectedImageBytes ??
                                  existingImageBytes!,
                              height: 200,
                              width:
                                  double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),

                          const SizedBox(
                              height: 12),

                          Row(
                            children: [
                              Expanded(
                                child:
                                    OutlinedButton
                                        .icon(
                                  onPressed:
                                      showImageSourceDialog,
                                  icon:
                                      const Icon(
                                    Icons
                                        .photo_library_outlined,
                                    color: primary,
                                  ),
                                  label:
                                      const Text(
                                    'Ganti Foto',
                                  ),
                                  style:
                                      OutlinedButton.styleFrom(
                                    foregroundColor:
                                        primary,
                                    side:
                                        const BorderSide(
                                      color:
                                          primary,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(
                                  width: 10),

                              OutlinedButton
                                  .icon(
                                onPressed:
                                    removeSelectedImage,
                                icon:
                                    const Icon(
                                  Icons
                                      .delete_outline,
                                ),
                                label:
                                    const Text(
                                  'Hapus',
                                ),
                                style:
                                    OutlinedButton.styleFrom(
                                  foregroundColor:
                                      error,
                                  side:
                                      const BorderSide(
                                    color:
                                        error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    else
                      InkWell(
                        onTap:
                            showImageSourceDialog,
                        borderRadius:
                            BorderRadius.circular(
                                14),
                        child: Container(
                          height: 140,
                          width:
                              double.infinity,
                          decoration:
                              BoxDecoration(
                            color: primary
                                .withValues(
                                    alpha: 0.04),
                            borderRadius:
                                BorderRadius
                                    .circular(
                                        14),
                            border:
                                Border.all(
                              color: primary
                                  .withValues(
                                      alpha:
                                          0.25),
                            ),
                          ),
                          child:
                              const Column(
                            mainAxisAlignment:
                                MainAxisAlignment
                                    .center,
                            children: [
                              Icon(
                                Icons
                                    .add_a_photo_outlined,
                                size: 38,
                                color: primary,
                              ),
                              SizedBox(
                                  height: 8),
                              Text(
                                'Ketuk untuk memilih foto',
                                style: TextStyle(
                                  color:
                                      textSecondary,
                                  fontWeight:
                                      FontWeight
                                          .w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ==================================================
              // LOKASI
              // ==================================================

              sectionCard(
                title:
                    'Lokasi Survey (Koordinat)',
                icon:
                    Icons.location_on_outlined,
                child: Row(
                  children: [
                    Expanded(
                      child:
                          TextFormField(
                        controller:
                            latitudeController,
                        keyboardType:
                            const TextInputType
                                .numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        decoration:
                            inputDecoration(
                          hint:
                              '-7.3274000',
                          label:
                              'Latitude',
                          icon:
                              Icons.my_location,
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child:
                          TextFormField(
                        controller:
                            longitudeController,
                        keyboardType:
                            const TextInputType
                                .numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        decoration:
                            inputDecoration(
                          hint:
                              '108.2207000',
                          label:
                              'Longitude',
                          icon:
                              Icons.explore_outlined,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ==================================================
              // SIMPAN
              // ==================================================

              SizedBox(
                width:
                    double.infinity,
                height: 52,
                child:
                    ElevatedButton(
                  onPressed:
                      isSubmitting
                          ? null
                          : saveSurvey,
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        primary,
                    foregroundColor:
                        Colors.white,
                    elevation: 0,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                              14),
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child:
                              CircularProgressIndicator(
                            color:
                                Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          isEdit
                              ? 'Simpan Perubahan'
                              : 'Simpan Survey',
                          style:
                              const TextStyle(
                            fontSize: 15,
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}