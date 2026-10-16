import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:field_survey_nifaa/screens/auth/login_page.dart';
import 'package:field_survey_nifaa/screens/survey_form_page.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class SurveyDetailPage extends StatefulWidget {
  final int surveyId;

  const SurveyDetailPage({
    super.key,
    required this.surveyId,
  });

  @override
  State<SurveyDetailPage> createState() => _SurveyDetailPageState();
}

class _SurveyDetailPageState extends State<SurveyDetailPage> {
  // ==========================================================
  // THEME
  // ==========================================================

  static const Color primaryColor = Color.fromARGB(255, 104, 194, 217);
  static const Color primaryLight = Color.fromARGB(255, 135, 214, 228);
  static const Color primaryDark = Color.fromARGB(255, 79, 185, 180);

  static const Color backgroundColor = Color(0xFFFFF8F8);
  static const Color surfaceColor = Colors.white;

  static const Color textPrimary = Color.fromARGB(255, 48, 61, 58);
  static const Color textSecondary = Color.fromARGB(255, 127, 145, 146);
  static const Color textMuted = Color(0xFFB9A8A8);

  static const Color borderColor = Color.fromARGB(255, 222, 240, 241);

  static const Color errorColor = Color.fromARGB(255, 68, 213, 239);
  static const Color errorBackground = Color(0xFFFFF0F0);

  static const Color successColor = Color(0xFF10B981);

  // ==========================================================
  // DATA SURVEY
  // ==========================================================

  Map<String, dynamic>? survey;

  bool isLoading = true;
  bool isLoadingImage = false;
  bool isDeleting = false;

  String? errorMessage;

  Uint8List? imageBytes;

  // ==========================================================
  // FIELD API
  // ==========================================================
  //
  // Field yang digunakan dari API:
  //
  // id
  // title
  // description
  // category_name
  // category.name
  // latitude
  // longitude
  // photo
  // created_at
  //
  // ==========================================================

  @override
  void initState() {
    super.initState();

    fetchDetail();
  }

  // ==========================================================
  // GET DETAIL SURVEY
  // ==========================================================

  Future<void> fetchDetail() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
        imageBytes = null;
        isLoadingImage = false;
      });
    }

    try {
      // --------------------------------------------------------
      // AMBIL TOKEN
      // --------------------------------------------------------

      final prefs =
          await SharedPreferences.getInstance();

      final token =
          prefs.getString('token') ?? '';

      // --------------------------------------------------------
      // TOKEN KOSONG
      // --------------------------------------------------------

      if (token.isEmpty) {
        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const LoginPage(),
          ),
          (route) => false,
        );

        return;
      }

      // --------------------------------------------------------
      // URL DETAIL
      // --------------------------------------------------------

      final url = Uri.parse(
        'https://sijala.biz.id/api/v1/surveys/${widget.surveyId}',
      );

      // --------------------------------------------------------
      // REQUEST GET
      // --------------------------------------------------------

      final response = await http.get(
        url,
        headers: {
          'Accept':
              'application/json',
          'Authorization':
              'Bearer $token',
        },
      ).timeout(
        const Duration(seconds: 15),
      );

      // --------------------------------------------------------
      // TOKEN EXPIRED
      // --------------------------------------------------------

      if (response.statusCode == 401) {
        await prefs.remove('token');
        await prefs.remove('user');

        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const LoginPage(),
          ),
          (route) => false,
        );

        return;
      }

      // --------------------------------------------------------
      // SUCCESS
      // --------------------------------------------------------

      if (response.statusCode == 200) {
        final dynamic result =
            jsonDecode(response.body);

        if (result is Map<String, dynamic>) {
          if (result['status'] == true &&
              result['data'] != null) {
            final data =
                Map<String, dynamic>.from(
              result['data'],
            );

            if (!mounted) return;

            setState(() {
              survey = data;
              isLoading = false;
            });

            // --------------------------------------------------
            // FIELD PHOTO
            // --------------------------------------------------

            final photoName =
                data['photo']?.toString();

            if (photoName != null &&
                photoName.isNotEmpty &&
                photoName !=
                    'placeholder.jpg') {
              fetchImage(
                photoName,
                token,
              );
            }

            return;
          }
        }
      }

      throw Exception(
        'Survey tidak ditemukan '
        '(Kode: ${response.statusCode})',
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage =
            'Gagal memuat detail survey. '
            'Periksa koneksi Anda.';
      });

      debugPrint(
        'ERROR FETCH DETAIL: $e',
      );
    }
  }

  // ==========================================================
  // GET FOTO SURVEY
  // ==========================================================

  Future<void> fetchImage(
    String photoName,
    String token,
  ) async {
    if (!mounted) return;

    setState(() {
      isLoadingImage = true;
    });

    try {
      final fileName =
          photoName.contains('/')
              ? photoName.split('/').last
              : photoName;

      final url = Uri.parse(
        'https://sijala.biz.id/api/image/$fileName',
      );

      final response = await http.get(
        url,
        headers: {
          'Accept':
              'application/json',
          'Authorization':
              'Bearer $token',
        },
      ).timeout(
        const Duration(seconds: 15),
      );

      if (response.statusCode == 200 &&
          response.bodyBytes.isNotEmpty) {
        if (!mounted) return;

        setState(() {
          imageBytes =
              response.bodyBytes;

          isLoadingImage = false;
        });

        return;
      }
    } catch (e) {
      debugPrint(
        'ERROR FETCH IMAGE: $e',
      );
    }

    if (!mounted) return;

    setState(() {
      isLoadingImage = false;
    });
  }

  // ==========================================================
  // DELETE SURVEY
  // ==========================================================

  Future<void> deleteSurvey() async {
    // --------------------------------------------------------
    // CEGAH DOUBLE CLICK
    // --------------------------------------------------------

    if (isDeleting) {
      return;
    }

    // --------------------------------------------------------
    // KONFIRMASI
    // --------------------------------------------------------

    final confirm =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Hapus Survey',
            style: TextStyle(
              fontWeight:
                  FontWeight.w700,
            ),
          ),
          content: const Text(
            'Apakah kamu yakin ingin '
            'menghapus survey ini?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Batal',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    errorColor,
                foregroundColor:
                    Colors.white,
              ),
              child: const Text(
                'Hapus',
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    // --------------------------------------------------------
    // LOADING DELETE
    // --------------------------------------------------------

    if (mounted) {
      setState(() {
        isDeleting = true;
      });
    }

    try {
      // ------------------------------------------------------
      // AMBIL TOKEN
      // ------------------------------------------------------

      final prefs =
          await SharedPreferences
              .getInstance();

      final token =
          prefs.getString('token') ?? '';

      // ------------------------------------------------------
      // CEK TOKEN
      // ------------------------------------------------------

      if (token.isEmpty) {
        if (!mounted) return;

        setState(() {
          isDeleting = false;
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          const SnackBar(
            content: Text(
              'Token login tidak ditemukan. '
              'Silakan login kembali.',
            ),
            backgroundColor:
                errorColor,
          ),
        );

        return;
      }

      // ------------------------------------------------------
      // ID SURVEY
      // ------------------------------------------------------

      final int id =
          widget.surveyId;

      // ------------------------------------------------------
      // URL HAPUS
      // ------------------------------------------------------

      final url = Uri.parse(
        'https://sijala.biz.id/api/v1/surveys/$id/delete',
      );

      debugPrint(
        '================================',
      );
      debugPrint(
        'MULAI HAPUS SURVEY',
      );
      debugPrint(
        'SURVEY ID: $id',
      );
      debugPrint(
        'URL: $url',
      );
      debugPrint(
        'TOKEN ADA: ${token.isNotEmpty}',
      );
      debugPrint(
        '================================',
      );

      // ------------------------------------------------------
      // REQUEST POST
      // ------------------------------------------------------
      //
      // BUKAN:
      // http.delete(...)
      //
      // TAPI:
      // http.post(...)
      //
      // Endpoint:
      // /surveys/{id}/delete
      //
      // ------------------------------------------------------

      final response =
          await http.post(
        url,
        headers: {
          'Accept':
              'application/json',
          'Authorization':
              'Bearer $token',
        },
      ).timeout(
        const Duration(seconds: 20),
      );

      // ------------------------------------------------------
      // DEBUG RESPONSE
      // ------------------------------------------------------

      debugPrint(
        '================================',
      );
      debugPrint(
        'HASIL HAPUS SURVEY',
      );
      debugPrint(
        'STATUS: ${response.statusCode}',
      );
      debugPrint(
        'BODY: ${response.body}',
      );
      debugPrint(
        '================================',
      );

      if (!mounted) return;

      setState(() {
        isDeleting = false;
      });

      // ------------------------------------------------------
      // BERHASIL
      // ------------------------------------------------------

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 204) {
        String message =
            'Survey berhasil dihapus.';

        try {
          if (response.body.isNotEmpty) {
            final result =
                jsonDecode(
              response.body,
            );

            if (result
                    is Map<String, dynamic> &&
                result['message'] !=
                    null) {
              message =
                  result['message']
                      .toString();
            }
          }
        } catch (_) {}

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            content: Text(
              message,
            ),
            backgroundColor:
                successColor,
          ),
        );

        await Future.delayed(
          const Duration(
            milliseconds: 700,
          ),
        );

        if (!mounted) return;

        Navigator.pop(
          context,
          true,
        );

        return;
      }

      // ------------------------------------------------------
      // 401
      // ------------------------------------------------------

      if (response.statusCode == 401) {
        await prefs.remove(
          'token',
        );

        await prefs.remove(
          'user',
        );

        if (!mounted) return;

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          const SnackBar(
            content: Text(
              'Sesi login sudah habis. '
              'Silakan login kembali.',
            ),
            backgroundColor:
                errorColor,
          ),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const LoginPage(),
          ),
          (route) => false,
        );

        return;
      }

      // ------------------------------------------------------
      // 403
      // ------------------------------------------------------

      if (response.statusCode == 403) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          const SnackBar(
            content: Text(
              'Kamu tidak memiliki izin '
              'untuk menghapus survey ini.',
            ),
            backgroundColor:
                errorColor,
          ),
        );

        return;
      }

      // ------------------------------------------------------
      // 404
      // ------------------------------------------------------

      if (response.statusCode == 404) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          const SnackBar(
            content: Text(
              'Survey tidak ditemukan '
              'atau endpoint hapus tidak tersedia.',
            ),
            backgroundColor:
                errorColor,
          ),
        );

        return;
      }

      // ------------------------------------------------------
      // ERROR DARI SERVER
      // ------------------------------------------------------

      String message =
          'Gagal menghapus survey.';

      try {
        if (response.body.isNotEmpty) {
          final result =
              jsonDecode(
            response.body,
          );

          if (result
              is Map<String, dynamic>) {
            if (result['message'] !=
                null) {
              message =
                  result['message']
                      .toString();
            } else if (result['error'] !=
                null) {
              message =
                  result['error']
                      .toString();
            }
          }
        }
      } catch (_) {}

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            '$message '
            '(Kode: ${response.statusCode})',
          ),
          backgroundColor:
              errorColor,
        ),
      );
    }

    // --------------------------------------------------------
    // CLIENT EXCEPTION
    // --------------------------------------------------------

    on http.ClientException catch (e) {
      debugPrint(
        '================================',
      );
      debugPrint(
        'CLIENT EXCEPTION DELETE',
      );
      debugPrint(
        '$e',
      );
      debugPrint(
        '================================',
      );

      if (!mounted) return;

      setState(() {
        isDeleting = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'Request hapus gagal dikirim dari browser.',
          ),
          backgroundColor:
              errorColor,
        ),
      );
    }

    // --------------------------------------------------------
    // TIMEOUT
    // --------------------------------------------------------

    on TimeoutException catch (e) {
      debugPrint(
        '================================',
      );
      debugPrint(
        'TIMEOUT DELETE',
      );
      debugPrint(
        '$e',
      );
      debugPrint(
        '================================',
      );

      if (!mounted) return;

      setState(() {
        isDeleting = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'Koneksi ke server terlalu lama.',
          ),
          backgroundColor:
              errorColor,
        ),
      );
    }

    // --------------------------------------------------------
    // ERROR UMUM
    // --------------------------------------------------------

    catch (e) {
      debugPrint(
        '================================',
      );
      debugPrint(
        'ERROR DELETE SURVEY',
      );
      debugPrint(
        '$e',
      );
      debugPrint(
        '================================',
      );

      if (!mounted) return;

      setState(() {
        isDeleting = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            'Terjadi kesalahan saat '
            'menghapus survey: $e',
          ),
          backgroundColor:
              errorColor,
        ),
      );
    }
  }

  // ==========================================================
  // EDIT SURVEY
  // ==========================================================

  Future<void> editSurvey() async {
    if (survey == null) {
      return;
    }

    final result =
        await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SurveyFormPage(
          survey: survey,
        ),
      ),
    );

    if (result == true &&
        mounted) {
      await fetchDetail();
    }
  }

  // ==========================================================
  // GOOGLE MAPS
  // ==========================================================

  Future<void> openGoogleMaps(
    double lat,
    double lng,
  ) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1'
      '&query=$lat,$lng',
    );

    try {
      final launched =
          await launchUrl(
        uri,
        mode: LaunchMode
            .externalApplication,
      );

      if (!launched) {
        if (!mounted) return;

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            content: const Text(
              'Tidak dapat membuka Google Maps',
            ),
            backgroundColor:
                errorColor,
            behavior:
                SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint(
        'ERROR GOOGLE MAPS: $e',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: const Text(
            'Tidak dapat membuka Google Maps',
          ),
          backgroundColor:
              errorColor,
          behavior:
              SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              12,
            ),
          ),
        ),
      );
    }
  }

  // ==========================================================
  // COPY COORDINATES
  // ==========================================================

  void copyCoordinates(
    double lat,
    double lng,
  ) {
    Clipboard.setData(
      ClipboardData(
        text: '$lat, $lng',
      ),
    );

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content: const Text(
          'Koordinat berhasil disalin!',
        ),
        backgroundColor:
            successColor,
        behavior:
            SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            12,
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // FULL IMAGE
  // ==========================================================

  void showFullImageDialog(
    Uint8List bytes,
  ) {
    showDialog(
      context: context,
      barrierColor:
          Colors.black.withValues(
        alpha: 0.85,
      ),
      builder: (ctx) {
        return Dialog(
          backgroundColor:
              Colors.transparent,
          elevation: 0,
          child: Stack(
            alignment:
                Alignment.topRight,
            children: [
              InteractiveViewer(
                minScale: 0.5,
                maxScale: 4,
                child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),
                  child:
                      Image.memory(
                    bytes,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  onPressed: () {
                    Navigator.pop(
                      ctx,
                    );
                  },
                  icon: Container(
                    width: 38,
                    height: 38,
                    decoration:
                        BoxDecoration(
                      color: Colors.black
                          .withValues(
                        alpha: 0.55,
                      ),
                      shape:
                          BoxShape.circle,
                    ),
                    child:
                        const Icon(
                      Icons.close_rounded,
                      color:
                          Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          backgroundColor,

      // ======================================================
      // APP BAR
      // ======================================================

      appBar: AppBar(
        title: const Text(
          'Detail Survey',
          style: TextStyle(
            fontWeight:
                FontWeight.w700,
          ),
        ),

        flexibleSpace:
            Container(
          decoration:
              const BoxDecoration(
            gradient:
                LinearGradient(
              colors: [
                primaryLight,
                primaryDark,
              ],
              begin:
                  Alignment.topLeft,
              end:
                  Alignment.bottomRight,
            ),
          ),
        ),

        foregroundColor:
            Colors.white,

        elevation: 0,

        actions: [
          if (survey != null) ...[
            IconButton(
              icon: const Icon(
                Icons.edit_rounded,
              ),
              tooltip:
                  'Edit Survey',
              onPressed:
                  isDeleting
                      ? null
                      : editSurvey,
            ),

            IconButton(
              icon: isDeleting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                        color:
                            Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons
                          .delete_outline_rounded,
                    ),
              tooltip:
                  'Hapus Survey',
              onPressed:
                  isDeleting
                      ? null
                      : deleteSurvey,
            ),

            const SizedBox(
              width: 4,
            ),
          ],
        ],
      ),

      body: buildBody(),
    );
  }

  // ==========================================================
  // BODY
  // ==========================================================

  Widget buildBody() {
    // ========================================================
    // LOADING
    // ========================================================

    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child:
                  CircularProgressIndicator(
                strokeWidth: 3,
                color:
                    primaryColor,
              ),
            ),

            SizedBox(
              height: 16,
            ),

            Text(
              'Memuat detail survey...',
              style: TextStyle(
                color:
                    textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    // ========================================================
    // ERROR
    // ========================================================

    if (errorMessage != null ||
        survey == null) {
      return Center(
        child: Padding(
          padding:
              const EdgeInsets.all(
            24,
          ),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration:
                    const BoxDecoration(
                  color:
                      errorBackground,
                  shape:
                      BoxShape.circle,
                ),
                child:
                    const Icon(
                  Icons
                      .error_outline_rounded,
                  size: 36,
                  color:
                      errorColor,
                ),
              ),

              const SizedBox(
                height: 18,
              ),

              const Text(
                'Survey Tidak Ditemukan',
                textAlign:
                    TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.w700,
                  color:
                      textPrimary,
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              Text(
                errorMessage ??
                    'Survey tidak ditemukan.',
                textAlign:
                    TextAlign.center,
                style:
                    const TextStyle(
                  fontSize: 13.5,
                  color:
                      textSecondary,
                  height: 1.4,
                ),
              ),

              const SizedBox(
                height: 22,
              ),

              ElevatedButton.icon(
                onPressed:
                    fetchDetail,
                icon:
                    const Icon(
                  Icons
                      .refresh_rounded,
                  size: 18,
                ),
                label:
                    const Text(
                  'Coba Lagi',
                ),
                style:
                    ElevatedButton
                        .styleFrom(
                  backgroundColor:
                      primaryColor,
                  foregroundColor:
                      Colors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius
                            .circular(
                      12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ========================================================
    // FIELD SURVEY
    // ========================================================

    final title =
        survey!['title']
                ?.toString() ??
            '';

    final description =
        survey!['description']
                ?.toString() ??
            '';

    final category =
        survey!['category_name']
                ?.toString() ??
            survey!['category']?['name']
                ?.toString() ??
            'Tanpa Kategori';

    final date =
        survey!['created_at']
                ?.toString() ??
            '';

    final lat =
        double.tryParse(
      survey!['latitude']
              ?.toString() ??
          '',
    );

    final lng =
        double.tryParse(
      survey!['longitude']
              ?.toString() ??
          '',
    );

    final hasValidCoords =
        lat != null &&
            lng != null;

    // ========================================================
    // MAIN LIST
    // ========================================================

    return RefreshIndicator(
      color:
          primaryColor,
      backgroundColor:
          Colors.white,

      onRefresh:
          fetchDetail,

      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),

        padding:
            const EdgeInsets.all(
          16,
        ),

        children: [
          // ====================================================
          // KARTU 1
          // INFORMASI UTAMA
          // ====================================================

          Card(
            elevation: 0,
            color:
                surfaceColor,

            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(
                16,
              ),
              side:
                  const BorderSide(
                color:
                    borderColor,
              ),
            ),

            child: Padding(
              padding:
                  const EdgeInsets.all(
                18,
              ),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,

                children: [
                  // CATEGORY

                  Container(
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),

                    decoration:
                        BoxDecoration(
                      color:
                          primaryColor
                              .withValues(
                        alpha: 0.08,
                      ),
                      borderRadius:
                          BorderRadius
                              .circular(
                        8,
                      ),
                      border:
                          Border.all(
                        color:
                            primaryColor
                                .withValues(
                          alpha: 0.16,
                        ),
                      ),
                    ),

                    child:
                        Text(
                      category,
                      style:
                          const TextStyle(
                        fontSize: 12,
                        fontWeight:
                            FontWeight.w600,
                        color:
                            primaryColor,
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 14,
                  ),

                  // TITLE

                  Text(
                    title,
                    style:
                        const TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.w800,
                      color:
                          textPrimary,
                      height: 1.25,
                    ),
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  // DATE

                  Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration:
                            BoxDecoration(
                          color:
                              primaryColor
                                  .withValues(
                            alpha:
                                0.08,
                          ),
                          borderRadius:
                              BorderRadius
                                  .circular(
                            8,
                          ),
                        ),
                        child:
                            const Icon(
                          Icons
                              .access_time_rounded,
                          size: 15,
                          color:
                              primaryColor,
                        ),
                      ),

                      const SizedBox(
                        width: 8,
                      ),

                      Expanded(
                        child: Text(
                          'Waktu: $date',
                          style:
                              const TextStyle(
                            fontSize:
                                12.5,
                            color:
                                textSecondary,
                            fontWeight:
                                FontWeight
                                    .w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(
            height: 14,
          ),

          // ====================================================
          // KARTU 2
          // FOTO
          // ====================================================

          Card(
            elevation: 0,
            color:
                surfaceColor,

            clipBehavior:
                Clip.antiAlias,

            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(
                16,
              ),
              side:
                  const BorderSide(
                color:
                    borderColor,
              ),
            ),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,

              children: [
                Padding(
                  padding:
                      const EdgeInsets
                          .fromLTRB(
                    18,
                    16,
                    18,
                    12,
                  ),

                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration:
                            BoxDecoration(
                          color:
                              primaryColor
                                  .withValues(
                            alpha:
                                0.08,
                          ),
                          borderRadius:
                              BorderRadius
                                  .circular(
                            10,
                          ),
                        ),
                        child:
                            const Icon(
                          Icons
                              .photo_camera_outlined,
                          size: 18,
                          color:
                              primaryColor,
                        ),
                      ),

                      const SizedBox(
                        width: 10,
                      ),

                      const Text(
                        'Foto Survey',
                        style:
                            TextStyle(
                          fontSize: 15,
                          fontWeight:
                              FontWeight
                                  .w700,
                          color:
                              textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),

                if (isLoadingImage)
                  const SizedBox(
                    height: 200,
                    child:
                        Center(
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 3,
                        color:
                            primaryColor,
                      ),
                    ),
                  )

                else if (imageBytes !=
                    null)
                  GestureDetector(
                    onTap: () {
                      showFullImageDialog(
                        imageBytes!,
                      );
                    },

                    child: Stack(
                      children: [
                        Image.memory(
                          imageBytes!,
                          height: 220,
                          width:
                              double.infinity,
                          fit:
                              BoxFit.cover,
                        ),

                        Positioned(
                          right: 12,
                          bottom: 12,
                          child:
                              Container(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal:
                                  10,
                              vertical:
                                  7,
                            ),
                            decoration:
                                BoxDecoration(
                              color: Colors
                                  .black
                                  .withValues(
                                alpha:
                                    0.55,
                              ),
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                10,
                              ),
                            ),
                            child:
                                const Row(
                              mainAxisSize:
                                  MainAxisSize
                                      .min,
                              children: [
                                Icon(
                                  Icons
                                      .zoom_in_rounded,
                                  color:
                                      Colors.white,
                                  size:
                                      16,
                                ),

                                SizedBox(
                                  width: 5,
                                ),

                                Text(
                                  'Lihat Foto',
                                  style:
                                      TextStyle(
                                    color:
                                        Colors.white,
                                    fontSize:
                                        11.5,
                                    fontWeight:
                                        FontWeight
                                            .w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )

                else
                  Container(
                    height: 140,
                    width:
                        double.infinity,

                    color:
                        primaryColor
                            .withValues(
                      alpha:
                          0.035,
                    ),

                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .center,

                      children: [
                        Icon(
                          Icons
                              .image_not_supported_outlined,
                          size: 34,
                          color:
                              textMuted
                                  .withValues(
                            alpha:
                                0.8,
                          ),
                        ),

                        const SizedBox(
                          height: 8,
                        ),

                        const Text(
                          'Tidak ada foto survey',
                          style:
                              TextStyle(
                            color:
                                textMuted,
                            fontSize:
                                13,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(
            height: 14,
          ),

          // ====================================================
          // KARTU 3
          // DESKRIPSI
          // ====================================================

          Card(
            elevation: 0,
            color:
                surfaceColor,

            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(
                16,
              ),
              side:
                  const BorderSide(
                color:
                    borderColor,
              ),
            ),

            child: Padding(
              padding:
                  const EdgeInsets.all(
                18,
              ),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,

                children: [
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration:
                            BoxDecoration(
                          color:
                              primaryColor
                                  .withValues(
                            alpha:
                                0.08,
                          ),
                          borderRadius:
                              BorderRadius
                                  .circular(
                            10,
                          ),
                        ),
                        child:
                            const Icon(
                          Icons
                              .description_outlined,
                          size: 18,
                          color:
                              primaryColor,
                        ),
                      ),

                      const SizedBox(
                        width: 10,
                      ),

                      const Text(
                        'Deskripsi',
                        style:
                            TextStyle(
                          fontSize: 15,
                          fontWeight:
                              FontWeight
                                  .w700,
                          color:
                              textPrimary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 14,
                  ),

                  Text(
                    description.isEmpty
                        ? 'Tidak ada deskripsi.'
                        : description,

                    style:
                        const TextStyle(
                      fontSize: 14,
                      color:
                          textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(
            height: 14,
          ),

          // ====================================================
          // KARTU 4
          // LOKASI
          // ====================================================

          Card(
            elevation: 0,
            color:
                surfaceColor,

            clipBehavior:
                Clip.antiAlias,

            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(
                16,
              ),
              side:
                  const BorderSide(
                color:
                    borderColor,
              ),
            ),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,

              children: [
                Padding(
                  padding:
                      const EdgeInsets
                          .fromLTRB(
                    18,
                    16,
                    18,
                    14,
                  ),

                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration:
                            BoxDecoration(
                          color:
                              primaryColor
                                  .withValues(
                            alpha:
                                0.08,
                          ),
                          borderRadius:
                              BorderRadius
                                  .circular(
                            10,
                          ),
                        ),
                        child:
                            const Icon(
                          Icons
                              .location_on_outlined,
                          size: 19,
                          color:
                              primaryColor,
                        ),
                      ),

                      const SizedBox(
                        width: 10,
                      ),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,

                          children: [
                            const Text(
                              'Lokasi Survey',
                              style:
                                  TextStyle(
                                fontSize:
                                    15,
                                fontWeight:
                                    FontWeight
                                        .w700,
                                color:
                                    textPrimary,
                              ),
                            ),

                            const SizedBox(
                              height: 5,
                            ),

                            Text(
                              hasValidCoords
                                  ? 'Koordinat: $lat, $lng'
                                  : 'Koordinat tidak tersedia',

                              style:
                                  const TextStyle(
                                fontSize:
                                    12,
                                color:
                                    textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ==================================================
                // MAP
                // ==================================================

                if (hasValidCoords) ...[
                  SizedBox(
                    height: 220,
                    width:
                        double.infinity,

                    child:
                        FlutterMap(
                      options:
                          MapOptions(
                        initialCenter:
                            LatLng(
                          lat,
                          lng,
                        ),
                        initialZoom:
                            15.0,
                      ),

                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',

                          userAgentPackageName:
                              'com.example.flutter_application_akoy',
                        ),

                        MarkerLayer(
                          markers: [
                            Marker(
                              point:
                                  LatLng(
                                lat,
                                lng,
                              ),

                              width: 48,
                              height: 48,

                              child:
                                  Container(
                                decoration:
                                    BoxDecoration(
                                  color:
                                      Colors.white,

                                  shape:
                                      BoxShape.circle,

                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors
                                          .black
                                          .withValues(
                                        alpha:
                                            0.15,
                                      ),
                                      blurRadius:
                                          8,
                                    ),
                                  ],
                                ),

                                child:
                                    const Icon(
                                  Icons
                                      .location_on_rounded,
                                  color:
                                      primaryColor,
                                  size:
                                      34,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ==================================================
                  // BUTTON MAP
                  // ==================================================

                  Padding(
                    padding:
                        const EdgeInsets
                            .all(
                      14,
                    ),

                    child: Row(
                      children: [
                        // SALIN

                        Expanded(
                          child:
                              OutlinedButton
                                  .icon(
                            onPressed:
                                () {
                              copyCoordinates(
                                lat,
                                lng,
                              );
                            },

                            icon:
                                const Icon(
                              Icons
                                  .copy_rounded,
                              size:
                                  16,
                            ),

                            label:
                                const Text(
                              'Salin Koordinat',
                            ),

                            style:
                                OutlinedButton
                                    .styleFrom(
                              foregroundColor:
                                  primaryColor,

                              side:
                                  const BorderSide(
                                color:
                                    primaryColor,
                              ),

                              elevation:
                                  0,

                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                vertical:
                                    12,
                              ),

                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  11,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(
                          width: 10,
                        ),

                        // GOOGLE MAPS

                        Expanded(
                          child:
                              ElevatedButton
                                  .icon(
                            onPressed:
                                () {
                              openGoogleMaps(
                                lat,
                                lng,
                              );
                            },

                            icon:
                                const Icon(
                              Icons
                                  .map_rounded,
                              size:
                                  17,
                            ),

                            label:
                                const Text(
                              'Buka Maps',
                            ),

                            style:
                                ElevatedButton
                                    .styleFrom(
                              backgroundColor:
                                  primaryColor,

                              foregroundColor:
                                  Colors.white,

                              elevation:
                                  0,

                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                vertical:
                                    12,
                              ),

                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  11,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ]

                // ==================================================
                // TIDAK ADA KOORDINAT
                // ==================================================

                else
                  Container(
                    height: 180,
                    width:
                        double.infinity,

                    color:
                        primaryColor
                            .withValues(
                      alpha:
                          0.035,
                    ),

                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .center,

                      children: [
                        const Icon(
                          Icons
                              .location_off_outlined,
                          size: 34,
                          color:
                              textMuted,
                        ),

                        const SizedBox(
                          height: 8,
                        ),

                        const Text(
                          'Peta tidak tersedia',
                          style:
                              TextStyle(
                            color:
                                textMuted,
                            fontSize:
                                13,
                          ),
                        ),

                        const SizedBox(
                          height: 3,
                        ),

                        const Text(
                          'Koordinat survey kosong',
                          style:
                              TextStyle(
                            color:
                                textMuted,
                            fontSize:
                                11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(
            height: 24,
          ),

          // ====================================================
          // TOMBOL EDIT DAN HAPUS
          // ====================================================

          if (survey != null) ...[
            Row(
              children: [
                // ==================================================
                // EDIT
                // ==================================================

                Expanded(
                  child:
                      OutlinedButton
                          .icon(
                    onPressed:
                        isDeleting
                            ? null
                            : editSurvey,

                    icon:
                        const Icon(
                      Icons
                          .edit_rounded,
                      size: 18,
                    ),

                    label:
                        const Text(
                      'Edit Survey',
                    ),

                    style:
                        OutlinedButton
                            .styleFrom(
                      foregroundColor:
                          primaryColor,

                      side:
                          const BorderSide(
                        color:
                            primaryColor,
                      ),

                      padding:
                          const EdgeInsets
                              .symmetric(
                        vertical:
                            13,
                      ),

                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                          12,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  width: 10,
                ),

                // ==================================================
                // DELETE
                // ==================================================

                Expanded(
                  child:
                      ElevatedButton
                          .icon(
                    onPressed:
                        isDeleting
                            ? null
                            : deleteSurvey,

                    icon: isDeleting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child:
                                CircularProgressIndicator(
                              strokeWidth:
                                  2,
                              color:
                                  Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons
                                .delete_outline_rounded,
                            size: 18,
                          ),

                    label: Text(
                      isDeleting
                          ? 'Menghapus...'
                          : 'Hapus Survey',
                    ),

                    style:
                        ElevatedButton
                            .styleFrom(
                      backgroundColor:
                          errorColor,

                      foregroundColor:
                          Colors.white,

                      disabledBackgroundColor:
                          errorColor
                              .withValues(
                        alpha:
                            0.6,
                      ),

                      disabledForegroundColor:
                          Colors.white,

                      elevation:
                          0,

                      padding:
                          const EdgeInsets
                              .symmetric(
                        vertical:
                            13,
                      ),

                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                          12,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 20,
            ),
          ],
        ],
      ),
    );
  }
}