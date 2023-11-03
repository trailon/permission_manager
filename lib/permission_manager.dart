library permission_manager;

import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart' as perm;
import 'package:permission_manager/models/permission_response.dart';

export 'package:permission_handler/permission_handler.dart';
export 'package:permission_manager/permission_manager.dart';

BaseDeviceInfo? _baseDeviceInfo;
AndroidDeviceInfo? _androidDeviceInfo;
IosDeviceInfo? _iosDeviceInfo;
WindowsDeviceInfo? _windowsDeviceInfo;
MacOsDeviceInfo? _macosDeviceInfo;
LinuxDeviceInfo? _linuxDeviceInfo;
WebBrowserInfo? _webBrowserInfo;

class PermissionManager {
  final DeviceInfoPlugin _plugin = DeviceInfoPlugin();
  int get androidsdk => _androidDeviceInfo!.version.sdkInt;
  double get iosversion => double.tryParse(_iosDeviceInfo!.systemVersion) ?? 0;
  PermissionManager();

  Future<perm.PermissionStatus> cameraStatus() async =>
      await perm.Permission.camera.status;

  PermissionManager.initialize() {
    _plugin.deviceInfo.then((basedev) async {
      _baseDeviceInfo = basedev;
      if (kIsWeb) {
        _webBrowserInfo = await _plugin.webBrowserInfo;
        return;
      }
      if (Platform.isWindows) {
        _windowsDeviceInfo = await _plugin.windowsInfo;
        return;
      }
      if (Platform.isMacOS) {
        _macosDeviceInfo = await _plugin.macOsInfo;
        return;
      }
      if (Platform.isLinux) {
        _linuxDeviceInfo = await _plugin.linuxInfo;
        return;
      }
      if (Platform.isAndroid) {
        _androidDeviceInfo = await _plugin.androidInfo;
        return;
      }
      if (Platform.isIOS) {
        _iosDeviceInfo = await _plugin.iosInfo;
        return;
      }
    });
  }

  Future<PermissionResponse> requestLocation() async {
    late final List<perm.PermissionStatus> locationPerm;
    if (Platform.isIOS) {
      locationPerm = [await perm.Permission.location.request()];
    }
    if (Platform.isAndroid) {
      locationPerm = [
        await perm.Permission.locationWhenInUse.request(),
        await perm.Permission.locationAlways.request(),
      ];
    }
    return PermissionResponse(locationPerm);
  }

  Future<PermissionResponse> requestCamera() async {
    late final List<perm.PermissionStatus> cameraPerm;
    cameraPerm = [
      await perm.Permission.camera.request(),
    ];
    return PermissionResponse(cameraPerm);
  }

  Future<PermissionResponse> requestMediaLocation() async {
    late final List<perm.PermissionStatus> cameraPerm;
    cameraPerm = [
      await perm.Permission.accessMediaLocation.request(),
    ];
    return PermissionResponse(cameraPerm);
  }

  Future<PermissionResponse> requestMediaLibrary() async {
    late final List<perm.PermissionStatus> cameraPerm;
    cameraPerm = [
      await perm.Permission.mediaLibrary.request(),
    ];
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
      bluetoothPerm = [
        await perm.Permission.bluetooth.request(),
        if (connect) await perm.Permission.bluetoothConnect.request(),
        if (scan) await perm.Permission.bluetoothScan.request(),
        if (advertise) await perm.Permission.bluetoothAdvertise.request(),
      ];
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
        externalStoragePerm = [
          await perm.Permission.manageExternalStorage.request(),
        ];
      } else {
        externalStoragePerm = [await perm.Permission.storage.request()];
      }
    }
    return PermissionResponse(externalStoragePerm);
  }

  /// If you want to access photos, videos, or audio use this method. It is not for accessing external storage.
  /// PermissionResponse has all the required fields that needs to be added into info.plist and android manifest for you to now waste your time on finding what to add.
  /// It is accessible via PermissionResponse.toMap() method.
  Future<PermissionResponse> requestMedia(
      {bool photos = true,
      bool videos = false,
      bool audio = false,
      bool music = false}) async {
    late final List<perm.PermissionStatus> mediaPerm;
    if (Platform.isIOS) {
      mediaPerm = [
        if (iosversion >= 14) await perm.Permission.photos.request(),
        if (iosversion >= 9.3 && iosversion <= 14 && music)
          await perm.Permission.mediaLibrary.request(),
      ];
    }
    if (Platform.isAndroid) {
      if (androidsdk >= 29) {
        mediaPerm = [
          if (photos) await perm.Permission.photos.request(),
          if (videos) await perm.Permission.videos.request(),
          if (audio) await perm.Permission.audio.request()
        ];
      } else {
        mediaPerm = [await perm.Permission.storage.request()];
      }
    }
    return PermissionResponse(mediaPerm, infoplistkeys: {
      "NSPhotoLibraryUsageDescription":
          "Your app accesses the user's photo library",
      "NSPhotoLibraryAddUsageDescription":
          "Your app adds photos to the user's photo library"
    });
  }
}
