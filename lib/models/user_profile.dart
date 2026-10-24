enum PilotRole { passenger, frequentFlyer, guest, captain, firstOfficer, flightDispatcher, airTrafficController }

class UserProfile {
  final String id;
  final String name;
  final String email;
  final String callsign;
  final String licenseNumber;
  final PilotRole role;
  final double totalHoursLogged;
  final String avatarUrl;
  final bool nightMode;
  final bool isMetric;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.callsign,
    required this.licenseNumber,
    required this.role,
    required this.totalHoursLogged,
    required this.avatarUrl,
    this.nightMode = true,
    this.isMetric = false,
  });

  String get roleDisplayName {
    switch (role) {
      case PilotRole.passenger:
        return 'Passenger / Traveler';
      case PilotRole.frequentFlyer:
        return 'Frequent Flyer (Gold)';
      case PilotRole.guest:
        return 'Guest Explorer';
      case PilotRole.captain:
        return 'Captain (PIC)';
      case PilotRole.firstOfficer:
        return 'First Officer (FO)';
      case PilotRole.flightDispatcher:
        return 'Flight Dispatcher';
      case PilotRole.airTrafficController:
        return 'Air Traffic Controller';
    }
  }

  UserProfile copyWith({
    String? name,
    String? email,
    String? callsign,
    String? licenseNumber,
    PilotRole? role,
    double? totalHoursLogged,
    String? avatarUrl,
    bool? nightMode,
    bool? isMetric,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      callsign: callsign ?? this.callsign,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      role: role ?? this.role,
      totalHoursLogged: totalHoursLogged ?? this.totalHoursLogged,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      nightMode: nightMode ?? this.nightMode,
      isMetric: isMetric ?? this.isMetric,
    );
  }
}
