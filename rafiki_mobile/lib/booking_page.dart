// rafiki_mobile/lib/booking_page.dart
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

String normalizePhone(String input) {
  var p = input.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
  if (p.startsWith('0') && p.length == 10) {
    p = '254${p.substring(1)}';
  } else if (p.startsWith('7') && p.length == 9) {
    p = '254$p';
  }
  return p;
}

class BookingPage extends StatefulWidget {
  final Map<String, dynamic> item;
  const BookingPage({super.key, required this.item});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  String _bookingType = 'instant';
  DateTime? _scheduledAt;
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledAt ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
    );
    if (date == null) return;
    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
    );
    if (time == null) return;
    setState(() {
      _scheduledAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _confirmBooking() async {
    final auth = AuthState.instance;

    if (!auth.isLoggedIn) {
      final logged = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const AuthPage()),
      );
      if (logged != true) return;
    }

    if (_bookingType == 'scheduled' && _scheduledAt == null) {
      setState(() => _error = 'Please pick a date and time for scheduled booking.');
      return;
    }
    if (_addressCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please enter the service address.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final item = widget.item;
      final booking = await ApiService.createBooking(
        token: AuthState.instance.token!,
        serviceId: item['service_id'] as int,
        bookingType: _bookingType,
        scheduledAt: _scheduledAt,
        address: _addressCtrl.text.trim(),
        notes: _notesCtrl.text.trim(),
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => BookingSuccessPage(booking: booking, item: item),
        ),
      );
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final p = item['provider'] as Map<String, dynamic>;
    final price = (item['price'] as num).toDouble();

    return Scaffold(
      backgroundColor: RafikiColors.bg,
      appBar: AppBar(
        title: const Text('Confirm Booking'),
        backgroundColor: RafikiColors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: RafikiColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: RafikiColors.indigo.withOpacity(0.12),
                        child: Text(
                          _initials(p['name'] as String),
                          style: const TextStyle(
                            color: RafikiColors.indigo,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p['name'] as String,
                              style: const TextStyle(fontSize: 15,
                                fontWeight: FontWeight.w700, color: RafikiColors.ink)),
                            const SizedBox(height: 2),
                            Text('${p['sub_county'] ?? ''}, ${p['county'] ?? ''}',
                              style: const TextStyle(fontSize: 12, color: RafikiColors.muted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Text(item['title'] as String,
                    style: const TextStyle(fontSize: 14,
                      fontWeight: FontWeight.w600, color: RafikiColors.ink)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text('KSh ${price.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 20,
                          fontWeight: FontWeight.w800, color: RafikiColors.indigo)),
                      const SizedBox(width: 6),
                      Text(item['price_unit'] ?? '',
                        style: const TextStyle(fontSize: 12, color: RafikiColors.muted)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text('When do you need this?',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: RafikiColors.ink)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _typeCard('instant', 'Instant', 'As soon as possible', Icons.flash_on)),
                const SizedBox(width: 10),
                Expanded(child: _typeCard('scheduled', 'Scheduled', 'Pick date & time', Icons.calendar_today)),
              ],
            ),

            if (_bookingType == 'scheduled') ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _pickDateTime,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: RafikiColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.event, color: RafikiColors.indigo),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _scheduledAt == null
                            ? 'Tap to pick date and time'
                            : '${_scheduledAt!.day}/${_scheduledAt!.month}/${_scheduledAt!.year} at '
                              '${_scheduledAt!.hour.toString().padLeft(2, '0')}:'
                              '${_scheduledAt!.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: _scheduledAt == null ? FontWeight.w500 : FontWeight.w700,
                            color: _scheduledAt == null ? RafikiColors.muted : RafikiColors.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),
            const Text('Service address',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: RafikiColors.ink)),
            const SizedBox(height: 10),
            TextField(
              controller: _addressCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Building, street, area...',
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: RafikiColors.border)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: RafikiColors.border)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: RafikiColors.indigo, width: 1.5)),
              ),
            ),

            const SizedBox(height: 20),
            const Text('Additional notes (optional)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: RafikiColors.ink)),
            const SizedBox(height: 10),
            TextField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'e.g. Bring your own tools',
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: RafikiColors.border)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: RafikiColors.border)),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: RafikiColors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_error!,
                  style: const TextStyle(color: RafikiColors.red, fontSize: 13)),
              ),
            ],

            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _confirmBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: RafikiColors.indigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Confirm Booking',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _typeCard(String value, String title, String subtitle, IconData icon) {
    final active = _bookingType == value;
    return GestureDetector(
      onTap: () => setState(() => _bookingType = value),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: active ? RafikiColors.indigo.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? RafikiColors.indigo : RafikiColors.border,
            width: active ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: active ? RafikiColors.indigo : RafikiColors.muted, size: 22),
            const SizedBox(height: 8),
            Text(title,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                color: active ? RafikiColors.indigo : RafikiColors.ink)),
            const SizedBox(height: 2),
            Text(subtitle,
              style: const TextStyle(fontSize: 11, color: RafikiColors.muted)),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}

class BookingSuccessPage extends StatefulWidget {
  final Map<String, dynamic> booking;
  final Map<String, dynamic> item;
  const BookingSuccessPage({super.key, required this.booking, required this.item});

  @override
  State<BookingSuccessPage> createState() => _BookingSuccessPageState();
}

class _BookingSuccessPageState extends State<BookingSuccessPage> {
  bool _payLoading = false;

  Future<void> _openWhatsApp() async {
    try {
      final link = await ApiService.getWhatsAppLink(widget.booking['reference'] as String);
      final url = link['whatsapp_url'] as String;
      html.window.open(url, '_blank');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('WhatsApp error: ${e.toString().replaceFirst('Exception: ', '')}')),
        );
      }
    }
  }

  Future<void> _payViaMpesa() async {
    final startingPhone = normalizePhone(
      AuthState.instance.user?['phone'] as String? ?? '254712345678',
    );
    final phoneCtrl = TextEditingController(text: startingPhone);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pay via M-Pesa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter the phone number to receive the STK push:',
              style: TextStyle(fontSize: 13, color: RafikiColors.muted)),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(12),
              ],
              decoration: InputDecoration(
                hintText: '254712345678',
                helperText: 'Format: 2547XXXXXXXX',
                prefixIcon: const Icon(Icons.phone_android, color: RafikiColors.muted, size: 18),
                filled: true,
                fillColor: RafikiColors.bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: RafikiColors.border),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text('You will receive a prompt on your phone to enter your M-Pesa PIN.',
              style: TextStyle(fontSize: 11, color: RafikiColors.muted)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: RafikiColors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Send STK'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    final phone = normalizePhone(phoneCtrl.text.trim());
    if (phone.isEmpty) return;

    setState(() => _payLoading = true);
    try {
      final resp = await ApiService.initiateSTKPush(
        token: AuthState.instance.token!,
        bookingReference: widget.booking['reference'] as String,
        phone: phone,
        paymentType: 'full',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resp['customer_message'] ?? 'Check your phone to enter M-Pesa PIN'),
          backgroundColor: RafikiColors.green,
          duration: const Duration(seconds: 6),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('M-Pesa: ${e.toString().replaceFirst('Exception: ', '')}'),
          backgroundColor: RafikiColors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) setState(() => _payLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ref = widget.booking['reference'] as String;
    final p = widget.item['provider'] as Map<String, dynamic>;

    return Scaffold(
      backgroundColor: RafikiColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Center(
                child: Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    color: RafikiColors.green.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle, size: 64, color: RafikiColors.green),
                ),
              ),
              const SizedBox(height: 24),
              const Center(
                child: Text('Booking confirmed!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: RafikiColors.ink)),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text('Your service provider has been notified.',
                  style: TextStyle(fontSize: 14, color: RafikiColors.muted)),
              ),
              const SizedBox(height: 30),

              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: RafikiColors.border),
                ),
                child: Column(
                  children: [
                    const Text('Booking reference',
                      style: TextStyle(fontSize: 12, color: RafikiColors.muted)),
                    const SizedBox(height: 6),
                    Text(ref,
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: RafikiColors.indigo)),
                    const SizedBox(height: 14),
                    const Divider(height: 1),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Icon(Icons.person, size: 16, color: RafikiColors.muted),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(p['name'] as String,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 16, color: RafikiColors.muted),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('${p['sub_county'] ?? ''}, ${p['county'] ?? ''}',
                            style: const TextStyle(fontSize: 13, color: RafikiColors.muted)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _openWhatsApp,
                  icon: const Icon(Icons.chat, color: Colors.white),
                  label: const Text('Chat on WhatsApp',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _payLoading ? null : _payViaMpesa,
                  icon: _payLoading
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.payment, color: Colors.white),
                  label: Text(_payLoading ? 'Sending STK...' : 'Pay via M-Pesa',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RafikiColors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: RafikiColors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: RafikiColors.amber.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: RafikiColors.amber),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'The service provider will contact you shortly. You can also reach them directly on WhatsApp.',
                        style: TextStyle(fontSize: 12, color: RafikiColors.ink.withOpacity(0.8)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              TextButton(
                onPressed: () {
                  Navigator.of(context).popUntil((r) => r.isFirst);
                },
                child: const Text('Back to Home',
                  style: TextStyle(color: RafikiColors.indigo, fontWeight: FontWeight.w700, fontSize: 14)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}