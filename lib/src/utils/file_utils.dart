import 'dart:math';

class FileUtils {
  static String formatFileSize(int bytes) {
    if (bytes == 0) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB'];
    final i = (log(bytes.toDouble()) / log(k)).floor();
    final index = i.clamp(0, sizes.length - 1);
    return '${(bytes / pow(k, index)).toStringAsFixed(1)} ${sizes[index]}';
  }

  static String formatDateTime(int timestamp) {
    if (timestamp == 0) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final year = dt.year;
    final month = dt.month;
    final day = dt.day;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    final second = dt.second.toString().padLeft(2, '0');
    
    return '$year年$month月$day日，$hour:$minute:$second';
  }
}
