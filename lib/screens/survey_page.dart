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
  static const Color primary = Color(0xFF68D5D9);
  static const Color primaryLight = Color(0xFF87E4DF);
  static const Color primaryDark = Color(0xFF4FA4B9);

  static const Color background = Color(0xFFF5FAFA);
  static const Color surface = Colors.white;

  static const Color textPrimary = Color(0xFF303D3D);
  static const Color textSecondary = Color(0xFF7F9192);
  static const Color textMuted = Color(0xFFA8B5B9);

  static const Color border = Color(0xFFDEEEEE);
  static const Color error = Color(0xFFE05252);
  static const Color errorBg = Color(0xFFFFF0F0);
  static const Color success = Color(0xFF10B981);

  static const double mobileBreakpoint = 600;
  static const double desktopBreakpoint = 1024;
  static const double maxContentWidth = 1100;
  static const double cardRadius = 16;
  static const double badgeRadius = 8;

  static EdgeInsets getPagePadding(double width) {
    if (width >= desktopBreakpoint) {
      return const EdgeInsets.symmetric(
        horizontal: 32,
        vertical: 24,
      );
    }

    if (width > mobileBreakpoint) {
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
  static const String _surveyEndpoint =
      'https://sijala.biz.id/api/v1/surveys';

  List<Survey> _surveys = [];

  bool _isLoading = true;
  bool _isRefreshing = false;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    fetchSurveys();
  }

  // ==========================================================
  // FETCH SURVEYS
  // ==========================================================

  Future<void> fetchSurveys({
    bool isRefresh = false,
  }) async {
    if (isRefresh) {
      if (_isRefreshing) return;
      _isRefreshing = true;
    } else {
      if (!mounted) return;

      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.trim().isEmpty) {
        if (!mounted) return;

        _showSnackBar(
          'Sesi telah berakhir. Silakan login kembali.',
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
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 401) {
        await prefs.remove('token');
        await prefs.remove('user');

        if (!mounted) return;

        _showSnackBar(
          'Sesi telah berakhir. Silakan login kembali.',
          isSuccess: false,
        );

        context.go(AppRouter.login);
        return;
      }

      if (response.statusCode != 200) {
        throw Exception(
          'Gagal memuat survey '
          '(Kode: ${response.statusCode}).',
        );
      }

      final dynamic decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw Exception('Format respons API tidak sesuai.');
      }

      if (decoded['status'] != true) {
        throw Exception(
          decoded['message']?.toString() ??
              'Gagal memuat daftar survey.',
        );
      }

      final dynamic data = decoded['data'];
      final List<Survey> loadedSurveys = [];

      if (data is List) {
        for (final item in data) {
          if (item is Map<String, dynamic>) {
            loadedSurveys.add(Survey.fromJson(item));
          } else if (item is Map) {
            loadedSurveys.add(
              Survey.fromJson(
                Map<String, dynamic>.from(item),
              ),
            );
          }
        }
      }

      if (!mounted) return;

      setState(() {
        _surveys = loadedSurveys;
        _errorMessage = null;
      });
    } on SocketException {
      _handleFetchError(
        'Tidak dapat terhubung ke server. '
        'Periksa koneksi internet kamu.',
        isRefresh: isRefresh,
      );
    } on TimeoutException {
      _handleFetchError(
        'Koneksi terlalu lama. Silakan coba lagi.',
        isRefresh: isRefresh,
      );
    } on FormatException {
      _handleFetchError(
        'Respons server tidak dapat dibaca.',
        isRefresh: isRefresh,
      );
    } catch (e) {
      _handleFetchError(
        e.toString().replaceFirst('Exception: ', ''),
        isRefresh: isRefresh,
      );
    } finally {
      _isRefreshing = false;

      if (mounted) {
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
      if (!isRefresh || _surveys.isEmpty) {
        _errorMessage = message;
      }
    });

    if (isRefresh) {
      _showSnackBar(message, isSuccess: false);
    }
  }

  // ==========================================================
  // ADD SURVEY
  // ==========================================================

  Future<void> _handleAddSurvey() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => const SurveyFormPage(),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      await fetchSurveys(isRefresh: true);
    }
  }

  // ==========================================================
  // OPEN DETAIL
  // ==========================================================

  Future<void> _openSurveyDetail(Survey survey) async {
    final surveyId = int.tryParse(survey.id.toString());

    if (surveyId == null) {
      _showSnackBar(
        'ID survey tidak valid.',
        isSuccess: false,
      );
      return;
    }

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => SurveyDetailPage(
          surveyId: surveyId,
        ),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      await fetchSurveys(isRefresh: true);
    }
  }

  // ==========================================================
  // GOOGLE MAPS
  // ==========================================================

  Future<void> _openSurveyMap(Survey survey) async {
    if (survey.latitude == null ||
        survey.longitude == null) {
      _showSnackBar(
        'Lokasi survey tidak tersedia.',
        isSuccess: false,
      );
      return;
    }

    final uri = Uri.https(
      'www.google.com',
      '/maps/search/',
      {
        'api': '1',
        'query': '${survey.latitude},${survey.longitude}',
      },
    );

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        _showSnackBar(
          'Tidak dapat membuka Google Maps.',
          isSuccess: false,
        );
      }
    } catch (_) {
      if (!mounted) return;

      _showSnackBar(
        'Tidak dapat membuka Google Maps.',
        isSuccess: false,
      );
    }
  }

  // ==========================================================
  // SNACKBAR
  // ==========================================================

  void _showSnackBar(
    String message, {
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
          horizontal: 20,
          vertical: 12,
        ),
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
                  fontSize: 13,
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
    final screenWidth = MediaQuery.sizeOf(context).width;
    final padding = SurveyTheme.getPagePadding(screenWidth);

    return Scaffold(
      backgroundColor: SurveyTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: RefreshIndicator(
                color: SurveyTheme.primaryDark,
                backgroundColor: Colors.white,
                onRefresh: () => fetchSurveys(isRefresh: true),
                child: _buildBodyContent(
                  screenWidth: screenWidth,
                  padding: padding,
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
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
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  SurveyTheme.primaryLight,
                  SurveyTheme.primaryDark,
                ],
              ),
              borderRadius: BorderRadius.circular(13),
              boxShadow: [
                BoxShadow(
                  color: SurveyTheme.primaryDark.withValues(
                    alpha: 0.18,
                  ),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.assignment_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Survey',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: SurveyTheme.textPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
                Text(
                  'Daftar hasil survey',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: SurveyTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: () => fetchSurveys(isRefresh: true),
            icon: const Icon(
              Icons.refresh_rounded,
              color: SurveyTheme.primaryDark,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // BODY CONTENT
  // ==========================================================

  Widget _buildBodyContent({
    required double screenWidth,
    required EdgeInsets padding,
  }) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null && _surveys.isEmpty) {
      return _buildErrorState();
    }

    if (_surveys.isEmpty) {
      return _buildEmptyState();
    }

    return _buildResponsiveSurveyList(
      screenWidth: screenWidth,
      padding: padding,
    );
  }

  // ==========================================================
  // RESPONSIVE LIST
  // SETIAP CARD SATU PER BARIS
  // CARD MEMENUHI LEBAR HALAMAN
  // ==========================================================

  Widget _buildResponsiveSurveyList({
    required double screenWidth,
    required EdgeInsets padding,
  }) {
    final contentPadding = padding.copyWith(
      bottom: padding.bottom + 88,
    );

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: contentPadding,
      itemCount: _surveys.length,
      separatorBuilder: (context, index) {
        return const SizedBox(height: 16);
      },
      itemBuilder: (context, index) {
        return SizedBox(
          width: double.infinity,
          child: _buildSurveyCard(_surveys[index]),
        );
      },
    );
  }

  // ==========================================================
  // SURVEY CARD
  // ==========================================================

  Widget _buildSurveyCard(Survey survey) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: SurveyTheme.surface,
        borderRadius: BorderRadius.circular(
          SurveyTheme.cardRadius,
        ),
        border: Border.all(
          color: SurveyTheme.border,
        ),
        boxShadow: [
          BoxShadow(
            color: SurveyTheme.primaryDark.withValues(
              alpha: 0.06,
            ),
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
          onTap: () => _openSurveyDetail(survey),
          child: Padding(
            padding: const EdgeInsets.all(17),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: SurveyTheme.primary.withValues(
                              alpha: 0.12,
                            ),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: const Icon(
                            Icons.assignment_outlined,
                            size: 19,
                            color: SurveyTheme.primaryDark,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            survey.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: SurveyTheme.textPrimary,
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
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        color: SurveyTheme.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: SurveyTheme.primary.withValues(
                          alpha: 0.12,
                        ),
                        borderRadius: BorderRadius.circular(
                          SurveyTheme.badgeRadius,
                        ),
                      ),
                      child: Text(
                        survey.categoryName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: SurveyTheme.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Divider(
                      color: SurveyTheme.border,
                      height: 18,
                    ),
                    InkWell(
                      onTap: () => _openSurveyMap(survey),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 3,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              size: 16,
                              color: SurveyTheme.primaryDark,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                survey.formattedCoordinates,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: SurveyTheme.textSecondary,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.open_in_new_rounded,
                              size: 13,
                              color: SurveyTheme.textMuted,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: SurveyTheme.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            survey.formattedDate,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: SurveyTheme.textMuted,
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
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.55,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 38,
                height: 38,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    SurveyTheme.primaryDark,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Memuat daftar survey...',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: SurveyTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // ERROR
  // ==========================================================

  Widget _buildErrorState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.6,
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: const BoxDecoration(
                    color: SurveyTheme.errorBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.cloud_off_rounded,
                    color: SurveyTheme.error,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Gagal Memuat Survey',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: SurveyTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage ??
                      'Periksa koneksi internet dan coba lagi.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: SurveyTheme.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 22),
                ElevatedButton.icon(
                  onPressed: () => fetchSurveys(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Coba Lagi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SurveyTheme.primaryDark,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // EMPTY
  // ==========================================================

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.6,
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: SurveyTheme.primary.withValues(
                      alpha: 0.12,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.assignment_outlined,
                    color: SurveyTheme.primaryDark,
                    size: 38,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Belum Ada Survey',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: SurveyTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Belum ada data survey yang tersedia saat ini.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: SurveyTheme.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 22),
                ElevatedButton.icon(
                  onPressed: _handleAddSurvey,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Tambah Survey'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SurveyTheme.primaryDark,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // FLOATING BUTTON
  // ==========================================================

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _handleAddSurvey,
      backgroundColor: SurveyTheme.primaryDark,
      foregroundColor: Colors.white,
      elevation: 4,
      icon: const Icon(Icons.add_rounded),
      label: Text(
        'Tambah Survey',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}