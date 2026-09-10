import 'package:flutter/material.dart';
import 'package:belajar_flutter/models/item_model.dart';
import 'package:belajar_flutter/services/item_service.dart';
import 'package:belajar_flutter/screens/home/widgets/counter_display.dart';
import 'package:belajar_flutter/widgets/custom_button.dart';

/// Halaman Home utama aplikasi
class HomeScreen extends StatefulWidget {
  final String title;

  const HomeScreen({super.key, required this.title});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _counter = 0;
  final ItemService _itemService = ItemService();
  List<ItemModel> _items = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    final data = await _itemService.fetchItems();
    setState(() {
      _items = data;
      _isLoading = false;
    });
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  void _resetCounter() {
    setState(() {
      _counter = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat Ulang Data',
            onPressed: _loadItems,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Widget Counter modular
            CounterDisplay(count: _counter),
            const SizedBox(height: 12),

            // Tombol aksi custom
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    label: 'Reset Counter',
                    icon: Icons.restart_alt,
                    onPressed: _resetCounter,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Bagian Daftar Data (Service integration)
            const Text(
              'Modul Belajar (Data dari ItemService):',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.separated(
                      itemCount: _items.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        return Card(
                          elevation: 1,
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text('${item.id}'),
                            ),
                            title: Text(
                              item.title,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(item.description),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Tambah Counter',
        child: const Icon(Icons.add),
      ),
    );
  }
}
