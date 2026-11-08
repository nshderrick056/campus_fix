import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/date_format.dart';
import '../../models/incident.dart';
import 'incident_photo.dart';
import 'status_chip.dart';

/// List row for an incident: thumbnail, title, location, status, age.
class ReportCard extends StatelessWidget {
  const ReportCard({super.key, required this.incident, required this.onTap});

  final Incident incident;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              IncidentPhoto(url: incident.photoUrl, fallbackIcon: incident.category.icon, size: 64),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(incident.title,
                        style: t.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(incident.location,
                        style: t.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Row(children: [
                      StatusChip(incident.status),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(relativeTime(incident.createdAt),
                            style: t.bodySmall, overflow: TextOverflow.ellipsis),
                      ),
                    ]),
                  ],
                ),
              ),
              Icon(Symbols.chevron_right_rounded, color: c.placeholder),
            ],
          ),
        ),
      ),
    );
  }
}
