enum JobStatus {
  wishlist,
  applied,
  phoneScreen,
  interview,
  offer,
  rejected,
  withdrawn,
}

extension JobStatusLabel on JobStatus {
  String get label {
    switch (this) {
      case JobStatus.wishlist:
        return 'Wishlist';
      case JobStatus.applied:
        return 'Applied';
      case JobStatus.phoneScreen:
        return 'Phone Screen';
      case JobStatus.interview:
        return 'Interview';
      case JobStatus.offer:
        return 'Offer';
      case JobStatus.rejected:
        return 'Rejected';
      case JobStatus.withdrawn:
        return 'Withdrawn';
    }
  }
}

class JobApplication {
  final int? id;
  final String company;
  final String? position;
  final JobStatus status;
  final String? source;
  final String? location;
  final int? priority;
  final String? link;
  final DateTime? dateApplied;
  final DateTime? followUpDate;
  final String? notes;
  final String? contactPerson;

  const JobApplication({
    this.id,
    required this.company,
    this.position,
    this.status = JobStatus.wishlist,
    this.source,
    this.location,
    this.priority,
    this.link,
    this.dateApplied,
    this.followUpDate,
    this.notes,
    this.contactPerson,
  });

  JobApplication copyWith({
    int? id,
    String? company,
    String? position,
    JobStatus? status,
    String? source,
    String? location,
    int? priority,
    String? link,
    DateTime? dateApplied,
    bool clearDateApplied = false,
    DateTime? followUpDate,
    bool clearFollowUpDate = false,
    String? notes,
    String? contactPerson,
  }) {
    return JobApplication(
      id: id ?? this.id,
      company: company ?? this.company,
      position: position ?? this.position,
      status: status ?? this.status,
      source: source ?? this.source,
      location: location ?? this.location,
      priority: priority ?? this.priority,
      link: link ?? this.link,
      dateApplied:
          clearDateApplied ? null : (dateApplied ?? this.dateApplied),
      followUpDate:
          clearFollowUpDate ? null : (followUpDate ?? this.followUpDate),
      notes: notes ?? this.notes,
      contactPerson: contactPerson ?? this.contactPerson,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'company': company,
      'position': position,
      'status': status.name,
      'source': source,
      'location': location,
      'priority': priority,
      'link': link,
      'dateApplied': dateApplied?.toIso8601String(),
      'followUpDate': followUpDate?.toIso8601String(),
      'notes': notes,
      'contactPerson': contactPerson,
    };
  }

  factory JobApplication.fromMap(Map<String, dynamic> map) {
    return JobApplication(
      id: map['id'] as int?,
      company: map['company'] as String,
      position: map['position'] as String?,
      status: JobStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => JobStatus.wishlist,
      ),
      source: map['source'] as String?,
      location: map['location'] as String?,
      priority: map['priority'] as int?,
      link: map['link'] as String?,
      dateApplied: map['dateApplied'] != null
          ? DateTime.parse(map['dateApplied'] as String)
          : null,
      followUpDate: map['followUpDate'] != null
          ? DateTime.parse(map['followUpDate'] as String)
          : null,
      notes: map['notes'] as String?,
      contactPerson: map['contactPerson'] as String?,
    );
  }
}
