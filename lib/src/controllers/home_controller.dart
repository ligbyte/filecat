import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import '../models/file_item.dart';
import '../rust/rust_bridge.dart';
import '../constants/app_colors.dart';

class HomeController extends GetxController with TrayListener, WindowListener {
  final filecatPath = ''.obs;
  final directoryContents = <FileItem>[].obs;
  final expandedFolders = <String, bool>{}.obs;
  final folderContents = <String, List<FileItem>>{}.obs;
  final isLoading = false.obs;
  final autostartEnabled = false.obs;
  final serverRunning = false.obs;
  final currentLanguage = 'system'.obs;

  @override
  void onInit() {
    super.onInit();
    windowManager.addListener(this);
    _setPreventClose();
    _initTray();
    _loadFilecatPath();
    _loadAutostartPreference();
    _loadLanguagePreference();
  }

  void _loadLanguagePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString('language_code');
    if (langCode != null) {
      currentLanguage.value = langCode;
      if (langCode == 'zh_CN') {
        Get.updateLocale(const Locale('zh', 'CN'));
      } else if (langCode == 'en_US') {
        Get.updateLocale(const Locale('en', 'US'));
      } else {
        Get.updateLocale(Get.deviceLocale ?? const Locale('en', 'US'));
      }
    } else {
      currentLanguage.value = 'system';
      Get.updateLocale(Get.deviceLocale ?? const Locale('en', 'US'));
    }
    updateTrayMenu();
  }

  void switchLanguage(String langCode) async {
    currentLanguage.value = langCode;
    if (langCode == 'zh_CN') {
      Get.updateLocale(const Locale('zh', 'CN'));
    } else if (langCode == 'en_US') {
      Get.updateLocale(const Locale('en', 'US'));
    } else {
      // Follow System
      Get.updateLocale(Get.deviceLocale ?? const Locale('en', 'US'));
    }
    
    final prefs = await SharedPreferences.getInstance();
    if (langCode == 'system') {
      await prefs.remove('language_code');
    } else {
      await prefs.setString('language_code', langCode);
    }
    
    updateTrayMenu(); // Rebuild tray menu with new language
    windowManager.setTitle('app_name'.tr); // Update window title
  }

  @override
  void onClose() {
    windowManager.removeListener(this);
    trayManager.removeListener(this);
    super.onClose();
  }

  void _setPreventClose() async {
    await windowManager.setPreventClose(true);
  }

  @override
  void onWindowClose() async {
    bool isPreventClose = await windowManager.isPreventClose();
    if (isPreventClose) {
      await windowManager.hide();
      updateTrayMenu(forceVisible: false);
    }
  }

  @override
  void onWindowHide() {
    updateTrayMenu(forceVisible: false);
  }

  @override
  void onWindowShow() {
    updateTrayMenu(forceVisible: true);
  }

  Future<void> updateTrayMenu({bool? forceVisible}) async {
    bool isVisible = forceVisible ?? await windowManager.isVisible();
    final menu = Menu(
      items: [
        MenuItem(
          key: 'toggle_window',
          label: isVisible ? 'hide_window'.tr : 'show_window'.tr,
        ),
        MenuItem.separator(),
        MenuItem.submenu(
          key: 'switch_lang',
          label: 'switch_lang'.tr,
          submenu: Menu(
            items: [
              _buildLanguageMenuItem('zh_CN', 'lang_chinese'.tr),
              _buildLanguageMenuItem('en_US', 'lang_english'.tr),
              _buildLanguageMenuItem('system', 'lang_system'.tr),
            ],
          ),
        ),
        MenuItem.separator(),
        MenuItem(
          key: 'support',
          label: 'support_author'.tr,
        ),
        MenuItem.separator(),
        MenuItem(
          key: 'about',
          label: 'about'.tr,
        ),
        MenuItem.separator(),
        MenuItem(
          key: 'exit',
          label: 'exit'.tr,
        ),
      ],
    );
    await trayManager.setContextMenu(menu);
  }

  MenuItem _buildLanguageMenuItem(String code, String label) {
    return MenuItem.checkbox(
      key: 'language_$code',
      label: label,
      checked: currentLanguage.value == code,
    );
  }

  void _initTray() async {
    trayManager.addListener(this);
    await trayManager.setIcon(
      Platform.isWindows ? 'assets/images/app_icon.ico' : 'assets/images/app_icon.ico',
    );
    await trayManager.setToolTip('文件猫');
    updateTrayMenu(forceVisible: true);
  }

  @override
  void onTrayIconMouseDown() async {
    bool isVisible = await windowManager.isVisible();
    if (isVisible) {
      await windowManager.hide();
      updateTrayMenu(forceVisible: false);
    } else {
      await windowManager.show();
      await windowManager.focus();
      updateTrayMenu(forceVisible: true);
    }
  }

  @override
  void onTrayIconRightMouseDown() {
    updateTrayMenu().then((_) {
      trayManager.popUpContextMenu();
    });
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) async {
    if (menuItem.key == 'toggle_window') {
      bool isVisible = await windowManager.isVisible();
      if (isVisible) {
        await windowManager.hide();
        updateTrayMenu(forceVisible: false);
      } else {
        await windowManager.show();
        await windowManager.focus();
        updateTrayMenu(forceVisible: true);
      }
    } else if (menuItem.key == 'support') {
      showSupportDialog();
    } else if (menuItem.key == 'about') {
      showAboutDialog();
    } else if (menuItem.key?.startsWith('language_') == true) {
      final langCode = menuItem.key!.replaceFirst('language_', '');
      switchLanguage(langCode);
    } else if (menuItem.key == 'exit') {
      exit(0);
    }
  }

  void showAboutDialog() {
    Get.dialog(
      Dialog(
        backgroundColor: AppColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 360,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => Get.back(),
                  child: Image.asset(
                    'assets/images/close.png',
                    width: 28,
                    height: 28,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/images/app_icon.png',
                  width: 80,
                  height: 80,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'app_name'.tr,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textMain,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'v1.0.0',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'app_desc'.tr,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'app_features'.tr,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showSupportDialog() {
    Get.dialog(
      Dialog(
        backgroundColor: AppColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 360,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => Get.back(),
                  child: Image.asset(
                    'assets/images/close.png',
                    width: 28,
                    height: 28,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Image.asset(
                  'wechat_pay_img'.tr,
                  width: 240,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'support_title'.tr,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textMain,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'support_desc'.tr,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showLanguageDialog() {
    Get.dialog(
      Dialog(
        backgroundColor: AppColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'switch_lang'.tr,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textMain,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Image.asset(
                      'assets/images/close.png',
                      width: 24,
                      height: 24,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildLanguageOption('zh_CN', 'lang_chinese'.tr),
              const SizedBox(height: 8),
              _buildLanguageOption('en_US', 'lang_english'.tr),
              const SizedBox(height: 8),
              _buildLanguageOption('system', 'lang_system'.tr),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String code, String label) {
    return Obx(() {
      final isSelected = currentLanguage.value == code;
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            switchLanguage(code);
            Get.back();
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.divider,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(8),
              color: isSelected ? AppColors.primary.withOpacity(0.05) : Colors.transparent,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? AppColors.primary : AppColors.textMain,
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }

  void _loadAutostartPreference() async {
    final prefs = await SharedPreferences.getInstance();
    autostartEnabled.value = prefs.getBool('autostart_enabled') ?? false;
    serverRunning.value = RustBridge.isServerRunning();
  }

  void _loadFilecatPath() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPath = prefs.getString('filecat_path');
    
    if (savedPath != null && savedPath.isNotEmpty) {
      filecatPath.value = savedPath;
      _loadDirectoryContents(savedPath);
      RustBridge.startStaticServer(savedPath);
    } else {
      final path = RustBridge.getFilecatPath();
      if (path != null) {
        try {
          final pathStr = path.contains('"data":"') 
              ? path.split('"data":"')[1].split('"')[0]
              : path;
          filecatPath.value = pathStr;
          _loadDirectoryContents(pathStr);
          RustBridge.startStaticServer(pathStr);
        } catch (e) {
          filecatPath.value = path;
          _loadDirectoryContents(path);
          RustBridge.startStaticServer(path);
        }
      }
    }
  }

  void _loadDirectoryContents(String path) {
    isLoading.value = true;
    final result = RustBridge.listDirectory(path);
    if (result != null) {
      try {
        final List<dynamic> jsonList = _extractJsonArray(result);
        directoryContents.value = jsonList.map((item) => FileItem.fromJson(item as Map<String, dynamic>)).toList();
      } catch (e) {
        directoryContents.clear();
      }
    }
    isLoading.value = false;
  }

  List<dynamic> _extractJsonArray(String response) {
    try {
      final startIndex = response.indexOf('[');
      final endIndex = response.lastIndexOf(']');
      if (startIndex != -1 && endIndex != -1) {
        final jsonArray = response.substring(startIndex, endIndex + 1);
        return jsonDecode(jsonArray) as List<dynamic>;
      }
    } catch (e) {
      debugPrint('Error extracting JSON array: $e');
    }
    return [];
  }

  void toggleFolder(String path) {
    if (expandedFolders[path] == true) {
      expandedFolders[path] = false;
    } else {
      expandedFolders[path] = true;
      _loadFolderContents(path);
    }
  }

  void refreshContents() {
    if (filecatPath.value.isNotEmpty) {
      _loadDirectoryContents(filecatPath.value);
      for (var entry in expandedFolders.entries) {
        if (entry.value) {
          _loadFolderContents(entry.key);
        }
      }
      Get.snackbar('tip'.tr, 'refresh_success'.tr, snackPosition: SnackPosition.BOTTOM);
    }
  }

  void _loadFolderContents(String path) {
    final result = RustBridge.listDirectory(path);
    if (result != null) {
      try {
        final List<dynamic> jsonList = _extractJsonArray(result);
        folderContents[path] = jsonList.map((item) => FileItem.fromJson(item as Map<String, dynamic>)).toList();
      } catch (e) {
        debugPrint('Error loading folder contents: $e');
      }
    }
  }

  void changeFilecatPath(String? selectedDirectory) async {
    if (selectedDirectory != null) {
      filecatPath.value = selectedDirectory;
      directoryContents.clear();
      expandedFolders.clear();
      folderContents.clear();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('filecat_path', selectedDirectory);
      
      _loadDirectoryContents(selectedDirectory);
      RustBridge.updateServerPath(selectedDirectory);
    }
  }

  Future<void> setAutostart(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value) {
      final result = RustBridge.enableAutostart('文件猫');
      if (result != null) {
        try {
          final json = jsonDecode(result);
          if (json['success'] == true) {
            await prefs.setBool('autostart_enabled', true);
            autostartEnabled.value = true;
          }
        } catch (e) {
          debugPrint('Error enabling autostart: $e');
        }
      }
    } else {
      final result = RustBridge.disableAutostart('文件猫');
      if (result != null) {
        try {
          final json = jsonDecode(result);
          if (json['success'] == true) {
            await prefs.setBool('autostart_enabled', false);
            autostartEnabled.value = false;
          }
        } catch (e) {
          debugPrint('Error disabling autostart: $e');
        }
      }
    }
  }

  void copyFileRelativePath(FileItem item) {
    final filePath = item.path;
    String relativePath = filePath;

    if (filecatPath.value.isNotEmpty && filePath.startsWith(filecatPath.value)) {
      relativePath = filePath.substring(filecatPath.value.length);
      if (relativePath.startsWith('/') || relativePath.startsWith('\\')) {
        relativePath = relativePath.substring(1);
      }
    }

    relativePath = relativePath.replaceAll('\\', '/');

    final ipResult = RustBridge.getLocalIp();
    String ip = '127.0.0.1';
    if (ipResult != null) {
      try {
        final Map<String, dynamic> json = jsonDecode(ipResult);
        if (json['success'] == true) {
          ip = json['data'] as String;
        }
      } catch (e) {
        debugPrint('Error parsing local IP: $e');
      }
    }

    final fullUrl = 'http://$ip:9202/file/$relativePath';
    Clipboard.setData(ClipboardData(text: fullUrl));
    Get.snackbar("", 'copied'.tr + fullUrl, snackPosition: SnackPosition.BOTTOM,titleText: const SizedBox.shrink(), );
  }
}
