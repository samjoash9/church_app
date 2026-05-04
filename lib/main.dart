import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

import 'models/sound_entry.dart';
import 'screens/worship_pads_screen.dart';
import 'theme/app_colors.dart';
import 'theme/theme_provider.dart';
import 'services/song_repository.dart';
import 'services/lineup_repository.dart';
import 'services/ppt_repository.dart';

/// Asset paths for each major key's default bundled pad.
const _defaultMajorPads = <String, String>{
  'A': 'assets/audio/A_Major_Pad.mp3',
  'B': 'assets/audio/B_Major_Pad.mp3',
  'C': 'assets/audio/C_Major_Pad.mp3',
  'D': 'assets/audio/D Major Pad.mp3',
  'E': 'assets/audio/E_Major_Pad.mp3',
  'F': 'assets/audio/F_Major_Pad.mp3',
  'G': 'assets/audio/G_Major_Pad.mp3',
};

/// Returns the media_kit URI for a bundled asset path.
/// e.g. 'assets/audio/A_Major_Pad.mp3' → 'asset:///assets/audio/A_Major_Pad.mp3'
String _assetUri(String assetPath) => 'asset:///$assetPath';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  await SongRepository().init();
  await LineupRepository().init();
  await PptRepository().init();

  // Build the default library: one bundled sound per Major key.
  final defaultSounds = <String, List<SoundEntry>>{};
  final defaultActivePaths = <String, String>{};

  _defaultMajorPads.forEach((key, assetPath) {
    final folderId = 'Major::$key';
    final entry = SoundEntry(
      name: '$key Major Pad',
      path: _assetUri(assetPath),
      sizeInBytes: 0,
      isAsset: true,
    );
    defaultSounds[folderId] = [entry];
    defaultActivePaths[folderId] = entry.path;
  });

  runApp(
    WorshipPadsApp(
      initialLibrarySounds: defaultSounds,
      initialActiveSoundPaths: defaultActivePaths,
    ),
  );
}

class WorshipPadsApp extends StatefulWidget {
  const WorshipPadsApp({
    super.key,
    this.initialLibrarySounds = const {},
    this.initialActiveSoundPaths = const {},
  });

  final Map<String, List<SoundEntry>> initialLibrarySounds;
  final Map<String, String> initialActiveSoundPaths;

  @override
  State<WorshipPadsApp> createState() => _WorshipPadsAppState();
}

class _WorshipPadsAppState extends State<WorshipPadsApp> {
  final _themeNotifier = ThemeNotifier();

  @override
  void dispose() {
    _themeNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ThemeProvider(
      notifier: _themeNotifier,
      child: Builder(
        builder: (context) {
          final isDark = ThemeProvider.of(context).isDarkMode;
          final appColors = isDark ? AppColors.dark : AppColors.light;

          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Worship Pads',
            theme: ThemeData(
              useMaterial3: true,
              scaffoldBackgroundColor: appColors.scaffold,
              fontFamily: 'Roboto',
              extensions: [appColors],
            ),
            home: WorshipPadsScreen(
              initialLibrarySounds: widget.initialLibrarySounds,
              initialActiveSoundPaths: widget.initialActiveSoundPaths,
            ),
          );
        },
      ),
    );
  }
}
