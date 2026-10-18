import 'package:jigsaw_puzzle_game/domain/interfaces.dart';
import 'package:jigsaw_puzzle_game/domain/models.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

/// Concrete implementation of [PermissionService] using the `permission_handler` plugin.
class PermissionServiceImpl implements PermissionService {
  @override
  Future<PermissionStatus> requestCameraPermission() async {
    final status = await ph.Permission.camera.request();
    return _mapStatus(status);
  }

  @override
  Future<PermissionStatus> requestGalleryPermission() async {
    final permission = _galleryPermission();
    final status = await permission.request();
    return _mapStatus(status);
  }

  @override
  Future<void> openAppSettings() async {
    await ph.openAppSettings();
  }

  /// Selects the correct permission for photo library access.
  ///
  /// Both platforms use [ph.Permission.photos]; `permission_handler` maps it to
  /// the right underlying permission:
  /// - iOS: `NSPhotoLibraryUsageDescription`.
  /// - Android 13+ (API 33+): `READ_MEDIA_IMAGES`.
  /// - Android 12 and below: no runtime permission is requested, because
  ///   `image_picker` reads the chosen file through the system picker.
  ph.Permission _galleryPermission() {
    return ph.Permission.photos;
  }

  /// Maps a `permission_handler` [ph.PermissionStatus] to the app's own [PermissionStatus].
  PermissionStatus _mapStatus(ph.PermissionStatus status) {
    if (status.isGranted || status.isLimited) {
      return PermissionStatus.granted;
    }
    if (status.isPermanentlyDenied) {
      return PermissionStatus.permanentlyDenied;
    }
    return PermissionStatus.denied;
  }
}
