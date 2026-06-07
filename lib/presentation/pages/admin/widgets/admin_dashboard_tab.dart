import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/datasources/member_remote_datasource.dart';
import '../../../../data/datasources/registration_remote_datasource.dart';

class AdminDashboardTab extends StatefulWidget {
  final Future<void> Function() onRefresh;

  const AdminDashboardTab({
    super.key,
    required this.onRefresh,
  });

  @override
  State<AdminDashboardTab> createState() => _AdminDashboardTabState();
}

class _AdminDashboardTabState extends State<AdminDashboardTab> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AdminDashboardStats>(
      future: _loadDashboardStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildEmptyState(
            Icons.error_outline,
            'Could not load dashboard',
            snapshot.error.toString(),
          );
        }

        final stats = snapshot.data ?? AdminDashboardStats.empty();

        return RefreshIndicator(
          onRefresh: () async {
            await widget.onRefresh();
            setState(() {});
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _dashboardStatCard(
                      title: 'Total Members',
                      value: '${stats.totalMembers}',
                      icon: Icons.groups,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _dashboardStatCard(
                      title: 'New This Month',
                      value: '${stats.newMembersThisMonth}',
                      icon: Icons.person_add_alt_1,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _dashboardStatCard(
                      title: 'Total Payments',
                      value: 'BDT ${_formatMoney(stats.totalPayments)}',
                      icon: Icons.payments,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _dashboardStatCard(
                      title: 'Pending Applications',
                      value: '${stats.pendingApplications}',
                      icon: Icons.pending_actions,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _dashboardSectionTitle(
                icon: Icons.bar_chart,
                title: 'Graph & Statistics Dashboard',
              ),
              const SizedBox(height: 12),
              _buildApplicationsChart(stats),
              const SizedBox(height: 16),
              _buildDashboardBreakdown(stats),
            ],
          ),
        );
      },
    );
  }

  Future<AdminDashboardStats> _loadDashboardStats() async {
    final members = await sl<MemberRemoteDataSource>().getAllMembers();
    final applications =
        await sl<RegistrationRemoteDataSource>().getAllApplications();

    final now = DateTime.now();

    final approvedApplications = applications
        .where((a) => a.status.toLowerCase() == 'approved')
        .toList();

    final rejectedApplications = applications
        .where((a) => a.status.toLowerCase() == 'rejected')
        .toList();

    final pendingApplications = applications
        .where((a) => a.status.toLowerCase() == 'pending')
        .toList();

    final newMembersThisMonth = approvedApplications.where((app) {
      final submittedAt = DateTime.tryParse(app.submittedAt);
      if (submittedAt == null) return false;

      return submittedAt.year == now.year && submittedAt.month == now.month;
    }).length;

    double totalPayments = 0;
    for (final app in applications) {
      final status = app.status.toLowerCase();

      if (status == 'rejected') continue;

      totalPayments += _parsePaymentAmount(app.paymentAmount);
    }

    final processedApplications =
        applications.where((a) => a.status != 'pending').length;

    return AdminDashboardStats(
      totalMembers: members.length,
      newMembersThisMonth: newMembersThisMonth,
      totalPayments: totalPayments,
      pendingApplications: pendingApplications.length,
      approvedApplications: approvedApplications.length,
      rejectedApplications: rejectedApplications.length,
      processedApplications: processedApplications,
      totalApplications: applications.length,
    );
  }

  Widget _dashboardStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.12),
              color.withValues(alpha: 0.04),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 14),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: value.length > 12 ? 18 : 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dashboardSectionTitle({
    required IconData icon,
    required String title,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildApplicationsChart(AdminDashboardStats stats) {
    final maxValue = [
      stats.pendingApplications,
      stats.approvedApplications,
      stats.rejectedApplications,
      stats.newMembersThisMonth,
    ].fold<int>(1, (prev, value) => value > prev ? value : prev);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Applications Overview',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  maxY: maxValue.toDouble() + 2,
                  alignment: BarChartAlignment.spaceAround,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: AppColors.textHint.withValues(alpha: 0.25),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          if (value % 1 != 0) return const SizedBox.shrink();
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 42,
                        getTitlesWidget: (value, meta) {
                          final label = switch (value.toInt()) {
                            0 => 'Pending',
                            1 => 'Approved',
                            2 => 'Rejected',
                            3 => 'New',
                            _ => '',
                          };

                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              label,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: [
                    _barGroup(
                      x: 0,
                      value: stats.pendingApplications,
                      color: Colors.orange,
                    ),
                    _barGroup(
                      x: 1,
                      value: stats.approvedApplications,
                      color: AppColors.success,
                    ),
                    _barGroup(
                      x: 2,
                      value: stats.rejectedApplications,
                      color: AppColors.error,
                    ),
                    _barGroup(
                      x: 3,
                      value: stats.newMembersThisMonth,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _barGroup({
    required int x,
    required int value,
    required Color color,
  }) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: value.toDouble(),
          width: 22,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(6),
          ),
          color: color,
        ),
      ],
    );
  }

  Widget _buildDashboardBreakdown(AdminDashboardStats stats) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Statistics',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _dashboardBreakdownRow(
              label: 'Total Applications',
              value: '${stats.totalApplications}',
              icon: Icons.assignment,
              color: AppColors.primary,
            ),
            _dashboardBreakdownRow(
              label: 'Approved Applications',
              value: '${stats.approvedApplications}',
              icon: Icons.check_circle,
              color: AppColors.success,
            ),
            _dashboardBreakdownRow(
              label: 'Rejected Applications',
              value: '${stats.rejectedApplications}',
              icon: Icons.cancel,
              color: AppColors.error,
            ),
            _dashboardBreakdownRow(
              label: 'Processed Applications',
              value: '${stats.processedApplications}',
              icon: Icons.task_alt,
              color: Colors.blueGrey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _dashboardBreakdownRow({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  double _parsePaymentAmount(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9.]'), '');
    if (cleaned.isEmpty) return 0;
    return double.tryParse(cleaned) ?? 0;
  }

  String _formatMoney(double value) {
    final formatter = NumberFormat('#,##0', 'en_US');
    return formatter.format(value.round());
  }
}

class AdminDashboardStats {
  final int totalMembers;
  final int newMembersThisMonth;
  final double totalPayments;
  final int pendingApplications;
  final int approvedApplications;
  final int rejectedApplications;
  final int processedApplications;
  final int totalApplications;

  const AdminDashboardStats({
    required this.totalMembers,
    required this.newMembersThisMonth,
    required this.totalPayments,
    required this.pendingApplications,
    required this.approvedApplications,
    required this.rejectedApplications,
    required this.processedApplications,
    required this.totalApplications,
  });

  factory AdminDashboardStats.empty() {
    return const AdminDashboardStats(
      totalMembers: 0,
      newMembersThisMonth: 0,
      totalPayments: 0,
      pendingApplications: 0,
      approvedApplications: 0,
      rejectedApplications: 0,
      processedApplications: 0,
      totalApplications: 0,
    );
  }
}
