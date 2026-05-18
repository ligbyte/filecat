class FileItem {
  final String name;
  final bool isDir;
  final int size;
  final int modified;
  final String path;

  FileItem({
    required this.name,
    required this.isDir,
    required this.size,
    required this.modified,
    required this.path,
  });

  factory FileItem.fromJson(Map<String, dynamic> json) {
    return FileItem(
      name: json['name'] as String,
      isDir: json['is_dir'] as bool,
      size: json['size'] as int,
      modified: json['modified'] as int? ?? 0,
      path: json['path'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'is_dir': isDir,
      'size': size,
      'modified': modified,
      'path': path,
    };
  }
}
