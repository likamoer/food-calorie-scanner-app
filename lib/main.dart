import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '算了么',
      home: const WebViewPage(),
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

  @override
  void initState() {
    super.initState();
    
    // 初始化WebViewController
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
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
              // 处理路由变化
              if (!_isStartSafeArea) {
                setState(() {
                  _isStartSafeArea = true;
                });
              }
            }
          },
        ),
      )
      ..loadRequest(Uri.parse('http://154.8.136.162/AiCalorie/'));
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
