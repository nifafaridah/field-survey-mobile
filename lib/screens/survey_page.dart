import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:field_survey_nifaa/models/survey.dart';
import 'package:field_survey_nifaa/routes/app_router.dart';
import 'package:field_survey_nifaa/screens/survey_detail_page.dart';
import 'package:field_survey_nifaa/screens/survey_form_page.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

// ============================================================
// THEME
// ============================================================

abstract class SurveyTheme {
  static const Color primary = Color.fromARGB(255, 104, 213, 217);
  static const Color primaryLight = Color.fromARGB(255, 135, 228, 223);
  static const Color primaryDark = Color.fromARGB(255, 79, 164, 185);

  static const Color background = Color(0xFFFFF8F8);
  static const Color surface = Colors.white;

  static const Color textPrimary = Color(0xFF3D3030);
  static const Color textSecondary = Color(0xFF927F7F);
  static const Color textMuted = Color(0xFFB9A8A8);

  static const Color border = Color(0xFFF1DEDE);

  static const Color error = Color.fromARGB(255, 68, 99, 239);
  static const Color errorBg = Color(0xFFFFF0F0);

  static const Color success = Color(0xFF10B981);

  static const double mobileBreakpoint = 600.0;
  static const double desktopBreakpoint = 1024.0;

  static const double maxContentWidth = 1100.0;
  static const double cardRadius = 16.0;
  static const double badgeRadius = 8.0;

  static EdgeInsets getPagePadding(double screenWidth) {
    if (screenWidth >= desktopBreakpoint) {
      return const EdgeInsets.symmetric(
        horizontal: 32,
        vertical: 24,
      );
    }

    if (screenWidth > mobileBreakpoint) {
      return const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 16,
      );
    }

    return const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 12,
    );
  }
}

// ============================================================
// SURVEY PAGE
// ============================================================

class SurveyPage extends StatefulWidget {
  const SurveyPage({super.key});

  @override
  State<SurveyPage> createState() => _SurveyPageState();
}

class _SurveyPageState extends State<SurveyPage> {
  // ==========================================================
  // API
  // ==========================================================

  static const String _surveyEndpoint =
      'https://sijala.biz.id/api/v1/surveys';

  // ==========================================================
  // STATE
  // ==========================================================

  List<Survey> _surveys = [];

  bool _isLoading = true;
  bool _isRefreshing = false;

  String? _errorMessage;

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();
    fetchSurveys();
  }

  // ==========================================================
  // GET SURVEY
  // ==========================================================

  Future<void> fetchSurveys({
    bool isRefresh = false,
  }) async {
    if (isRefresh) {
      if (_isRefreshing) return;
      _isRefreshing = true;
    } else {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
      }
    }

    try {
      final prefs = await SharedPreferences.getInstance();

      final token = prefs.getString('token');

      if (token == null || token.trim().isEmpty) {
        if (!mounted) return;

        _showModernSnackBar(
          message: 'Sesi telah berakhir. Silakan login kembali.',
          isSuccess: false,
        );

        context.go(AppRouter.login);
        return;
      }

      final response = await http
          .get(
            Uri.parse(_surveyEndpoint),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(
            const Duration(seconds: 15),
          );

      // ======================================================
      // TOKEN EXPIRED
      // ======================================================

      if (response.statusCode == 401) {
        await prefs.remove('token');
        await prefs.remove('user');

        if (!mounted) return;

        _showModernSnackBar(
          message: 'Sesi telah berakhir. Silakan login kembali.',
          isSuccess: false,
        );

        context.go(AppRouter.login);
        return;
      }

      // ======================================================
      // SUCCESS
      // ======================================================

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);

        if (decoded is Map<String, dynamic>) {
          if (decoded['status'] == true) {
            final dynamic data = decoded['data'];

            final List<Survey> loadedSurveys = [];

            if (data is List) {
              for (final item in data) {
                if (item is Map<String, dynamic>) {
                  loadedSurveys.add(
                    Survey.fromJson(item),
                  );
                }
              }
            }

            if (!mounted) return;

            setState(() {
              _surveys = loadedSurveys;
              _isLoading = false;
              _errorMessage = null;
            });

            return;
          }

          final String message =
              decoded['message']?.toString() ??
                  'Gagal memuat daftar survey.';

          throw Exception(message);
        }

        throw Exception(
          'Format response API tidak sesuai.',
        );
      }

      throw Exception(
        'Gagal memuat survey '
        '(Kode: ${response.statusCode})',
      );
    }

    // ==========================================================
    // CONNECTION ERROR
    // ==========================================================

    on SocketException {
      if (!mounted) return;

      _handleFetchError(
        'Tidak dapat terhubung ke server. '
        'Periksa koneksi internet Anda.',
        isRefresh: isRefresh,
      );
    }

    // ==========================================================
    // TIMEOUT
    // ==========================================================

    on TimeoutException {
      if (!mounted) return;

      _handleFetchError(
        'Koneksi waktu habis. Silakan coba lagi.',
        isRefresh: isRefresh,
      );
    }

    // ==========================================================
    // OTHER ERROR
    // ==========================================================

    catch (e) {
      if (!mounted) return;

      final String message = e
          .toString()
          .replaceFirst(
            'Exception: ',
            '',
          );

      _handleFetchError(
        message,
        isRefresh: isRefresh,
      );
    }

    // ==========================================================
    // FINALLY
    // ==========================================================

    finally {
      _isRefreshing = false;

      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ==========================================================
  // HANDLE ERROR
  // ==========================================================

  void _handleFetchError(
    String message, {
    required bool isRefresh,
  }) {
    if (!mounted) return;

    setState(() {
      _isLoading = false;

      if (!isRefresh || _surveys.isEmpty) {
        _errorMessage = message;
      }
    });

    if (isRefresh) {
      _showModernSnackBar(
        message: message,
        isSuccess: false,
      );
    }
  }

  // ==========================================================
  // ADD SURVEY
  // ==========================================================

  Future<void> _handleAddSurvey() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SurveyFormPage(),
      ),
    );

    if (result == true && mounted) {
      await fetchSurveys(
        isRefresh: true,
      );
    }
  }

  // ==========================================================
  // OPEN DETAIL
  // ==========================================================

  Future<void> _openSurveyDetail(Survey survey) async {
    final int? surveyId = int.tryParse(
      survey.id.toString(),
    );

    if (surveyId == null) {
      _showModernSnackBar(
        message: 'ID survey tidak valid.',
        isSuccess: false,
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SurveyDetailPage(
          surveyId: surveyId,
        ),
      ),
    );

    // Jika kembali setelah edit/delete
    if (result == true && mounted) {
      await fetchSurveys(
        isRefresh: true,
      );
    }
  }

  // ==========================================================
  // OPEN GOOGLE MAPS
  // ==========================================================

  Future<void> _openSurveyMap(Survey survey) async {
    if (survey.latitude == null ||
        survey.longitude == null) {
      _showModernSnackBar(
        message: 'Lokasi survey tidak tersedia.',
        isSuccess: false,
      );
      return;
    }

    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1'
      '&query=${survey.latitude},${survey.longitude}',
    );

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        _showModernSnackBar(
          message: 'Tidak dapat membuka Google Maps.',
          isSuccess: false,
        );
      }
    } catch (_) {
      if (!mounted) return;

      _showModernSnackBar(
        message: 'Tidak dapat membuka Google Maps.',
        isSuccess: false,
      );
    }
  }

  // ==========================================================
  // SNACKBAR
  // ==========================================================

  void _showModernSnackBar({
    required String message,
    required bool isSuccess,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isSuccess
            ? SurveyTheme.success
            : SurveyTheme.error,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: 28,
          vertical: 16,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            Icon(
              isSuccess
                  ? Icons.check_circle_rounded
                  : Icons.error_outline_rounded,
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final screenWidth =
        MediaQuery.sizeOf(context).width;

    final pagePadding =
        SurveyTheme.getPagePadding(screenWidth);

    return Scaffold(
      backgroundColor: SurveyTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),

            Expanded(
              child: RefreshIndicator(
                color: SurveyTheme.primary,
                backgroundColor: SurveyTheme.surface,
                onRefresh: () => fetchSurveys(
                  isRefresh: true,
                ),
                child: _buildBodyContent(
                  screenWidth: screenWidth,
                  padding: pagePadding,
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton:
          _buildFloatingActionButton(),
    );
  }

  // ==========================================================
  // HEADER
  // ==========================================================

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 14,
      ),
      decoration: const BoxDecoration(
        color: SurveyTheme.surface,
        border: Border(
          bottom: BorderSide(
            color: SurveyTheme.border,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  SurveyTheme.primaryLight,
                  SurveyTheme.primaryDark,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius:
                  BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: SurveyTheme.primary
                      .withValues(alpha: 0.22),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.assignment_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Survey',
                  style:
                      GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color:
                        SurveyTheme.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'Daftar hasil survey',
                  style:
                      GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color:
                        const Color.fromARGB(255, 127, 143, 146),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // BODY
  // ==========================================================

  Widget _buildBodyContent({
    required double screenWidth,
    required EdgeInsets padding,
  }) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null &&
        _surveys.isEmpty) {
      return _buildErrorState();
    }

    if (_surveys.isEmpty) {
      return _buildEmptyState();
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: SurveyTheme.maxContentWidth,
        ),
        child: _buildResponsiveSurveyList(
          screenWidth: screenWidth,
          padding: padding,
        ),
      ),
    );
  }

  // ==========================================================
  // SURVEY LIST
  // ==========================================================

  Widget _buildResponsiveSurveyList({
    required double screenWidth,
    required EdgeInsets padding,
  }) {
    final contentPadding =
        padding.copyWith(
      bottom: padding.bottom + 84,
    );

    // DESKTOP
    if (screenWidth >=
        SurveyTheme.desktopBreakpoint) {
      final int crossAxisCount =
          _surveys.length == 1 ? 1 : 2;

      if (crossAxisCount == 1) {
        return ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          padding: contentPadding,
          children: [
            Center(
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(
                  maxWidth: 540,
                ),
                child: _buildSurveyCard(
                  _surveys.first,
                ),
              ),
            ),
          ],
        );
      }

      return GridView.builder(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: contentPadding,
        gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          mainAxisExtent: 220,
        ),
        itemCount: _surveys.length,
        itemBuilder: (context, index) {
          return _buildSurveyCard(
            _surveys[index],
          );
        },
      );
    }

    // TABLET
    if (screenWidth >=
        SurveyTheme.mobileBreakpoint) {
      if (_surveys.length == 1) {
        return ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          padding: contentPadding,
          children: [
            Center(
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(
                  maxWidth: 520,
                ),
                child: _buildSurveyCard(
                  _surveys.first,
                ),
              ),
            ),
          ],
        );
      }

      return GridView.builder(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: contentPadding,
        gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          mainAxisExtent: 230,
        ),
        itemCount: _surveys.length,
        itemBuilder: (context, index) {
          return _buildSurveyCard(
            _surveys[index],
          );
        },
      );
    }

    // MOBILE
    return ListView.separated(
      physics:
          const AlwaysScrollableScrollPhysics(),
      padding: contentPadding,
      itemCount: _surveys.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: 14),
      itemBuilder: (context, index) {
        return _buildSurveyCard(
          _surveys[index],
        );
      },
    );
  }

  // ==========================================================
  // SURVEY CARD
  // ==========================================================

  Widget _buildSurveyCard(Survey survey) {
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 255, 255, 255),
        borderRadius: BorderRadius.circular(
          SurveyTheme.cardRadius,
        ),
        border: Border.all(
          color: const Color.fromARGB(255, 222, 238, 241).withValues(
            alpha: 0.8,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A)
                .withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(
          SurveyTheme.cardRadius,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(
            SurveyTheme.cardRadius,
          ),

          // ==================================================
          // CARD → DETAIL PAGE
          // ==================================================

          onTap: () {
            _openSurveyDetail(survey);
          },

          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                // ============================================
                // ATAS
                // ============================================

                Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding:
                              const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: SurveyTheme.primary
                                .withValues(
                              alpha: 0.08,
                            ),
                            borderRadius:
                                BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.assignment_outlined,
                            size: 18,
                            color:
                                SurveyTheme.primary,
                          ),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: Text(
                            survey.title,
                            maxLines: 2,
                            overflow:
                                TextOverflow.ellipsis,
                            style: GoogleFonts
                                .plusJakartaSans(
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.w700,
                              color: const Color.fromARGB(255, 48, 61, 61),
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Text(
                      survey.description,
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style: GoogleFonts
                          .plusJakartaSans(
                        fontSize: 13.5,
                        color: const Color.fromARGB(255, 127, 145, 146),
                        height: 1.45,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration:
                          BoxDecoration(
                        color: SurveyTheme.primary
                            .withValues(
                          alpha: 0.08,
                        ),
                        borderRadius:
                            BorderRadius.circular(
                          SurveyTheme.badgeRadius,
                        ),
                        border: Border.all(
                          color: SurveyTheme.primary
                              .withValues(
                            alpha: 0.16,
                          ),
                        ),
                      ),
                      child: Text(
                        survey.categoryName,
                        style: GoogleFonts
                            .plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight:
                              FontWeight.w600,
                          color:
                              SurveyTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),

                // ============================================
                // BAWAH
                // ============================================

                Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),

                    const Divider(
                      color: Color.fromARGB(255, 222, 241, 241),
                      height: 1,
                    ),

                    const SizedBox(height: 10),

                    // ========================================
                    // LOCATION → GOOGLE MAPS
                    // ========================================

                    InkWell(
                      onTap: () {
                        _openSurveyMap(survey);
                      },
                      borderRadius:
                          BorderRadius.circular(8),
                      child: Padding(
                        padding:
                            const EdgeInsets.symmetric(
                          vertical: 4,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              size: 15,
                              color: SurveyTheme
                                  .primaryLight,
                            ),

                            const SizedBox(width: 6),

                            Expanded(
                              child: Text(
                                survey
                                    .formattedCoordinates,
                                maxLines: 1,
                                overflow: TextOverflow
                                    .ellipsis,
                                style: GoogleFonts
                                    .plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight:
                                      FontWeight.w500,
                                  color: const Color.fromARGB(255, 127, 146, 145),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 4),

                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color:
                              Color.fromARGB(255, 168, 181, 185),
                        ),

                        const SizedBox(width: 6),

                        Expanded(
                          child: Text(
                            survey.formattedDate,
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style: GoogleFonts
                                .plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight:
                                  FontWeight.w500,
                              color: SurveyTheme
                                  .textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // LOADING
  // ==========================================================

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor:
                  AlwaysStoppedAnimation<Color>(
                SurveyTheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Memuat daftar survey...',
            style:
                GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color:
                  const Color.fromARGB(255, 127, 146, 143),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // ERROR
  // ==========================================================

  Widget _buildErrorState() {
    return SingleChildScrollView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 28,
          vertical: 60,
        ),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration:
                  const BoxDecoration(
                color: SurveyTheme.errorBg,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.cloud_off_rounded,
                  color: SurveyTheme.error,
                  size: 32,
                ),
              ),
            ),

            const SizedBox(height: 28),

            Text(
              'Gagal Memuat Survey',
              textAlign: TextAlign.center,
              style:
                  GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight:
                    FontWeight.w700,
                color:
                    SurveyTheme.textPrimary,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              _errorMessage ??
                  'Periksa koneksi internet Anda '
                      'dan coba lagi.',
              textAlign: TextAlign.center,
              style:
                  GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                color:
                    const Color.fromARGB(255, 127, 139, 146),
                height: 1.4,
              ),
            ),

            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: () => fetchSurveys(),
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    SurveyTheme.primary,
                foregroundColor:
                    Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 12,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(
                Icons.refresh_rounded,
                size: 18,
              ),
              label: Text(
                'Coba Lagi',
                style:
                    GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // EMPTY
  // ==========================================================

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      child: Center(
        child: Padding(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 28,
            vertical: 60,
          ),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: SurveyTheme.primary
                      .withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.assignment_outlined,
                    color:
                        SurveyTheme.primary,
                    size: 36,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Text(
                'Belum Ada Survey',
                textAlign: TextAlign.center,
                style:
                    GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.w700,
                  color:
                      const Color.fromARGB(255, 48, 59, 61),
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Belum ada data survey yang '
                'tersedia saat ini.',
                textAlign: TextAlign.center,
                style:
                    GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  color:
                      const Color.fromARGB(255, 127, 145, 146),
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 24),

              ElevatedButton.icon(
                onPressed:
                    _handleAddSurvey,
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      SurveyTheme.primary,
                  foregroundColor:
                      Colors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 12,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(
                  Icons.add_rounded,
                  size: 18,
                ),
                label: Text(
                  'Tambah Survey',
                  style:
                      GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // FLOATING BUTTON
  // ==========================================================

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _handleAddSurvey,
      backgroundColor:
          SurveyTheme.primary,
      foregroundColor: const Color.fromARGB(255, 255, 255, 255),
      elevation: 4,
      icon: const Icon(
        Icons.add_rounded,
        size: 22,
      ),
      label: Text(
        'Tambah Survey',
        style:
            GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}