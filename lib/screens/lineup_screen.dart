import 'package:flutter/material.dart';
import '../models/song.dart';
import '../models/ppt.dart';
import '../models/ppt_theme.dart';
import '../services/song_repository.dart';
import '../services/lineup_repository.dart';
import '../services/pdf_export_service.dart';
import '../services/ppt_export_service.dart';
import '../services/ppt_themes.dart';
import '../services/transposer.dart';
import '../theme/app_colors.dart';
import '../widgets/section_header.dart';
import '../widgets/app_drawer.dart';
import 'perform_screen.dart';
import 'song_overview_screen.dart';

class LineupScreen extends StatefulWidget {
  const LineupScreen({super.key});

  @override
  State<LineupScreen> createState() => _LineupScreenState();
}

class _LineupScreenState extends State<LineupScreen> {
  void _refresh() => setState(() {});

  // ── Theme picker + export ───────────────────────────────────────────────
  Future<void> _exportWithThemePicker(PptData ppt, List<SongData> pptSongs) async {
    final colors = AppColors.of(context);
    PptTheme? selectedTheme;

    // Show theme picker dialog
    await showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        PptTheme pickedTheme = PptThemes.all.first;
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: colors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                'Choose a Theme',
                style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Select the design for your PowerPoint slides.',
                      style: TextStyle(color: colors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    // Theme grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.5,
                      ),
                      itemCount: PptThemes.all.length,
                      itemBuilder: (_, i) {
                        final theme = PptThemes.all[i];
                        final isSelected = pickedTheme.id == theme.id;
                        return GestureDetector(
                          onTap: () => setDialogState(() => pickedTheme = theme),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? colors.accent : colors.border,
                                width: isSelected ? 2.5 : 1.5,
                              ),
                              boxShadow: isSelected
                                  ? [BoxShadow(color: colors.accent.withOpacity(0.25), blurRadius: 8, spreadRadius: 1)]
                                  : [],
                            ),
                            child: Stack(
                              children: [
                                // Preview image
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.asset(
                                    theme.previewAsset,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: colors.surfaceDim,
                                      child: Icon(Icons.image_outlined, color: colors.textMuted, size: 32),
                                    ),
                                  ),
                                ),
                                // Name label at bottom
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
                                      gradient: LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                                      ),
                                    ),
                                    padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
                                    child: Text(
                                      theme.displayName,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                // Checkmark for selected
                                if (isSelected)
                                  Positioned(
                                    top: 6,
                                    right: 6,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: colors.accent,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.check, color: Colors.white, size: 14),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: Text('Cancel', style: TextStyle(color: colors.textMuted)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    selectedTheme = pickedTheme;
                    Navigator.of(dialogCtx).pop();
                  },
                  child: const Text('Export', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );

    // User cancelled the theme picker
    if (selectedTheme == null || !mounted) return;

    final theme = selectedTheme!;
    final progressNotifier = ValueNotifier<double>(0.0);
    final statusNotifier = ValueNotifier<String>('Initializing...');
    bool isCancelled = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: colors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Exporting PPTX', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ValueListenableBuilder<double>(
                valueListenable: progressNotifier,
                builder: (context, val, _) => ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: val,
                    backgroundColor: colors.surfaceDim,
                    color: colors.accent,
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ValueListenableBuilder<String>(
                valueListenable: statusNotifier,
                builder: (context, val, _) => Text(
                  val,
                  style: TextStyle(color: colors.textSecondary, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                isCancelled = true;
                Navigator.of(dialogCtx).pop();
              },
              child: Text('Cancel', style: TextStyle(color: colors.danger, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    final path = await PptExportService.exportPptx(
      ppt: ppt,
      songs: pptSongs,
      theme: theme,
      onProgress: (status, progress) {
        statusNotifier.value = status;
        progressNotifier.value = progress;
      },
      isCancelled: () => isCancelled,
    );

    if (mounted) {
      if (!isCancelled) {
        // Match the navigator used to show the progress dialog (plain
        // showDialog, not rootNavigator) so the correct route is popped.
        Navigator.of(context).pop();
      }
      if (path != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PPTX saved successfully!')),
        );
      } else if (isCancelled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Export cancelled.')),
        );
      }
    }
  }

  void _showAddSongsSheet() {
    final allSongs = SongRepository().songs;
    final currentLineupIds = Set<String>.from(LineupRepository().songIds);

    // Track selections inside the sheet
    final selected = Set<String>.from(currentLineupIds);
    String _sheetSearchQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        final colors = AppColors.of(context);
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Handle bar
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
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Row(
                      children: [
                        Text(
                          'Add songs to Line up',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
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
                  
                  // Search Bar
                  if (allSongs.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: TextField(
                        onChanged: (val) {
                          setSheetState(() {
                            _sheetSearchQuery = val.toLowerCase();
                          });
                        },
                        style: TextStyle(color: colors.textPrimary, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Search songs...',
                          hintStyle: TextStyle(color: colors.textMuted),
                          prefixIcon: Icon(Icons.search, color: colors.textMuted, size: 20),
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
                    ),

                  // Song list
                  if (allSongs.isEmpty)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.queue_music_rounded, size: 48, color: colors.textMuted),
                            const SizedBox(height: 12),
                            Text(
                              'No songs available',
                              style: TextStyle(color: colors.textMuted, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Create songs first from the Chords screen.',
                              style: TextStyle(color: colors.textMuted, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          final filteredSongs = allSongs.where((song) {
                            return song.title.toLowerCase().contains(_sheetSearchQuery) ||
                                   song.songKey.toLowerCase().contains(_sheetSearchQuery);
                          }).toList();

                          if (filteredSongs.isEmpty) {
                            return Center(
                              child: Text(
                                'No songs found',
                                style: TextStyle(color: colors.textMuted),
                              ),
                            );
                          }

                          return ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: filteredSongs.length,
                            separatorBuilder: (_, __) => Divider(color: colors.border, height: 1, indent: 72),
                            itemBuilder: (_, index) {
                              final song = filteredSongs[index];
                              final isChecked = selected.contains(song.id);
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
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
                                  style: TextStyle(color: colors.textSecondary, fontSize: 13),
                                ),
                                trailing: Checkbox(
                                  value: isChecked,
                                  activeColor: colors.accent,
                                  side: BorderSide(color: colors.border, width: 1.5),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                  onChanged: (val) {
                                    setSheetState(() {
                                      if (val == true) {
                                        selected.add(song.id);
                                      } else {
                                        selected.remove(song.id);
                                      }
                                    });
                                  },
                                ),
                                onTap: () {
                                  setSheetState(() {
                                    if (isChecked) {
                                      selected.remove(song.id);
                                    } else {
                                      selected.add(song.id);
                                    }
                                  });
                                },
                              );
                            },
                          );
                        }
                      ),
                    ),
                  // Confirm button
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          // Add newly selected songs, remove unchecked ones
                          for (final song in allSongs) {
                            if (selected.contains(song.id)) {
                              await LineupRepository().addToLineup(song.id);
                            } else {
                              await LineupRepository().removeFromLineup(song.id);
                            }
                          }
                          if (!mounted) return;
                          Navigator.of(sheetCtx).pop();
                          _refresh();
                        },
                        child: Text(
                          'Add ${(selected.difference(currentLineupIds)).length} song(s) to Line up',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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
  /// The song is stored in [SongRepository], so the change is reflected
  /// everywhere the song appears (Chords, Line up, exports).
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
                        value:
                            allKeys.contains(selectedKey) ? selectedKey : null,
                        isExpanded: true,
                        dropdownColor: colors.surface,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        icon: Icon(Icons.arrow_drop_down,
                            color: colors.textMuted),
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
                  child:
                      Text('Cancel', style: TextStyle(color: colors.textMuted)),
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

  /// Confirms then removes [song] from the lineup (the song itself is kept).
  Future<void> _confirmRemove(SongData song) async {
    final colors = AppColors.of(context);
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        title: Text('Remove from Line up',
            style: TextStyle(color: colors.textPrimary)),
        content: Text(
          'Remove "${song.title}" from the lineup? The song itself is kept.',
          style: TextStyle(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: TextStyle(color: colors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Remove',
                style: TextStyle(
                    color: colors.danger, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (shouldRemove != true || !mounted) return;
    await LineupRepository().removeFromLineup(song.id);
    if (!mounted) return;
    _refresh();
  }

  /// Action sheet shown when a lineup song is tapped: change key or remove.
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
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: colors.accentSurface.withAlpha(40),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.music_note_rounded,
                      color: colors.accent, size: 28),
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

                // ── Overview (lyrics + chords) ──
                _LineupModalButton(
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

                // ── Change key ──
                _LineupModalButton(
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

                // ── Remove from Line up ──
                _LineupModalButton(
                  icon: Icons.remove_circle_outline_rounded,
                  label: 'Remove from Line up',
                  colors: colors,
                  isPrimary: false,
                  isDanger: true,
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _confirmRemove(song);
                  },
                ),
                const SizedBox(height: 12),

                // ── Back ──
                _LineupModalButton(
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
    final lineupIds = LineupRepository().songIds;
    final allSongs = SongRepository().songs;

    // Map IDs to actual SongData objects
    final lineupSongs = lineupIds.map((id) {
      return allSongs.firstWhere(
        (s) => s.id == id,
        orElse: () => SongData(id: id, title: 'Unknown', songKey: '?', lines: []),
      );
    }).toList();

    return Scaffold(
      drawer: AppDrawer(
        selectedItem: 'Line up',
        onSelectItem: (_) {},
      ),
      floatingActionButton: FloatingActionButton(
        shape: const CircleBorder(),
        backgroundColor: colors.accent,
        foregroundColor: colors.onAccent,
        elevation: 4,
        onPressed: _showAddSongsSheet,
        child: const Icon(Icons.add_rounded),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Builder(
              builder: (context) => SectionHeader(
                title: 'Line up',
                onMenuTap: () => Scaffold.of(context).openDrawer(),
                action: PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: colors.textPrimary),
                  color: colors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: colors.border),
                  ),
                  onSelected: (value) async {
                    if (value == 'perform') {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PerformScreen(songs: lineupSongs),
                        ),
                      );
                    } else if (value == 'export_pdf') {
                      final pdf = await PdfExportService.generateChordCharts(lineupSongs);
                      await PdfExportService.exportPdf(
                        pdf: pdf,
                        songTitle: 'Lineup',
                      );
                    } else if (value == 'export_ppt') {
                      final ppt = PptData(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        title: 'Lineup',
                        songIds: lineupIds.toList(),
                      );
                      await _exportWithThemePicker(ppt, lineupSongs);
                    } else if (value == 'export_setlist') {
                      // Setlist = chord-chart PDF + themed PPTX in one action.
                      // PDF first (silent save), then the PPT theme picker so
                      // the user only interacts with one dialog.
                      final pdf = await PdfExportService.generateChordCharts(lineupSongs);
                      final pdfPath = await PdfExportService.exportPdf(
                        pdf: pdf,
                        songTitle: 'Setlist',
                      );
                      if (!mounted) return;
                      if (pdfPath != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Setlist PDF saved. Now choose a PPT theme…')),
                        );
                      }
                      final ppt = PptData(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        title: 'Setlist',
                        songIds: lineupIds.toList(),
                      );
                      await _exportWithThemePicker(ppt, lineupSongs);
                    } else if (value == 'clear') {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: colors.surface,
                          title: Text('Clear Line up', style: TextStyle(color: colors.textPrimary)),
                          content: Text('Are you sure you want to remove all songs from the lineup?', style: TextStyle(color: colors.textSecondary)),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('Cancel', style: TextStyle(color: colors.textMuted)),
                            ),
                            TextButton(
                              onPressed: () {
                                LineupRepository().clearLineup();
                                Navigator.pop(context);
                                _refresh();
                              },
                              child: Text('Clear All', style: TextStyle(color: colors.danger, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'perform',
                      enabled: lineupSongs.isNotEmpty,
                      child: Row(
                        children: [
                          Icon(Icons.play_arrow_rounded, color: lineupSongs.isNotEmpty ? colors.textPrimary : colors.textMuted, size: 20),
                          const SizedBox(width: 12),
                          Text('Perform', style: TextStyle(color: lineupSongs.isNotEmpty ? colors.textPrimary : colors.textMuted)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'export_pdf',
                      enabled: lineupSongs.isNotEmpty,
                      child: Row(
                        children: [
                          Icon(Icons.picture_as_pdf_rounded, color: lineupSongs.isNotEmpty ? colors.textPrimary : colors.textMuted, size: 20),
                          const SizedBox(width: 12),
                          Text('Export as PDF', style: TextStyle(color: lineupSongs.isNotEmpty ? colors.textPrimary : colors.textMuted)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'export_ppt',
                      enabled: lineupSongs.isNotEmpty,
                      child: Row(
                        children: [
                          Icon(Icons.slideshow_rounded, color: lineupSongs.isNotEmpty ? colors.textPrimary : colors.textMuted, size: 20),
                          const SizedBox(width: 12),
                          Text('Export as PPT', style: TextStyle(color: lineupSongs.isNotEmpty ? colors.textPrimary : colors.textMuted)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'export_setlist',
                      enabled: lineupSongs.isNotEmpty,
                      child: Row(
                        children: [
                          Icon(Icons.library_books_rounded, color: lineupSongs.isNotEmpty ? colors.textPrimary : colors.textMuted, size: 20),
                          const SizedBox(width: 12),
                          Text('Export Setlist (PDF + PPT)', style: TextStyle(color: lineupSongs.isNotEmpty ? colors.textPrimary : colors.textMuted)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'clear',
                      enabled: lineupSongs.isNotEmpty,
                      child: Row(
                        children: [
                          Icon(Icons.delete_sweep_rounded, color: lineupSongs.isNotEmpty ? colors.danger : colors.textMuted, size: 20),
                          const SizedBox(width: 12),
                          Text('Clear Line up', style: TextStyle(color: lineupSongs.isNotEmpty ? colors.danger : colors.textMuted)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (lineupSongs.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.playlist_add_rounded, size: 64, color: colors.textMuted),
                      const SizedBox(height: 16),
                      Text(
                        'Empty Line up',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap + to add songs to your lineup.',
                        style: TextStyle(color: colors.textSecondary),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ReorderableListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: lineupSongs.length,
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      LineupRepository().reorder(oldIndex, newIndex);
                    });
                  },
                  proxyDecorator: (child, index, animation) => Material(
                    elevation: 0,
                    color: Colors.transparent,
                    child: child,
                  ),
                  itemBuilder: (context, index) {
                    final song = lineupSongs[index];
                    return Padding(
                      key: ValueKey(song.id),
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colors.border),
                        ),
                        child: ListTile(
                          onTap: () => _showSongActionModal(song),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            width: 40,
                            height: 40,
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
                              ),
                            ),
                          ),
                          title: Text(
                            song.title,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.chevron_right_rounded, color: colors.textMuted),
                              ReorderableDragStartListener(
                                index: index,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                  child: Icon(Icons.drag_handle, color: Colors.grey, size: 28),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LineupModalButton extends StatelessWidget {
  const _LineupModalButton({
    required this.icon,
    required this.label,
    required this.colors,
    required this.isPrimary,
    required this.onTap,
    this.isDanger = false,
  });

  final IconData icon;
  final String label;
  final AppColors colors;
  final bool isPrimary;
  final bool isDanger;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = isPrimary ? colors.accentSurface : colors.surfaceDim;
    final fg = isDanger
        ? colors.danger
        : (isPrimary ? colors.onAccent : colors.textPrimary);
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
