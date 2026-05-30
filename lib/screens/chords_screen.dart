import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../theme/app_colors.dart';
import '../widgets/section_header.dart';
import '../widgets/app_drawer.dart';
import '../models/song.dart';
import 'create_song_screen.dart';
import 'song_editor_screen.dart';
import 'song_overview_screen.dart';
import 'lineup_screen.dart';
import '../services/song_repository.dart';
import '../services/lineup_repository.dart';
import '../services/pdf_export_service.dart';
import '../services/transposer.dart';

class ChordsScreen extends StatefulWidget {
  const ChordsScreen({super.key});

  @override
  State<ChordsScreen> createState() => _ChordsScreenState();
}

class _ChordsScreenState extends State<ChordsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  Future<void> _exportSongAsPdf(SongData song) async {
    try {
      final pdf = await PdfExportService.generateChordChart(song);

      final savedPath = await PdfExportService.exportPdf(
        pdf: pdf,
        songTitle: song.title,
      );

      if (!mounted || savedPath == null) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF exported successfully!')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF export failed: $error')),
      );
    }
  }

  Future<String?> _exportSongs(List<SongData> songs) async {
    final payload = const JsonEncoder.withIndent(
      '  ',
    ).convert(songs.map((song) => song.toMap()).toList());
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final fileName = 'songs_export_$timestamp.json';

    if (Platform.isAndroid || Platform.isIOS) {
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/$fileName';
      final file = File(filePath);
      await file.writeAsString(payload);

      try {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(filePath, mimeType: 'application/json')],
            title: 'Export Songs',
          ),
        );
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Share failed: $error')),
          );
        }
        return null;
      }

      return filePath;
    }

    final outputPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Export Songs',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (outputPath == null) return null;

    final finalPath =
        outputPath.endsWith('.json') ? outputPath : '$outputPath.json';
    final file = File(finalPath);
    await file.writeAsString(payload);
    return finalPath;
  }

  Future<void> _importSongs() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Import Songs',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) return;
      final pickedPath = result.files.first.path;
      if (pickedPath == null) return;

      final file = File(pickedPath);
      final content = await file.readAsString();
      final decoded = jsonDecode(content);

      final List<dynamic> rawSongs;
      if (decoded is List) {
        rawSongs = decoded;
      } else if (decoded is Map<String, dynamic>) {
        rawSongs = [decoded];
      } else {
        throw const FormatException('Unsupported JSON format.');
      }

      if (rawSongs.isEmpty) {
        throw const FormatException('No songs found in the selected file.');
      }

      var importedCount = 0;
      for (final rawSong in rawSongs) {
        if (rawSong is! Map) continue;
        final song = SongData.fromMap(Map<String, dynamic>.from(rawSong));
        if (song.id.isEmpty || song.title.isEmpty) continue;
        await SongRepository().saveSong(song);
        importedCount++;
      }

      if (!mounted) return;

      if (importedCount == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No valid songs were found in that JSON file.'),
          ),
        );
        return;
      }

      _refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$importedCount song${importedCount == 1 ? '' : 's'} imported successfully!',
          ),
        ),
      );
    } on FormatException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import failed: ${error.message}')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Import failed. Please choose a valid JSON file.'),
        ),
      );
    }
  }

  Future<void> _showExportSongsModal(List<SongData> songs, {bool isPdf = false}) async {
    final selectedSongIds = songs.map((song) => song.id).toSet();
    String sheetSearchQuery = '';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        final colors = AppColors.of(context);
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final filteredSongs = songs.where((song) {
              return song.title.toLowerCase().contains(sheetSearchQuery) ||
                  song.songKey.toLowerCase().contains(sheetSearchQuery);
            }).toList();
            final selectedSongs = songs
                .where((song) => selectedSongIds.contains(song.id))
                .toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isPdf ? 'Export PDFs' : 'Export Songs',
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${selectedSongs.length} of ${songs.length} selected',
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(Icons.close, color: colors.textMuted),
                          onPressed: () => Navigator.of(sheetCtx).pop(),
                        ),
                      ],
                    ),
                  ),
                  Divider(color: colors.border, height: 1),
                  if (songs.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Column(
                        children: [
                          TextField(
                            onChanged: (value) {
                              setSheetState(() {
                                sheetSearchQuery = value.toLowerCase();
                              });
                            },
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 14,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search songs...',
                              hintStyle: TextStyle(color: colors.textMuted),
                              prefixIcon: Icon(
                                Icons.search,
                                color: colors.textMuted,
                                size: 20,
                              ),
                              isDense: true,
                              filled: true,
                              fillColor: colors.surfaceDim,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: colors.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: colors.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: colors.accent),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              TextButton(
                                onPressed: () {
                                  setSheetState(() {
                                    selectedSongIds
                                      ..clear()
                                      ..addAll(songs.map((song) => song.id));
                                  });
                                },
                                child: const Text('Select all'),
                              ),
                              TextButton(
                                onPressed: () {
                                  setSheetState(() {
                                    selectedSongIds.clear();
                                  });
                                },
                                child: const Text('Clear all'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  if (songs.isEmpty)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.queue_music_rounded,
                              size: 48,
                              color: colors.textMuted,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No songs available',
                              style: TextStyle(
                                color: colors.textMuted,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Create songs first from the Chords screen.',
                              style: TextStyle(
                                color: colors.textMuted,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: filteredSongs.isEmpty
                          ? Center(
                              child: Text(
                                'No songs found',
                                style: TextStyle(color: colors.textMuted),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: filteredSongs.length,
                              separatorBuilder: (_, __) => Divider(
                                color: colors.border,
                                height: 1,
                                indent: 72,
                              ),
                              itemBuilder: (_, index) {
                                final song = filteredSongs[index];
                                final isChecked = selectedSongIds.contains(
                                  song.id,
                                );

                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 4,
                                  ),
                                  leading: Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: colors.accentSurface.withAlpha(51),
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      song.songKey,
                                      style: TextStyle(
                                        color: colors.accent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    song.title,
                                    style: TextStyle(
                                      color: colors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Key of ${song.songKey}',
                                    style: TextStyle(
                                      color: colors.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                  trailing: Checkbox(
                                    value: isChecked,
                                    activeColor: colors.accent,
                                    side: BorderSide(
                                      color: colors.border,
                                      width: 1.5,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    onChanged: (value) {
                                      setSheetState(() {
                                        if (value == true) {
                                          selectedSongIds.add(song.id);
                                        } else {
                                          selectedSongIds.remove(song.id);
                                        }
                                      });
                                    },
                                  ),
                                  onTap: () {
                                    setSheetState(() {
                                      if (isChecked) {
                                        selectedSongIds.remove(song.id);
                                      } else {
                                        selectedSongIds.add(song.id);
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                    ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      8,
                      16,
                      MediaQuery.of(context).viewInsets.bottom + 16,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: selectedSongs.isEmpty
                            ? null
                            : () async {
                                final messenger = ScaffoldMessenger.of(
                                  this.context,
                                );
                                Navigator.of(sheetCtx).pop();
                                
                                if (isPdf) {
                                  final pdf = await PdfExportService.generateChordCharts(selectedSongs);
                                  final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
                                  final savedPath = await PdfExportService.exportPdf(
                                    pdf: pdf,
                                    songTitle: 'songs_export_$timestamp',
                                  );
                                  
                                  if (!mounted || savedPath == null) return;
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '${selectedSongs.length} PDF${selectedSongs.length == 1 ? '' : 's'} exported successfully!',
                                      ),
                                    ),
                                  );
                                } else {
                                  final savedPath = await _exportSongs(
                                    selectedSongs,
                                  );
  
                                  if (!mounted || savedPath == null) return;
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '${selectedSongs.length} song${selectedSongs.length == 1 ? '' : 's'} exported successfully!',
                                      ),
                                    ),
                                  );
                                }
                              },
                        child: Text(
                          'Export ${selectedSongs.length} ${isPdf ? 'PDF' : 'song'}${selectedSongs.length == 1 ? '' : 's'}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Returns a copy of [song] with every chord shifted into [targetKey] and
  /// its stored key updated. Lyrics and section headers are untouched.
  SongData _transposeSong(SongData song, String targetKey) {
    final semitones = Transposer.semitonesBetween(song.songKey, targetKey);
    final flats = Transposer.prefersFlats(targetKey);
    return SongData(
      id: song.id,
      title: song.title,
      songKey: targetKey,
      lines: song.lines
          .map(
            (line) => SongLineData(
              lyrics: line.lyrics,
              chords: line.chords
                  .map((c) => Transposer.transposeChord(c, semitones,
                      preferFlats: flats))
                  .toList(),
            ),
          )
          .toList(),
    );
  }

  /// Dialog: pick a target key, transpose all chords, and save permanently.
  Future<void> _showChangeKeyDialog(SongData song) async {
    const allKeys = ['A', 'B', 'C', 'D', 'E', 'F', 'G'];
    final colors = AppColors.of(context);
    String selectedKey = song.songKey;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final semitones =
                Transposer.semitonesBetween(song.songKey, selectedKey);
            return AlertDialog(
              backgroundColor: colors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: colors.border),
              ),
              title: Text(
                'Change Key',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current key: ${song.songKey}',
                    style: TextStyle(color: colors.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'New key',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: colors.surfaceDim,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: allKeys.contains(selectedKey)
                            ? selectedKey
                            : null,
                        isExpanded: true,
                        dropdownColor: colors.surface,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        icon: Icon(Icons.arrow_drop_down, color: colors.textMuted),
                        items: allKeys
                            .map(
                              (k) => DropdownMenuItem(
                                value: k,
                                child: Text('Key of $k'),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedKey = val);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    semitones == 0
                        ? 'No change'
                        : '${semitones > 0 ? '+' : ''}$semitones semitone'
                            '${semitones.abs() == 1 ? '' : 's'}',
                    style: TextStyle(color: colors.textMuted, fontSize: 12),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text('Cancel',
                      style: TextStyle(color: colors.textMuted)),
                ),
                TextButton(
                  onPressed: selectedKey == song.songKey
                      ? null
                      : () => Navigator.of(ctx).pop(true),
                  child: Text(
                    'Save',
                    style: TextStyle(
                      color: selectedKey == song.songKey
                          ? colors.textMuted
                          : colors.accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true || !mounted) return;

    final transposed = _transposeSong(song, selectedKey);
    await SongRepository().saveSong(transposed);
    if (!mounted) return;
    _refresh();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"${song.title}" changed to key of $selectedKey')),
    );
  }

  void _showSongActionModal(SongData song) {
    final colors = AppColors.of(context);
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) {
        return Dialog(
          backgroundColor: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: colors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: colors.accentSurface.withAlpha(40),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.music_note_rounded,
                    color: colors.accent,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  song.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Key of ${song.songKey}',
                  style: TextStyle(color: colors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 28),

                // ── Overview ──
                _ChordsModalButton(
                  icon: Icons.visibility_rounded,
                  label: 'Overview',
                  colors: colors,
                  isPrimary: true,
                  onTap: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SongOverviewScreen(song: song),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),

                // ── Edit song ──
                _ChordsModalButton(
                  icon: Icons.edit_rounded,
                  label: 'Edit Song',
                  colors: colors,
                  isPrimary: false,
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SongEditorScreen(
                          songId: song.id,
                          title: song.title,
                          songKey: song.songKey,
                          initialLines: song.lines,
                        ),
                      ),
                    );
                    _refresh();
                  },
                ),
                const SizedBox(height: 12),

                // ── Change key ──
                _ChordsModalButton(
                  icon: Icons.swap_vert_rounded,
                  label: 'Change Key',
                  colors: colors,
                  isPrimary: false,
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _showChangeKeyDialog(song);
                  },
                ),
                const SizedBox(height: 12),

                // ── Add to Line up ──
                _ChordsModalButton(
                  icon: Icons.playlist_add_rounded,
                  label: 'Add to Line up',
                  colors: colors,
                  isPrimary: false,
                  onTap: () async {
                    await LineupRepository().addToLineup(song.id);
                    if (!mounted) return;
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('"${song.title}" added to Line up'),
                        backgroundColor: colors.accent,
                        behavior: SnackBarBehavior.floating,
                        action: SnackBarAction(
                          label: 'VIEW',
                          textColor: Colors.white,
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const LineupScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),

                // ── Export as PDF ──
                _ChordsModalButton(
                  icon: Icons.picture_as_pdf_rounded,
                  label: 'Export as PDF',
                  colors: colors,
                  isPrimary: false,
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _exportSongAsPdf(song);
                  },
                ),
                const SizedBox(height: 12),

                // ── Back ──
                _ChordsModalButton(
                  icon: Icons.arrow_back_rounded,
                  label: 'Back',
                  colors: colors,
                  isPrimary: false,
                  onTap: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final allSongs = SongRepository().songs;
    final filteredSongs = allSongs.where((song) {
      final query = _searchQuery.toLowerCase();
      return song.title.toLowerCase().contains(query) ||
          song.songKey.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      drawer: AppDrawer(selectedItem: 'Chords', onSelectItem: (_) {}),
      body: SafeArea(
        child: Column(
          children: [
            Builder(
              builder: (context) => SectionHeader(
                title: 'Chords',
                onMenuTap: () => Scaffold.of(context).openDrawer(),
                action: PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: colors.textPrimary),
                  color: colors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: colors.border),
                  ),
                  onSelected: (value) {
                    if (value == 'import') {
                      _importSongs();
                    } else if (value == 'export_songs') {
                      if (allSongs.isNotEmpty) {
                        _showExportSongsModal(allSongs, isPdf: false);
                      }
                    } else if (value == 'export_pdfs') {
                      if (allSongs.isNotEmpty) {
                        _showExportSongsModal(allSongs, isPdf: true);
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'import',
                      child: Row(
                        children: [
                          Icon(Icons.file_upload_rounded, color: colors.textPrimary, size: 20),
                          const SizedBox(width: 12),
                          Text('Import Songs', style: TextStyle(color: colors.textPrimary)),
                        ],
                      ),
                    ),
                    if (allSongs.isNotEmpty) ...[
                      PopupMenuItem(
                        value: 'export_songs',
                        child: Row(
                          children: [
                            Icon(Icons.data_object_rounded, color: colors.textPrimary, size: 20),
                            const SizedBox(width: 12),
                            Text('Export Songs', style: TextStyle(color: colors.textPrimary)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'export_pdfs',
                        child: Row(
                          children: [
                            Icon(Icons.picture_as_pdf_rounded, color: colors.textPrimary, size: 20),
                            const SizedBox(width: 12),
                            Text('Export PDFs', style: TextStyle(color: colors.textPrimary)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                child: Column(
                  children: [
                    // ── Search Bar (if songs exist) ──
                    if (allSongs.isNotEmpty) ...[
                      TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 16,
                          ),
                          hintText: 'Search songs...',
                          hintStyle: TextStyle(color: colors.textMuted),
                          prefixIcon: Icon(
                            Icons.search,
                            color: colors.textMuted,
                          ),
                          filled: true,
                          fillColor: colors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colors.accent),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],


                    // ── Empty state or Song List ──
                    if (allSongs.isEmpty)
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Spacer(),
                            Icon(
                              Icons.queue_music_rounded,
                              size: 64,
                              color: colors.textMuted,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No Songs Yet',
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Create your first chord chart to get started.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: colors.textMuted,
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colors.accent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () async {
                                final result = await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const CreateSongScreen(),
                                  ),
                                );
                                if (!context.mounted) return;
                                if (result != null && result is Map) {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => SongEditorScreen(
                                        title: result['title'],
                                        songKey: result['key'],
                                      ),
                                    ),
                                  );
                                }
                                _refresh();
                              },
                              icon: const Icon(Icons.add_rounded),
                              label: const Text(
                                'Create New Song',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: colors.textPrimary,
                                side: BorderSide(color: colors.border),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _importSongs,
                              icon: const Icon(Icons.file_upload_rounded),
                              label: const Text(
                                'Import Songs',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            const Spacer(),
                          ],
                        ),
                      )
                    else if (filteredSongs.isEmpty)
                      Expanded(
                        child: Center(
                          child: Text(
                            'No songs found matching "$_searchQuery"',
                            style: TextStyle(
                              color: colors.textMuted,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: ListView.separated(
                            itemCount: filteredSongs.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final song = filteredSongs[index];
                              return InkWell(
                                onTap: () {
                                  _showSongActionModal(song);
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Ink(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colors.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: colors.border),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: colors.accentSurface.withAlpha(
                                            51,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          song.songKey,
                                          style: TextStyle(
                                            color: colors.accent,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              song.title,
                                              style: TextStyle(
                                                color: colors.textPrimary,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Key of ${song.songKey}',
                                              style: TextStyle(
                                                color: colors.textSecondary,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.delete_outline,
                                          color: colors.danger,
                                        ),
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              backgroundColor: colors.surface,
                                              title: Text(
                                                'Delete Song',
                                                style: TextStyle(
                                                  color: colors.textPrimary,
                                                ),
                                              ),
                                              content: Text(
                                                'Are you sure you want to delete "${song.title}"?',
                                                style: TextStyle(
                                                  color: colors.textSecondary,
                                                ),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                  child: Text(
                                                    'Cancel',
                                                    style: TextStyle(
                                                      color: colors.textMuted,
                                                    ),
                                                  ),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    SongRepository().deleteSong(
                                                      song.id,
                                                    );
                                                    Navigator.pop(context);
                                                    _refresh();
                                                  },
                                                  child: Text(
                                                    'Delete',
                                                    style: TextStyle(
                                                      color: colors.danger,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        shape: const CircleBorder(),
        backgroundColor: colors.accent,
        foregroundColor: colors.onAccent,
        elevation: 4,
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const CreateSongScreen(),
            ),
          );
          if (!context.mounted) return;
          if (result != null && result is Map) {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SongEditorScreen(
                  title: result['title'],
                  songKey: result['key'],
                ),
              ),
            );
          }
          _refresh();
        },
        child: const Icon(Icons.add_rounded, size: 32),
      ),
    );
  }
}

class _ChordsModalButton extends StatelessWidget {
  const _ChordsModalButton({
    required this.icon,
    required this.label,
    required this.colors,
    required this.isPrimary,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final AppColors colors;
  final bool isPrimary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = isPrimary ? colors.accentSurface : colors.surfaceDim;
    final fg = isPrimary ? colors.onAccent : colors.textPrimary;
    final borderColor = isPrimary ? colors.accentSurface : colors.border;

    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor, width: 1.2),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: fg, size: 20),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    color: fg,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
