import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../events/events_tab_page.dart';
import '../home/home_tab_page.dart';
import '../members/members_tab_page.dart';
import '../notices/notices_tab_page.dart';
import '../profile/profile_tab_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _tabs = <_NavTab>[
    _NavTab(
      label: 'Home',
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
    ),
    _NavTab(
      label: 'Members',
      icon: Icons.people_outline,
      activeIcon: Icons.people,
    ),
    _NavTab(
      label: 'Notices',
      icon: Icons.campaign_outlined,
      activeIcon: Icons.campaign,
    ),
    _NavTab(
      label: 'Events',
      icon: Icons.event_outlined,
      activeIcon: Icons.event,
    ),
    _NavTab(
      label: 'Profile',
      icon: Icons.person_outline,
      activeIcon: Icons.person,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (_index >= _tabs.length) _index = 0;

        const pages = <Widget>[
          HomeTabPage(),
          MembersTabPage(),
          NoticesTabPage(),
          EventsTabPage(),
          ProfileTabPage(),
        ];

        return Scaffold(
          body: IndexedStack(
            index: _index,
            children: pages,
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: _index,
              onTap: (i) => setState(() => _index = i),
              type: BottomNavigationBarType.fixed,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: AppColors.textSecondary,
              showUnselectedLabels: true,
              items: [
                for (final t in _tabs)
                  BottomNavigationBarItem(
                    icon: Icon(t.icon),
                    activeIcon: Icon(t.activeIcon),
                    label: t.label,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NavTab {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  const _NavTab({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}
