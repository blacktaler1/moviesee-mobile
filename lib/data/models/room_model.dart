class RoomModel {
  final int id;
  final String code;
  final String name;
  final String? videoUrl;
  final int? createdBy;

  const RoomModel({
    required this.id,
    required this.code,
    required this.name,
    this.videoUrl,
    this.createdBy,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) => RoomModel(
        id: json['id'] as int,
        code: json['code'] as String,
        name: json['name'] as String,
        videoUrl: json['video_url'] as String?,
        createdBy: json['created_by'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'name': name,
        if (videoUrl != null) 'video_url': videoUrl,
        if (createdBy != null) 'created_by': createdBy,
      };
}
