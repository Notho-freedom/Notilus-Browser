import 'package:uuid/uuid.dart';

enum TabState { loading, loaded, error, blank }
enum TabType { web, terminal }

class TabModel {
  final String id;
  final String? url;
  final String? title;
  final String? favicon;
  TabState state;
  final DateTime createdAt;
  bool isPinned;
  bool isSelected;
  String? groupId;
  final TabType type;

  TabModel({
    String? id,
    this.url,
    this.title,
    this.favicon,
    this.state = TabState.blank,
    DateTime? createdAt,
    this.isPinned = false,
    this.isSelected = false,
    this.groupId,
    this.type = TabType.web,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  TabModel copyWith({
    String? id,
    String? url,
    String? title,
    String? favicon,
    TabState? state,
    DateTime? createdAt,
    bool? isPinned,
    bool? isSelected,
    String? groupId,
    TabType? type,
  }) {
    return TabModel(
      id: id ?? this.id,
      url: url ?? this.url,
      title: title ?? this.title,
      favicon: favicon ?? this.favicon,
      state: state ?? this.state,
      createdAt: createdAt ?? this.createdAt,
      isPinned: isPinned ?? this.isPinned,
      isSelected: isSelected ?? this.isSelected,
      groupId: groupId ?? this.groupId,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'title': title,
      'favicon': favicon,
      'state': state.toString(),
      'createdAt': createdAt.toIso8601String(),
      'isPinned': isPinned,
      'isSelected': isSelected,
      'groupId': groupId,
      'type': type.toString(),
    };
  }

  factory TabModel.fromJson(Map<String, dynamic> json) {
    return TabModel(
      id: json['id'],
      url: json['url'],
      title: json['title'],
      favicon: json['favicon'],
      state: TabState.values.firstWhere(
        (e) => e.toString() == json['state'],
        orElse: () => TabState.blank,
      ),
      createdAt: DateTime.parse(json['createdAt']),
      isPinned: json['isPinned'] ?? false,
      isSelected: json['isSelected'] ?? false,
      groupId: json['groupId'],
      type: json['type'] != null
          ? TabType.values.firstWhere(
              (e) => e.toString() == json['type'],
              orElse: () => TabType.web,
            )
          : TabType.web,
    );
  }
}

