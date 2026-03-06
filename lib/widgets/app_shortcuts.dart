import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/lang.dart';

class ShortcutItem {
  final String packageName;
  final String appName;
  final String? iconBase64;

  ShortcutItem({
    required this.packageName,
    required this.appName,
    this.iconBase64,
  });

  Map<String, dynamic> toJson() => {
    'packageName': packageName,
    'appName': appName,
    'iconBase64': iconBase64,
  };

  factory ShortcutItem.fromJson(Map<String, dynamic> json) => ShortcutItem(
    packageName: json['packageName'],
    appName: json['appName'],
    iconBase64: json['iconBase64'],
  );
}

class AppShortcuts extends StatefulWidget {
  const AppShortcuts({super.key});

  @override
  State<AppShortcuts> createState() => _AppShortcutsState();
}

class _AppShortcutsState extends State<AppShortcuts> {
  static const String _prefsKey = 'pomo_custom_native_shortcuts_v3';
  static const platform = MethodChannel('com.example.pomospace/apps');
  List<ShortcutItem> _shortcuts = [];

  @override
  void initState() {
    super.initState();
    _loadShortcuts();
  }

  Future<void> _loadShortcuts() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_prefsKey);
    if (data != null) {
      final List<dynamic> decoded = jsonDecode(data);
      setState(() {
        _shortcuts = decoded
            .map((item) => ShortcutItem.fromJson(item))
            .toList();
      });
    }
  }

  Future<void> _saveShortcuts() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(
      _shortcuts.map((s) => s.toJson()).toList(),
    );
    await prefs.setString(_prefsKey, encoded);
  }

  Future<void> _launchApp(String packageName) async {
    try {
      final bool? launched = await platform.invokeMethod<bool>('launchApp', {
        'packageName': packageName,
      });
      if (launched != true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('App "$packageName" could not be launched.')),
        );
      }
    } on PlatformException catch (e) {
      debugPrint("Failed to launch app: '${e.message}'.");
    }
  }

  void _showAddShortcutDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Colors.deepPurpleAccent),
      ),
    );

    List<dynamic> apps = [];
    try {
      final result = await platform.invokeMethod('getInstalledApps');
      if (result != null) {
        apps = result as List<dynamic>;
      }
    } catch (e) {
      debugPrint("Failed to get apps: $e");
    }

    if (!mounted) return;
    Navigator.pop(context); // close loading dialog

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  AppLang.selectNativeApp,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: apps.length,
                  itemBuilder: (context, index) {
                    final app = apps[index] as Map<dynamic, dynamic>;
                    final String packageName = app['packageName'] as String;
                    final String appName = app['appName'] as String;
                    final String? iconBase64 = app['icon'] as String?;

                    Widget iconWidget = const Icon(
                      Icons.android,
                      color: Colors.greenAccent,
                    );
                    if (iconBase64 != null && iconBase64.isNotEmpty) {
                      try {
                        Uint8List bytes = base64Decode(iconBase64);
                        iconWidget = Image.memory(bytes, width: 32, height: 32);
                      } catch (e) {
                        debugPrint("Base64 error $e");
                      }
                    }

                    return ListTile(
                      leading: iconWidget,
                      title: Text(
                        appName,
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        packageName,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          if (!_shortcuts.any(
                            (s) => s.packageName == packageName,
                          )) {
                            _shortcuts.add(
                              ShortcutItem(
                                packageName: packageName,
                                appName: appName,
                                iconBase64: iconBase64,
                              ),
                            );
                          }
                        });
                        _saveShortcuts();
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _removeShortcut(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          AppLang.delete,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: Text(
          '${AppLang.delete} ${_shortcuts[index].appName}?',
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLang.cancel,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              setState(() {
                _shortcuts.removeAt(index);
              });
              _saveShortcuts();
              Navigator.pop(context);
            },
            child: Text(AppLang.delete),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ..._shortcuts.asMap().entries.map((entry) {
            final int index = entry.key;
            final ShortcutItem shortcut = entry.value;

            Widget iconWidget = const Icon(
              Icons.android,
              color: Colors.greenAccent,
              size: 24,
            );
            if (shortcut.iconBase64 != null &&
                shortcut.iconBase64!.isNotEmpty) {
              try {
                Uint8List bytes = base64Decode(shortcut.iconBase64!);
                iconWidget = Image.memory(bytes, width: 24, height: 24);
              } catch (e) {
                debugPrint("Base64 error $e");
              }
            }

            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Tooltip(
                message: shortcut.appName,
                child: InkWell(
                  onTap: () => _launchApp(shortcut.packageName),
                  onLongPress: () => _removeShortcut(index),
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.05),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: iconWidget,
                  ),
                ),
              ),
            );
          }),
          // Add Button
          Tooltip(
            message: AppLang.add,
            child: InkWell(
              onTap: _showAddShortcutDialog,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.deepPurpleAccent.withOpacity(0.2),
                  border: Border.all(
                    color: Colors.deepPurpleAccent.withOpacity(0.5),
                  ),
                ),
                child: Icon(
                  Icons.add,
                  color: Colors.deepPurpleAccent.shade100,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
