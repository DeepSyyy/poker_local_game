/// Model data sederhana yang mendukung parsing JSON
class ItemModel {
  final int id;
  final String title;
  final String description;

  const ItemModel({
    required this.id,
    required this.title,
    required this.description,
  });

  /// Factory untuk konversi dari Map/JSON (berguna saat integrasi REST API)
  factory ItemModel.fromJson(Map<String, dynamic> json) {
    return ItemModel(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
    );
  }

  /// Konversi objek model kembali ke Map/JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
    };
  }
}
