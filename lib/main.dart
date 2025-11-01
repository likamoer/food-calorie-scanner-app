import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'Pages/CameraPage/index.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '算了么',
      initialRoute: '/',
      routes: {
        '/': (context) => const WebViewPage(),
        '/camera': (context) {
          return CameraPage();
        },
      },
    );
  }
}

class WebViewPage extends StatefulWidget {
  const WebViewPage({super.key});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late WebViewController _controller;
  bool _isLoading = true; // 页面是否加载完成
  bool _isStartSafeArea = false; // 是否开启安全区域

  // 隐藏手机的导航栏
  hideStatusBar() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersive, // 沉浸式模式：隐藏状态栏和导航栏（滑动屏幕边缘可临时显示）
      overlays: [SystemUiOverlay.bottom], // 仅隐藏状态栏，保留底部导航栏
    );
  }

  @override
  void initState() {
    super.initState();

    // 隐藏导航栏
    hideStatusBar();
    
    // 初始化WebViewController
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setOnJavaScriptAlertDialog(
        (JavaScriptAlertDialogRequest request) {
          // 处理JavaScript alert弹窗
          return showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('提示'),
                content: Text(request.message),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('确定'),
                  ),
                ],
              );
            },
          );
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // 处理加载进度
            if (progress == 100) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onPageStarted: (String url) {
            // 页面开始加载
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            // 页面加载完成
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            // 处理加载错误
            setState(() {
              _isLoading = false;
            });
          },
          onUrlChange: (UrlChange change) {
            // 获取当前页面URL
            String curPageUrl = change.url ?? '';
            final uri = Uri.parse(curPageUrl);
            if (uri.fragment.isNotEmpty) {
              // 处理React-Router的路由变化
              if (!_isStartSafeArea) {
                setState(() {
                  _isStartSafeArea = true;
                });
              }
            }
          }
        ),
      )
      ..addJavaScriptChannel(
        'cameraBridge',
        onMessageReceived: (JavaScriptMessage message) {
          // 处理从JavaScript发送的消息
          print('收到消息: ${message.message}');
          // 跳转到相机页面，并传递消息
          Navigator.pushNamed(
            context,
            '/camera',
            arguments: {
              'h5SendFlutterMessage': message.message,
              'webview': _controller,
            },
          );
        },
      )
      ..loadRequest(Uri.parse('http://154.8.136.162/AiCalorie/?timestamp=${DateTime.now().millisecondsSinceEpoch}'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(    
      body: Stack(
        children: [
          _isStartSafeArea ? SafeArea(child: WebViewWidget(controller: _controller)) : WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
