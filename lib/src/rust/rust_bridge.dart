import 'dart:ffi';
import 'dart:io';
import 'dart:convert';
import 'package:ffi/ffi.dart';

class RustBridge {
  static late DynamicLibrary _dylib;
  
  // FFI lookup signatures
  static late Pointer<NativeFunction<Pointer Function(Pointer)>> _createFile;
  static late Pointer<NativeFunction<Pointer Function(Pointer)>> _readFile;
  static late Pointer<NativeFunction<Pointer Function(Pointer, Pointer)>> _writeFile;
  static late Pointer<NativeFunction<Pointer Function(Pointer)>> _getFileInfo;
  static late Pointer<NativeFunction<Pointer Function(Pointer)>> _deleteFile;
  static late Pointer<NativeFunction<Pointer Function()>> _getFilecatPath;
  static late Pointer<NativeFunction<Pointer Function(Pointer)>> _listDirectory;
  static late Pointer<NativeFunction<Void Function(Pointer)>> _freeString;
  
  // New static server functions
  static late Pointer<NativeFunction<Pointer Function(Pointer)>> _startStaticServer;
  static late Pointer<NativeFunction<Pointer Function()>> _stopStaticServer;
  static late Pointer<NativeFunction<Pointer Function(Pointer)>> _updateServerPath;
  static late Pointer<NativeFunction<Pointer Function()>> _getLocalIp;
  static late Pointer<NativeFunction<Pointer Function(Pointer)>> _enableAutostart;
  static late Pointer<NativeFunction<Pointer Function(Pointer)>> _disableAutostart;
  static late Pointer<NativeFunction<Pointer Function(Pointer)>> _isAutostartEnabled;
  static late Pointer<NativeFunction<Pointer Function()>> _isServerRunning;

  static void initialize() {
    String libraryPath = '';

    if (Platform.isWindows) {
      libraryPath = 'filecat.dll';
    } else if (Platform.isLinux) {
      libraryPath = 'libfilecat.so';
    } else if (Platform.isMacOS) {
      libraryPath = 'libfilecat.dylib';
    }

    _dylib = DynamicLibrary.open(libraryPath);

    _createFile = _dylib.lookup('create_file');
    _readFile = _dylib.lookup('read_file');
    _writeFile = _dylib.lookup('write_file');
    _getFileInfo = _dylib.lookup('get_file_info');
    _deleteFile = _dylib.lookup('delete_file');
    _getFilecatPath = _dylib.lookup('get_filecat_path');
    _listDirectory = _dylib.lookup('list_directory');
    _freeString = _dylib.lookup('free_string');
    
    _startStaticServer = _dylib.lookup('start_static_server');
    _stopStaticServer = _dylib.lookup('stop_static_server');
    _updateServerPath = _dylib.lookup('update_server_path');
    _getLocalIp = _dylib.lookup('get_local_ip');
    _enableAutostart = _dylib.lookup('enable_autostart');
    _disableAutostart = _dylib.lookup('disable_autostart');
    _isAutostartEnabled = _dylib.lookup('is_autostart_enabled');
    _isServerRunning = _dylib.lookup('is_server_running');
  }

  static String? createFile(String path) {
    final pathPtr = path.toNativeUtf8();
    try {
      final resultPtr = _createFile.asFunction<Pointer Function(Pointer)>()(pathPtr);
      final result = resultPtr.cast<Utf8>().toDartString();
      _freeString.asFunction<void Function(Pointer)>()(resultPtr);
      return result;
    } finally {
      malloc.free(pathPtr);
    }
  }

  static String? readFile(String path) {
    final pathPtr = path.toNativeUtf8();
    try {
      final resultPtr = _readFile.asFunction<Pointer Function(Pointer)>()(pathPtr);
      final result = resultPtr.cast<Utf8>().toDartString();
      _freeString.asFunction<void Function(Pointer)>()(resultPtr);
      return result;
    } finally {
      malloc.free(pathPtr);
    }
  }

  static String? writeFile(String path, String content) {
    final pathPtr = path.toNativeUtf8();
    final contentPtr = content.toNativeUtf8();
    try {
      final resultPtr = _writeFile.asFunction<Pointer Function(Pointer, Pointer)>()(pathPtr, contentPtr);
      final result = resultPtr.cast<Utf8>().toDartString();
      _freeString.asFunction<void Function(Pointer)>()(resultPtr);
      return result;
    } finally {
      malloc.free(pathPtr);
      malloc.free(contentPtr);
    }
  }

  static String? getFileInfo(String path) {
    final pathPtr = path.toNativeUtf8();
    try {
      final resultPtr = _getFileInfo.asFunction<Pointer Function(Pointer)>()(pathPtr);
      final result = resultPtr.cast<Utf8>().toDartString();
      _freeString.asFunction<void Function(Pointer)>()(resultPtr);
      return result;
    } finally {
      malloc.free(pathPtr);
    }
  }

  static String? deleteFile(String path) {
    final pathPtr = path.toNativeUtf8();
    try {
      final resultPtr = _deleteFile.asFunction<Pointer Function(Pointer)>()(pathPtr);
      final result = resultPtr.cast<Utf8>().toDartString();
      _freeString.asFunction<void Function(Pointer)>()(resultPtr);
      return result;
    } finally {
      malloc.free(pathPtr);
    }
  }

  static String? getFilecatPath() {
    try {
      final resultPtr = _getFilecatPath.asFunction<Pointer Function()>()();
      if (resultPtr == nullptr) return null;
      final result = resultPtr.cast<Utf8>().toDartString();
      _freeString.asFunction<void Function(Pointer)>()(resultPtr);
      return result;
    } catch (e) {
      return null;
    }
  }

  static String? listDirectory(String path) {
    final pathPtr = path.toNativeUtf8();
    try {
      final resultPtr = _listDirectory.asFunction<Pointer Function(Pointer)>()(pathPtr);
      final result = resultPtr.cast<Utf8>().toDartString();
      _freeString.asFunction<void Function(Pointer)>()(resultPtr);
      return result;
    } finally {
      malloc.free(pathPtr);
    }
  }

  static String? startStaticServer(String path) {
    final pathPtr = path.toNativeUtf8();
    try {
      final resultPtr = _startStaticServer.asFunction<Pointer Function(Pointer)>()(pathPtr);
      final result = resultPtr.cast<Utf8>().toDartString();
      _freeString.asFunction<void Function(Pointer)>()(resultPtr);
      return result;
    } finally {
      malloc.free(pathPtr);
    }
  }

  static String? stopStaticServer() {
    try {
      final resultPtr = _stopStaticServer.asFunction<Pointer Function()>()();
      final result = resultPtr.cast<Utf8>().toDartString();
      _freeString.asFunction<void Function(Pointer)>()(resultPtr);
      return result;
    } catch (e) {
      return null;
    }
  }

  static String? updateServerPath(String path) {
    final pathPtr = path.toNativeUtf8();
    try {
      final resultPtr = _updateServerPath.asFunction<Pointer Function(Pointer)>()(pathPtr);
      final result = resultPtr.cast<Utf8>().toDartString();
      _freeString.asFunction<void Function(Pointer)>()(resultPtr);
      return result;
    } finally {
      malloc.free(pathPtr);
    }
  }

  static String? getLocalIp() {
    try {
      final resultPtr = _getLocalIp.asFunction<Pointer Function()>()();
      final result = resultPtr.cast<Utf8>().toDartString();
      _freeString.asFunction<void Function(Pointer)>()(resultPtr);
      return result;
    } catch (e) {
      return null;
    }
  }

  static String? enableAutostart(String appName) {
    final appNamePtr = appName.toNativeUtf8();
    try {
      final resultPtr = _enableAutostart.asFunction<Pointer Function(Pointer)>()(appNamePtr);
      final result = resultPtr.cast<Utf8>().toDartString();
      _freeString.asFunction<void Function(Pointer)>()(resultPtr);
      return result;
    } finally {
      malloc.free(appNamePtr);
    }
  }

  static String? disableAutostart(String appName) {
    final appNamePtr = appName.toNativeUtf8();
    try {
      final resultPtr = _disableAutostart.asFunction<Pointer Function(Pointer)>()(appNamePtr);
      final result = resultPtr.cast<Utf8>().toDartString();
      _freeString.asFunction<void Function(Pointer)>()(resultPtr);
      return result;
    } finally {
      malloc.free(appNamePtr);
    }
  }

  static bool isAutostartEnabled(String appName) {
    final appNamePtr = appName.toNativeUtf8();
    try {
      final resultPtr = _isAutostartEnabled.asFunction<Pointer Function(Pointer)>()(appNamePtr);
      final result = resultPtr.cast<Utf8>().toDartString();
      _freeString.asFunction<void Function(Pointer)>()(resultPtr);
      try {
        final Map<String, dynamic> json = jsonDecode(result);
        return json['data'] == true;
      } catch (e) {
        return false;
      }
    } finally {
      malloc.free(appNamePtr);
    }
  }

  static bool isServerRunning() {
    try {
      final resultPtr = _isServerRunning.asFunction<Pointer Function()>()();
      final result = resultPtr.cast<Utf8>().toDartString();
      _freeString.asFunction<void Function(Pointer)>()(resultPtr);
      try {
        final Map<String, dynamic> json = jsonDecode(result);
        return json['data'] == true;
      } catch (e) {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
}
