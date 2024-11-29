library;

import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart' as perm;
import 'package:permission_manager/models/permission_response.dart';

export 'package:permission_handler/permission_handler.dart';
export 'package:permission_manager/permission_manager.dart';

class PermissionManager {
  final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();

  BaseDeviceInfo? _baseDeviceInfo;
  AndroidDeviceInfo? _androidDeviceInfo;
  IosDeviceInfo? _iosDeviceInfo;
  WindowsDeviceInfo? _windowsDeviceInfo;
  MacOsDeviceInfo? _macosDeviceInfo;
  LinuxDeviceInfo? _linuxDeviceInfo;
  WebBrowserInfo? _webBrowserInfo;

  PermissionManager() {
    _initializeDeviceInfo();
  }

  Future<void> _initializeDeviceInfo() async {
    _baseDeviceInfo = await _deviceInfoPlugin.deviceInfo;

    if (kIsWeb) {
      _webBrowserInfo = await _deviceInfoPlugin.webBrowserInfo;
    } else if (Platform.isAndroid) {
      _androidDeviceInfo = await _deviceInfoPlugin.androidInfo;
    } else if (Platform.isIOS) {
      _iosDeviceInfo = await _deviceInfoPlugin.iosInfo;
    } else if (Platform.isWindows) {
      _windowsDeviceInfo = await _deviceInfoPlugin.windowsInfo;
    } else if (Platform.isMacOS) {
      _macosDeviceInfo = await _deviceInfoPlugin.macOsInfo;
    } else if (Platform.isLinux) {
      _linuxDeviceInfo = await _deviceInfoPlugin.linuxInfo;
    }
  }

  int get androidSdkVersion => _androidDeviceInfo?.version.sdkInt ?? 0;
  double get iosVersion =>
      double.tryParse(_iosDeviceInfo?.systemVersion ?? '') ?? 0;

  Future<perm.PermissionStatus> cameraStatus() async {
    return perm.Permission.camera.status;
  }

  Future<PermissionResponse> requestLocation() async {
    List<perm.PermissionStatus> locationPermissions = [];
    if (Platform.isIOS) {
      locationPermissions = [await perm.Permission.location.request()];
    } else if (Platform.isAndroid) {
      locationPermissions = [
        await perm.Permission.locationWhenInUse.request(),
        await perm.Permission.locationAlways.request(),
      ];
    }
    return PermissionResponse(locationPermissions);
  }

  Future<PermissionResponse> requestCamera() async {
    final cameraPerm = [await perm.Permission.camera.request()];
    return PermissionResponse(cameraPerm);
  }

  Future<PermissionResponse> requestMediaLocation() async {
    final mediaLocationPerm = [
      await perm.Permission.accessMediaLocation.request()
    ];
    return PermissionResponse(mediaLocationPerm);
  }

  Future<PermissionResponse> requestMediaLibrary() async {
    final mediaLibraryPerm = [await perm.Permission.mediaLibrary.request()];
    return PermissionResponse(mediaLibraryPerm);
  }

  Future<PermissionResponse> requestBluetooth({
    bool connect = true,
    bool scan = true,
    bool advertise = false,
  }) async {
    List<perm.PermissionStatus> bluetoothPermissions = [];

    if (Platform.isIOS) {
      bluetoothPermissions = [await perm.Permission.bluetooth.request()];
    } else if (Platform.isAndroid) {
      bluetoothPermissions = [
        await perm.Permission.bluetooth.request(),
        if (connect) await perm.Permission.bluetoothConnect.request(),
        if (scan) await perm.Permission.bluetoothScan.request(),
        if (advertise) await perm.Permission.bluetoothAdvertise.request(),
      ];
    }

    return PermissionResponse(bluetoothPermissions);
  }

  Future<PermissionResponse> requestExternalStorage() async {
    List<perm.PermissionStatus> storagePermissions = [];

    if (Platform.isIOS) {
      storagePermissions = [await perm.Permission.storage.request()];
    } else if (Platform.isAndroid) {
      storagePermissions = androidSdkVersion >= 30
          ? [await perm.Permission.manageExternalStorage.request()]
          : [await perm.Permission.storage.request()];
    }

    return PermissionResponse(storagePermissions);
  }

  Future<PermissionResponse> requestMedia({
    bool photos = true,
    bool videos = false,
    bool audio = false,
    bool music = false,
  }) async {
    List<perm.PermissionStatus> mediaPermissions = [];

    if (Platform.isIOS) {
      if (iosVersion >= 14) {
        if (photos) {
          mediaPermissions.add(await perm.Permission.photos.request());
        }
      }
      if (iosVersion >= 9.3 && iosVersion <= 14 && music) {
        mediaPermissions.add(await perm.Permission.mediaLibrary.request());
      }
    } else if (Platform.isAndroid) {
      if (androidSdkVersion >= 29) {
        if (photos) {
          mediaPermissions.add(await perm.Permission.photos.request());
        }
        if (videos) {
          mediaPermissions.add(await perm.Permission.videos.request());
        }
        if (audio) mediaPermissions.add(await perm.Permission.audio.request());
      } else {
        mediaPermissions = [await perm.Permission.storage.request()];
      }
    }

    return PermissionResponse(
      mediaPermissions,
      infoplistkeys: {
        "NSPhotoLibraryUsageDescription":
            "Your app accesses the user's photo library",
        "NSPhotoLibraryAddUsageDescription":
            "Your app adds photos to the user's photo library"
      },
    );
  }
}
