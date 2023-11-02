import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionResponse {
  final List<PermissionStatus> permissionStatus;
  PermissionResponse(this.permissionStatus,
      {this.infoplistkeys, this.androidmanifestperms}) {
    debugPrint(toMap().toString());
  }
  bool get isAllGranted => permissionStatus.every((_) => _.isGranted);
  bool get isAnyDenied => permissionStatus.any((_) => _.isDenied);
  Map<String,String>? infoplistkeys = {};
  Map<String,String>? androidmanifestperms = {};

  Map<String, Map<String,String>> toMap() {
    return {
      "infoplists": infoplistkeys!,
      "androidmanifests": androidmanifestperms!,
    };
  }
}
