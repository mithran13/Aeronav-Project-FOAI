import 'package:flutter/material.dart';
import '../models/user_profile.dart';

class AuthService extends ChangeNotifier {
  UserProfile _currentUser = UserProfile(
    id: 'AV-001',
    name: 'Captain Vance',
    email: 'operations@aeronav.io',
    callsign: 'AERONAV-1',
    licenseNumber: 'ATP-99218-ICAO',
    role: PilotRole.captain,
    totalHoursLogged: 4850.0,
    avatarUrl: '',
    nightMode: true,
    isMetric: false,
  );

  UserProfile get currentUser => _currentUser;
  bool get isLoggedIn => true;

  void toggleNightMode() {
    _currentUser = _currentUser.copyWith(nightMode: !_currentUser.nightMode);
    notifyListeners();
  }

  void toggleUnits() {
    _currentUser = _currentUser.copyWith(isMetric: !_currentUser.isMetric);
    notifyListeners();
  }

  void updateProfile(UserProfile updated) {
    _currentUser = updated;
    notifyListeners();
  }
}
