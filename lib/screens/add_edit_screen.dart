import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../db/database_helper.dart';
import '../models/job_application.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

class AddEditScreen extends StatefulWidget {
  final JobApplication? application;

  const AddEditScreen({super.key, this.application});

  @override
  State<AddEditScreen> createState() => _AddEditScreenState();
}

class _AddEditScreenState extends State<AddEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _companyController;
  late TextEditingController _positionController;
  late TextEditingController _sourceController;
  late TextEditingController _locationController;
  late TextEditingController _linkController;
  late TextEditingController _notesController;
  late TextEditingController _contactController;

  late JobStatus _status;
  int? _priority;
  DateTime? _dateApplied;
  DateTime? _followUpDate;
  bool _saving = false;

  bool get _isEditing => widget.application != null;

  @override
  void initState() {
    super.initState();
    final app = widget.application;
    _companyController = TextEditingController(text: app?.company ?? '');
    _positionController = TextEditingController(text: app?.position ?? '');
    _sourceController = TextEditingController(text: app?.source ?? '');
    _locationController = TextEditingController(text: app?.location ?? '');
    _linkController = TextEditingController(text: app?.link ?? '');
    _notesController = TextEditingController(text: app?.notes ?? '');
    _contactController =
        TextEditingController(text: app?.contactPerson ?? '');
    _status = app?.status ?? JobStatus.wishlist;
    _priority = app?.priority;
    _dateApplied = app?.dateApplied;
    _followUpDate = app?.followUpDate;
  }

  @override
  void dispose() {
    for (final c in [
      _companyController,
      _positionController,
      _sourceController,
      _locationController,
      _linkController,
      _notesController,
      _contactController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate(
      {required DateTime? initial,
      required void Function(DateTime) onPicked}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context)
              .colorScheme
              .copyWith(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) onPicked(picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_status != JobStatus.wishlist && _dateApplied == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please set the date applied'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFBE123C),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    String? trimOrNull(String s) => s.trim().isEmpty ? null : s.trim();

    final application = JobApplication(
      id: widget.application?.id,
      company: _companyController.text.trim(),
      position: trimOrNull(_positionController.text),
      status: _status,
      source: trimOrNull(_sourceController.text),
      location: trimOrNull(_locationController.text),
      priority: _priority,
      link: trimOrNull(_linkController.text),
      dateApplied: _status == JobStatus.wishlist ? null : _dateApplied,
      followUpDate: _followUpDate,
      notes: trimOrNull(_notesController.text),
      contactPerson: trimOrNull(_contactController.text),
    );

    int id;
    if (_isEditing) {
      id = application.id!;
      await DatabaseHelper.instance.update(application);
    } else {
      id = await DatabaseHelper.instance.insert(application);
    }

    if (application.followUpDate != null) {
      await NotificationService.instance.scheduleFollowUpReminder(
        id: id,
        company: application.company,
        position: application.position ?? '',
        followUpDate: application.followUpDate!,
      );
    } else {
      await NotificationService.instance.cancelReminder(id);
    }

    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.pop(context, true);
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete application?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFBE123C)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final id = widget.application!.id!;
    await DatabaseHelper.instance.delete(id);
    await NotificationService.instance.cancelReminder(id);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Application' : 'New Application'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: Color(0xFFBE123C)),
              onPressed: _saving ? null : _delete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
          children: [
            // ── Company & Position ──────────────────────────────────────
            _Card(
              child: Column(
                children: [
                  _Field(
                    controller: _companyController,
                    label: 'Company',
                    icon: Icons.business_outlined,
                    required: true,
                    capitalize: TextCapitalization.words,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Company is required'
                        : null,
                  ),
                  _divider(),
                  _Field(
                    controller: _positionController,
                    label: 'Position / Role',
                    icon: Icons.work_outline_rounded,
                    capitalize: TextCapitalization.words,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Status ──────────────────────────────────────────────────
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CardHeader(
                      icon: Icons.flag_outlined, label: 'Application Status'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: JobStatus.values.map((s) {
                      final (bg, text) = AppColors.forStatus(s);
                      final selected = _status == s;
                      return GestureDetector(
                        onTap: () => setState(() {
                          _status = s;
                          if (s == JobStatus.wishlist) _dateApplied = null;
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected ? text : bg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            s.label,
                            style: TextStyle(
                              color: selected ? Colors.white : text,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Priority ────────────────────────────────────────────────
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CardHeader(
                      icon: Icons.star_outline_rounded, label: 'Priority'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      ...List.generate(5, (i) {
                        final star = i + 1;
                        final filled =
                            _priority != null && star <= _priority!;
                        return GestureDetector(
                          onTap: () => setState(() =>
                              _priority = _priority == star ? null : star),
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 3),
                            child: Icon(
                              filled
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: filled
                                  ? const Color(0xFFF59E0B)
                                  : AppColors.border,
                              size: 32,
                            ),
                          ),
                        );
                      }),
                      const SizedBox(width: 8),
                      Text(
                        _priority != null
                            ? 'Priority $_priority'
                            : 'Not set',
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textMuted),
                      ),
                      if (_priority != null) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => setState(() => _priority = null),
                          child: const Icon(Icons.close_rounded,
                              size: 16, color: AppColors.textMuted),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Dates ───────────────────────────────────────────────────
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CardHeader(
                      icon: Icons.calendar_today_outlined, label: 'Dates'),
                  const SizedBox(height: 12),
                  _DateRow(
                    label: 'Date Applied',
                    value: _dateApplied,
                    enabled: _status != JobStatus.wishlist,
                    required: _status != JobStatus.wishlist,
                    onTap: () => _pickDate(
                      initial: _dateApplied,
                      onPicked: (d) => setState(() => _dateApplied = d),
                    ),
                  ),
                  _divider(),
                  _DateRow(
                    label: 'Follow-up Reminder',
                    value: _followUpDate,
                    enabled: true,
                    onTap: () => _pickDate(
                      initial: _followUpDate,
                      onPicked: (d) => setState(() => _followUpDate = d),
                    ),
                    onClear: _followUpDate != null
                        ? () => setState(() => _followUpDate = null)
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Source & Location ───────────────────────────────────────
            _Card(
              child: Column(
                children: [
                  _Field(
                    controller: _sourceController,
                    label: 'Source',
                    hint: 'LinkedIn, JobStreet, Indeed…',
                    icon: Icons.travel_explore_rounded,
                  ),
                  _divider(),
                  _Field(
                    controller: _locationController,
                    label: 'Location',
                    hint: 'Kuala Lumpur, Remote…',
                    icon: Icons.location_on_outlined,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Extra ───────────────────────────────────────────────────
            _Card(
              child: Column(
                children: [
                  _Field(
                    controller: _linkController,
                    label: 'Job Link',
                    hint: 'https://',
                    icon: Icons.link_rounded,
                    keyboardType: TextInputType.url,
                  ),
                  _divider(),
                  _Field(
                    controller: _contactController,
                    label: 'Contact Person',
                    hint: 'HR name or email',
                    icon: Icons.person_outline_rounded,
                  ),
                  _divider(),
                  _Field(
                    controller: _notesController,
                    label: 'Notes',
                    hint: 'Benefits, follow-up details…',
                    icon: Icons.notes_rounded,
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Save ────────────────────────────────────────────────────
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      _isEditing ? 'Save Changes' : 'Add Application',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() => const Divider(height: 1, indent: 52);
}

// ── Shared Widgets ────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }
}

class _CardHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  const _CardHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData icon;
  final bool required;
  final int maxLines;
  final TextInputType? keyboardType;
  final TextCapitalization capitalize;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.required = false,
    this.maxLines = 1,
    this.keyboardType,
    this.capitalize = TextCapitalization.none,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      textCapitalization: capitalize,
      validator: validator,
      style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: Colors.transparent,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
        isDense: true,
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  final String label;
  final DateTime? value;
  final bool enabled;
  final bool required;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _DateRow({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onTap,
    this.required = false,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat.yMMMd();
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 20,
              color: enabled ? AppColors.primary : AppColors.border,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    required ? '$label *' : label,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value != null ? fmt.format(value!) : 'Tap to select',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: value != null
                          ? FontWeight.w500
                          : FontWeight.w400,
                      color: value != null
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (onClear != null && value != null)
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close_rounded,
                    size: 18, color: AppColors.textMuted),
              )
            else
              Icon(
                Icons.chevron_right_rounded,
                color: enabled ? AppColors.textMuted : AppColors.border,
              ),
          ],
        ),
      ),
    );
  }
}
