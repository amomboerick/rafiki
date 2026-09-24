// rafiki_mobile/lib/my_bookings_page.dart
import 'package:flutter/material.dart';
import 'api_service.dart';
import 'auth_state.dart';
import 'auth_page.dart';

class RafikiColors {
  static const indigo = Color(0xFF4F46E5);
  static const coral  = Color(0xFFFF6B6B);
  static const ink    = Color(0xFF1F2937);
  static const muted  = Color(0xFF6B7280);
  static const bg     = Color(0xFFF9FAFB);
  static const border = Color(0xFFE5E7EB);
  static const green  = Color(0xFF10B981);
  static const amber  = Color(0xFFF59E0B);
  static const red    = Color(0xFFEF4444);
}

class MyBookingsPage extends StatefulWidget {
  const MyBookingsPage({super.key});
  @override
  State<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage> {
  Future<List<dynamic>>? _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final auth = AuthState.instance;
    if (auth.isLoggedIn) {
      setState(() {
        _future = ApiService.getMyBookings(token: auth.token!);
      });
    } else {
      setState(() => _future = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RafikiColors.bg,
      appBar: AppBar(
        title: const Text('My Bookings'),
        backgroundColor: RafikiColors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: AuthState.instance,
        builder: (context, _) {
          final auth = AuthState.instance;

          if (!auth.isLoggedIn) {
            return _signInPrompt(context);
          }

          if (_future == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _load());
            return const Center(child: CircularProgressIndicator(color: RafikiColors.indigo));
          }

          return RefreshIndicator(
            onRefresh: () async => _load(),
            color: RafikiColors.indigo,
            child: FutureBuilder<List<dynamic>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: RafikiColors.indigo));
                }
                if (snapshot.hasError) {
                  return ListView(
                    children: [
                      const SizedBox(height: 80),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              const Icon(Icons.cloud_off, size: 48, color: RafikiColors.muted),
                              const SizedBox(height: 12),
                              Text('${snapshot.error}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: RafikiColors.muted)),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _load,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: RafikiColors.indigo,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }
                final data = snapshot.data ?? [];
                if (data.isEmpty) {
                  return ListView(
                    children: [
                      const SizedBox(height: 100),
                      const Center(
                        child: Icon(Icons.receipt_long, size: 72, color: RafikiColors.muted),
                      ),
                      const SizedBox(height: 16),
                      const Center(
                        child: Text('No bookings yet',
                          style: TextStyle(fontSize: 16,
                            fontWeight: FontWeight.w700, color: RafikiColors.ink)),
                      ),
                      const SizedBox(height: 8),
                      const Center(
                        child: Text('Book a service to see it here',
                          style: TextStyle(fontSize: 13, color: RafikiColors.muted)),
                      ),
                    ],
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: data.length,
                  itemBuilder: (context, i) =>
                    _BookingCard(booking: data[i] as Map<String, dynamic>),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _signInPrompt(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calendar_today_outlined, size: 72, color: RafikiColors.muted),
            const SizedBox(height: 16),
            const Text('Sign in to see your bookings',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: RafikiColors.ink)),
            const SizedBox(height: 24),
            SizedBox(
              width: 220, height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AuthPage()),
                  );
                  _load();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: RafikiColors.indigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Sign In / Register',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  const _BookingCard({required this.booking});

  Color _statusColor(String s) {
    switch (s) {
      case 'completed':   return RafikiColors.green;
      case 'cancelled':   return RafikiColors.red;
      case 'in_progress': return RafikiColors.amber;
      case 'accepted':    return RafikiColors.amber;
      default:            return RafikiColors.indigo;
    }
  }

  IconData _statusIcon(String s) {
    switch (s) {
      case 'completed':   return Icons.check_circle;
      case 'cancelled':   return Icons.cancel;
      case 'in_progress': return Icons.directions_run;
      case 'accepted':    return Icons.thumb_up;
      default:            return Icons.schedule;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ref = booking['reference'] as String;
    final status = booking['status'] as String;
    final total = (booking['total_amount'] as num).toDouble();
    final scheduled = booking['scheduled_at'] as String?;
    final service = booking['service'] as Map<String, dynamic>;
    final provider = booking['provider'] as Map<String, dynamic>;
    final statusColor = _statusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: RafikiColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---- Header row: reference + status ----
            Row(
              children: [
                Expanded(
                  child: Text(ref,
                    style: const TextStyle(fontSize: 16,
                      fontWeight: FontWeight.w800, color: RafikiColors.indigo)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_statusIcon(status), size: 12, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        status.toUpperCase(),
                        style: TextStyle(fontSize: 10,
                          fontWeight: FontWeight.w800, color: statusColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ---- Service info ----
            Text(service['title'] as String,
              style: const TextStyle(fontSize: 15,
                fontWeight: FontWeight.w700, color: RafikiColors.ink)),
            const SizedBox(height: 3),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: RafikiColors.indigo.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(service['category'] as String,
                    style: const TextStyle(fontSize: 10,
                      fontWeight: FontWeight.w700, color: RafikiColors.indigo)),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.repeat, size: 11, color: RafikiColors.muted),
                const SizedBox(width: 3),
                Text(booking['booking_type'] as String,
                  style: const TextStyle(fontSize: 11, color: RafikiColors.muted)),
              ],
            ),

            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // ---- Provider row ----
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: RafikiColors.indigo.withOpacity(0.12),
                  child: Text(
                    _initials(provider['name'] as String),
                    style: const TextStyle(fontSize: 10,
                      fontWeight: FontWeight.w800, color: RafikiColors.indigo),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(provider['name'] as String,
                            style: const TextStyle(fontSize: 13,
                              fontWeight: FontWeight.w600, color: RafikiColors.ink)),
                          if (provider['verified'] == true) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.verified, size: 12, color: RafikiColors.green),
                          ],
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 11, color: RafikiColors.amber),
                          const SizedBox(width: 2),
                          Text('${provider['rating']}',
                            style: const TextStyle(fontSize: 11,
                              fontWeight: FontWeight.w600, color: RafikiColors.ink)),
                          const SizedBox(width: 8),
                          const Icon(Icons.location_on, size: 11, color: RafikiColors.muted),
                          const SizedBox(width: 2),
                          Text('${provider['sub_county']}',
                            style: const TextStyle(fontSize: 11, color: RafikiColors.muted)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (scheduled != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.event, size: 13, color: RafikiColors.muted),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(scheduled),
                    style: const TextStyle(fontSize: 12, color: RafikiColors.muted),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // ---- Price + Action ----
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total',
                        style: TextStyle(fontSize: 10, color: RafikiColors.muted)),
                      Text('KSh ${total.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 18,
                          fontWeight: FontWeight.w800, color: RafikiColors.indigo)),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Booking $ref — detail view coming next')),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline, size: 14, color: RafikiColors.indigo),
                  label: const Text('Details',
                    style: TextStyle(color: RafikiColors.indigo, fontWeight: FontWeight.w700, fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: RafikiColors.indigo),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  static String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      final hh = dt.hour.toString().padLeft(2, '0');
      final mm = dt.minute.toString().padLeft(2, '0');
      return '${dt.day} ${months[dt.month-1]} ${dt.year} · $hh:$mm';
    } catch (_) {
      return iso;
    }
  }
}