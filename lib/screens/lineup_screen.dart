import 'package:flutter/material.dart';
import '../models/song.dart';
import '../services/song_repository.dart';
import '../services/lineup_repository.dart';
import '../theme/app_colors.dart';
import '../widgets/section_header.dart';
import '../widgets/app_drawer.dart';
import 'perform_screen.dart';

class LineupScreen extends StatefulWidget {
  const LineupScreen({super.key});

  @override
  State<LineupScreen> createState() => _LineupScreenState();
}

class _LineupScreenState extends State<LineupScreen> {
  void _refresh() => setState(() {});

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
      body: SafeArea(
        child: Column(
          children: [
            Builder(
              builder: (context) => SectionHeader(
                title: 'Line up',
                onMenuTap: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            if (lineupSongs.isNotEmpty)
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
                    onPressed: _showAddSongsSheet,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add songs', style: TextStyle(fontWeight: FontWeight.bold)),
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
                        'Tap "Add songs" to build your lineup.',
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
                        onPressed: _showAddSongsSheet,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add songs', style: TextStyle(fontWeight: FontWeight.bold)),
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
                              IconButton(
                                icon: Icon(Icons.remove_circle_outline, color: colors.danger),
                                onPressed: () {
                                  LineupRepository().removeFromLineup(song.id);
                                  _refresh();
                                },
                              ),
                              const Icon(Icons.drag_handle, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            if (lineupSongs.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.accent,
                      foregroundColor: colors.onAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PerformScreen(songs: lineupSongs),
                        ),
                      );
                    },
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Perform', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ),
            if (lineupSongs.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.danger.withAlpha(30),
                      foregroundColor: colors.danger,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: colors.danger.withAlpha(100)),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
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
                    },
                    icon: const Icon(Icons.delete_sweep_rounded),
                    label: const Text('Clear Line up', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
