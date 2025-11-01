import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import './fixedCameraCorner.dart';
import '../../utils/index.dart';

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
    initCamera(); // 初始化摄像头
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

  // 从相册上传图片
  uploadImageFromAlbum(BuildContext contextValue) async {
    final picker = ImagePicker();
    // 从相册选择图片
    XFile? pickedImage = await picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      // 1. 读取 XFile 的字节流（支持本地文件和临时文件）
      final List<int> imageBytes = await pickedImage.readAsBytes();
      // 2. 将字节流转换为Base64编码字符串
      String base64Str = base64Encode(imageBytes);
      print('Base64编码后的图片: $base64Str');
      // 从路由参数中获取WebView控制器, 调用JavaScript方法，将Base64编码后的图片内容传递给H5
      dynamic routeArguments = ModalRoute.of(contextValue)?.settings.arguments as Map<String, dynamic>?;

      // 3. 获取图片文件格式
      String imageFormat = getFileTypeByPath(pickedImage);
      // 4. 拼接图片数据URL
      String imageDataUrl = 'data:image/$imageFormat;base64,$base64Str';


      await routeArguments?['webview']?.runJavaScript('''
        window.receiveCameraBridgeMessage('$imageDataUrl');
      ''');

      // 关闭当前路由
      Navigator.pop(contextValue);
      return;
    }
    // 用户取消选择图片
    print('上传的图片: $pickedImage');
  }

  // 拍照逻辑
  Future<void> takeCameraPhoto(BuildContext contextValue) async {
    try {
      // 拍照
      final XFile picture = await _controller!.takePicture();
      // 读取图片文件内容
      final File imageFile = File(picture.path);
      final List<int> imageBytes = await imageFile.readAsBytes();
      // 将图片内容转换为Base64编码
      final String base64Image = base64Encode(imageBytes);
      // 3. 获取图片文件格式
      String imageFormat = getFileTypeByPath(picture);
      // 4. 拼接图片数据URL
      String imageDataUrl = 'data:image/$imageFormat;base64,$base64Image';

      // 从路由参数中获取WebView控制器, 调用JavaScript方法，将Base64编码后的图片内容传递给H5
      dynamic routeArguments = ModalRoute.of(contextValue)?.settings.arguments as Map<String, dynamic>?;

      await routeArguments?['webview']?.runJavaScript('''
        window.receiveCameraBridgeMessage('$imageDataUrl');
      ''');

      // 关闭当前路由
      Navigator.pop(contextValue);
      
    } catch (e) {
      // 拍照失败时显示错误提示
      showInitCameraError(message: '拍照失败，请重试');
    }
  }

  // 初始化摄像头
  Future<void> initCamera() async {
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
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
                          Container(width: 50),
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
                                takeCameraPhoto(context);
                              }
                            ),
                          ),
                          Container(width: 50),
                          // 上传图片icon
                          Container(
                            width: 50,
                            height: 50,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black,
                              border: Border.fromBorderSide(
                                BorderSide(color: Colors.white, width: 2),
                              ),
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.add_photo_alternate_outlined, 
                                color: Colors.white, 
                              ), 
                              onPressed: () {
                                // 上传图片逻辑
                                uploadImageFromAlbum(context);
                              }
                            ),
                          ),
                        ],
                      )
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