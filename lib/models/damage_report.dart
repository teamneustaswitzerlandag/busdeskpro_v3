// Einzelner Schaden mit individueller Dokumentation
class IndividualDamage {
  final String itemId;
  final String itemTitle;
  final String? comment;
  final List<String> photoUrls;
  final DateTime createdAt;

  IndividualDamage({
    required this.itemId,
    required this.itemTitle,
    this.comment,
    required this.photoUrls,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'item_id': itemId,
      'item_title': itemTitle,
      'comment': comment,
      'photo_urls': photoUrls,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory IndividualDamage.fromJson(Map<String, dynamic> json) {
    return IndividualDamage(
      itemId: json['item_id'],
      itemTitle: json['item_title'],
      comment: json['comment'],
      photoUrls: List<String>.from(json['photo_urls'] ?? []),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class DamageReport {
  final String categoryId;
  final String categoryTitle;
  final List<String> selectedDamages;
  final String? comment;
  final List<String> photoUrls;
  final DateTime createdAt;
  final Map<String, IndividualDamage>? individualDamages; // Neue Eigenschaft

  DamageReport({
    required this.categoryId,
    required this.categoryTitle,
    required this.selectedDamages,
    this.comment,
    required this.photoUrls,
    required this.createdAt,
    this.individualDamages,
  });

  Map<String, dynamic> toJson() {
    return {
      'category_id': categoryId,
      'category_title': categoryTitle,
      'selected_damages': selectedDamages,
      'comment': comment,
      'photo_urls': photoUrls,
      'created_at': createdAt.toIso8601String(),
      'individual_damages': individualDamages?.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
    };
  }

  factory DamageReport.fromJson(Map<String, dynamic> json) {
    Map<String, IndividualDamage>? individualDamages;
    if (json['individual_damages'] != null) {
      individualDamages = (json['individual_damages'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, IndividualDamage.fromJson(value)),
      );
    }
    
    return DamageReport(
      categoryId: json['category_id'],
      categoryTitle: json['category_title'],
      selectedDamages: List<String>.from(json['selected_damages']),
      comment: json['comment'],
      photoUrls: List<String>.from(json['photo_urls'] ?? []),
      createdAt: DateTime.parse(json['created_at']),
      individualDamages: individualDamages,
    );
  }
}

class CategoryStatus {
  final String categoryId;
  final bool? isOk; // null = nicht ausgewählt, true = OK, false = Nicht OK
  final bool hasSubItems;
  final List<String> checkedSubItems;
  final List<String> uncheckedSubItems;

  CategoryStatus({
    required this.categoryId,
    this.isOk,
    required this.hasSubItems,
    required this.checkedSubItems,
    required this.uncheckedSubItems,
  });

  bool get hasIssues => isOk == false || uncheckedSubItems.isNotEmpty;
  bool get isSelected => isOk != null;

  Map<String, dynamic> toJson() {
    return {
      'category_id': categoryId,
      'is_ok': isOk ?? false,
      'has_sub_items': hasSubItems,
      'checked_sub_items': checkedSubItems,
      'unchecked_sub_items': uncheckedSubItems,
    };
  }
}

