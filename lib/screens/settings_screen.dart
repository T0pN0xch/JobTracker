import 'package:flutter/material.dart';

import '../services/import_service.dart';
import '../theme/app_theme.dart';

class SettingsTabContent extends StatefulWidget {
  const SettingsTabContent({super.key});

  @override
  State<SettingsTabContent> createState() => _SettingsTabContentState();
}

class _SettingsTabContentState extends State<SettingsTabContent> {
  bool _hasImported = false;
  bool _importing = false;
  bool _loadingFlag = true;

  @override
  void initState() {
    super.initState();
    _loadFlag();
  }

  Future<void> _loadFlag() async {
    final hasImported = await ImportService.instance.hasImported();
    if (!mounted) return;
    setState(() {
      _hasImported = hasImported;
      _loadingFlag = false;
    });
  }

  Future<void> _import() async {
    setState(() => _importing = true);
    try {
      final result = await ImportService.instance.pickAndImport();
      if (!mounted) return;
      if (result == null) {
        setState(() => _importing = false);
        return;
      }
      setState(() {
        _hasImported = true;
        _importing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Imported ${result.imported} applications'
            '${result.skipped > 0 ? ' (${result.skipped} rows skipped)' : ''}.',
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _importing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Import failed: $e'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingFlag) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 4),
        _SettingsSection(
          icon: Icons.upload_file_rounded,
          iconColor: AppColors.primary,
          iconBg: AppColors.primaryLight,
          title: 'Import from Excel',
          subtitle: _hasImported
              ? 'Data already imported. Importing again will create duplicates.'
              : 'One-tap import from your .xlsx job application spreadsheet.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_hasImported)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          size: 16, color: Color(0xFFB45309)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Importing again will add duplicate entries',
                          style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFFB45309),
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              FilledButton.icon(
                onPressed: _importing ? null : _import,
                icon: _importing
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.upload_rounded, size: 18),
                label: Text(
                  _hasImported ? 'Import again' : 'Choose file & import',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SettingsSection(
          icon: Icons.info_outline_rounded,
          iconColor: const Color(0xFF0F766E),
          iconBg: const Color(0xFFCCFBF1),
          title: 'About',
          subtitle: 'Job Tracker v1.0.0 — offline, no account needed.',
          child: const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final Widget child;

  const _SettingsSection({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary)),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
          if (child is! SizedBox) ...[
            const SizedBox(height: 16),
            child,
          ],
        ],
      ),
    );
  }
}
