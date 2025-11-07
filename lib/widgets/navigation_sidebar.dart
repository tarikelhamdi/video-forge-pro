import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Navigation sidebar with icons
class NavigationSidebar extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onNavigationChanged;

  const NavigationSidebar({
    super.key,
    required this.selectedIndex,
    required this.onNavigationChanged,
  });

  @override
  State<NavigationSidebar> createState() => _NavigationSidebarState();
}

class _NavigationSidebarState extends State<NavigationSidebar> {
  int? _hoveredIndex;

  final List<NavigationItem> _items = const [
    NavigationItem(icon: Icons.home, label: 'Home'),
    NavigationItem(icon: Icons.settings, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: AppTheme.spacingL),
          
          // Logo
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.neonBlue, AppTheme.neonPurple],
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: const Icon(
              Icons.video_camera_back,
              color: Colors.white,
              size: 28,
            ),
          ),
          
          const SizedBox(height: AppTheme.spacingXL),
          const Divider(height: 1, color: AppTheme.darkSurfaceVariant),
          const SizedBox(height: AppTheme.spacingL),
          
          // Navigation items
          Expanded(
            child: ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                final isSelected = widget.selectedIndex == index;
                final isHovered = _hoveredIndex == index;
                
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingM,
                    vertical: AppTheme.spacingS,
                  ),
                  child: MouseRegion(
                    onEnter: (_) => setState(() => _hoveredIndex = index),
                    onExit: (_) => setState(() => _hoveredIndex = null),
                    child: GestureDetector(
                      onTap: () => widget.onNavigationChanged(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          vertical: AppTheme.spacingM,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.neonBlue.withOpacity(0.2)
                              : isHovered
                                  ? AppTheme.darkSurfaceVariant
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          border: isSelected
                              ? Border.all(color: AppTheme.neonBlue, width: 2)
                              : null,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              item.icon,
                              color: isSelected
                                  ? AppTheme.neonBlue
                                  : isHovered
                                      ? AppTheme.textPrimary
                                      : AppTheme.textSecondary,
                              size: 28,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.label,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: isSelected
                                        ? AppTheme.neonBlue
                                        : isHovered
                                            ? AppTheme.textPrimary
                                            : AppTheme.textSecondary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final String label;

  const NavigationItem({
    required this.icon,
    required this.label,
  });
}
