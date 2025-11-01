import 'package:image_picker/image_picker.dart';

String getFileTypeByPath(XFile xfile) {
  String extension = xfile.path.split('.').last;
  return extension;
}