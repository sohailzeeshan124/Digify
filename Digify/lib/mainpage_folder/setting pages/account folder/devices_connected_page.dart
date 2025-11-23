// ...existing code...
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:io';

class Devicesconnected extends StatefulWidget {
  const Devicesconnected({super.key});

  @override
  State<Devicesconnected> createState() => _DevicesconnectedState();
}

class _DevicesconnectedState extends State<Devicesconnected> {
  bool _loading = true;
  List<Map<String, dynamic>> _sessions = [];
  DateTime? _lastLogin;
  String? _deviceName;

  @override
  void initState() {
    super.initState();
    _deviceName = _detectDeviceName();
    _loadSessions();
  }

  String _detectDeviceName() {
    try {
      return '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
    } catch (_) {
      return Platform.operatingSystem;
    }
  }

  Future<void> _loadSessions() async {
    setState(() => _loading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _sessions = [];
          _lastLogin = null;
          _loading = false;
        });
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = doc.data() ?? {};

      // parse lastLogin
      final lastLoginRaw = data['lastLogin'];
      DateTime? parsedLastLogin;
      if (lastLoginRaw is Timestamp) {
        parsedLastLogin = lastLoginRaw.toDate();
      } else if (lastLoginRaw is DateTime) {
        parsedLastLogin = lastLoginRaw;
      } else if (lastLoginRaw is String) {
        parsedLastLogin = DateTime.tryParse(lastLoginRaw);
      }

      // parse sessions array
      final sessionsRaw = data['sessions'];
      final List<Map<String, dynamic>> sessions = [];
      if (sessionsRaw is List) {
        for (final item in sessionsRaw) {
          if (item is Map) {
            final map = Map<String, dynamic>.from(item as Map);
            // normalize loggedInAt
            final rawTime = map['loggedInAt'];
            DateTime? time;
            if (rawTime is Timestamp) {
              time = rawTime.toDate();
            } else if (rawTime is DateTime) {
              time = rawTime;
            } else if (rawTime is String) {
              time = DateTime.tryParse(rawTime);
            }
            map['loggedInAt'] = time;
            sessions.add(map);
          }
        }
      }

      // sort sessions by loggedInAt desc
      sessions.sort((a, b) {
        final ta = a['loggedInAt'] as DateTime?;
        final tb = b['loggedInAt'] as DateTime?;
        if (ta == null && tb == null) return 0;
        if (ta == null) return 1;
        if (tb == null) return -1;
        return tb.compareTo(ta);
      });

      // filter out current device entries so they are not shown in the list
      final filtered = sessions.where((s) {
        final device = (s['device'] ?? '').toString();
        return device != (_deviceName ?? '');
      }).toList();

      setState(() {
        _sessions = filtered;
        _lastLogin = parsedLastLogin;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return 'Unknown';
    return DateFormat('dd MMM yyyy • hh:mm a').format(dt);
  }

  Widget _buildSessionCard(Map<String, dynamic> s, int index) {
    final device = (s['device'] ?? 'Unknown device').toString();
    final ip = (s['ip'] ?? '').toString();
    final loggedAt = s['loggedInAt'] as DateTime?;
    final isCurrent =
        _deviceName != null && device.isNotEmpty && device == _deviceName;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: isCurrent ? Colors.green[50] : Colors.grey[100],
              child: Icon(
                isCurrent ? Icons.smartphone : Icons.devices,
                color: isCurrent ? Colors.green[700] : Colors.grey[700],
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            // Main content column: device name, then IP row, then date row
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Device name (single line, ellipsize)
                  Text(
                    device,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // IP row (if available) on its own line
                  if (ip.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(Icons.wifi, size: 14, color: Colors.grey),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            ip,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],
                  // Date row on its own line
                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          _formatDateTime(loggedAt),
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Action column: "This device" chip and delete button
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isCurrent)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Chip(
                      label: const Text('This device'),
                      backgroundColor: Colors.green[50],
                      labelStyle: const TextStyle(color: Colors.green),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  tooltip: 'Remove session',
                  onPressed: () => _confirmAndDeleteSession(s, index),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmAndDeleteSession(
      Map<String, dynamic> session, int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove session'),
        content: const Text('Are you sure you want to remove this session?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Remove')),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final docRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);

      // Build the exact entry to remove. Firestore stores DateTime as Timestamp,
      // so convert if necessary.
      dynamic rawLogged = session['loggedInAt'];
      dynamic loggedForRemove;
      if (rawLogged is DateTime) {
        loggedForRemove = Timestamp.fromDate(rawLogged);
      } else if (rawLogged is Timestamp) {
        loggedForRemove = rawLogged;
      } else if (rawLogged is String) {
        final parsed = DateTime.tryParse(rawLogged);
        loggedForRemove =
            parsed != null ? Timestamp.fromDate(parsed) : rawLogged;
      } else {
        loggedForRemove = rawLogged;
      }

      final Map<String, dynamic> entryForRemove = {
        'device': session['device'] ?? '',
        'ip': session['ip'] ?? '',
        'loggedInAt': loggedForRemove,
      };

      await docRef.update({
        'sessions': FieldValue.arrayRemove([entryForRemove])
      });

      // Update local state to reflect removal
      setState(() {
        // best-effort remove the matching item at index if still present
        if (index >= 0 && index < _sessions.length) {
          _sessions.removeAt(index);
        } else {
          // fallback: remove first matching by device+ip+timestamp
          _sessions.removeWhere((e) =>
              (e['device'] ?? '') == (session['device'] ?? '') &&
              (e['ip'] ?? '') == (session['ip'] ?? '') &&
              ((e['loggedInAt'] as DateTime?)?.toIso8601String() ==
                  (session['loggedInAt'] as DateTime?)?.toIso8601String()));
        }
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Session removed')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove session: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF274A31),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Connected Devices',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.refresh, color: Colors.white),
        //     onPressed: _loadSessions,
        //     tooltip: 'Refresh',
        //   ),
        // ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadSessions,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
                      child: Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              const Icon(Icons.login,
                                  size: 28, color: Colors.blueAccent),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Last login',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 6),
                                    Text(_formatDateTime(_lastLogin),
                                        style: const TextStyle(fontSize: 14)),
                                  ],
                                ),
                              ),
                              // TextButton.icon(
                              //   onPressed: _loadSessions,
                              //   icon: const Icon(Icons.update),
                              //   label: const Text('Update'),
                              // ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      child: Text(
                        'Sessions (${_sessions.length})',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          _buildSessionCard(_sessions[index], index),
                      childCount: _sessions.length,
                    ),
                  ),
                  if (_sessions.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 36.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.devices_other,
                                  size: 56, color: Colors.grey),
                              SizedBox(height: 12),
                              Text(
                                'No connected devices found.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              ),
            ),
    );
  }
}
