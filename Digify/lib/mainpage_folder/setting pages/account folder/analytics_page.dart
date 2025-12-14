import 'package:digify/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:digify/viewmodels/user_viewmodel.dart';
import 'package:digify/modal_classes/user_data.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  // final UserViewModel _vm = UserViewModel(); // Unused
  UserModel? _user;
  bool _loading = true;
  int _touchedIndex = -1;

  final Map<String, String> _categories = {
    'pdf': 'PDFs',
    'signed': 'Signed',
    'img2txt': 'OCR',
    'cert': 'Certs',
  };

  String _selectedCategory = 'pdf';
  int _days = 7;

  // Chart data
  List<String> _labels = [];
  List<double> _values = [];
  double _maxY = 0;
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    setState(() => _loading = true);

    // MOCK DATA GENERATION
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate delay

    final Random random = Random();
    final DateTime now = DateTime.now();

    List<DateTime> generateRandomDates(int count) {
      return List.generate(count, (_) {
        return now.subtract(Duration(
          days: random.nextInt(365),
          hours: random.nextInt(24),
        ));
      });
    }

    _user = UserModel(
      uid: 'mock_uid',
      email: 'mock@example.com',
      username: 'Mock User',
      fullName: 'Mock User',
      dateOfBirth: DateTime(1990, 1, 1),
      createdAt: DateTime(2023, 1, 1),
      isGoogleDriveLinked: false,
      pdfCreatedAt: generateRandomDates(50),
      documentsSignedAt: generateRandomDates(30),
      imagesToTextAt: generateRandomDates(40),
      certificatesCreatedAt: generateRandomDates(20),

      // Default empty/dummy values for required fields
      friends: [],
      serversJoined: [],
      sessions: [],
      serverRoles: {},
    );

    if (!mounted) return;
    setState(() {});
    _rebuildChart();
    setState(() => _loading = false);
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
    _labels = [];
    _values = [];
    _totalCount = 0;

    if (_days == 365) {
      // Monthly grouping for 1 year
      List<DateTime> months = [];
      for (int i = 11; i >= 0; i--) {
        months.add(DateTime(now.year, now.month - i, 1));
      }

      _values = List.filled(12, 0.0);
      _labels = months.map((d) => DateFormat('MMM').format(d)).toList();

      for (var dt in raw) {
        // Check if dt is within the last ~365 days (roughly)
        // We match by month bucket
        for (int i = 0; i < 12; i++) {
          final m = months[i];
          if (dt.year == m.year && dt.month == m.month) {
            _values[i]++;
            break;
          }
        }
      }
    } else {
      // Daily grouping
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
        if (buckets.containsKey(key)) {
          buckets[key] = buckets[key]! + 1;
        }
      }

      final sortedKeys = buckets.keys.toList()..sort();
      _labels = sortedKeys.map((d) {
        if (_days == 7) return DateFormat('E').format(d);
        return DateFormat('d/M').format(d);
      }).toList();
      _values = sortedKeys.map((d) => buckets[d]!.toDouble()).toList();
    }

    _totalCount = _values.fold(0, (sum, v) => sum + v.toInt());
    _maxY =
        _values.isEmpty ? 5.0 : (_values.reduce((a, b) => a > b ? a : b) * 1.2);
    if (_maxY < 5) _maxY = 5;

    setState(() {});
  }

  Widget _buildCategorySelector() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: _categories.entries.map((e) {
          final isSelected = _selectedCategory == e.key;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = e.key;
                _touchedIndex = -1;
              });
              _rebuildChart();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryGreen
                    : AppColors.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                            color: AppColors.primaryGreen.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 4))
                      ]
                    : [],
              ),
              child: Center(
                child: Text(
                  e.value,
                  style: GoogleFonts.poppins(
                    color: isSelected ? Colors.white : AppColors.primaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTimeRangeSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [7, 30, 90, 365].map((d) {
          final isSelected = _days == d;
          String label = '';
          if (d == 7) label = '7 Days';
          if (d == 30) label = '30 Days';
          if (d == 90) label = '3 Months';
          if (d == 365) label = '1 Year';

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _days = d;
                  _touchedIndex = -1;
                });
                _rebuildChart();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2))
                        ]
                      : [],
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? Colors.black : Colors.grey[600],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryGreen,
            AppColors.primaryGreen.withOpacity(0.8)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.insights, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total ${_categories[_selectedCategory]}',
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
              ),
              Text(
                '$_totalCount',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  BarChartGroupData _makeGroupData(int x, double y, {bool isTouched = false}) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: isTouched ? y + (y * 0.05) : y,
          color: isTouched ? AppColors.primaryGreen : const Color(0xFF81C784),
          width: _days == 7
              ? 22
              : _days == 30
                  ? 8
                  : _days == 90
                      ? 4
                      : 16,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: _maxY,
            color: Colors.grey[100],
          ),
        ),
      ],
      showingTooltipIndicators: isTouched ? [0] : [],
    );
  }

  Widget _buildChart() {
    if (_values.isEmpty) {
      return SizedBox(
        height: 300,
        child: Center(
            child: Text('No data available', style: GoogleFonts.poppins())),
      );
    }

    return Container(
      height: 320,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 5,
          ),
        ],
      ),
      child: BarChart(
        BarChartData(
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppColors.primaryGreen,
              tooltipPadding: const EdgeInsets.all(8),
              tooltipMargin: 8,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${rod.toY.toInt()}\n',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  children: <TextSpan>[
                    TextSpan(
                      text: _labels[group.x],
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                );
              },
            ),
            touchCallback: (FlTouchEvent event, barTouchResponse) {
              setState(() {
                if (!event.isInterestedForInteractions ||
                    barTouchResponse == null ||
                    barTouchResponse.spot == null) {
                  _touchedIndex = -1;
                  return;
                }
                _touchedIndex = barTouchResponse.spot!.touchedBarGroupIndex;
              });
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= _labels.length) {
                    return const SizedBox();
                  }

                  // Smart label showing logic
                  if (_days == 30 && index % 5 != 0) return const SizedBox();
                  if (_days == 90 && index % 15 != 0) return const SizedBox();

                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _labels[index],
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
                reservedSize: 30,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: _maxY / 4 > 0 ? _maxY / 4 : 1,
                getTitlesWidget: (value, meta) {
                  if (value == 0) return const SizedBox();
                  return Text(
                    value.toInt().toString(),
                    style: GoogleFonts.poppins(
                      color: Colors.grey[400],
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(_values.length, (i) {
            return _makeGroupData(i, _values[i], isTouched: i == _touchedIndex);
          }),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: _maxY / 4 > 0 ? _maxY / 4 : 1,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey[100],
              strokeWidth: 1,
            ),
          ),
          alignment: BarChartAlignment.spaceAround,
          maxY: _maxY,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        title: Text(
          'Analytics',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: AppColors.primaryGreen,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen))
          : RefreshIndicator(
              onRefresh: _loadUser,
              color: AppColors.primaryGreen,
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 20),
                children: [
                  _buildCategorySelector(),
                  const SizedBox(height: 24),
                  _buildSummaryCard(),
                  const SizedBox(height: 24),
                  _buildTimeRangeSelector(),
                  const SizedBox(height: 8),
                  _buildChart(),
                ],
              ),
            ),
    );
  }
}
