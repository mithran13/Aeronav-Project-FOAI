import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/flight_item.dart';
import '../../services/auth_service.dart';
import '../../services/flight_tracker_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/hover_animated_widgets.dart';

class DashboardView extends StatelessWidget {
  final Function(int tabIndex) onNavigateToTab;

  const DashboardView({super.key, required this.onNavigateToTab});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final trackerService = Provider.of<FlightTrackerService>(context);
    final activeFlight = trackerService.activeFlight;
    final isDark = authService.currentUser.nightMode;

    return Scaffold(
      backgroundColor: isDark ? AppColors.spaceNavy : AppColors.lightBg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Enhanced Multi-Field Search Header Bar
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardBg : AppColors.lightCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppColors.borderSubtle : AppColors.lightBorder),
                boxShadow: isDark
                    ? null
                    : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Real-Time World Flight Search',
                            style: AppTypography.h2.copyWith(color: isDark ? Colors.white : AppColors.lightText),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Search by Flight # (AA 452), Airport (JFK, LHR), Airline, Route, or Tail Registration (N737AA)',
                            style: AppTypography.caption.copyWith(color: isDark ? AppColors.textSecondary : AppColors.lightTextMuted),
                          ),
                        ],
                      ),
                      // Live Update Timestamp Indicator
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.radarGreen.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.radarGreen.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.radarGreen,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Updated ${trackerService.lastUpdatedSecondsAgo}s ago',
                              style: const TextStyle(color: AppColors.radarGreen, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    onChanged: (query) => trackerService.setSearchQuery(query),
                    style: TextStyle(color: isDark ? Colors.white : AppColors.lightText),
                    decoration: InputDecoration(
                      hintText: 'Search flight number, airport (JFK, LHR), route, airline, or tail # (e.g. AA 452, N737AA)...',
                      hintStyle: TextStyle(color: isDark ? AppColors.textMuted : AppColors.lightTextMuted),
                      prefixIcon: const Icon(Icons.search, color: AppColors.electricBlue),
                      filled: true,
                      fillColor: isDark ? AppColors.cockpitDark : AppColors.lightBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 2. Active Tracked Flight Hero Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: isDark ? AppColors.glassGradient : null,
                color: isDark ? null : AppColors.lightCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppColors.electricBlue.withValues(alpha: 0.4) : AppColors.electricBlue,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.electricBlue.withValues(alpha: isDark ? 0.15 : 0.08),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card Header: Airline, Flight #, Aircraft, Status Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: AppColors.electricBlue.withValues(alpha: 0.2),
                            child: const Icon(Icons.flight_takeoff, color: AppColors.electricBlue, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${activeFlight.airlineName} ${activeFlight.flightNumber}',
                                style: AppTypography.h1.copyWith(
                                  fontSize: 22,
                                  color: isDark ? Colors.white : AppColors.lightText,
                                ),
                              ),
                              Text(
                                '${activeFlight.aircraftModel} • Tail ${activeFlight.tailNumber}',
                                style: AppTypography.caption.copyWith(color: isDark ? AppColors.textSecondary : AppColors.lightTextMuted),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Delay / Status Pill Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: (activeFlight.isDelayed ? AppColors.electricAmber : AppColors.radarGreen).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: activeFlight.isDelayed ? AppColors.electricAmber : AppColors.radarGreen),
                        ),
                        child: Text(
                          activeFlight.statusText,
                          style: TextStyle(
                            color: activeFlight.isDelayed ? AppColors.electricAmber : AppColors.radarGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Route Progress Bar (Origin ✈️ Destination)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Origin Info
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activeFlight.origin.iata,
                            style: AppTypography.h1.copyWith(fontSize: 32, color: AppColors.electricAmber),
                          ),
                          Text(
                            activeFlight.origin.city,
                            style: AppTypography.h3.copyWith(color: isDark ? Colors.white : AppColors.lightText),
                          ),
                          Text(
                            activeFlight.origin.formattedTerminalGate,
                            style: AppTypography.caption.copyWith(color: isDark ? AppColors.textSecondary : AppColors.lightTextMuted),
                          ),
                        ],
                      ),

                      // Center Flight Progress Tracker
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Column(
                            children: [
                              Text(
                                activeFlight.timeRemainingFormatted,
                                style: AppTypography.hudMetric.copyWith(color: AppColors.electricBlue, fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              Stack(
                                alignment: Alignment.centerLeft,
                                children: [
                                  Container(
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: isDark ? AppColors.borderSubtle : AppColors.lightBorder,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  FractionallySizedBox(
                                    widthFactor: activeFlight.progress.clamp(0.0, 1.0),
                                    child: Container(
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: AppColors.electricBlue,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment(activeFlight.progress * 2.0 - 1.0, 0.0),
                                    child: Transform.rotate(
                                      angle: 1.5708,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppColors.electricBlue,
                                        ),
                                        child: const Icon(
                                          Icons.flight,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${activeFlight.distanceCoveredMiles.toInt()} mi covered / ${activeFlight.distanceRemainingMiles.toInt()} mi left',
                                style: AppTypography.caption.copyWith(color: isDark ? AppColors.textSecondary : AppColors.lightTextMuted),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Destination Info
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            activeFlight.destination.iata,
                            style: AppTypography.h1.copyWith(fontSize: 32, color: AppColors.electricBlue),
                          ),
                          Text(
                            activeFlight.destination.city,
                            style: AppTypography.h3.copyWith(color: isDark ? Colors.white : AppColors.lightText),
                          ),
                          Text(
                            activeFlight.destination.formattedTerminalGate,
                            style: AppTypography.caption.copyWith(color: isDark ? AppColors.textSecondary : AppColors.lightTextMuted),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // 3. 7-Step Interactive Flight Timeline Component
                  Text(
                    'FLIGHT TIMELINE STAGE',
                    style: AppTypography.hudLabel.copyWith(color: AppColors.electricBlue),
                  ),
                  const SizedBox(height: 10),
                  _buildFlightTimelineBar(activeFlight, isDark),

                  const SizedBox(height: 24),

                  // Track on Map Action Button
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () => onNavigateToTab(1), // Open World Map tab
                      icon: const Icon(Icons.public, color: Colors.white),
                      label: const Text('TRACK THIS FLIGHT ON WORLD MAP'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.electricBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 4. Passenger Information Cards & Route Weather Widget Grid
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Cards Column
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoCard(
                              title: 'BAGGAGE CLAIM',
                              value: activeFlight.destination.baggageClaim ?? 'Carousel 4',
                              subtitle: activeFlight.destination.formattedTerminalGate,
                              icon: Icons.luggage,
                              color: AppColors.electricAmber,
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildInfoCard(
                              title: 'SPEED & ALTITUDE',
                              value: '${activeFlight.currentSpeedMph.toInt()} mph',
                              subtitle: '${activeFlight.currentAltitudeFeet.toInt()} ft altitude',
                              icon: Icons.speed,
                              color: AppColors.electricBlue,
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 5. Route Weather, Wind & Turbulence Widget
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.cardBg : AppColors.lightCard,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isDark ? AppColors.borderSubtle : AppColors.lightBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.cloud_queue, color: AppColors.skyBlue, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'ROUTE WEATHER & TURBULENCE FORECAST',
                                      style: AppTypography.hudLabel.copyWith(color: AppColors.skyBlue),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.skyBlue.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    activeFlight.destination.city,
                                    style: const TextStyle(color: AppColors.skyBlue, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildWeatherCol('DEST. TEMP', activeFlight.destination.weatherTemp ?? '18°C', Icons.thermostat, AppColors.electricAmber, isDark),
                                _buildWeatherCol('WIND SPEED', '${activeFlight.windSpeedKts.toInt()} kts ${activeFlight.windDirection}', Icons.air, AppColors.electricBlue, isDark),
                                _buildWeatherCol('CLOUD COVER', activeFlight.cloudCeiling, Icons.filter_drama, AppColors.skyBlue, isDark),
                                _buildWeatherCol('TURBULENCE', activeFlight.turbulenceRisk, Icons.warning_amber, AppColors.radarGreen, isDark),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // 6. Flight Alerts & Notification Drawer Panel
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardBg : AppColors.lightCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isDark ? AppColors.borderSubtle : AppColors.lightBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.notifications_active, color: AppColors.electricAmber, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'FLIGHT ALERTS (${activeFlight.alerts.length})',
                              style: AppTypography.hudLabel.copyWith(color: AppColors.electricAmber),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        if (activeFlight.alerts.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Center(
                              child: Text(
                                'No high-priority alerts for this flight.',
                                style: AppTypography.caption.copyWith(color: isDark ? AppColors.textMuted : AppColors.lightTextMuted),
                              ),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: activeFlight.alerts.length,
                            separatorBuilder: (ctx, i) => const Divider(height: 16, color: AppColors.borderSubtle),
                            itemBuilder: (context, index) {
                              final alert = activeFlight.alerts[index];
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    alert.isHighPriority ? Icons.error_outline : Icons.info_outline,
                                    color: alert.isHighPriority ? AppColors.emergencyRed : AppColors.electricBlue,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          alert.title,
                                          style: AppTypography.body2.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? Colors.white : AppColors.lightText,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          alert.message,
                                          style: AppTypography.caption.copyWith(
                                            color: isDark ? AppColors.textSecondary : AppColors.lightTextMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // 7. Multiple Tracked Flight Cards List
            Text(
              'ALL TRACKED FLIGHTS (${trackerService.filteredFlights.length})',
              style: AppTypography.h2.copyWith(color: isDark ? Colors.white : AppColors.lightText),
            ),
            const SizedBox(height: 12),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: trackerService.filteredFlights.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final flight = trackerService.filteredFlights[index];
                bool isSelected = flight.id == activeFlight.id;

                return HoverAnimatedCard(
                  onTap: () {
                    trackerService.selectFlight(flight);
                  },
                  glowColor: isSelected ? AppColors.electricAmber : AppColors.electricBlue,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark ? AppColors.surfaceOverlay : AppColors.electricBlue.withValues(alpha: 0.1))
                          : (isDark ? AppColors.cardBg : AppColors.lightCard),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.cockpitDark : AppColors.lightBg,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  flight.airlineCode,
                                  style: AppTypography.hudMetric.copyWith(color: AppColors.electricBlue, fontSize: 12),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${flight.airlineName} (${flight.flightNumber}) • Tail ${flight.tailNumber}',
                                      style: AppTypography.body1.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : AppColors.lightText,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      '${flight.origin.city} (${flight.origin.iata}) ➔ ${flight.destination.city} (${flight.destination.iata})',
                                      style: AppTypography.caption.copyWith(color: isDark ? AppColors.textSecondary : AppColors.lightTextMuted),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              flight.timeRemainingFormatted,
                              style: AppTypography.hudLabel.copyWith(color: AppColors.skyBlue),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: () {
                                trackerService.selectFlight(flight);
                                onNavigateToTab(1); // Open Map
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.electricBlue,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('TRACK ON MAP'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlightTimelineBar(PassengerFlightItem flight, bool isDark) {
    const steps = [
      {'key': FlightTimelineStep.checkIn, 'label': 'Check-in'},
      {'key': FlightTimelineStep.boarding, 'label': 'Boarding'},
      {'key': FlightTimelineStep.departed, 'label': 'Departed'},
      {'key': FlightTimelineStep.cruising, 'label': 'Cruising'},
      {'key': FlightTimelineStep.descent, 'label': 'Descent'},
      {'key': FlightTimelineStep.landing, 'label': 'Landing'},
      {'key': FlightTimelineStep.arrived, 'label': 'Arrived'},
    ];

    int activeIndex = steps.indexWhere((s) => s['key'] == flight.currentTimelineStep);
    if (activeIndex == -1) activeIndex = 3;

    return Row(
      children: List.generate(steps.length, (i) {
        bool isCompleted = i <= activeIndex;
        bool isCurrent = i == activeIndex;

        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 3,
                      color: i == 0
                          ? Colors.transparent
                          : (isCompleted ? AppColors.electricBlue : (isDark ? AppColors.borderSubtle : AppColors.lightBorder)),
                    ),
                  ),
                  Container(
                    width: isCurrent ? 14 : 10,
                    height: isCurrent ? 14 : 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCurrent
                          ? AppColors.electricAmber
                          : (isCompleted ? AppColors.electricBlue : (isDark ? AppColors.borderSubtle : AppColors.lightBorder)),
                      border: isCurrent ? Border.all(color: Colors.white, width: 2) : null,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 3,
                      color: i == steps.length - 1
                          ? Colors.transparent
                          : (i < activeIndex ? AppColors.electricBlue : (isDark ? AppColors.borderSubtle : AppColors.lightBorder)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                steps[i]['label'] as String,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  color: isCurrent
                      ? AppColors.electricAmber
                      : (isCompleted
                          ? (isDark ? Colors.white : AppColors.lightText)
                          : (isDark ? AppColors.textMuted : AppColors.lightTextMuted)),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardBg : AppColors.lightCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppTypography.hudLabel.copyWith(color: color, fontSize: 10)),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 10),
          Text(value, style: AppTypography.h2.copyWith(color: isDark ? Colors.white : AppColors.lightText, fontSize: 18)),
          const SizedBox(height: 4),
          Text(subtitle, style: AppTypography.caption.copyWith(color: isDark ? AppColors.textSecondary : AppColors.lightTextMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildWeatherCol(String label, String val, IconData icon, Color color, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(val, style: AppTypography.body2.copyWith(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.lightText, fontSize: 12)),
        Text(label, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
