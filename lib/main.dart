import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/atc_radio_service.dart';
import 'services/auth_service.dart';
import 'services/flight_file_service.dart';
import 'services/flight_tracker_service.dart';
import 'theme/app_colors.dart';
import 'theme/app_typography.dart';
import 'views/ai_delay_analyzer/ai_delay_analyzer_view.dart';
import 'views/ai_route_planner/ai_route_planner_view.dart';
import 'views/dashboard/dashboard_view.dart';
import 'views/eco_route/eco_route_view.dart';
import 'views/gnss_anomaly/gnss_anomaly_view.dart';
import 'views/world_map/world_map_view.dart';
import 'widgets/aviation_radar_bg.dart';
import 'widgets/hover_animated_widgets.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AeroNavApp());
}

class AeroNavApp extends StatelessWidget {
  const AeroNavApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => FlightFileService()),
        ChangeNotifierProvider(create: (_) => FlightTrackerService()),
        ChangeNotifierProvider(create: (_) => AtcRadioService()),
      ],
      child: Consumer<AuthService>(
        builder: (context, authService, child) {
          final isNightMode = authService.currentUser.nightMode;

          return MaterialApp(
            title: 'AeroNav World Tracker',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              brightness: isNightMode ? Brightness.dark : Brightness.light,
              scaffoldBackgroundColor: isNightMode
                  ? AppColors.spaceNavy
                  : AppColors.lightBg,
              primaryColor: AppColors.electricBlue,
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.electricBlue,
                brightness: isNightMode ? Brightness.dark : Brightness.light,
              ),
              useMaterial3: true,
            ),
            home: const MainLayoutScreen(),
          );
        },
      ),
    );
  }
}

class MainLayoutScreen extends StatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  int _selectedTabIndex = 0;

  void _navigateToTab(int index) {
    setState(() {
      _selectedTabIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final trackerService = Provider.of<FlightTrackerService>(context);
    final isDark = authService.currentUser.nightMode;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final currentUser = authService.currentUser;

    final List<Widget> pages = [
      DashboardView(onNavigateToTab: _navigateToTab),
      const WorldMapView(),
      AiRoutePlannerView(
        onViewOnMap: (routeResult) {
          trackerService.setGlobalPlannedRoute(
            fromIata: routeResult.path.first.iata,
            toIata: routeResult.path.last.iata,
            aiRoute: routeResult,
          );
          _navigateToTab(1);
        },
      ),
      const EcoRouteAiView(),
      const GnssAnomalyView(),
      const AiDelayAnalyzerView(),
    ];

    return Scaffold(
      backgroundColor: isDark ? AppColors.spaceNavy : AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.cockpitDark : AppColors.lightCard,
        elevation: isDark ? 4 : 1,
        titleSpacing: isMobile ? 12 : 20,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? AppColors.spaceNavy : AppColors.lightBg,
                border: Border.all(color: AppColors.electricBlue),
              ),
              child: const Icon(
                Icons.public,
                color: AppColors.electricBlue,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isMobile ? 'AERONAV' : 'AERONAV WORLD TRACKER',
                overflow: TextOverflow.ellipsis,
                style: AppTypography.hudMetric.copyWith(
                  color: isDark ? AppColors.electricBlue : AppColors.royalBlue,
                  fontSize: isMobile ? 14 : 18,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
        actions: [
          // Instant Flight Search Input
          if (!isMobile)
            SizedBox(
              width: 150,
              height: 38,
              child: TextField(
                onChanged: (q) => trackerService.setSearchQuery(q),
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.lightText,
                  fontSize: 13,
                ),
                decoration: InputDecoration(
                  hintText: 'Search flight or airport...',
                  hintStyle: TextStyle(
                    color: isDark
                        ? AppColors.textMuted
                        : AppColors.lightTextMuted,
                    fontSize: 12,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.electricBlue,
                    size: 16,
                  ),
                  filled: true,
                  fillColor: isDark ? AppColors.spaceNavy : AppColors.lightBg,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

          const SizedBox(width: 12),

          // User Profile Chip
          if (!isMobile)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: isDark ? AppColors.spaceNavy : AppColors.lightBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.electricAmber.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.flight_takeoff,
                    size: 16,
                    color: AppColors.electricAmber,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    currentUser.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.lightText,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(width: 8),

          // Theme Switcher
          IconButton(
            icon: Icon(
              isDark ? Icons.dark_mode : Icons.light_mode,
              color: AppColors.electricBlue,
              size: 20,
            ),
            tooltip: 'Toggle Theme Mode',
            onPressed: () => authService.toggleNightMode(),
          ),

          const SizedBox(width: 8),
        ],
      ),

      // Responsive Body with Ambient GPU Aviation Radar Background
      body: AviationRadarBackgroundWidget(
        isDark: isDark,
        child: isMobile
            ? IndexedStack(index: _selectedTabIndex, children: pages)
            : Row(
                children: [
                  Container(
                    width: screenWidth > 1150 ? 230 : 76,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.cockpitDark.withValues(alpha: 0.95)
                          : AppColors.lightCard.withValues(alpha: 0.95),
                      border: Border(
                        right: BorderSide(
                          color: isDark
                              ? AppColors.borderSubtle
                              : AppColors.lightBorder,
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      children: [
                        HoverNavItem(
                          icon: Icons.dashboard_rounded,
                          label: 'Flight Tracker',
                          isSelected: _selectedTabIndex == 0,
                          onTap: () => _navigateToTab(0),
                          isCompact: screenWidth <= 1150,
                          isDark: isDark,
                        ),
                        HoverNavItem(
                          icon: Icons.public_rounded,
                          label: 'World Map',
                          isSelected: _selectedTabIndex == 1,
                          onTap: () => _navigateToTab(1),
                          isCompact: screenWidth <= 1150,
                          isDark: isDark,
                        ),
                        HoverNavItem(
                          icon: Icons.psychology_rounded,
                          label: 'AI Route Planner',
                          isSelected: _selectedTabIndex == 2,
                          onTap: () => _navigateToTab(2),
                          isCompact: screenWidth <= 1150,
                          isDark: isDark,
                        ),
                        HoverNavItem(
                          icon: Icons.eco_rounded,
                          label: 'Eco-Route AI',
                          isSelected: _selectedTabIndex == 3,
                          onTap: () => _navigateToTab(3),
                          isCompact: screenWidth <= 1150,
                          isDark: isDark,
                        ),
                        HoverNavItem(
                          icon: Icons.satellite_alt_rounded,
                          label: 'GNSS Anomaly',
                          isSelected: _selectedTabIndex == 4,
                          onTap: () => _navigateToTab(4),
                          isCompact: screenWidth <= 1150,
                          isDark: isDark,
                        ),
                        HoverNavItem(
                          icon: Icons.analytics_rounded,
                          label: 'Delay Risk (Bayes)',
                          isSelected: _selectedTabIndex == 5,
                          onTap: () => _navigateToTab(5),
                          isCompact: screenWidth <= 1150,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: IndexedStack(
                      index: _selectedTabIndex,
                      children: pages,
                    ),
                  ),
                ],
              ),
      ),

      // Mobile Bottom Navigation Bar
      bottomNavigationBar: isMobile
          ? BottomNavigationBar(
              currentIndex: _selectedTabIndex,
              onTap: (index) => _navigateToTab(index),
              backgroundColor: isDark
                  ? AppColors.cockpitDark
                  : AppColors.lightCard,
              selectedItemColor: AppColors.electricBlue,
              unselectedItemColor: isDark
                  ? AppColors.textSecondary
                  : AppColors.lightTextMuted,
              type: BottomNavigationBarType.fixed,
              selectedFontSize: 10,
              unselectedFontSize: 9,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard, size: 20),
                  label: 'Tracker',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.public, size: 20),
                  label: 'Map',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.psychology, size: 20),
                  label: 'AI Route',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.eco, size: 20),
                  label: 'Eco AI',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.satellite_alt, size: 20),
                  label: 'GNSS',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.analytics, size: 20),
                  label: 'Delay Risk',
                ),
              ],
            )
          : null,
    );
  }
}
