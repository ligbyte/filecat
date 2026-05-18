import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:file_picker/file_picker.dart';
import '../controllers/home_controller.dart';
import '../models/file_item.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';
import '../utils/file_utils.dart';
import '../widgets/copy_button.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: AppColors.scaffoldBackground,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final isMobileLayout = width <= 450;
              final isTabletLayout = width > 450 && width <= 800;
              
              double maxWidth;
              if (isMobileLayout) {
                maxWidth = double.infinity;
              } else if (isTabletLayout) {
                maxWidth = 850;
              } else {
                maxWidth = 1100;
              }
              
              double horizontalPadding;
              if (isMobileLayout) {
                horizontalPadding = 16.0;
              } else if (isTabletLayout) {
                horizontalPadding = 24.0;
              } else {
                horizontalPadding = 32.0;
              }
              
              return Padding(
                padding: EdgeInsets.only(
                  left: horizontalPadding,
                  right: horizontalPadding,
                  top: 16,
                  bottom: 8,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPathSelection(),
                        const SizedBox(height: 12),
                        Expanded(
                          child: _buildDirectoryContents(),
                        ),
                        const SizedBox(height: 4),
                        _buildAutostartCheckbox(),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPathSelection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: AppStyles.cardDecoration,
      child: Row(
        children: [
          Image.asset(
            'assets/images/ic_floder_share.png',
            width: 40,
            height: 40,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, 
              children: [
                Text('share_path'.tr, style: const TextStyle(fontSize: 12, color: AppColors.textLight)), 
                const SizedBox(height: 2), 
                Obx(() => Text(
                  controller.filecatPath.value.isEmpty ? 'loading'.tr : controller.filecatPath.value, 
                  style: const TextStyle(fontSize: 14, color: AppColors.textDark, fontWeight: FontWeight.w600), 
                  maxLines: 1, 
                  overflow: TextOverflow.ellipsis
                ))
              ] 
            )
          ),
          const SizedBox(width: 16),
          Material(
            color: AppColors.white,
            child: InkWell(
              onTap: () async {
                String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
                controller.changeFilecatPath(selectedDirectory);
              },
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Color(0xFF000000)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'change_path'.tr,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF000000),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectoryContents() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      decoration: AppStyles.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'dir_contents'.tr,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: controller.refreshContents,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  tooltip: 'refresh_dir'.tr,
                  color: AppColors.primary,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const Spacer(),
                Obx(() => controller.isLoading.value
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          Expanded(
            child: Obx(() => controller.directoryContents.isEmpty && !controller.isLoading.value
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_open_outlined,
                          size: 48,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'empty_dir'.tr,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: controller.directoryContents.length,
                    separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.divider),
                    itemBuilder: (context, index) {
                      final item = controller.directoryContents[index];
                      return _buildDirectoryItem(item, 0);
                    },
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutostartCheckbox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Image.asset(
                'assets/images/loading_cat.gif',
                width: 28,
                height: 28,
              ),
              const SizedBox(width: 8),
              Text(
                'service_running'.tr,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.success,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Text(
                'autostart'.tr,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(width: 4),
              SizedBox(
                height: 24,
                child: Transform.scale(
                  scale: 0.7,
                  child: Obx(() => Switch(
                    value: controller.autostartEnabled.value,
                    onChanged: controller.setAutostart,
                    activeColor: const Color(0xFF6ECC54),
                  )),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDirectoryItem(FileItem item, int indentLevel) {
    final isDir = item.isDir;
    final name = item.name;
    final path = item.path;
    final size = item.size;
    
    String getHeliumIcon(bool isExpanded) {
      if (isDir) {
        final folderName = name.toLowerCase();
        const folderMap = {
          'src': 'folder-src', 'source': 'folder-src', 'sources': 'folder-src',
          'dist': 'folder-dist', 'out': 'folder-dist', 'build': 'folder-dist',
          'release': 'folder-dist', 'bin': 'folder-dist', 'css': 'folder-css',
          'styles': 'folder-css', 'style': 'folder-css', 'sass': 'folder-sass',
          'scss': 'folder-sass', 'images': 'folder-images', 'image': 'folder-images',
          'img': 'folder-images', 'icons': 'folder-images', 'icon': 'folder-images',
          'scripts': 'folder-scripts', 'script': 'folder-scripts', 'node_modules': 'folder-node',
          'js': 'folder-javascript', 'javascript': 'folder-javascript', 'font': 'folder-font',
          'fonts': 'folder-font', 'test': 'folder-test', 'tests': 'folder-test',
          'spec': 'folder-test', 'specs': 'folder-test', 'doc': 'folder-docs',
          'docs': 'folder-docs', 'documents': 'folder-docs', '.git': 'folder-git',
          '.github': 'folder-github', '.vscode': 'folder-vscode', 'views': 'folder-views',
          'pages': 'folder-views', 'components': 'folder-components', 'assets': 'folder-resource',
          'res': 'folder-resource', 'resource': 'folder-resource', 'resources': 'folder-resource',
          'lib': 'folder-lib', 'libs': 'folder-lib', 'vendor': 'folder-lib',
          'themes': 'folder-theme', 'theme': 'folder-theme', 'public': 'folder-public',
          'www': 'folder-public', 'include': 'folder-include', 'docker': 'folder-docker',
          'db': 'folder-database', 'database': 'folder-database', 'sql': 'folder-database',
          'log': 'folder-log', 'logs': 'folder-log', 'temp': 'folder-temp',
          'tmp': 'folder-temp', 'cache': 'folder-temp', 'video': 'folder-video',
          'videos': 'folder-video', 'audio': 'folder-audio', 'music': 'folder-audio',
          'api': 'folder-api', 'app': 'folder-app', 'config': 'folder-config',
          'settings': 'folder-config', 'tools': 'folder-tools', 'helper': 'folder-helper',
          'helpers': 'folder-helper',
        };
        
        String iconName = folderMap[folderName] ?? 'folder-resource';
        if (isExpanded) {
          return 'assets/images/$iconName-open.svg';
        }
        return 'assets/images/$iconName.svg';
      } else {
        final ext = name.split('.').last.toLowerCase();
        final fileName = name.toLowerCase();
        
        const fileNameMap = {
          'package.json': 'nodejs', 'package-lock.json': 'nodejs',
          'tsconfig.json': 'json', 'dockerfile': 'docker',
          'docker-compose.yml': 'docker', 'docker-compose.yaml': 'docker',
          'gitignored': 'git', '.gitignore': 'git', '.gitattributes': 'git',
          'readme.md': 'readme', 'license': 'certificate',
          'license.md': 'certificate', 'license.txt': 'certificate',
          'makefile': 'makefile',
        };
        
        if (fileNameMap.containsKey(fileName)) {
          return 'assets/images/${fileNameMap[fileName]}.svg';
        }

        const extMap = {
          'html': 'html', 'htm': 'html', 'css': 'css', 'scss': 'sass',
          'sass': 'sass', 'less': 'less', 'js': 'javascript', 'mjs': 'javascript',
          'ts': 'typescript', 'tsx': 'react_ts', 'jsx': 'react', 'json': 'json',
          'yaml': 'yaml', 'yml': 'yaml', 'xml': 'xml', 'md': 'markdown',
          'markdown': 'markdown', 'py': 'python', 'pyc': 'python-misc',
          'whl': 'python-misc', 'java': 'java', 'jar': 'java', 'c': 'c',
          'cpp': 'cpp', 'cc': 'cpp', 'h': 'h', 'hpp': 'hpp', 'go': 'go',
          'rb': 'ruby', 'rs': 'rust', 'swift': 'swift', 'dart': 'dart',
          'php': 'php', 'sql': 'database', 'sh': 'console', 'bash': 'console',
          'bat': 'console', 'cmd': 'console', 'ps1': 'powershell', 'pdf': 'pdf',
          'png': 'image', 'jpg': 'image', 'jpeg': 'image', 'gif': 'image',
          'svg': 'svg', 'ico': 'image', 'webp': 'image', 'zip': 'zip',
          'tar': 'zip', 'gz': 'zip', '7z': 'zip', 'rar': 'zip', 'mp3': 'audio',
          'wav': 'audio', 'mp4': 'video', 'mov': 'video', 'avi': 'video',
          'exe': 'exe', 'msi': 'exe', 'apk': 'android', 'doc': 'word',
          'docx': 'word', 'xls': 'table', 'xlsx': 'table', 'csv': 'table',
          'ppt': 'powerpoint', 'pptx': 'powerpoint', 'ini': 'settings',
          'conf': 'settings', 'config': 'settings', 'toml': 'settings',
        };
        
        String iconName = extMap[ext] ?? 'file';
        return 'assets/images/$iconName.svg';
      }
    }

    return Obx(() {
      final isExpanded = controller.expandedFolders[path] == true;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: EdgeInsets.only(
              left: 16 + (indentLevel * 24),
              right: 16,
              top: 4,
              bottom: 4,
            ),
            hoverColor: const Color(0xFFF5F5F5),
            leading: SvgPicture.asset(
              getHeliumIcon(isExpanded),
              width: 20,
              height: 20,
              placeholderBuilder: (context) => Icon(
                isDir 
                    ? (isExpanded ? Icons.folder_open_outlined : Icons.folder_outlined)
                    : Icons.article_outlined,
                color: isDir ? AppColors.primary : AppColors.textLight,
                size: 20,
              ),
            ),
            title: Text(
              name,
              style: AppStyles.itemTitleStyle,
            ),
            subtitle: isDir 
                ? null 
                : Text(
                    '${FileUtils.formatFileSize(size)}  ·  ${FileUtils.formatDateTime(item.modified)}',
                    style: AppStyles.itemSubtitleStyle,
                  ),
            trailing: isDir
                ? Icon(
                    isExpanded ? Icons.expand_more : Icons.chevron_right,
                    color: const Color(0xFFBFBFBF),
                    size: 20,
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CopyButton(onTap: () => controller.copyFileRelativePath(item)),
                    ],
                  ),
            onTap: isDir ? () => controller.toggleFolder(path) : null,
          ),
          if (isDir && isExpanded && controller.folderContents.containsKey(path))
            ...controller.folderContents[path]!.map((childItem) => 
              _buildDirectoryItem(childItem, indentLevel + 1),
            ).toList(),
        ],
      );
    });
  }
}
