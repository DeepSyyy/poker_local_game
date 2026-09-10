import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:poker_local_game/core/constants/app_colors.dart';
import 'package:poker_local_game/screens/poker/native_companion_screen.dart';

class JoinGameScreen extends StatefulWidget {
  const JoinGameScreen({super.key});

  @override
  State<JoinGameScreen> createState() => _JoinGameScreenState();
}

class _JoinGameScreenState extends State<JoinGameScreen> {
  final TextEditingController _ipController = TextEditingController(
    text: '192.168.1.',
  );
  bool _isScanning = false;
  MobileScannerController? _scannerController;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController();
  }

  @override
  void dispose() {
    _ipController.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  void _connect([String? inputUrl]) {
    final raw = inputUrl ?? _ipController.text.trim();
    if (raw.isEmpty) return;

    // Extract IP:Port from raw string (handles "http://192.168.1.34:8080" or "192.168.1.34")
    String formattedUrl = raw
        .replaceAll('http://', '')
        .replaceAll('https://', '');
    if (formattedUrl.contains('/')) {
      formattedUrl = formattedUrl.split('/').first;
    }
    if (!formattedUrl.contains(':')) {
      formattedUrl = '$formattedUrl:8080';
    }

    if (_isScanning) {
      setState(() => _isScanning = false);
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => NativeCompanionScreen(serverUrl: formattedUrl),
      ),
    );
  }

  void _onDetect(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final code = barcode.rawValue;
      if (code != null && code.isNotEmpty) {
        _scannerController?.stop();
        _connect(code);
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardSurface,
        title: const Text(
          'Gabung Meja Poker',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isScanning
                  ? Icons.keyboard_rounded
                  : Icons.qr_code_scanner_rounded,
              color: AppColors.gold,
            ),
            onPressed: () => setState(() => _isScanning = !_isScanning),
            tooltip: _isScanning ? 'Input IP Manual' : 'Scan QR Kamera',
          ),
        ],
      ),
      body: SafeArea(
        child: _isScanning ? _buildCameraScanner() : _buildManualInput(),
      ),
    );
  }

  Widget _buildCameraScanner() {
    return Stack(
      children: [
        MobileScanner(
          controller: _scannerController,
          onDetect: _onDetect,
          errorBuilder: (context, error, child) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.cardSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.redAccent.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.videocam_off_rounded,
                        color: Colors.redAccent,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Kamera Tidak Tersedia',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Penyebab: Izin kamera belum diberikan atau berjalan di iOS Simulator / Android Emulator.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => setState(() => _isScanning = false),
                        icon: const Icon(Icons.keyboard_rounded),
                        label: const Text('Gunakan Input IP Manual'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),

        // Scanning Frame Overlay
        Center(
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ],
            ),
          ),
        ),

        // Top Hint Banner & Controls
        Positioned(
          top: 20,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.qr_code_2_rounded,
                      color: AppColors.gold,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Arahkan ke QR Code Meja',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.flash_on_rounded,
                        color: AppColors.gold,
                        size: 20,
                      ),
                      onPressed: () => _scannerController?.toggleTorch(),
                      tooltip: 'Lampu Senter',
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.cameraswitch_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () => _scannerController?.switchCamera(),
                      tooltip: 'Ganti Kamera',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Bottom Fallback Button
        Positioned(
          bottom: 20,
          left: 40,
          right: 40,
          child: ElevatedButton.icon(
            onPressed: () => setState(() => _isScanning = false),
            icon: const Icon(Icons.keyboard_rounded),
            label: const Text('Ketik IP Manual Saja'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cardSurface,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildManualInput() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon Header
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: const Icon(
                Icons.qr_code_scanner_rounded,
                size: 36,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'SAMBUNG KE MEJA UTAMA',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Scan QR Code Meja Utama atau ketik IP lokal host di bawah',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),

            // Primary Action: Live Camera Scanner Button
            ElevatedButton.icon(
              onPressed: () => setState(() => _isScanning = true),
              icon: const Icon(Icons.camera_alt_rounded, size: 22),
              label: const Text('SCAN QR CODE DENGAN KAMERA'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 4,
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: const [
                Expanded(child: Divider(color: AppColors.borderSubtle)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    'ATAU KETIK IP MANUAL',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: AppColors.borderSubtle)),
              ],
            ),
            const SizedBox(height: 16),

            // IP Input Box
            TextField(
              controller: _ipController,
              keyboardType: TextInputType.url,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                labelText: 'IP Server Lokal (misal 192.168.1.34)',
                labelStyle: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
                prefixIcon: const Icon(
                  Icons.language_rounded,
                  color: AppColors.gold,
                ),
                filled: true,
                fillColor: AppColors.cardSurfaceElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.borderSubtle),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Connect Button
            ElevatedButton.icon(
              onPressed: () => _connect(),
              icon: const Icon(Icons.login_rounded, size: 20),
              label: const Text('SAMBUNGKAN MANUALLY'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cardSurfaceElevated,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: AppColors.borderSubtle),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
