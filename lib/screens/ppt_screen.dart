import 'package:flutter/material.dart';
import '../models/song.dart';
import '../models/ppt.dart';
import '../services/song_repository.dart';
import '../services/ppt_repository.dart';
import '../services/ppt_export_service.dart';
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
    final _nameController = TextEditingController(text: 'Presentation ${DateTime.now().toLocal().toString().split(' ')[0]}');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: colors.surface,
          title: Text('Name your PPT', style: TextStyle(color: colors.textPrimary)),
          content: TextField(
            controller: _nameController,
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
                final title = _nameController.text.trim();
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
              ),
            ),
            if (ppts.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.accentSurface,
                      foregroundColor: colors.onAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _showCreatePptSheet,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Create PPT', style: TextStyle(fontWeight: FontWeight.bold)),
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
                                onPressed: () async {
                                  final allSongs = SongRepository().songs;
                                  final pptSongs = ppt.songIds.map((id) => allSongs.firstWhere(
                                        (s) => s.id == id,
                                        orElse: () => SongData(id: id, title: 'Unknown', songKey: '?', lines: []),
                                      )).where((s) => s.title != 'Unknown').toList();
                                  
                                  final messenger = ScaffoldMessenger.of(context);
                                  messenger.showSnackBar(
                                    const SnackBar(content: Text('Generating PPTX...')),
                                  );

                                  final path = await PptExportService.exportPptx(
                                    ppt: ppt,
                                    songs: pptSongs,
                                  );

                                  if (path != null && mounted) {
                                    messenger.hideCurrentSnackBar();
                                    messenger.showSnackBar(
                                      const SnackBar(content: Text('PPTX saved successfully!')),
                                    );
                                  }
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
                          onTap: () {
                            // Can be extended later to view or perform the PPT
                          },
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
