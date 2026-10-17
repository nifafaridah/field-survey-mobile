import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneController = TextEditingController();

  String? gender;

  bool isPasswordVisible = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color.fromARGB(255, 104, 217, 217);
    const primaryDark = Color.fromARGB(255, 79, 185, 176);
    const backgroundColor = Color.fromARGB(255, 248, 254, 255);
    const textColor = Color.fromARGB(255, 48, 61, 61);
    const secondaryText = Color.fromARGB(255, 127, 142, 146);
    const borderColor = Color.fromARGB(255, 222, 240, 241);

    return Scaffold(
      backgroundColor: backgroundColor,

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,

        title: const Text(
          'Register',
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
          physics:
              const BouncingScrollPhysics(),

          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              24,
              10,
              24,
              30,
            ),

            child: Form(
              key: _formKey,

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.stretch,

                children: [
                  const SizedBox(height: 8),

                  // ============================
                  // ICON
                  // ============================

                  Container(
                    width: 92,
                    height: 92,

                    margin:
                        const EdgeInsets.symmetric(
                      horizontal: 100,
                    ),

                    decoration:
                        BoxDecoration(
                      gradient:
                          const LinearGradient(
                        colors: [
                          Color.fromARGB(255, 104, 217, 189),
                          Color.fromARGB(255, 135, 228, 216),
                        ],

                        begin:
                            Alignment.topLeft,
                        end:
                            Alignment.bottomRight,
                      ),

                      borderRadius:
                          BorderRadius.circular(28),

                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color.fromARGB(255, 104, 191, 217)
                                  .withOpacity(0.25),

                          blurRadius: 20,

                          offset:
                              const Offset(0, 8),
                        ),
                      ],
                    ),

                    child: const Icon(
                      Icons.person_add_alt_1_rounded,
                      size: 45,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'BUAT AKUN BARU',
                    textAlign: TextAlign.center,

                    style: TextStyle(
                      fontSize: 24,
                      fontWeight:
                          FontWeight.w900,
                      color: textColor,
                      letterSpacing: 0.5,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Silakan lengkapi data diri Anda',
                    textAlign: TextAlign.center,

                    style: TextStyle(
                      fontSize: 13,
                      color: Color.fromARGB(255, 127, 146, 143),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ============================
                  // NAMA
                  // ============================

                  const Text(
                    'Nama Lengkap',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          FontWeight.w700,
                      color: textColor,
                    ),
                  ),

                  const SizedBox(height: 8),

                  TextFormField(
                    controller:
                        nameController,

                    keyboardType:
                        TextInputType.name,

                    decoration:
                        _inputDecoration(
                      hint:
                          'Masukkan nama lengkap',
                      icon:
                          Icons.person_outline_rounded,
                      primaryColor:
                          const Color.fromARGB(255, 104, 217, 211),
                      borderColor:
                          borderColor,
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ============================
                  // EMAIL
                  // ============================

                  const Text(
                    'Email',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          FontWeight.w700,
                      color: textColor,
                    ),
                  ),

                  const SizedBox(height: 8),

                  TextFormField(
                    controller:
                        emailController,

                    keyboardType:
                        TextInputType.emailAddress,

                    decoration:
                        _inputDecoration(
                      hint:
                          'Masukkan email',
                      icon:
                          Icons.email_outlined,
                      primaryColor:
                          primaryColor,
                      borderColor:
                          borderColor,
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ============================
                  // PASSWORD
                  // ============================

                  const Text(
                    'Password',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          FontWeight.w700,
                      color: textColor,
                    ),
                  ),

                  const SizedBox(height: 8),

                  TextFormField(
                    controller:
                        passwordController,

                    obscureText:
                        isPasswordVisible,

                    decoration:
                        InputDecoration(
                      hintText:
                          'Masukkan password',

                      hintStyle:
                          const TextStyle(
                        color:
                            Color.fromARGB(255, 168, 183, 185),
                        fontSize: 13,
                      ),

                      prefixIcon:
                          const Icon(
                        Icons.lock_outline_rounded,
                        color: Color.fromARGB(255, 104, 209, 217),
                      ),

                      suffixIcon:
                          IconButton(
                        icon: Icon(
                          isPasswordVisible
                              ? Icons
                                  .visibility_rounded
                              : Icons
                                  .visibility_off_rounded,

                          color:
                              const Color.fromARGB(255, 140, 155, 158),
                        ),

                        onPressed: () {
                          setState(() {
                            isPasswordVisible =
                                !isPasswordVisible;
                          });
                        },
                      ),

                      filled: true,
                      fillColor: Colors.white,

                      border:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(16),
                        borderSide:
                            const BorderSide(
                          color: borderColor,
                        ),
                      ),

                      enabledBorder:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(16),
                        borderSide:
                            const BorderSide(
                          color: borderColor,
                        ),
                      ),

                      focusedBorder:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(16),
                        borderSide:
                            const BorderSide(
                          color: primaryColor,
                          width: 1.5,
                        ),
                      ),

                      contentPadding:
                          const EdgeInsets.symmetric(
                        vertical: 17,
                        horizontal: 16,
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ============================
                  // GENDER
                  // ============================

                  const Text(
                    'Jenis Kelamin',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: gender,

                    decoration:
                        InputDecoration(
                      hintText:
                          'Pilih jenis kelamin',

                      hintStyle:
                          const TextStyle(
                        color:
                            Color.fromARGB(255, 168, 184, 185),
                        fontSize: 13,
                      ),

                      prefixIcon:
                          const Icon(
                        Icons.wc_rounded,
                        color: primaryColor,
                      ),

                      filled: true,
                      fillColor: Colors.white,

                      border:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(16),
                        borderSide:
                            const BorderSide(
                          color: borderColor,
                        ),
                      ),

                      enabledBorder:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(16),
                        borderSide:
                            const BorderSide(
                          color: borderColor,
                        ),
                      ),

                      focusedBorder:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(16),
                        borderSide:
                            const BorderSide(
                          color: primaryColor,
                          width: 1.5,
                        ),
                      ),
                    ),

                    items: const [
                      DropdownMenuItem(
                        value: "Laki-Laki",
                        child:
                            Text("Laki-Laki"),
                      ),

                      DropdownMenuItem(
                        value: "Perempuan",
                        child:
                            Text("Perempuan"),
                      ),
                    ],

                    onChanged: (value) {
                      setState(() {
                        gender = value;
                      });
                    },
                  ),

                  const SizedBox(height: 18),

                  // ============================
                  // PHONE
                  // ============================

                  const Text(
                    'Nomor Telepon / WhatsApp',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          FontWeight.w700,
                      color: textColor,
                    ),
                  ),

                  const SizedBox(height: 8),

                  TextFormField(
                    controller:
                        phoneController,

                    keyboardType:
                        TextInputType.phone,

                    decoration:
                        _inputDecoration(
                      hint:
                          'Masukkan nomor telepon',
                      icon:
                          Icons.phone_outlined,
                      primaryColor:
                          primaryColor,
                      borderColor:
                          borderColor,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ============================
                  // DAFTAR
                  // ============================

                  SizedBox(
                    height: 54,

                    child: ElevatedButton(
                      onPressed: () {
                        // Aksi registrasi di sini,
                        // lalu arahkan kembali ke login
                        // atau dashboard

                        context.go("/dashboard");
                      },

                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            primaryColor,

                        foregroundColor:
                            Colors.white,

                        elevation: 4,

                        shadowColor:
                            primaryColor
                                .withOpacity(0.3),

                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(16),
                        ),
                      ),

                      child: const Text(
                        "DAFTAR",

                        style: TextStyle(
                          fontSize: 15,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ============================
                  // LOGIN
                  // ============================

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,

                    children: [
                      const Text(
                        'Sudah punya akun? ',
                        style: TextStyle(
                          fontSize: 12.5,
                          color:
                              secondaryText,
                        ),
                      ),

                      TextButton(
                        onPressed: () {
                          context.go("/");
                        },

                        style:
                            TextButton.styleFrom(
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 4,
                          ),
                        ),

                        child: const Text(
                          "Login",
                          style: TextStyle(
                            color:
                                primaryDark,
                            fontSize: 13,
                            fontWeight:
                                FontWeight.w800,
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

  // ==========================================================
  // INPUT DECORATION
  // Ini hanya helper tampilan
  // ==========================================================

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    required Color primaryColor,
    required Color borderColor,
  }) {
    return InputDecoration(
      hintText: hint,

      hintStyle: const TextStyle(
        color: Color.fromARGB(255, 168, 182, 185),
        fontSize: 13,
      ),

      prefixIcon: Icon(
        icon,
        color: primaryColor,
      ),

      filled: true,
      fillColor: Colors.white,

      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(16),

        borderSide: BorderSide(
          color: borderColor,
        ),
      ),

      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(16),

        borderSide: BorderSide(
          color: borderColor,
        ),
      ),

      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(16),

        borderSide: BorderSide(
          color: primaryColor,
          width: 1.5,
        ),
      ),

      contentPadding:
          const EdgeInsets.symmetric(
        vertical: 17,
        horizontal: 16,
      ),
    );
  }
}