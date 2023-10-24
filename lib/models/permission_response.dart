import 'package:permission_handler/permission_handler.dart';

class PermissionResponse {
  final List<PermissionStatus> permissionStatus;
  PermissionResponse(this.permissionStatus);
  bool get isAllGranted => permissionStatus.every((_) => _.isGranted);
  bool get isAnyDenied => permissionStatus.any((_) => _.isDenied);
}
