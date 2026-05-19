import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../models/song.dart';
import '../services/song_repository.dart';
import '../services/pdf_export_service.dart';

class ChordSlot {
  String chord;
  bool isEditing;
  late TextEditingController controller;
  late FocusNode focusNode;

  ChordSlot({this.chord = '', this.isEditing = false}) {
    controller = TextEditingController(text: chord);
    focusNode = FocusNode();
  }

  void dispose() {
    controller.dispose();
    focusNode.dispose();
  }
}

class SongLine {
  String lyrics;
  List<ChordSlot> slots;

  SongLine({required this.lyrics, List<String>? initialChords})
      : slots = List.generate(
          24,
          (index) => ChordSlot(
            chord: (initialChords != null && index < initialChords.length)
                ? initialChords[index]
                : '',
          ),
        );

  void dispose() {
    for (var slot in slots) {
      slot.dispose();
    }
  }

  List<String> get chordValues => slots.map((s) => s.controller.text).toList();
}

class SongEditorScreen extends StatefulWidget {
  const SongEditorScreen({
    super.key,
    this.songId,
    required this.title,
    required this.songKey,
    this.initialLines,
  });

  final String? songId;
  final String title;
  final String songKey;
  final List<SongLineData>? initialLines;

  @override
  State<SongEditorScreen> createState() => _SongEditorScreenState();
}

enum EditorMode { lyrics, chords, view }

class LyricSection {
  final String title;
  final TextEditingController controller;
  bool isExpanded;

  LyricSection({required this.title, this.isExpanded = false}) 
      : controller = TextEditingController();

  void dispose() {
    controller.dispose();
  }
}

class _SongEditorScreenState extends State<SongEditorScreen> {
  final List<LyricSection> _sections = [
    LyricSection(title: 'Verse', isExpanded: true),
    LyricSection(title: 'Second Verse'),
    LyricSection(title: 'Pre-Chorus'),
    LyricSection(title: 'Chorus'),
    LyricSection(title: 'Second Chorus'),
    LyricSection(title: 'Bridge'),
  ];
  EditorMode _currentMode = EditorMode.lyrics;
  List<SongLine> _lines = [];
  late String _currentKey;
  late String _songId;

  @override
  void initState() {
    super.initState();
    _currentKey = widget.songKey;
    _songId = widget.songId ?? DateTime.now().millisecondsSinceEpoch.toString();
    
    if (widget.initialLines != null) {
      _lines = widget.initialLines!.map((l) => SongLine(
        lyrics: l.lyrics,
        initialChords: l.chords,
      )).toList();
      _syncLinesToSections();
    } else {
      _sections[0].isExpanded = true;
    }
  }

  @override
  void dispose() {
    for (final section in _sections) {
      section.dispose();
    }
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  void _syncLinesToSections() {
    for (var section in _sections) {
      section.controller.clear();
      section.isExpanded = false;
    }

    LyricSection? currentSection;
    List<String> currentLines = [];

    void saveCurrentSection() {
      if (currentSection != null) {
        final existingText = currentSection!.controller.text;
        final newText = currentLines.join('\n').trim();
        if (existingText.isNotEmpty && newText.isNotEmpty) {
           currentSection!.controller.text = existingText + '\n\n' + newText;
        } else if (newText.isNotEmpty) {
           currentSection!.controller.text = newText;
        }
        if (currentSection!.controller.text.isNotEmpty) {
          currentSection!.isExpanded = true;
        }
      } else if (currentLines.isNotEmpty) {
        final newText = currentLines.join('\n').trim();
        if (newText.isNotEmpty) {
           _sections[0].controller.text = newText;
           _sections[0].isExpanded = true;
        }
      }
      currentLines.clear();
    }

    for (final line in _lines) {
      final text = line.lyrics.trim();
      final cleanText = text.replaceAll('[', '').replaceAll(']', '').trim().toLowerCase();
      
      final matchedSections = _sections.where((s) => s.title.toLowerCase() == cleanText);
      final matchedSection = matchedSections.isNotEmpty ? matchedSections.first : null;
      
      if (matchedSection != null) {
        saveCurrentSection();
        currentSection = matchedSection;
      } else {
        if (text.isNotEmpty || currentLines.isNotEmpty) {
          currentLines.add(line.lyrics); 
        }
      }
    }
    saveCurrentSection();
    
    if (_sections.every((s) => s.controller.text.isEmpty)) {
      _sections[0].isExpanded = true;
    }
  }

  void _syncTextToLines() {
    final newLines = <SongLine>[];
    int oldLineIndex = 0;

    for (int i = 0; i < _sections.length; i++) {
      final section = _sections[i];
      final sectionText = section.controller.text.trim();
      
      if (sectionText.isNotEmpty) {
        List<String>? headerChords;
        final cleanOldText = oldLineIndex < _lines.length ? _lines[oldLineIndex].lyrics.replaceAll('[', '').replaceAll(']', '').trim().toLowerCase() : '';
        if (oldLineIndex < _lines.length && cleanOldText == section.title.toLowerCase()) {
          headerChords = _lines[oldLineIndex++].chordValues;
        } else {
          headerChords = null;
        }
        newLines.add(SongLine(lyrics: '[${section.title}]', initialChords: headerChords));
        
        final lyrics = sectionText.split('\n');
        for (final lyric in lyrics) {
          List<String>? lyricChords;
          if (oldLineIndex < _lines.length) {
            lyricChords = _lines[oldLineIndex++].chordValues;
          }
          newLines.add(SongLine(lyrics: lyric, initialChords: lyricChords));
        }
        
        List<String>? blankChords;
        if (oldLineIndex < _lines.length && _lines[oldLineIndex].lyrics.trim().isEmpty) {
          blankChords = _lines[oldLineIndex++].chordValues;
        }
        newLines.add(SongLine(lyrics: '', initialChords: blankChords));
      }
    }

    while (newLines.isNotEmpty && newLines.last.lyrics.trim().isEmpty) {
      newLines.removeLast();
    }

    for (final line in _lines) {
      line.dispose();
    }
    _lines = newLines;
  }

  void _toggleMode(EditorMode mode) {
    if (_currentMode == mode) return;

    if (mode != EditorMode.lyrics) {
      if (_currentMode == EditorMode.lyrics) {
        _syncTextToLines();
      }
    } else {
      _syncLinesToSections();
    }

    setState(() {
      _currentMode = mode;
    });
  }

  void _transposeAllChords(String oldKey, String newKey) {
    final oldChords = _keyChords[oldKey];
    final newChords = _keyChords[newKey];
    if (oldChords == null || newChords == null) return;

    for (final line in _lines) {
      for (final slot in line.slots) {
        final currentChord = slot.controller.text;
        if (currentChord.isNotEmpty) {
          int index = oldChords.indexOf(currentChord);
          if (index != -1) {
            slot.controller.text = newChords[index];
          }
        }
      }
    }
  }

  SongData _buildSongData() {
    if (_currentMode == EditorMode.lyrics) {
      _syncTextToLines();
    }
    return SongData(
      id: _songId,
      title: widget.title,
      songKey: _currentKey,
      lines: _lines.map((line) => SongLineData(
        lyrics: line.lyrics,
        chords: line.chordValues,
      )).toList(),
    );
  }

  void _performSave() {
    final songData = _buildSongData();
    SongRepository().saveSong(songData);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved "${widget.title}"!')),
    );
    Navigator.of(context).pop();
  }

  Future<void> _exportAsPdf() async {
    final songData = _buildSongData();
    final pdf = await PdfExportService.generateChordChart(songData);

    final savedPath = await PdfExportService.exportPdf(
      pdf: pdf,
      songTitle: widget.title,
    );

    if (!mounted || savedPath == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PDF exported successfully!')),
    );
  }

  void _showSaveModal() {
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
                  child: Icon(Icons.save_outlined, color: colors.accent, size: 28),
                ),
                const SizedBox(height: 16),
                Text(
                  'Save Options',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.title,
                  style: TextStyle(color: colors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 28),

                // ── Save button ──
                _ModalActionButton(
                  icon: Icons.save_rounded,
                  label: 'Save',
                  colors: colors,
                  isPrimary: true,
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _performSave();
                  },
                ),
                const SizedBox(height: 12),

                // ── Export as PDF ──
                _ModalActionButton(
                  icon: Icons.picture_as_pdf_rounded,
                  label: 'Export as PDF',
                  colors: colors,
                  isPrimary: false,
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _exportAsPdf();
                  },
                ),
                const SizedBox(height: 12),

                // ── Back ──
                _ModalActionButton(
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

  void _exit() {
    Navigator.of(context).pop();
  }

  Widget _buildSectionToggle(LyricSection section, AppColors colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: section.controller,
            builder: (context, value, child) {
              final isFilled = value.text.trim().isNotEmpty;
              final headerBgColor = isFilled ? colors.accentSurface : colors.surfaceDim;
              final headerTextColor = isFilled ? colors.onAccent : colors.textPrimary;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    section.isExpanded = !section.isExpanded;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: headerBgColor,
                    borderRadius: section.isExpanded 
                        ? const BorderRadius.vertical(top: Radius.circular(8))
                        : BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        section.title,
                        style: TextStyle(
                          color: headerTextColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Icon(
                        section.isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: headerTextColor,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          if (section.isExpanded)
            Container(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: section.controller,
                maxLines: null,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 15,
                  height: 1.5,
                  letterSpacing: 0.5,
                ),
                decoration: InputDecoration(
                  hintText: 'Paste or type lyrics here...',
                  hintStyle: TextStyle(color: colors.textMuted),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Configuration Bar ──
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border(bottom: BorderSide(color: colors.border)),
              ),
              child: Row(
                children: [
                  // Toggle
                  Expanded(
                    flex: 6,
                    child: Container(
                      height: 38,
                      decoration: BoxDecoration(
                        color: colors.accent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _toggleMode(EditorMode.chords),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeInOut,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: _currentMode == EditorMode.chords ? colors.surface : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: _currentMode == EditorMode.chords
                                      ? [const BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))]
                                      : [],
                                ),
                                child: Text(
                                  'Chords',
                                  style: TextStyle(
                                    color: _currentMode == EditorMode.chords ? colors.accent : colors.onAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _toggleMode(EditorMode.lyrics),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeInOut,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: _currentMode == EditorMode.lyrics ? colors.surface : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: _currentMode == EditorMode.lyrics
                                      ? [const BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))]
                                      : [],
                                ),
                                child: Text(
                                  'Lyrics',
                                  style: TextStyle(
                                    color: _currentMode == EditorMode.lyrics ? colors.accent : colors.onAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _toggleMode(EditorMode.view),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeInOut,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: _currentMode == EditorMode.view ? colors.surface : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: _currentMode == EditorMode.view
                                      ? [const BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))]
                                      : [],
                                ),
                                child: Text(
                                  'View',
                                  style: TextStyle(
                                    color: _currentMode == EditorMode.view ? colors.accent : colors.onAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Key Dropdown
                  Expanded(
                    flex: 3,
                    child: Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: colors.accentSurface.withAlpha(51),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: colors.accent.withAlpha(128)),
                      ),
                      child: DropdownButton<String>(
                        value: _currentKey,
                        isExpanded: true,
                        dropdownColor: colors.surface,
                        underline: const SizedBox(),
                        icon: Icon(Icons.arrow_drop_down, color: colors.accent, size: 20),
                        style: TextStyle(color: colors.accent, fontWeight: FontWeight.bold, fontSize: 13),
                        items: _keyChords.keys.map((k) {
                          return DropdownMenuItem(
                            value: k,
                            child: Text(k),
                          );
                        }).toList(),
                        onChanged: (newKey) {
                          if (newKey != null && newKey != _currentKey) {
                            final oldKey = _currentKey;
                            setState(() {
                              _currentKey = newKey;
                            });
                            _transposeAllChords(oldKey, newKey);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Save Button
                  Expanded(
                    flex: 2,
                    child: TextButton(
                      onPressed: _showSaveModal,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 38),
                        backgroundColor: colors.accentSurface.withAlpha(51),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        'Save',
                        style: TextStyle(
                          color: colors.accent,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Exit Button
                  Expanded(
                    flex: 2,
                    child: TextButton(
                      onPressed: _exit,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 38),
                        backgroundColor: colors.surfaceDim,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        'Exit',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // ── Info Bar ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              color: colors.surfaceDim,
              child: Text(
                '${widget.title} • Key of $_currentKey',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),

            // ── Editor Area ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _currentMode == EditorMode.lyrics
                    ? ListView.builder(
                        itemCount: _sections.length,
                        itemBuilder: (context, index) {
                          final section = _sections[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: _buildSectionToggle(section, colors),
                          );
                        },
                      )
                    : ListView.builder(
                        itemCount: _lines.length,
                        itemBuilder: (context, index) {
                          final line = _lines[index];

                          if (line.lyrics.trim().isEmpty && line.chordValues.every((c) => c.isEmpty)) {
                            return const SizedBox(height: 16);
                          }

                          final isSectionHeader = line.lyrics.trim().startsWith('[') && line.lyrics.trim().endsWith(']');
                          
                          return Padding(
                            padding: EdgeInsets.only(
                              top: isSectionHeader && index > 0 ? 16.0 : 0.0,
                              bottom: isSectionHeader ? 12.0 : 12.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Chord Slots Row
                                if (!isSectionHeader)
                                  SizedBox(
                                    height: 26,
                                    child: ClipRect(
                                      child: Wrap(
                                        spacing: 4,
                                        runSpacing: 4,
                                        children: line.slots
                                            .map((slot) => ChordSlotWidget(
                                                  slot: slot,
                                                  colors: colors,
                                                  songKey: _currentKey,
                                                  isViewMode: _currentMode == EditorMode.view,
                                                ))
                                            .toList(),
                                      ),
                                    ),
                                  ),
                                if (!isSectionHeader) const SizedBox(height: 6),
                                // Lyric Line
                                if (line.lyrics.trim().isNotEmpty)
                                  Text(
                                    line.lyrics, 
                                    style: TextStyle(
                                      color: isSectionHeader ? colors.accent : colors.textPrimary, 
                                      fontSize: 15, 
                                      fontWeight: isSectionHeader ? FontWeight.bold : FontWeight.normal,
                                      height: 1,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const Map<String, List<String>> _keyChords = {
  'A': ['A', 'Bm', 'C#m', 'D', 'E', 'F#m', 'G#dim', 'G'],
  'B': ['B', 'C#m', 'D#m', 'E', 'F#', 'G#m', 'A#dim', 'A'],
  'C': ['C', 'Dm', 'Em', 'F', 'G', 'Am', 'Bdim', 'A#'],
  'D': ['D', 'Em', 'F#m', 'G', 'A', 'Bm', 'C#dim', 'C'],
  'E': ['E', 'F#m', 'G#m', 'A', 'B', 'C#m', 'D#dim', 'D'],
  'F': ['F', 'Gm', 'Am', 'Bb', 'C', 'Dm', 'Edim', 'E'],
  'G': ['G', 'Am', 'Bm', 'C', 'D', 'Em', 'F#dim', 'F'],
};

class ChordSlotWidget extends StatelessWidget {
  final ChordSlot slot;
  final AppColors colors;
  final String songKey;
  final bool isViewMode;

  const ChordSlotWidget({
    super.key,
    required this.slot,
    required this.colors,
    required this.songKey,
    this.isViewMode = false,
  });

  void _showChordSelector(BuildContext context) {
    // If the key is not in the map (e.g. minor keys not yet implemented), default to C
    final chords = _keyChords[songKey] ?? _keyChords['C']!;

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Select Chord (Key of $songKey)',
                  style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: chords.map((c) {
                    return InkWell(
                      onTap: () {
                        slot.controller.text = c;
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: colors.accentSurface.withAlpha(51),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: colors.accent.withAlpha(128)),
                        ),
                        child: Text(
                          c,
                          style: TextStyle(color: colors.accent, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),
                TextButton.icon(
                  onPressed: () {
                    slot.controller.text = '';
                    Navigator.pop(context);
                  },
                  icon: Icon(Icons.clear, color: colors.danger),
                  label: Text('Clear Chord', style: TextStyle(color: colors.danger, fontWeight: FontWeight.bold)),
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
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: slot.controller,
      builder: (context, value, child) {
        final hasChord = value.text.isNotEmpty;

        return GestureDetector(
          onTap: isViewMode ? null : () => _showChordSelector(context),
          child: Container(
            height: 26,
            constraints: const BoxConstraints(minWidth: 22),
            padding: hasChord ? const EdgeInsets.symmetric(horizontal: 6) : null,
            decoration: BoxDecoration(
              color: hasChord 
                  ? colors.accentSurface.withAlpha(51) 
                  : (isViewMode ? Colors.transparent : colors.accentSurface.withAlpha(51)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (hasChord)
                  Text(
                    value.text,
                    style: TextStyle(color: colors.accent, fontSize: 13, fontWeight: FontWeight.bold),
                  )
                else if (!isViewMode)
                  Icon(Icons.add, size: 14, color: colors.accent.withAlpha(178)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ModalActionButton extends StatelessWidget {
  const _ModalActionButton({
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
