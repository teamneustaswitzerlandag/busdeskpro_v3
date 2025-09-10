class ChecklistItem {
  final String id;
  final String groupId;
  final String projectId;
  final String? parentId;
  final String title;
  final String description;
  final int orderIndex;
  final int level;
  final String createdBy;
  final String createdByEmail;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool completed;
  final dynamic completionInfo;

  ChecklistItem({
    required this.id,
    required this.groupId,
    required this.projectId,
    this.parentId,
    required this.title,
    required this.description,
    required this.orderIndex,
    required this.level,
    required this.createdBy,
    required this.createdByEmail,
    required this.createdAt,
    required this.updatedAt,
    required this.completed,
    this.completionInfo,
  });

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      id: json['id'],
      groupId: json['group_id'],
      projectId: json['project_id'],
      parentId: json['parent_id'],
      title: json['title'],
      description: json['description'],
      orderIndex: json['order_index'],
      level: json['level'],
      createdBy: json['created_by'],
      createdByEmail: json['created_by_email'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      completed: json['completed'] ?? false,
      completionInfo: json['completion_info'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'project_id': projectId,
      'parent_id': parentId,
      'title': title,
      'description': description,
      'order_index': orderIndex,
      'level': level,
      'created_by': createdBy,
      'created_by_email': createdByEmail,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'completed': completed,
      'completion_info': completionInfo,
    };
  }

  ChecklistItem copyWith({
    String? id,
    String? groupId,
    String? projectId,
    String? parentId,
    String? title,
    String? description,
    int? orderIndex,
    int? level,
    String? createdBy,
    String? createdByEmail,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? completed,
    dynamic completionInfo,
  }) {
    return ChecklistItem(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      projectId: projectId ?? this.projectId,
      parentId: parentId ?? this.parentId,
      title: title ?? this.title,
      description: description ?? this.description,
      orderIndex: orderIndex ?? this.orderIndex,
      level: level ?? this.level,
      createdBy: createdBy ?? this.createdBy,
      createdByEmail: createdByEmail ?? this.createdByEmail,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completed: completed ?? this.completed,
      completionInfo: completionInfo ?? this.completionInfo,
    );
  }
}
