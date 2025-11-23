import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:digify/viewmodels/user_viewmodel.dart';
import 'package:digify/modal_classes/user_data.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  final UserViewModel _vm = UserViewModel();
  UserModel? _user;
  bool _loading = true;

  final Map<String, String> _display = {
    'pdf': 'PDFs Created',
    'signed': 'Documents Signed',
    'img2txt': 'Image→Text',
    'cert': 'Certificates',
  };

  String _selectedCategory = 'pdf';
  int _days = 30;
  List<DateTime> _dates = [];
  List<int> _counts = [];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    setState(() => _loading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _loading = false;
      });
      return;
    }
    try {
      final u = await _vm.getUser(user.uid);
      if (!mounted) return;
      setState(() {
        _user = u;
      });
      _rebuildChart();
    } catch (e) {
      if (!mounted) return;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<DateTime> _getDatesForCategory(UserModel u, String key) {
    switch (key) {
      case 'pdf':
        return u.pdfCreatedAt;
      case 'signed':
        return u.documentsSignedAt;
      case 'img2txt':
        return u.imagesToTextAt;
      case 'cert':
        return u.certificatesCreatedAt;
      default:
        return [];
    }
  }

  void _rebuildChart() {
    if (_user == null) return;
    final raw = _getDatesForCategory(_user!, _selectedCategory)
        .whereType<DateTime>()
        .toList();

    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: _days - 1));

    final buckets = <DateTime, int>{};
    for (int i = 0; i < _days; i++) {
      final d = start.add(Duration(days: i));
      buckets[DateTime(d.year, d.month, d.day)] = 0;
    }

    for (final dt in raw) {
      final key = DateTime(dt.year, dt.month, dt.day);
      if (key.isBefore(start)) continue;
      if (buckets.containsKey(key)) buckets[key] = buckets[key]! + 1;
    }

    final labels = buckets.keys.toList()..sort();
    final counts = labels.map((d) => buckets[d] ?? 0).toList();

    setState(() {
      _dates = labels;
      _counts = counts;
    });
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 8,
              children: _display.keys.map((k) {
                final selected = k == _selectedCategory;
                return ChoiceChip(
                  label: Text(_display[k]!),
                  selected: selected,
                  onSelected: (v) {
                    setState(() => _selectedCategory = k);
                    _rebuildChart();
                  },
                );
              }).toList(),
            ),
          ),
          const SizedBox(width: 8),
          DropdownButton<int>(
            value: _days,
            items: const [
              DropdownMenuItem(value: 7, child: Text('7d')),
              DropdownMenuItem(value: 30, child: Text('30d')),
              DropdownMenuItem(value: 90, child: Text('90d')),
              DropdownMenuItem(value: 365, child: Text('1y')),
            ],
            onChanged: (v) {
              if (v == null) return;
              setState(() => _days = v);
              _rebuildChart();
            },
          ),
        ],
      ),
    );
  }

  BarChartGroupData _makeGroup(int x, int value) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: value.toDouble(),
          width: 14,
          borderRadius: BorderRadius.circular(4),
          color: Theme.of(context).primaryColor,
        )
      ],
    );
  }

  Widget _buildChart() {
    if (_dates.isEmpty || _counts.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No data for selected period')),
      );
    }

    final maxY = (_counts.isEmpty
        ? 1.0
        : (_counts.reduce((a, b) => a > b ? a : b).toDouble() + 1.0));

    final interval = (maxY / 4).clamp(1.0, maxY);

    return SizedBox(
      height: 260,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceBetween,
            maxY: maxY,
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    return Text(value.toInt().toString(),
                        style: const TextStyle(fontSize: 10));
                  },
                  interval: interval,
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 36,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= _dates.length) {
                      return const SizedBox();
                    }
                    final dt = _dates[idx];
                    final label = (_days <= 30)
                        ? DateFormat('dd MMM').format(dt)
                        : DateFormat('MMM yy').format(dt);
                    return Text(label, style: const TextStyle(fontSize: 10));
                  },
                  interval: 1,
                ),
              ),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(
                show: true,
                drawHorizontalLine: true,
                horizontalInterval: interval),
            barGroups:
                List.generate(_counts.length, (i) => _makeGroup(i, _counts[i])),
            borderData: FlBorderData(show: false),
          ),
        ),
      ),
    );
  }

  Widget _buildEventList() {
    if (_user == null) return const SizedBox();
    final raw = _getDatesForCategory(_user!, _selectedCategory)
        .whereType<DateTime>()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    if (raw.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('No events recorded for this category.'),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: raw.map((dt) {
          return ListTile(
            dense: true,
            leading: const Icon(Icons.circle, size: 10),
            title: Text(DateFormat('dd MMM yyyy • hh:mm a').format(dt)),
            subtitle: Text('Event in ${_display[_selectedCategory]}'),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        backgroundColor: const Color(0xFF274A31),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUser,
              child: ListView(
                children: [
                  const SizedBox(height: 12),
                  _buildControls(),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Text(
                              _display[_selectedCategory] ?? '',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          _buildChart(),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Text('Events',
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                  _buildEventList(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}
