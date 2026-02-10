import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:qr_scanner_app/models/ticket.dart';
import 'package:qr_scanner_app/services/api_service.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_scanner_app/views/add_guest_screen.dart';
import 'package:qr_scanner_app/main.dart';
import 'package:image_picker/image_picker.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _api = ApiService();
  List<Ticket> _tickets = [];
  List<Ticket> _filteredTickets = [];
  bool _isLoading = true;

  // Controller untuk scanner agar bisa dipause/resume
  MobileScannerController cameraController = MobileScannerController();

  // Controller untuk input manual
  final TextEditingController _idController = TextEditingController();

  // Controller untuk pencarian
  final TextEditingController _searchController = TextEditingController();

  bool _isProcessingScan = false;

  @override
  void initState() {
    super.initState();
    _refreshTickets();
  }

  @override
  void dispose() {
    _idController.dispose();
    _searchController.dispose();
    cameraController.dispose();
    super.dispose();
  }

  Future<void> _refreshTickets() async {
    if (_tickets.isEmpty) setState(() => _isLoading = true);
    try {
      final data = await _api.getTickets();
      setState(() {
        _tickets = data;
        _runFilter(_searchController.text);
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memuat tiket: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Menambahkan fungsi delete yang sebelumnya hilang
  Future<void> _deleteTicket(String id) async {
    try {
      // await _api.deleteTicket(id); // Uncomment jika API sudah siap
      setState(() {
        _tickets.removeWhere((ticket) => ticket.id == id);
        _filteredTickets.removeWhere((ticket) => ticket.id == id);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Tiket berhasil dihapus')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menghapus: $e')));
    }
  }

  // Fungsi untuk scan dari galeri
  Future<void> _scanFromGallery() async {
    final ImagePicker picker = ImagePicker();
    // Buka galeri
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return; // User membatalkan pilih gambar

    // Analisa gambar menggunakan MobileScannerController
    final BarcodeCapture? barcodes = await cameraController.analyzeImage(
      image.path,
    );

    if (barcodes != null && barcodes.barcodes.isNotEmpty) {
      final String? code = barcodes.barcodes.first.rawValue;
      if (code != null) {
        _handleScan(code); // Proses hasil scan
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("QR Code tidak terbaca.")));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Tidak ditemukan QR Code pada gambar.")),
      );
    }
  }

  // Fungsi untuk menangani hasil scan di Tab 2
  Future<void> _handleScan(String code) async {
    if (_isProcessingScan) return; // Mencegah scan berulang-ulang secepat kilat
    if (code.isEmpty) return;

    setState(() => _isProcessingScan = true);

    // Cari index tiket berdasarkan ID/Code yang discan
    final int ticketIndex = _tickets.indexWhere((ticket) => ticket.id == code);

    if (ticketIndex == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Gagal: Tiket ID '$code' tidak terdaftar di Guest List!",
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      setState(() => _isProcessingScan = false);
      return; // Stop proses
    }

    final Ticket targetTicket = _tickets[ticketIndex];

    if (targetTicket.status.toLowerCase() == 'redeemed') {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Tiket Sudah Terpakai"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Nama: ${targetTicket.name}"),
              SizedBox(height: 8),
              Text(
                "Tiket ini sudah diredeem sebelumnya.",
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Tutup"),
            ),
          ],
        ),
      );
      setState(() => _isProcessingScan = false);
      return; // Stop proses
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    try {
      // 3. PANGGIL API REDEEM
      _api.scanTicket(targetTicket.id);

      await Future.delayed(Duration(seconds: 1));

      // 4. UPDATE STATUS LOKAL (Agar UI langsung berubah tanpa refresh internet)
      // Kita update status tiket di memori aplikasi menjadi 'Redeemed'
      setState(() {
        _tickets[ticketIndex] = Ticket(
          id: targetTicket.id,
          name: targetTicket.name,
          status: 'REDEEMED',
          createdAt: targetTicket.createdAt,
          redeemedAt: DateTime.now(), // Isi waktu redeem sekarang
        );
      });

      Navigator.pop(context); // Tutup loading dialog
      _idController.clear(); // Bersihkan input manual

      // 5. TAMPILKAN SUKSES
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          icon: Icon(Icons.check_circle, color: Colors.green, size: 50),
          title: Text("Berhasil Redeem!"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Tamu: ${targetTicket.name}",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 5),
              Text("Tiket berhasil divalidasi."),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("OK"),
            ),
          ],
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Tutup loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal Redeem: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // Beri jeda sedikit agar tidak double scan
      await Future.delayed(Duration(seconds: 2));
      setState(() => _isProcessingScan = false);
    }
  }

  // Fungsi untuk menampilkan QR Code dalam Dialog
  void _showQrDialog(Ticket ticket) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          contentPadding: EdgeInsets.all(20),
          content: SizedBox(
            width: 270, // Example size
            height: 300,
            child: Stack(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Ticket QR Code",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 10),
                    // Menampilkan Gambar QR
                    Container(
                      padding: EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Color(0xff9E3B3B),
                          width: 0.3,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: QrImageView(
                        data: ticket.id,
                        version: QrVersions.auto,
                        size: 190,
                      ),
                    ),
                    SizedBox(height: 15),
                    Text(
                      ticket.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      ticket.id,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Positioned(
                  top: -16, // Jarak dari atas
                  right: -16, // Jarak dari kanan
                  child: IconButton(
                    icon: Icon(Icons.close, color: Color(0xff9E3B3B)),
                    splashRadius: 20, // Agar efek kliknya kecil rapi
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Fungsi Logika Pencarian
  void _runFilter(String keyword) {
    List<Ticket> results = [];
    if (keyword.isEmpty) {
      // Jika kosong, tampilkan semua data asli
      results = _tickets;
    } else {
      // Filter berdasarkan Nama (Case Insensitive) ATAU ID
      results = _tickets
          .where(
            (ticket) =>
                ticket.name.toLowerCase().contains(keyword.toLowerCase()) ||
                ticket.id.toLowerCase().contains(keyword.toLowerCase()),
          )
          .toList();
    }

    setState(() {
      _filteredTickets = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color themeColor = Color(0xff9E3B3B);

    final Color containerColor = isDark ? Color(0xFF1E1E1E) : Colors.white70;

    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color borderColor = isDark ? themeColor.withOpacity(0.5) : themeColor;

    final searchInputDecoration = InputDecoration(
      hintText: "Search a Guest...",
      hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
      prefixIcon: Icon(Icons.search, color: Colors.grey),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      filled: true,
      fillColor: isDark ? Colors.black26 : Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: borderColor, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: themeColor),
      ),
    );

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: Container(
            padding: EdgeInsets.symmetric(vertical: 13, horizontal: 20),
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () {
                    themeNotifier.value = isDark
                        ? ThemeMode.light
                        : ThemeMode.dark;
                  },
                  child: Icon(
                    isDark ? Icons.light_mode : Icons.dark_mode,
                    color: themeColor,
                  ),
                ),
                Text(
                  'QR Scanner',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    color: textColor, // Pastikan warna teks kontras
                    fontWeight: FontWeight.bold,
                  ),
                ),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,

                      MaterialPageRoute(builder: (_) => AddGuestScreen()),
                    );
                  },
                  child: Icon(Icons.person_add, color: Color(0xff9E3B3B)),
                ),
              ],
            ),
          ),
        ),
        body: Container(
          // Margin agar terpisah dari AppBar dan pinggir layar
          margin: EdgeInsets.all(16),
          width: double.infinity,
          decoration: BoxDecoration(
            color: containerColor,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(10),
              bottomRight: Radius.circular(10),
            ),
            border: Border.all(color: borderColor, width: 0.2),
          ),
          child: Column(
            children: [
              // 1. TAB BAR (Sekarang ada di dalam Container Body)
              Container(
                decoration: BoxDecoration(
                  // Opsional: Memberi garis batas bawah antara Tab dan Isi
                  border: Border(
                    bottom: BorderSide(color: themeColor, width: 0.2),
                  ),
                ),
                child: TabBar(
                  labelColor: themeColor,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: themeColor,
                  indicatorSize:
                      TabBarIndicatorSize.tab, // Garis indikator selebar tab
                  tabs: [
                    Tab(icon: Icon(Icons.list), text: "Guest List"),
                    Tab(
                      icon: Icon(Icons.qr_code_scanner),
                      text: "Scan & Redeem",
                    ),
                  ],
                ),
              ),

              // 2. ISI TAB (TabBarView)
              // Wajib pakai Expanded agar mengisi sisa ruang di bawah TabBar
              Expanded(
                child: TabBarView(
                  children: [
                    // === TAB 1: Guest List ===
                    Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: TextField(
                            controller: _searchController,
                            onChanged: _runFilter,
                            style: TextStyle(color: textColor),
                            decoration: searchInputDecoration,
                          ),
                        ),
                        Expanded(
                          child: _isLoading
                              ? Center(child: CircularProgressIndicator())
                              : RefreshIndicator(
                                  onRefresh: _refreshTickets,
                                  child: _tickets.isEmpty
                                      ? Center(
                                          child: Text(
                                            "Belum ada guest yang terdaftar.",
                                          ),
                                        )
                                      : ListView.builder(
                                          padding: EdgeInsets.only(
                                            top: 20,
                                            left: 20,
                                            right: 20,
                                          ),
                                          itemCount: _filteredTickets.length,
                                          itemBuilder: (context, index) {
                                            final ticket =
                                                _filteredTickets[index];
                                            return Container(
                                              margin: EdgeInsets.only(
                                                bottom: 12,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: Color(0xff9E3B3B),
                                                  width: 0.2,
                                                ),
                                              ),
                                              child: ListTile(
                                                onTap: () {
                                                  _showQrDialog(ticket);
                                                },
                                                title: Text(ticket.name),
                                                subtitle: Text(ticket.status),
                                                trailing: IconButton(
                                                  icon: Icon(
                                                    Icons.delete,
                                                    color: Colors.red,
                                                  ),
                                                  onPressed: () =>
                                                      _deleteTicket(ticket.id),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                ),
                        ),
                      ],
                    ),

                    // === TAB 2: Scanner ===
                    // ClipRRect agar kamera tidak menembus sudut melengkung container
                    ClipRRect(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(10),
                        bottomRight: Radius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: Stack(
                              children: [
                                MobileScanner(
                                  controller: cameraController,
                                  onDetect: (capture) {
                                    final List<Barcode> barcodes =
                                        capture.barcodes;
                                    for (final barcode in barcodes) {
                                      if (barcode.rawValue != null) {
                                        _handleScan(barcode.rawValue!);
                                      }
                                    }
                                  },
                                ),
                                Center(
                                  child: Container(
                                    width: 200,
                                    height: 200,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: themeColor,
                                        width: 3,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: containerColor,
                              border: Border(
                                top: BorderSide(color: themeColor, width: 0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                InkWell(
                                  onTap: _scanFromGallery,
                                  child: Container(
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                        width: 1,
                                      ),
                                    ),
                                    child: Icon(Icons.image, color: themeColor),
                                  ),
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: _idController,
                                    decoration: InputDecoration(
                                      hintText: "Input Ticket ID Manual...",
                                      hintStyle: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                          color: Colors.grey.shade300,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                          color: themeColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 10),
                                ElevatedButton(
                                  onPressed: () =>
                                      _handleScan(_idController.text),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: themeColor,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Icon(Icons.send, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
