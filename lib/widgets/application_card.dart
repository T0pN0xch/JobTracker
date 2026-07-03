import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/job_application.dart';
import '../theme/app_theme.dart';

class ApplicationCard extends StatelessWidget {
  final JobApplication application;
  final VoidCallback onTap;

  const ApplicationCard({
    super.key,
    required this.application,
    required this.onTap,
  });

  bool get _isFollowUpDue {
    final followUp = application.followUpDate;
    if (followUp == null) return false;
    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);
    final followUpMidnight =
        DateTime(followUp.year, followUp.month, followUp.day);
    return !followUpMidnight.isAfter(todayMidnight);
  }

  @override
  Widget build(BuildContext context) {
    final (chipBg, chipText) = AppColors.forStatus(application.status);
    final avatarBg = AppColors.avatarBg(application.company);
    final avatarText = AppColors.avatarText(application.company);
    final initial = application.company.isNotEmpty
        ? application.company[0].toUpperCase()
        : '?';
    final dateLabel = application.dateApplied != null
        ? DateFormat.yMMMd().format(application.dateApplied!)
        : 'Not applied yet';

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: avatarBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: TextStyle(
                    color: avatarText,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            application.company,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: AppColors.textPrimary,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            color: chipBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            application.status.label,
                            style: TextStyle(
                              color: chipText,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (application.position?.isNotEmpty == true) ...[
                      const SizedBox(height: 3),
                      Text(
                        application.position!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            size: 12, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          dateLabel,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textMuted),
                        ),
                        if (application.location?.isNotEmpty == true) ...[
                          const SizedBox(width: 10),
                          const Icon(Icons.location_on_outlined,
                              size: 12, color: AppColors.textMuted),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              application.location!,
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textMuted),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        if (_isFollowUpDue) ...[
                          const SizedBox(width: 10),
                          const Icon(Icons.notifications_active,
                              size: 12, color: Color(0xFFEF4444)),
                          const SizedBox(width: 2),
                          const Text(
                            'Follow-up',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFFEF4444),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        if (application.source?.isNotEmpty == true) ...[
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              application.source!,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
