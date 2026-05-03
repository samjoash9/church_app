import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/section_header.dart';

class CreateSongScreen extends StatefulWidget {
  const CreateSongScreen({super.key});

  @override
  State<CreateSongScreen> createState() => _CreateSongScreenState();
}

class _CreateSongScreenState extends State<CreateSongScreen> {
  static const _majorKeys = ['E', 'F', 'G', 'A', 'B', 'C', 'D'];

  final _titleController = TextEditingController();
  String? _selectedKey;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _confirm() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop({
      'title': _titleController.text.trim(),
      'key': _selectedKey!,
    });
  }

  void _cancel() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            SectionHeader(
              title: 'Create New Song',
              onBack: _cancel,
            ),

            // ── Form ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 28, 16, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title field
                      _FieldLabel(label: 'Title', colors: colors),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _titleController,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 16,
                        ),
                        decoration: _inputDecoration(
                          colors: colors,
                          hint: 'e.g. Amazing Grace',
                        ),
                        textCapitalization: TextCapitalization.words,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 24),

                      // Key dropdown
                      _FieldLabel(label: 'Key', colors: colors),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedKey,
                        dropdownColor: colors.surface,
                        iconEnabledColor: colors.accent,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 16,
                          fontFamily: 'Roboto',
                        ),
                        decoration: _inputDecoration(
                          colors: colors,
                          hint: 'Select a key',
                        ),
                        hint: Text(
                          'Select a key',
                          style: TextStyle(color: colors.textSecondary, fontSize: 15),
                        ),
                        items: _majorKeys
                            .map(
                              (key) => DropdownMenuItem(
                                value: key,
                                child: Text(
                                  '$key Major',
                                  style: TextStyle(color: colors.textPrimary),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _selectedKey = v),
                        validator: (v) {
                          if (v == null) return 'Please select a key';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Action buttons ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Row(
                children: [
                  Expanded(
                    child: _BottomButton(
                      label: 'Cancel',
                      colors: colors,
                      isPrimary: false,
                      onTap: _cancel,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _BottomButton(
                      label: 'Confirm',
                      colors: colors,
                      isPrimary: true,
                      onTap: _confirm,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required AppColors colors,
    required String hint,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: colors.textSecondary, fontSize: 15),
      filled: true,
      fillColor: colors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
        borderSide: BorderSide(color: colors.accent, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.danger, width: 1.8),
      ),
      errorStyle: TextStyle(color: colors.danger),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label, required this.colors});

  final String label;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: colors.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      ),
    );
  }
}

class _BottomButton extends StatelessWidget {
  const _BottomButton({
    required this.label,
    required this.colors,
    required this.isPrimary,
    required this.onTap,
  });

  final String label;
  final AppColors colors;
  final bool isPrimary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = isPrimary ? colors.accentSurface : colors.surfaceDim;
    final fg = isPrimary ? colors.onAccent : colors.textPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          height: 52,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: fg,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
