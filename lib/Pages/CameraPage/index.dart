import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:convert';
import 'dart:io';
import './fixedCameraCorner.dart';

// 相机页面组件
class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {

  CameraController? _controller; // 摄像头控制器，使用可空类型
  List<CameraDescription> _cameras = []; // 设备上的摄像头列表
  int _selectedCameraIndex = 0; // 当前选中的摄像头索引（0：后置，1：前置）

  @override
  void initState() {
    super.initState();
    _initCamera(); // 初始化摄像头
  }

  // 初始化摄像头失败时的提示，同时关闭当前路由
  showInitCameraError({String message = '相机初始化失败，请检查设备摄像头'}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context);
    });
  }

  // 拍照逻辑
  Future<void> takePicture(BuildContext contextValue) async {
    try {
      // 拍照
      final XFile picture = await _controller!.takePicture();
      // 读取图片文件内容
      final File imageFile = File(picture.path);
      final List<int> imageBytes = await imageFile.readAsBytes();
      // 将图片内容转换为Base64编码
      final String base64Image = base64Encode(imageBytes);

      // 处理拍照后的图片（例如，上传到服务器）
      print('拍照后的图片路径: ${picture.path}');
      // 打印Base64编码后的图片内容
      print('Base64编码后的图片内容: $base64Image');

      // 从路由参数中获取WebView控制器, 调用JavaScript方法，将Base64编码后的图片内容传递给H5
      dynamic routeArguments = ModalRoute.of(contextValue)?.settings.arguments as Map<String, dynamic>?;

      await routeArguments?['webview']?.runJavaScript('''
        window.receiveCameraBridgeMessage('$base64Image');
      ''');

      // 关闭当前路由
      Navigator.pop(contextValue);
      
    } catch (e) {
      // 拍照失败时显示错误提示
      showInitCameraError(message: '拍照失败，请重试');
    }
  }

  // 初始化摄像头
  Future<void> _initCamera() async {
    try {
      // 获取设备上的所有摄像头
      _cameras = await availableCameras();
      // 确保有摄像头可用
      if (_cameras.isEmpty) {
        // 显示错误提示并关闭路由
        showInitCameraError(message: '未找到可用的摄像头');
        return;
      }

      // 初始化控制器（默认使用后置摄像头）
      _controller = CameraController(
        _cameras[_selectedCameraIndex],
        ResolutionPreset.max, // 最高分辨率
      );

      _controller?.initialize().then((_) {
        if (!mounted) {
          return;
        }
        setState(() {});
      })
      .catchError((error) {
        // 初始化失败时显示错误提示并关闭路由
        showInitCameraError(message: '相机初始化失败');
      });
    } catch (e) {
      showInitCameraError(message: '相机初始化失败');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: (_controller == null || !_controller!.value.isInitialized)? Center(child: Text('正在准备相机...')) : Stack(
        children: [
          // 拍照界面
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 200,
            child: Stack(
              children: [
                CameraPreview(_controller!),
                Align(
                  alignment: Alignment.center,
                  child: FixedCornerFocusFrame(
                    size: 200,
                    cornerLength: 30,
                    color: Colors.teal,
                    strokeWidth: 2,
                  ),
                ),
              ],
            ),
          ),
          // 底部操作区域
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                color: Colors.white
              ),
              child: Container(
                height: 300,
                child: Align(
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 拍照按钮
                      Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black,
                          border: Border.fromBorderSide(
                            BorderSide(color: Colors.white, width: 2),
                          ),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.camera_alt_outlined, color: Colors.white, size: 40), 
                          onPressed: () {
                            // 拍照逻辑
                            takePicture(context);
                          }
                        ),
                      ),
                    ],
                  )
                ),
              ),
            )
          ),
          // 顶部按钮
          Positioned(
            top: 80,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 返回按钮
                Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black38,
                  ),
                  child: IconButton(icon: Icon(Icons.arrow_back, color: Colors.white), onPressed: () {
                    Navigator.pop(context);
                  }),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    // 释放相机资源
    _controller?.dispose();
    super.dispose();
  }
}