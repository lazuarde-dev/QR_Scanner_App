import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:qr_scanner_app/services/api_service.dart';

class AddGuestScreen extends StatefulWidget {
  const AddGuestScreen({super.key});

  @override
  State<AddGuestScreen> createState() => _AddGuestScreenState();
}

class _AddGuestScreenState extends State<AddGuestScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controller untuk mengambil teks input
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _isLoading = false;
  String? _generatedQrData;

  // Fungsi saat tombol Save ditekan
  Future<void> _submitGuest() async {
    // 1. Cek Validasi (Apakah form sudah diisi dengan benar?)
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    // Sembunyikan keyboard agar layar lebih lega untuk lihat QR
    FocusScope.of(context).unfocus();

    try {
      await ApiService().addTicket(_nameController.text);

      // Simulasi delay request server
      await Future.delayed(Duration(seconds: 2));

      final String uniqueId = "TIKET-${DateTime.now().millisecondsSinceEpoch}";

      setState(() {
        _generatedQrData = uniqueId; // Simpan data untuk QR
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('QR Code berhasil digenerate!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal generate: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color themeColor = Color(0xff9E3B3B);

    final Color containerColor = isDark ? Color(0xFF1E1E1E) : Colors.white70;

    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color borderColor = isDark ? themeColor.withOpacity(0.5) : themeColor;

    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: themeColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.red, width: 1),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Container(
          padding: EdgeInsets.symmetric(vertical: 13),
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: containerColor, // Warna Background
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(10),
              topRight: Radius.circular(10),
            ), // Membuat sudut melengkung
            border: Border.all(
              color: borderColor, // Warna Garis Tepi (Border)
              width: 0.2, // Ketebalan Garis
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // --- Tombol Back (Kiri) ---
              Positioned(
                left: -15,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    Icons.arrow_back_ios_new, // Icon panah yang lebih modern
                    color: textColor,
                    size: 20,
                  ),
                  onPressed: () {
                    Navigator.pop(context); // Fungsi kembali
                  },
                ),
              ),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 90),
                child: Text(
                  "Create New Guest",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Container(
        margin: EdgeInsets.all(16), // Margin kiri kanan saja
        width: double.infinity,
        height: double.infinity, // Agar container mengisi layar ke bawah
        decoration: BoxDecoration(
          color: containerColor,
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(10),
            bottomRight: Radius.circular(10),
          ),
          border: Border.all(color: borderColor, width: 0.2),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // INPUT NAMA
                Text(
                  "Full Name",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: inputDecoration.copyWith(
                    hintText: "Ex: John Doe",
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Nama wajib diisi';
                    return null;
                  },
                ),
                SizedBox(height: 20),

                // INPUT EMAIL
                Text(
                  "Email Address",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: inputDecoration.copyWith(
                    hintText: "Ex: john@email.com",
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Email wajib diisi';
                    if (!value.contains('@')) return 'Email tidak valid';
                    return null;
                  },
                ),
                SizedBox(height: 20),

                // INPUT PHONE (Opsional)
                Text(
                  "Phone Number",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: inputDecoration.copyWith(
                    hintText: "Ex: 08123456789",
                  ),
                ),
                SizedBox(height: 30),

                // TOMBOL SAVE
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitGuest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(
                            "Generate QR Code",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                SizedBox(height: 30),
                // === AREA HASIL QR CODE ===
                if (_generatedQrData != null)
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(
                              color: Color(0xff9E3B3B),
                              width: 0.3,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: QrImageView(
                            data:
                                _generatedQrData!, // Data UUID yang digenerate
                            version: QrVersions.auto,
                            size: 270.0,
                            foregroundColor: Colors.black,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          _generatedQrData!,
                          style: TextStyle(
                            color: themeColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        SizedBox(height: 30), // Ruang kosong tambahan di bawah
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
