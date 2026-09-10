import 'package:belajar_flutter/models/item_model.dart';

/// Service untuk mengambil data (simulasi pemanggilan API/backend)
class ItemService {
  /// Mengambil daftar item dengan simulasi delay jaringan
  Future<List<ItemModel>> fetchItems() async {
    // Simulasi waktu tunggu koneksi server
    await Future.delayed(const Duration(milliseconds: 600));

    return const [
      ItemModel(
        id: 1,
        title: 'Widget & Layout Dasar',
        description: 'Mempelajari Scaffold, Column, Row, dan Container.',
      ),
      ItemModel(
        id: 2,
        title: 'State Management',
        description: 'Memahami cara kerja setState dan siklus hidup widget.',
      ),
      ItemModel(
        id: 3,
        title: 'Struktur Folder Modular',
        description: 'Memisahkan model, service, screen, dan widget reusable.',
      ),
    ];
  }
}
