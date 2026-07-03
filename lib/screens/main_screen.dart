import 'package:flutter/material.dart';

import '../models/job_application.dart';
import '../theme/app_theme.dart';
import 'add_edit_screen.dart';
import 'home_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  SortOption _sortOption = SortOption.dateAppliedNewest;

  final _homeKey = GlobalKey<HomeTabContentState>();

  static const _titles = ['My Applications', 'Statistics', 'Settings'];

  Future<void> _openAddEdit({JobApplication? application}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditScreen(application: application),
      ),
    );
    if (result == true) {
      _homeKey.currentState?.reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        actions: _selectedIndex == 0
            ? [
                PopupMenuButton<SortOption>(
                  icon: const Icon(Icons.sort_rounded),
                  tooltip: 'Sort',
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  onSelected: (option) =>
                      setState(() => _sortOption = option),
                  itemBuilder: (context) => SortOption.values
                      .map(
                        (option) => PopupMenuItem(
                          value: option,
                          child: Row(
                            children: [
                              if (option == _sortOption)
                                const Icon(Icons.check,
                                    size: 18, color: AppColors.primary)
                              else
                                const SizedBox(width: 18),
                              const SizedBox(width: 8),
                              Text(option.label),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ]
            : null,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          HomeTabContent(
            key: _homeKey,
            sortOption: _sortOption,
            onOpenAddEdit: _openAddEdit,
          ),
          const StatsTabContent(),
          const SettingsTabContent(),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () => _openAddEdit(),
              child: const Icon(Icons.add_rounded, size: 28),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        backgroundColor: AppColors.surface,
        elevation: 0,
        indicatorColor: AppColors.primaryLight,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.work_outline_rounded),
            selectedIcon: Icon(Icons.work_rounded, color: AppColors.primary),
            label: 'Jobs',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon:
                Icon(Icons.insights_rounded, color: AppColors.primary),
            label: 'Stats',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon:
                Icon(Icons.settings_rounded, color: AppColors.primary),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
