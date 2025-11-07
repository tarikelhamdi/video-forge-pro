import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../widgets/navigation_sidebar.dart';
import 'settings_screen.dart';
import 'split_video_screen.dart';
import 'timeline_editor_screen.dart';

/// Main home screen with navigation
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    SettingsScreen(),
  ];

  void _onNavigationChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Row(
        children: [
          // Left navigation sidebar
          NavigationSidebar(
            selectedIndex: _selectedIndex,
            onNavigationChanged: _onNavigationChanged,
          ),
          
          // Main content area
          Expanded(
            child: _screens[_selectedIndex],
          ),
        ],
      ),
    );
  }
}

/// Dashboard/Home screen
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Video Editor Pro',
              style: Theme.of(context).textTheme.displayLarge,
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              'Professional desktop video editing for social media',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingXXL),
            
            // Quick start cards
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: AppTheme.spacingL,
                crossAxisSpacing: AppTheme.spacingL,
                childAspectRatio: 1.5,
                children: [
                  _QuickStartCard(
                    icon: Icons.content_cut,
                    title: 'Split Video',
                    description: 'Split long video into clips',
                    gradient: const LinearGradient(
                      colors: [AppTheme.neonBlue, AppTheme.neonPurple],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SplitVideoScreen(),
                        ),
                      );
                    },
                  ),
                  _QuickStartCard(
                    icon: Icons.timeline,
                    title: 'Timeline Editor',
                    description: 'Edit videos with timeline',
                    gradient: const LinearGradient(
                      colors: [AppTheme.neonPurple, Color(0xFFFF6B9D)],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TimelineEditorScreen(
                            splitClips: [],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickStartCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final Gradient gradient;
  final VoidCallback onTap;

  const _QuickStartCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradient,
    required this.onTap,
  });

  @override
  State<_QuickStartCard> createState() => _QuickStartCardState();
}

class _QuickStartCardState extends State<_QuickStartCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity()
            ..scale(_isHovered ? 1.02 : 1.0),
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: AppTheme.neonBlue.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.icon,
                  size: 48,
                  color: Colors.white,
                ),
                const SizedBox(height: AppTheme.spacingM),
                Text(
                  widget.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppTheme.spacingS),
                Text(
                  widget.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
