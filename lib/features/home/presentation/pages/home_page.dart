import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../bloc/home_bloc.dart';
import '../widgets/dashboard_metrics.dart';
import '../widgets/activity_feed.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<HomeBloc>()..add(const HomeDataRequested()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Dashboard'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                context.read<HomeBloc>().add(const HomeDataRequested());
              },
            ),
          ],
        ),
        body: const RefreshIndicator(
          onRefresh: _onRefresh,
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DashboardMetrics(),
                SizedBox(height: 24),
                ActivityFeed(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Future<void> _onRefresh() async {
    // Implement refresh logic
    await Future.delayed(const Duration(seconds: 1));
  }
}