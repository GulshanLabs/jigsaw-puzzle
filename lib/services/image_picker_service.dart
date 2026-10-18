import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:jigsaw_puzzle_game/domain/interfaces.dart';

/// Concrete implementation of [ImagePickerService] using the `image_picker` plugin.
class ImagePickerServiceImpl implements ImagePickerService {
  final ImagePicker _picker;

  ImagePickerServiceImpl({ImagePicker? picker})
      : _picker = picker ?? ImagePicker();

  @override
  Future<Uint8List?> pickFromCamera() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.camera);
    if (file == null) return null;
    return file.readAsBytes();
  }

  @override
  Future<Uint8List?> pickFromGallery() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return null;
    return file.readAsBytes();
  }
}
