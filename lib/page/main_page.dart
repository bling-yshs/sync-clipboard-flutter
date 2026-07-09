import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_page.dart';
import 'config_page.dart';
import 'debug_page.dart';
import 'package:sync_clipboard_flutter/model/app_settings/app_settings.dart';
import 'package:sync_clipboard_flutter/service/update_service.dart';
import 'package:sync_clipboard_flutter/widget/update_dialog.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  late final PageController _pageController;

  // 定义导航项对应的页面。
  static const List<Widget> _pages = [HomePage(), ConfigPage(), DebugPage()];

  /// 初始化主页状态并检查应用更新。
  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    _checkForUpdate();
  }

  /// 释放页面切换控制器。
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// 检查更新
  Future<void> _checkForUpdate() async {
    // 先检查设置是否启用自动检查更新。
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString('app_settings');
    AppSettings? settings;
    if (settingsJson != null) {
      try {
        settings = appSettingsFromJson(settingsJson);
        if (!settings.autoCheckUpdate) {
          // 用户关闭了自动检查更新。
          return;
        }
      } catch (e) {
        // 解析失败，继续检查更新。
      }
    }

    final result = await UpdateService.checkForUpdate();
    if (result != null && mounted) {
      // 检查是否忽略了该版本，非强制更新时才生效。
      if (!result.isForced &&
          settings?.ignoredVersion == result.updateInfo.version) {
        // 用户已忽略该版本。
        return;
      }

      showGeneralDialog(
        context: context,
        barrierDismissible: !result.isForced,
        barrierLabel: '关闭',
        barrierColor: Colors.black54,
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (context, animation, secondaryAnimation) {
          return UpdateDialog(
            updateInfo: result.updateInfo,
            isForced: result.isForced,
            cachedApkPath: result.cachedApkPath,
          );
        },
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          // 从上往下滑入 + 淡入 + 轻微缩放
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );

          final slideAnimation = Tween<Offset>(
            begin: const Offset(0, -0.15),
            end: Offset.zero,
          ).animate(curvedAnimation);

          final scaleAnimation = Tween<double>(
            begin: 0.95,
            end: 1.0,
          ).animate(curvedAnimation);

          return SlideTransition(
            position: slideAnimation,
            child: ScaleTransition(
              scale: scaleAnimation,
              child: FadeTransition(opacity: curvedAnimation, child: child),
            ),
          );
        },
      );
    }
  }

  /// 根据底部导航点击切换当前页面。
  void _onItemTapped(int index) {
    if (_selectedIndex == index) {
      return;
    }

    setState(() {
      _selectedIndex = index;
    });

    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  /// 构建主页框架、页面内容和悬浮胶囊底部导航栏。
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: const Text('SyncClipboard'),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: _pages,
      ),
      bottomNavigationBar: _CustomNavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          _NavDestination(
            icon: Icons.home_outlined,
            selectedIcon: Icons.home,
            label: '首页',
          ),
          _NavDestination(
            icon: Icons.settings_outlined,
            selectedIcon: Icons.settings,
            label: '设置',
          ),
          _NavDestination(
            icon: Icons.bug_report_outlined,
            selectedIcon: Icons.bug_report,
            label: '调试',
          ),
        ],
      ),
    );
  }
}

/// 导航目的地数据类
class _NavDestination {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _NavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

/// 自定义导航栏，实现悬浮胶囊选中态。
class _CustomNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<_NavDestination> destinations;

  const _CustomNavigationBar({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  /// 构建跟随动态取色的悬浮胶囊导航栏。
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(40, 0, 40, 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(27),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.14),
              blurRadius: 24,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: colorScheme.surfaceContainerLowest,
          elevation: 0,
          borderRadius: BorderRadius.circular(27),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            height: 54,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(destinations.length, (index) {
                final destination = destinations[index];
                final isSelected = index == selectedIndex;

                return Expanded(
                  child: _NavItem(
                    icon: destination.icon,
                    selectedIcon: destination.selectedIcon,
                    label: destination.label,
                    isSelected: isSelected,
                    onTap: () => onDestinationSelected(index),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

/// 单个导航项，带有整项胶囊选中背景动画。
class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  /// 构建单个导航项及其选中态胶囊指示器。
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final contentColor = isSelected
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurfaceVariant;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 54,
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Stack(
            fit: StackFit.expand,
            alignment: Alignment.center,
            children: [
              AnimatedOpacity(
                opacity: isSelected ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  margin: EdgeInsets.symmetric(
                    horizontal: isSelected ? 0 : 24,
                    vertical: isSelected ? 0 : 12,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeOutCubic,
                    child: Icon(
                      isSelected ? selectedIcon : icon,
                      key: ValueKey(isSelected),
                      color: contentColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 1),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.0,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: contentColor,
                    ),
                    child: Text(label),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
