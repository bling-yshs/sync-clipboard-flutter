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
  late PageController _pageController;
  bool _isAnimating = false; // 标志位：是否正在执行点击触发的动画

  // 定义导航项对应的页面
  static const List<Widget> _pages = [HomePage(), ConfigPage(), DebugPage()];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    // 主页启动时检查更新
    _checkForUpdate();
  }

  /// 检查更新
  Future<void> _checkForUpdate() async {
    // 先检查设置是否启用自动检查更新
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString('app_settings');
    AppSettings? settings;
    if (settingsJson != null) {
      try {
        settings = appSettingsFromJson(settingsJson);
        if (!settings.autoCheckUpdate) {
          return; // 用户关闭了自动检查更新
        }
      } catch (e) {
        // 解析失败，继续检查更新
      }
    }

    final result = await UpdateService.checkForUpdate();
    if (result != null && mounted) {
      // 检查是否忽略了该版本（非强制更新时才生效）
      if (!result.isForced &&
          settings?.ignoredVersion == result.updateInfo.version) {
        return; // 用户已忽略该版本
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
            begin: const Offset(0, -0.15), // 从上方偏移
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

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return; // 点击当前页面，不做任何操作

    // 立即更新选中状态，避免底部导航栏图标闪现
    setState(() {
      _selectedIndex = index;
      _isAnimating = true; // 标记开始动画
    });

    // 所有页面切换都使用动画
    _pageController
        .animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        )
        .then((_) {
          // 动画完成后，清除标记
          setState(() {
            _isAnimating = false;
          });
        });
  }

  void _onPageChanged(int index) {
    // 如果是点击触发的动画，忽略这个回调（避免闪现）
    // 如果是手势滑动，正常更新状态
    if (!_isAnimating) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SyncClipboard'),
        // 可以根据当前页面显示不同的标题
        // title: Text(_getTitle(_selectedIndex)),
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
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

/// 自定义导航栏，实现 indicator 背景的淡入淡出效果
class _CustomNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<_NavDestination> destinations;

  const _CustomNavigationBar({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: 80,
      decoration: BoxDecoration(color: colorScheme.surfaceContainer),
      child: SafeArea(
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
    );
  }
}

/// 单个导航项，带有 indicator 背景的淡入淡出动画
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 80,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 图标容器，带有背景动画
            SizedBox(
              width: 64,
              height: 32,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 背景 indicator - 使用 AnimatedOpacity 实现淡入淡出
                  AnimatedOpacity(
                    opacity: isSelected ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      width: isSelected ? 64 : 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  // 图标 - 使用 AnimatedSwitcher 实现平滑切换
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      isSelected ? selectedIcon : icon,
                      key: ValueKey(isSelected),
                      color: isSelected
                          ? colorScheme.onSecondaryContainer
                          : colorScheme.onSurfaceVariant,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            // 标签文字
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? colorScheme.onSurface
                    : colorScheme.onSurfaceVariant,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
