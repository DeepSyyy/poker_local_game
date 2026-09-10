import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:poker_local_game/core/constants/app_colors.dart';
import 'package:poker_local_game/services/poker_server.dart';

class QrConnectDialog extends StatefulWidget {
  final PokerServer server;

  const QrConnectDialog({super.key, required this.server});

  @override
  State<QrConnectDialog> createState() => _QrConnectDialogState();
}

class _QrConnectDialogState extends State<QrConnectDialog> {
  @override
  Widget build(BuildContext context) {
    final url = widget.server.serverUrl;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      backgroundColor: AppColors.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      child: Container(
        width: 380,
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Row(
              children: [
                const Icon(
                  Icons.qr_code_2_rounded,
                  color: AppColors.primary,
                  size: 26,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sambung HP Pemain (QR Code)',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Buka browser HP & scan QR untuk kontrol rahasia',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // QR Code Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(color: Colors.black45, blurRadius: 10),
                ],
              ),
              child: QrImageView(
                data: url,
                version: QrVersions.auto,
                size: 190.0,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),

            // Local URL Text Box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.cardSurfaceElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.language_rounded,
                    size: 16,
                    color: AppColors.gold,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SelectableText(
                      url,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Connected Clients Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'HP Terhubung: ${widget.server.connectedSocketsCount} Perangkat',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'TUTUP DIALOG',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
