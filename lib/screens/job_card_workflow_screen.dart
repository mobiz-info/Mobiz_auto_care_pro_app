import 'package:flutter/material.dart';

import 'job_card_dashboard_screen.dart';
import 'leads_screen.dart';
import 'quotation_list_screen.dart';
import '../widgets/job_card_responsive.dart';

class JobCardWorkflowScreen extends StatefulWidget {
  const JobCardWorkflowScreen({super.key});

  @override
  State<JobCardWorkflowScreen> createState() => _JobCardWorkflowScreenState();
}

class _JobCardWorkflowScreenState extends State<JobCardWorkflowScreen> {
  int _selectedIndex = 0;

  static const _screens = [
    LeadsScreen(jobWorkflow: true),
    QuotationListScreen(jobWorkflow: true),
    JobCardDashboardScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final content = IndexedStack(index: _selectedIndex, children: _screens);

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (JobCardResponsive.isTabletWidth(constraints.maxWidth)) {
            const destinations = [
              NavigationRailDestination(
                icon: Icon(Icons.leaderboard_outlined),
                label: Text('Leads'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.request_quote_outlined),
                label: Text('Quotations'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.assignment_outlined),
                label: Text('Job Cards'),
              ),
            ];
            return Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (index) =>
                      setState(() => _selectedIndex = index),
                  labelType: NavigationRailLabelType.all,
                  destinations: destinations,
                ),
                const VerticalDivider(width: 1),
                Expanded(child: content),
              ],
            );
          }

          // Phone layout: content fills above the bottom nav bar
          return content;
        },
      ),
      bottomNavigationBar: LayoutBuilder(
        builder: (context, constraints) {
          // Hide the bottom nav on tablet (NavigationRail used instead)
          if (JobCardResponsive.isTabletWidth(
            MediaQuery.of(context).size.width,
          )) {
            return const SizedBox.shrink();
          }
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) => setState(() => _selectedIndex = index),
              backgroundColor: Colors.white,
              elevation: 0,
              selectedItemColor: const Color(0xFF000080),
              unselectedItemColor: Colors.grey.shade600,
              selectedFontSize: 12,
              unselectedFontSize: 12,
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.leaderboard_outlined),
                  activeIcon: Icon(Icons.leaderboard),
                  label: 'Leads',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.request_quote_outlined),
                  activeIcon: Icon(Icons.request_quote),
                  label: 'Quotations',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.assignment_outlined),
                  activeIcon: Icon(Icons.assignment),
                  label: 'Job Cards',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
