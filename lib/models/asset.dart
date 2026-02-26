class Asset {
  final int? id;
  final String assetNumber;
  final String description;
  final String location;
  final String remarks;
  final String validate;
  final String? createdAt;
  final String? updatedAt;

  Asset({
    this.id,
    required this.assetNumber,
    required this.description,
    required this.location,
    required this.remarks,
    required this.validate,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'asset_number': assetNumber.trim(),
      'description': description.trim(),
      'location': location.trim(),
      'remarks': remarks.trim(),
      'validate': validate,
      'created_at': (createdAt == null || createdAt!.isEmpty)
          ? DateTime.now().toIso8601String()
          : createdAt,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  factory Asset.fromMap(Map<String, dynamic> map) {
    return Asset(
      id: map['id'],
      assetNumber: map['asset_number'],
      description: map['description'],
      location: map['location'],
      remarks: map['remarks'],
      validate: map['validate'],
      createdAt: map['created_at']?.toString(),
      updatedAt: map['updated_at']?.toString(),
    );
  }
}
