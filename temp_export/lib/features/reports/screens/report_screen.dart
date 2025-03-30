import 'package:flutter/material.dart';
import '../../../core/widgets/empty_state_widget.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
      ),
      body: const EmptyStateWidget(
        message: 'Reports Coming Soon',
        subMessage: 'Business analytics and reports will be available in the next update.',
        icon: Icons.analytics_outlined,
      ),
    );
  }
}