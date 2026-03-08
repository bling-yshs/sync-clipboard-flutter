import 'package:go_router/go_router.dart';
import '../page/main_page.dart';
import '../page/tile_page.dart';
import '../page/share_upload_page.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    // 主页面路由（正常启动）
    GoRoute(
      path: '/',
      name: 'main',
      builder: (context, state) => const MainPage(),
    ),

    // 磁贴透明页面路由 - 上传剪贴板
    GoRoute(
      path: '/tile/upload',
      name: 'tile-upload',
      builder: (context, state) => const TileUploadPage(),
    ),

    // 磁贴透明页面路由 - 下载剪贴板
    GoRoute(
      path: '/tile/download',
      name: 'tile-download',
      builder: (context, state) => const TileDownloadPage(),
    ),

    // 分享透明页面路由 - 文本分享上传
    GoRoute(
      path: '/share/text',
      name: 'share-text',
      builder: (context, state) => const ShareTextUploadPage(),
    ),

    // 分享透明页面路由 - 文件分享上传
    GoRoute(
      path: '/share/file',
      name: 'share-file',
      builder: (context, state) => const ShareFileUploadPage(),
    ),
  ],
);
