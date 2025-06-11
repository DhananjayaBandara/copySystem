import 'dart:ui';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class SessionDashboardScreen extends StatefulWidget {
  final int sessionId;

  const SessionDashboardScreen({Key? key, required this.sessionId})
    : super(key: key);

  @override
  _SessionDashboardScreenState createState() => _SessionDashboardScreenState();
}

class _SessionDashboardScreenState extends State<SessionDashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Session Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.blue.shade800,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.5,
            colors: [
              Colors.blue.shade400,
              Colors.purple.shade400,
              Colors.indigo.shade500,
            ],
          ),
        ),
        child: SafeArea(
          child: FutureBuilder<Map<String, dynamic>>(
            future: ApiService.getSessionDashboard(widget.sessionId),
            builder: (context, snapshot) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: _buildBody(context, snapshot),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AsyncSnapshot<Map<String, dynamic>> snapshot,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          backgroundColor: Colors.white.withOpacity(0.2),
          strokeWidth: 3,
        ),
      );
    } else if (snapshot.hasError) {
      return Center(
        child: _buildGlassCard(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              'Error: ${snapshot.error}',
              style: TextStyle(
                color: Colors.red.shade600,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    } else if (snapshot.hasData) {
      final data = snapshot.data!;
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Session Dashboard',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.8,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Key Metrics & Feedback Insights',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              _buildMetricsGrid(data),
              const SizedBox(height: 16),
              _buildImpactSummaryCard(data),
              const SizedBox(height: 16),
              _buildSuggestionsCard(data),
            ],
          ),
        ),
      );
    } else {
      return Center(
        child: _buildGlassCard(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              'No data found.',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
  }

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
          child: child,
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(Map<String, dynamic> data) {
    return _buildGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.8,
          children: [
            _buildMetricTile(
              icon: Icons.person_add,
              title: 'Registered',
              value: '${data['registered_count']}',
              color: Colors.blue.shade600,
            ),
            _buildMetricTile(
              icon: Icons.check_circle,
              title: 'Attended',
              value: '${data['attended_count']}',
              color: Colors.green.shade600,
            ),
            _buildMetricTile(
              icon: Icons.pie_chart,
              title: 'Attendance %',
              value: '${data['attendance_percentage'].toStringAsFixed(1)}%',
              color: Colors.purple.shade600,
              progress: data['attendance_percentage'] / 100,
            ),
            _buildMetricTile(
              icon: Icons.star,
              title: 'Avg Rating',
              value: data['average_rating']?.toString() ?? 'N/A',
              color: Colors.orange.shade600,
              rating:
                  data['average_rating'] != null
                      ? data['average_rating']
                      : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    double? progress,
    double? rating,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Icon(icon, color: color, size: 24),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (progress != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        strokeWidth: 3,
                      ),
                    ),
                  )
                else if (rating != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return Icon(
                          index < rating.round()
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.orange.shade600,
                          size: 16,
                        );
                      }),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImpactSummaryCard(Map<String, dynamic> data) {
    return _buildGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Icon(
                    Icons.info,
                    color: Colors.blue.shade600,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Impact Summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              data['impact_summary'] ?? 'No feedback yet.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsCard(Map<String, dynamic> data) {
    final suggestions = (data['improvement_suggestions'] as List?) ?? [];
    return _buildGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Icon(
                    Icons.lightbulb,
                    color: Colors.yellow.shade600,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Suggestions for Improvement',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            suggestions.isEmpty
                ? Text(
                  'No suggestions provided.',
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                )
                : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: suggestions.length,
                  separatorBuilder:
                      (context, index) => Divider(
                        height: 8,
                        thickness: 0.5,
                        color: Colors.white.withOpacity(0.2),
                      ),
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: Icon(
                              Icons.arrow_right,
                              color: Colors.yellow.shade600,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              suggestions[index],
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
          ],
        ),
      ),
    );
  }
}
