import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart' as perm;
import 'package:permission_manager/models/permission_response.dart';

export 'package:permission_handler/permission_handler.dart';
export 'package:permission_manager/permission_manager.dart';

class PermissionManager {
  final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();

  // Device info for all supported platforms
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
    try {
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
    } catch (e) {
      // Handle any errors during device info initialization
      debugPrint('Error initializing device info: $e');
    }
  }

  // Platform-specific version getters
  int get androidSdkVersion => _androidDeviceInfo?.version.sdkInt ?? 0;
  double get iosVersion =>
      double.tryParse(_iosDeviceInfo?.systemVersion ?? '') ?? 0;
  String get windowsVersion => _windowsDeviceInfo?.buildNumber.toString() ?? '';
  String get macosVersion => _macosDeviceInfo?.osRelease ?? '';
  String get linuxVersion => _linuxDeviceInfo?.version ?? '';
  String get webUserAgent => _webBrowserInfo?.userAgent ?? '';

  // Platform detection getters
  bool get isAndroid => !kIsWeb && Platform.isAndroid;
  bool get isIOS => !kIsWeb && Platform.isIOS;
  bool get isWindows => !kIsWeb && Platform.isWindows;
  bool get isMacOS => !kIsWeb && Platform.isMacOS;
  bool get isLinux => !kIsWeb && Platform.isLinux;
  bool get isWeb => kIsWeb;

  Future<perm.PermissionStatus> cameraStatus() async {
    return perm.Permission.camera.status;
  }

  Future<PermissionResponse> requestLocation() async {
    List<perm.PermissionStatus> locationPermissions = [];
    
    if (isIOS) {
      locationPermissions = [await perm.Permission.location.request()];
    } else if (isAndroid) {
      locationPermissions = [
        await perm.Permission.locationWhenInUse.request(),
        await perm.Permission.locationAlways.request(),
      ];
    } else if (isWindows) {
      // Windows location permissions
      locationPermissions = [await perm.Permission.location.request()];
    } else if (isWeb) {
      // Web location permissions
      locationPermissions = [await perm.Permission.location.request()];
    } else {
      // macOS and Linux don't have location permissions in permission_handler
      // Return a response indicating no permissions were requested
      return PermissionResponse([]);
    }
    
    return PermissionResponse(locationPermissions);
  }

  Future<PermissionResponse> requestCamera() async {
    List<perm.PermissionStatus> cameraPermissions = [];

    if (isAndroid || isIOS || isWindows || isWeb) {
      cameraPermissions = [await perm.Permission.camera.request()];
    } else {
      // macOS and Linux don't have camera permissions in permission_handler
      return PermissionResponse([]);
    }

    return PermissionResponse(cameraPermissions);
  }

  Future<PermissionResponse> requestMediaLocation() async {
    List<perm.PermissionStatus> mediaLocationPermissions = [];

    if (isAndroid) {
      mediaLocationPermissions = [
        await perm.Permission.accessMediaLocation.request()
      ];
    } else {
      // Other platforms don't have media location permissions
      return PermissionResponse([]);
    }

    return PermissionResponse(mediaLocationPermissions);
  }

  Future<PermissionResponse> requestMediaLibrary() async {
    List<perm.PermissionStatus> mediaLibraryPermissions = [];

    if (isAndroid || isIOS) {
      mediaLibraryPermissions = [await perm.Permission.mediaLibrary.request()];
    } else {
      // Other platforms don't have media library permissions
      return PermissionResponse([]);
    }

    return PermissionResponse(mediaLibraryPermissions);
  }

  Future<PermissionResponse> requestBluetooth({
    bool connect = true,
    bool scan = true,
    bool advertise = false,
  }) async {
    List<perm.PermissionStatus> bluetoothPermissions = [];

    if (isIOS) {
      bluetoothPermissions = [await perm.Permission.bluetooth.request()];
    } else if (isAndroid) {
      bluetoothPermissions = [
        await perm.Permission.bluetooth.request(),
        if (connect) await perm.Permission.bluetoothConnect.request(),
        if (scan) await perm.Permission.bluetoothScan.request(),
        if (advertise) await perm.Permission.bluetoothAdvertise.request(),
      ];
    } else if (isWindows) {
      // Windows bluetooth permissions
      bluetoothPermissions = [await perm.Permission.bluetooth.request()];
    } else {
      // Web, macOS, and Linux don't have bluetooth permissions in permission_handler
      return PermissionResponse([]);
    }

    return PermissionResponse(bluetoothPermissions);
  }

  Future<PermissionResponse> requestExternalStorage() async {
    List<perm.PermissionStatus> storagePermissions = [];

    if (isIOS) {
      storagePermissions = [await perm.Permission.storage.request()];
    } else if (isAndroid) {
      storagePermissions = androidSdkVersion >= 30
          ? [await perm.Permission.manageExternalStorage.request()]
          : [await perm.Permission.storage.request()];
    } else if (isWindows) {
      // Windows storage permissions
      storagePermissions = [await perm.Permission.storage.request()];
    } else {
      // Web, macOS, and Linux don't have storage permissions in permission_handler
      return PermissionResponse([]);
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

    if (isIOS) {
      if (iosVersion >= 14) {
        if (photos) {
          mediaPermissions.add(await perm.Permission.photos.request());
        }
      }
      if (iosVersion >= 9.3 && iosVersion <= 14 && music) {
        mediaPermissions.add(await perm.Permission.mediaLibrary.request());
      }
    } else if (isAndroid) {
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
    } else if (isWindows) {
      // Windows media permissions
      if (photos) {
        mediaPermissions.add(await perm.Permission.photos.request());
      }
      if (videos) {
        mediaPermissions.add(await perm.Permission.videos.request());
      }
      if (audio) {
        mediaPermissions.add(await perm.Permission.audio.request());
      }
    } else {
      // Web, macOS, and Linux don't have these media permissions in permission_handler
      return PermissionResponse([]);
    }

    return PermissionResponse(
      mediaPermissions,
      infoplistkeys: isIOS
          ? {
        "NSPhotoLibraryUsageDescription":
            "Your app accesses the user's photo library",
        "NSPhotoLibraryAddUsageDescription":
            "Your app adds photos to the user's photo library"
            }
          : null,
    );
  }

  // Additional platform-specific methods
  Future<PermissionResponse> requestMicrophone() async {
    List<perm.PermissionStatus> microphonePermissions = [];

    if (isAndroid || isIOS || isWindows || isWeb) {
      microphonePermissions = [await perm.Permission.microphone.request()];
    } else {
      // macOS and Linux don't have microphone permissions in permission_handler
      return PermissionResponse([]);
    }

    return PermissionResponse(microphonePermissions);
  }

  Future<PermissionResponse> requestNotification() async {
    List<perm.PermissionStatus> notificationPermissions = [];

    if (isAndroid || isIOS) {
      notificationPermissions = [await perm.Permission.notification.request()];
    } else {
      // Other platforms don't have notification permissions in permission_handler
      return PermissionResponse([]);
    }

    return PermissionResponse(notificationPermissions);
  }

  Future<PermissionResponse> requestPhone() async {
    List<perm.PermissionStatus> phonePermissions = [];

    if (isAndroid || isIOS) {
      phonePermissions = [await perm.Permission.phone.request()];
    } else {
      // Other platforms don't have phone permissions in permission_handler
      return PermissionResponse([]);
    }

    return PermissionResponse(phonePermissions);
  }

  Future<PermissionResponse> requestSensors() async {
    List<perm.PermissionStatus> sensorPermissions = [];

    if (isAndroid) {
      sensorPermissions = [await perm.Permission.sensors.request()];
    } else {
      // Other platforms don't have sensor permissions in permission_handler
      return PermissionResponse([]);
    }

    return PermissionResponse(sensorPermissions);
  }

  // Platform information getters
  Map<String, dynamic> getPlatformInfo() {
    if (isAndroid) {
      return {
        'platform': 'Android',
        'sdkVersion': androidSdkVersion,
        'model': _androidDeviceInfo?.model,
        'brand': _androidDeviceInfo?.brand,
        'manufacturer': _androidDeviceInfo?.manufacturer,
      };
    } else if (isIOS) {
      return {
        'platform': 'iOS',
        'version': iosVersion,
        'model': _iosDeviceInfo?.model,
        'systemName': _iosDeviceInfo?.systemName,
        'systemVersion': _iosDeviceInfo?.systemVersion,
      };
    } else if (isWindows) {
      return {
        'platform': 'Windows',
        'version': windowsVersion,
        'buildNumber': _windowsDeviceInfo?.buildNumber,
        'majorVersion': _windowsDeviceInfo?.majorVersion,
        'minorVersion': _windowsDeviceInfo?.minorVersion,
      };
    } else if (isMacOS) {
      return {
        'platform': 'macOS',
        'version': macosVersion,
        'model': _macosDeviceInfo?.model,
        'osRelease': _macosDeviceInfo?.osRelease,
        'kernelVersion': _macosDeviceInfo?.kernelVersion,
      };
    } else if (isLinux) {
      return {
        'platform': 'Linux',
        'version': linuxVersion,
        'name': _linuxDeviceInfo?.name,
        'versionId': _linuxDeviceInfo?.versionId,
        'variant': _linuxDeviceInfo?.variant,
      };
    } else if (isWeb) {
      return {
        'platform': 'Web',
        'userAgent': webUserAgent,
        'browserName': _webBrowserInfo?.browserName,
        'appVersion': _webBrowserInfo?.appVersion,
        'browserPlatform': _webBrowserInfo?.platform,
      };
    }

    return {'platform': 'Unknown'};
  }
}
