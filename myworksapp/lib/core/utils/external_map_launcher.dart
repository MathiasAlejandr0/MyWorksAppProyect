import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'platform_support.dart';

/// Abre la ubicación en apps de navegación externas (Google Maps, Waze, Apple Maps).
class ExternalMapLauncher {
  ExternalMapLauncher._();

  static Future<void> showNavigationChooser(
    BuildContext context, {
    required double latitude,
    required double longitude,
  }) async {
    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Abrir ubicación en',
                  style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.map_outlined),
                  title: const Text('Google Maps'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _openGoogleMaps(latitude, longitude);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.navigation_outlined),
                  title: const Text('Waze'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _openWaze(latitude, longitude);
                  },
                ),
                if (AppPlatform.isIOS)
                  ListTile(
                    leading: const Icon(Icons.place_outlined),
                    title: const Text('Apple Maps'),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _openAppleMaps(latitude, longitude);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Future<void> _openGoogleMaps(double latitude, double longitude) async {
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );
    await _launch(url);
  }

  static Future<void> _openWaze(double latitude, double longitude) async {
    final appUrl = Uri.parse(
      'waze://?ll=$latitude,$longitude&navigate=yes',
    );
    if (await canLaunchUrl(appUrl)) {
      await launchUrl(appUrl, mode: LaunchMode.externalApplication);
      return;
    }

    final webUrl = Uri.parse(
      'https://waze.com/ul?ll=$latitude,$longitude&navigate=yes',
    );
    await _launch(webUrl);
  }

  static Future<void> _openAppleMaps(double latitude, double longitude) async {
    final url = Uri.parse(
      'https://maps.apple.com/?daddr=$latitude,$longitude',
    );
    await _launch(url);
  }

  static Future<void> _launch(Uri url) async {
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}
