import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../routes/app_router.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;

  @override
  void initState() {
    super.initState(); 

    // Hapus notifikasi lama ketika halaman Login dibuka.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    });
  }

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://sijala.biz.id/api/v1/login'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': emailController.text.trim(),
          'password': passwordController.text,
        }),
      );

      print('STATUS LOGIN: ${response.statusCode}');
      print('RESPONSE LOGIN: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 &&
          data['status'] == true) {
        final userData = data['data'];

        if (userData == null) {
          throw Exception('Data user tidak ditemukan.');
        }

        final token = userData['token'];

        if (token == null || token.toString().isEmpty) {
          throw Exception('Token tidak ditemukan.');
        }

        final prefs = await SharedPreferences.getInstance();

        // Simpan token
        await prefs.setString(
          'token',
          token.toString(),
        );

        // Simpan data user
        await prefs.setString(
          'user',
          jsonEncode(userData),
        );

        // Simpan email
        await prefs.setString(
          'email',
          emailController.text.trim(),
        );

        if (!mounted) return;

        // Langsung menuju dashboard tanpa notifikasi.
        context.go(AppRouter.dashboard);
      } else {
        // Login gagal tidak menampilkan SnackBar.
        // Pesan kesalahan tidak ditampilkan sebagai notifikasi.
        debugPrint(
          'Login gagal: ${data['message'] ?? 'Email atau password salah.'}',
        );
      }
    } catch (e) {
      // Tidak menampilkan notifikasi ketika terjadi kesalahan.
      debugPrint(
        'Terjadi kesalahan saat login: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color.fromARGB(255, 104, 209, 217);
    const primaryDark = Color.fromARGB(255, 79, 185, 180);
    const backgroundColor = Color.fromARGB(255, 248, 254, 255);
    const textColor = Color.fromARGB(255, 48, 59, 61);
    const secondaryText = Color.fromARGB(255, 127, 146, 145);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Login',
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        iconTheme: const IconThemeData(
          color: primaryColor,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 30),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),

                  // ICON
                  Container(
                    width: 92,
                    height: 92,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 100,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          primaryColor,
                          Color.fromARGB(255, 135, 228, 228),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.25),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.assignment_rounded,
                      size: 46,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'FIELD SURVEY',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                      letterSpacing: 1,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Selamat Datang! Silakan login untuk melanjutkan.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: secondaryText,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // EMAIL
                  const Text(
                    'Email',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),

                  const SizedBox(height: 8),

                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'Masukkan email Anda',
                      hintStyle: const TextStyle(
                        color: Color(0xFFB9A8A8),
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(
                        Icons.email_outlined,
                        color: primaryColor,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color(0xFFF1DEDE),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color.fromARGB(255, 222, 241, 240),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: primaryColor,
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 17,
                        horizontal: 16,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email wajib diisi';
                      }

                      if (!value.contains('@')) {
                        return 'Format email tidak valid';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 18),

                  // PASSWORD
                  const Text(
                    'Password',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),

                  const SizedBox(height: 8),

                  TextFormField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    decoration: InputDecoration(
                      hintText: 'Masukkan password Anda',
                      hintStyle: const TextStyle(
                        color: Color.fromARGB(255, 168, 185, 185),
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(
                        Icons.lock_outline_rounded,
                        color: primaryColor,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: const Color.fromARGB(
                            255,
                            140,
                            158,
                            158,
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color.fromARGB(255, 222, 241, 241),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color.fromARGB(255, 222, 240, 241),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: primaryColor,
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 17,
                        horizontal: 16,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password wajib diisi';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // LOGIN BUTTON
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        disabledBackgroundColor:
                            primaryColor.withOpacity(0.55),
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: primaryColor.withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 23,
                              height: 23,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // REGISTER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Belum punya akun? ',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: secondaryText,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          context.go(AppRouter.register);
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                          ),
                        ),
                        child: const Text(
                          'Daftar',
                          style: TextStyle(
                            color: primaryDark,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
