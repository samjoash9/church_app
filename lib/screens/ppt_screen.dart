import 'package:flutter/material.dart';
import '../models/song.dart';
import '../models/ppt.dart';
import '../models/ppt_theme.dart';
import '../services/song_repository.dart';
import '../services/ppt_repository.dart';
import '../services/ppt_export_service.dart';
import '../services/ppt_themes.dart';
import '../services/ppt_outline.dart';
import '../theme/app_colors.dart';
import '../widgets/section_header.dart';
import '../widgets/app_drawer.dart';

class PptScreen extends StatefulWidget {
  const PptScreen({super.key});

  @override
  State<PptScreen> createState() => _PptScreenState();
}

class _PptScreenState extends State<PptScreen> {
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

    String? path;
    Object? exportError;
    try {
      path = await PptExportService.exportPptx(
        ppt: ppt,
        songs: pptSongs,
        theme: theme,
        onProgress: (status, progress) {
          statusNotifier.value = status;
          progressNotifier.value = progress;
        },
        isCancelled: () => isCancelled,
      );
    } catch (error) {
      // Generation/save/share failed — capture so the finally-style cleanup
      // below always closes the (non-dismissible) progress dialog instead of
      // leaving the UI frozen.
      exportError = error;
    }

    if (mounted) {
      if (!isCancelled) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      if (exportError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $exportError')),
        );
      } else if (path != null) {
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

  void _showCreatePptSheet() {
    final allSongs = SongRepository().songs;
    final selected = <String>{};
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
                          'Select songs for PPT',
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
                        onPressed: selected.isEmpty ? null : () {
                          Navigator.of(sheetCtx).pop();
                          _promptPptName(selected.toList());
                        },
                        child: Text(
                          'Create PPT with ${selected.length} song(s)',
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

  void _promptPptName(List<String> songIds) {
    final colors = AppColors.of(context);
    final nameController = TextEditingController(text: 'Presentation ${DateTime.now().toLocal().toString().split(' ')[0]}');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: colors.surface,
          title: Text('Name your PPT', style: TextStyle(color: colors.textPrimary)),
          content: TextField(
            controller: nameController,
            style: TextStyle(color: colors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Enter PPT name',
              hintStyle: TextStyle(color: colors.textMuted),
              filled: true,
              fillColor: colors.surfaceDim,
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
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Cancel', style: TextStyle(color: colors.textMuted)),
            ),
            TextButton(
              onPressed: () async {
                final title = nameController.text.trim();
                if (title.isNotEmpty) {
                  final newPpt = PptData(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: title,
                    songIds: songIds,
                  );
                  await PptRepository().savePpt(newPpt);
                  if (mounted) {
                    Navigator.of(ctx).pop();
                    _refresh();
                  }
                }
              },
              child: Text('Save', style: TextStyle(color: colors.accent, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    ).then((_) => nameController.dispose());
  }

  // ── Slide overview ──────────────────────────────────────────────────────
  /// Resolves a PPT's song IDs to the songs that still exist, in order.
  List<SongData> _resolvePptSongs(PptData ppt) {
    final allSongs = SongRepository().songs;
    final resolved = <SongData>[];
    for (final id in ppt.songIds) {
      final match = allSongs.where((s) => s.id == id);
      if (match.isNotEmpty) resolved.add(match.first);
    }
    return resolved;
  }

  /// Bottom sheet glimpse of the slides a presentation produces. Uses the same
  /// buildPptOutline grouping as the exporter, so it mirrors the real deck.
  void _showPptOverview(PptData ppt) {
    final songs = _resolvePptSongs(ppt);
    final outline = buildPptOutline(songs);
    final missingCount = ppt.songIds.length - songs.length;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        final colors = AppColors.of(context);

        Widget sectionRow(String label) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(Icons.crop_16_9_outlined, size: 18, color: colors.textMuted),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            );

        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ppt.title,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${outline.totalSlides} slides · ${songs.length} song(s)',
                            style: TextStyle(color: colors.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: colors.textMuted),
                      onPressed: () => Navigator.of(sheetCtx).pop(),
                    ),
                  ],
                ),
              ),
              Divider(color: colors.border, height: 1),
              // Outline
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: [
                    // Title slide
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Icon(Icons.title_rounded, size: 18, color: colors.accent),
                          const SizedBox(width: 10),
                          Text(
                            'Title slide',
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...outline.introSections.map(sectionRow),
                    const SizedBox(height: 8),
                    // Songs
                    if (outline.songs.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'No songs in this presentation.',
                          style: TextStyle(color: colors.textMuted, fontSize: 13),
                        ),
                      )
                    else
                      ...outline.songs.map((s) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.music_note_rounded, size: 18, color: colors.accent),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        s.song.title,
                                        style: TextStyle(
                                          color: colors.textPrimary,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${s.slideCount} slides',
                                      style: TextStyle(color: colors.textMuted, fontSize: 12),
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 28, top: 4),
                                  child: Text(
                                    'Key of ${s.song.songKey}',
                                    style: TextStyle(color: colors.textSecondary, fontSize: 12),
                                  ),
                                ),
                                // Lyric-slide group titles
                                ...s.lyricSlides.map((slide) {
                                  // Strip the leading "[Title - " / trailing "]" so
                                  // only the section label shows.
                                  final raw = slide.title.replaceAll('[', '').replaceAll(']', '');
                                  final label = raw.contains(' - ')
                                      ? raw.substring(raw.indexOf(' - ') + 3)
                                      : 'Lyrics';
                                  return Padding(
                                    padding: const EdgeInsets.only(left: 28, top: 6),
                                    child: Row(
                                      children: [
                                        Icon(Icons.subdirectory_arrow_right_rounded,
                                            size: 14, color: colors.textMuted),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            label,
                                            style: TextStyle(
                                              color: colors.textSecondary,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          )),
                    const SizedBox(height: 8),
                    ...outline.outroSections.map(sectionRow),
                    if (missingCount > 0) ...[
                      const SizedBox(height: 16),
                      Text(
                        '$missingCount song(s) no longer exist and were skipped.',
                        style: TextStyle(color: colors.danger, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final ppts = PptRepository().ppts;

    return Scaffold(
      drawer: AppDrawer(
        selectedItem: 'PPT',
        onSelectItem: (_) {},
      ),
      body: SafeArea(
        child: Column(
          children: [
            Builder(
              builder: (context) => SectionHeader(
                title: 'Presentations',
                onMenuTap: () => Scaffold.of(context).openDrawer(),
                action: PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: colors.textPrimary),
                  color: colors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: colors.border),
                  ),
                  onSelected: (value) {
                    if (value == 'create') _showCreatePptSheet();
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'create',
                      child: Row(
                        children: [
                          Icon(Icons.add_rounded, color: colors.textPrimary, size: 20),
                          const SizedBox(width: 12),
                          Text('Create PPT', style: TextStyle(color: colors.textPrimary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (ppts.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.description_outlined, size: 64, color: colors.textMuted),
                      const SizedBox(height: 16),
                      Text(
                        'No PPTs Yet',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap "Create PPT" to build your presentation.',
                        style: TextStyle(color: colors.textSecondary),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _showCreatePptSheet,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Create PPT', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: ppts.length,
                  itemBuilder: (context, index) {
                    final ppt = ppts[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colors.border),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: colors.accentSurface.withAlpha(51),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Icon(Icons.slideshow_rounded, color: colors.accent),
                          ),
                          title: Text(
                            ppt.title,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            '${ppt.songIds.length} song(s)',
                            style: TextStyle(color: colors.textSecondary, fontSize: 13),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.file_download_outlined, color: colors.accent),
                                tooltip: 'Export PPTX',
                                onPressed: () {
                                  final allSongs = SongRepository().songs;
                                  final pptSongs = ppt.songIds.map((id) => allSongs.firstWhere(
                                        (s) => s.id == id,
                                        orElse: () => SongData(id: id, title: 'Unknown', songKey: '?', lines: []),
                                      )).where((s) => s.title != 'Unknown').toList();
                                  _exportWithThemePicker(ppt, pptSongs);
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.delete_outline, color: colors.danger),
                                onPressed: () {
                                  PptRepository().deletePpt(ppt.id);
                                  _refresh();
                                },
                              ),
                            ],
                          ),
                          onTap: () => _showPptOverview(ppt),
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
