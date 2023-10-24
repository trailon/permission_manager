library permission_manager;

import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart' as perm;
import 'package:permission_manager/models/permission_response.dart';

export 'package:permission_handler/permission_handler.dart';

late BaseDeviceInfo _baseDeviceInfo;
late AndroidDeviceInfo _androidDeviceInfo;
late IosDeviceInfo _iosDeviceInfo;
late WindowsDeviceInfo _windowsDeviceInfo;
late MacOsDeviceInfo _macosDeviceInfo;
late LinuxDeviceInfo _linuxDeviceInfo;
late WebBrowserInfo _webBrowserInfo;

class PermissionManager {
  late DeviceInfoPlugin _plugin;
  int get androidsdk => _androidDeviceInfo.version.sdkInt;
  double get iosversion => double.tryParse(_iosDeviceInfo.systemVersion) ?? 0;
  PermissionManager() {
    _plugin = DeviceInfoPlugin();
  }

  Future<bool> cameraStatusGranted() async {
    return await perm.Permission.camera.status.isGranted;
  }

  PermissionManager.initialize() {
    _plugin.deviceInfo.then((basedev) async {
      _baseDeviceInfo = basedev;
      if (Platform.isAndroid) {
        _androidDeviceInfo = await _plugin.androidInfo;
      }
      if (Platform.isIOS) {
        _iosDeviceInfo = await _plugin.iosInfo;
      }
      if (Platform.isWindows) {
        _windowsDeviceInfo = await _plugin.windowsInfo;
      }
      if (Platform.isMacOS) {
        _macosDeviceInfo = await _plugin.macOsInfo;
      }
      if (Platform.isLinux) {
        _linuxDeviceInfo = await _plugin.linuxInfo;
      }
      if (kIsWeb) {
        _webBrowserInfo = await _plugin.webBrowserInfo;
      }
    });
  }

  Future<PermissionResponse> requestLocation() async {
    late final List<perm.PermissionStatus> locationPerm;
    if (Platform.isIOS) {
      locationPerm = [await perm.Permission.location.request()];
    }
    if (Platform.isAndroid) {
      locationPerm = await Future.wait([
        perm.Permission.locationWhenInUse.request(),
        perm.Permission.locationAlways.request(),
      ]);
    }
    return PermissionResponse(locationPerm);
  }

  Future<PermissionResponse> requestCamera() async {
    late final List<perm.PermissionStatus> cameraPerm;
    cameraPerm = await Future.wait([
      perm.Permission.camera.request(),
    ]);
    return PermissionResponse(cameraPerm);
  }

  Future<PermissionResponse> requestMediaLocation() async {
    late final List<perm.PermissionStatus> cameraPerm;
    cameraPerm = await Future.wait([
      perm.Permission.accessMediaLocation.request(),
    ]);
    return PermissionResponse(cameraPerm);
  }

  Future<PermissionResponse> requestMediaLibrary() async {
    late final List<perm.PermissionStatus> cameraPerm;
    cameraPerm = await Future.wait([
      perm.Permission.mediaLibrary.request(),
    ]);
    return PermissionResponse(cameraPerm);
  }

  Future<PermissionResponse> requestBluetooth({
    bool connect = true,
    bool scan = true,
    bool advertise = false,
  }) async {
    late final List<perm.PermissionStatus> bluetoothPerm;
    if (Platform.isIOS) {
      bluetoothPerm = [await perm.Permission.bluetooth.request()];
    }
    if (Platform.isAndroid) {
      bluetoothPerm = await Future.wait([
        perm.Permission.bluetooth.request(),
        if (connect) perm.Permission.bluetoothConnect.request(),
        if (scan) perm.Permission.bluetoothScan.request(),
        if (advertise) perm.Permission.bluetoothAdvertise.request(),
      ]);
    }
    return PermissionResponse(bluetoothPerm);
  }

  /// External storage access is for the file management system access and its considered a highly risky permission
  /// for android users. If you are looking for a permission to access photos, videos, or audio use requestMedia instead.
  Future<PermissionResponse> requestExternalStorage() async {
    late final List<perm.PermissionStatus> externalStoragePerm;
    if (Platform.isIOS) {
      externalStoragePerm = [await perm.Permission.storage.request()];
    }
    if (Platform.isAndroid) {
      if (androidsdk >= 30) {
        externalStoragePerm = await Future.wait([
          perm.Permission.manageExternalStorage.request(),
        ]);
      } else {
        externalStoragePerm = [await perm.Permission.storage.request()];
      }
    }
    return PermissionResponse(externalStoragePerm);
  }

  /// If you want to access photos, videos, or audio use this method. It is not for accessing external storage.
  Future<PermissionResponse> requestMedia(
      {bool photos = true, bool videos = false, bool audio = false}) async {
    late final List<perm.PermissionStatus> mediaPerm;
    if (Platform.isIOS) {
      mediaPerm = await Future.wait([
        if (iosversion >= 14) perm.Permission.photos.request(),
        if (iosversion >= 9.3) perm.Permission.mediaLibrary.request(),
      ]);
    }
    if (Platform.isAndroid) {
      if (androidsdk >= 29) {
        mediaPerm = await Future.wait([
          if (photos) perm.Permission.photos.request(),
          if (videos) perm.Permission.videos.request(),
          if (audio) perm.Permission.audio.request()
        ]);
      } else {
        mediaPerm = [await perm.Permission.storage.request()];
      }
    }
    return PermissionResponse(mediaPerm);
  }
}
