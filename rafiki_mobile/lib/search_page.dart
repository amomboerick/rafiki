// rafiki_mobile/lib/search_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'api_service.dart';
import 'booking_page.dart';

class RafikiColors {
  static const indigo = Color(0xFF4F46E5);
  static const coral  = Color(0xFFFF6B6B);
  static const ink    = Color(0xFF1F2937);
  static const muted  = Color(0xFF6B7280);
  static const bg     = Color(0xFFF9FAFB);
  static const border = Color(0xFFE5E7EB);
  static const green  = Color(0xFF10B981);
  static const amber  = Color(0xFFF59E0B);
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _queryCtrl = TextEditingController();
  Timer? _debounce;
  Future<Map<String, dynamic>>? _future;
  String _lastQuery = '';

  @override
  void dispose() {
    _queryCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final q = text.trim();
      if (q == _lastQuery) return;
      _lastQuery = q;
      if (q.isEmpty) {
        setState(() => _future = null);
      } else {
        setState(() {
          _future = ApiService.getServices(
            query: q,
            county: 'Nairobi',
            sort: 'rating_desc',
            limit: 40,
          );
        });
      }
    });
  }

  void _clear() {
    _queryCtrl.clear();
    setState(() {
      _future = null;
      _lastQuery = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RafikiColors.bg,
      appBar: AppBar(
        title: const Text('Search'),
        backgroundColor: RafikiColors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // ---- Search Bar ----
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: TextField(
              controller: _queryCtrl,
              autofocus: true,
              onChanged: _onChanged,
              decoration: InputDecoration(
                hintText: 'Search services: plumber, haircut, cake...',
                prefixIcon: const Icon(Icons.search, color: RafikiColors.muted),
                suffixIcon: _queryCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, color: RafikiColors.muted, size: 20),
                      onPressed: _clear,
                    )
                  : null,
                filled: true,
                fillColor: RafikiColors.bg,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
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
          ),

          // ---- Results Area ----
          Expanded(
            child: _future == null
              ? _emptyState()
              : FutureBuilder<Map<String, dynamic>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: RafikiColors.indigo),
                      );
                    }
                    if (snapshot.hasError) {
                      return _errorState('${snapshot.error}');
                    }
                    final data = snapshot.data ?? {'count': 0, 'results': []};
                    final results = (data['results'] as List?) ?? [];

                    if (results.isEmpty) {
                      return _noResultsState(_lastQuery);
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                          child: Text(
                            '${results.length} result${results.length == 1 ? '' : 's'}',
                            style: const TextStyle(fontSize: 12,
                              fontWeight: FontWeight.w600, color: RafikiColors.muted),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                            itemCount: results.length,
                            itemBuilder: (context, i) =>
                              _ProviderCard(item: results[i] as Map<String, dynamic>),
                          ),
                        ),
                      ],
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: RafikiColors.indigo.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search, size: 56, color: RafikiColors.indigo),
            ),
            const SizedBox(height: 20),
            const Text('Search Rafiki',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: RafikiColors.ink)),
            const SizedBox(height: 8),
            const Text('Find any of our 184 services across Kenya',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: RafikiColors.muted)),
            const SizedBox(height: 20),
            // Sample keyword chips
            Wrap(
              spacing: 8, runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                'plumber', 'haircut', 'cake', 'towing',
                'cleaning', 'tutor', 'photographer', 'solar'
              ].map((w) => ActionChip(
                label: Text(w, style: const TextStyle(fontSize: 12)),
                backgroundColor: Colors.white,
                side: const BorderSide(color: RafikiColors.border),
                onPressed: () {
                  _queryCtrl.text = w;
                  _onChanged(w);
                },
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _noResultsState(String query) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: RafikiColors.muted),
            const SizedBox(height: 16),
            Text('No results for "$query"',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15,
                fontWeight: FontWeight.w600, color: RafikiColors.ink)),
            const SizedBox(height: 8),
            const Text('Try different keywords or check your spelling',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: RafikiColors.muted)),
          ],
        ),
      ),
    );
  }

  Widget _errorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: RafikiColors.muted),
            const SizedBox(height: 12),
            const Text('Could not reach Rafiki backend',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: RafikiColors.ink)),
            const SizedBox(height: 6),
            Text(error,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: RafikiColors.muted)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _onChanged(_queryCtrl.text),
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
    );
  }
}

// ---------- Provider Card (same as categories page) ----------
class _ProviderCard extends StatelessWidget {
  final Map<String, dynamic> item;
  const _ProviderCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final p = item['provider'] as Map<String, dynamic>;
    final rating = (p['rating'] as num?)?.toDouble() ?? 0;
    final verified = p['verified'] == true;
    final price = (item['price'] as num?)?.toDouble() ?? 0;
    final reviews = p['reviews'] ?? 0;

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
        padding: const EdgeInsets.all(14),
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
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              p['name'] as String,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: RafikiColors.ink,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (verified)
                            Container(
                              margin: const EdgeInsets.only(left: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: RafikiColors.green.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.verified, size: 12, color: RafikiColors.green),
                                  SizedBox(width: 3),
                                  Text(
                                    'Verified',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: RafikiColors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 12, color: RafikiColors.muted),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              '${p['sub_county'] ?? ''}, ${p['county'] ?? ''}',
                              style: const TextStyle(fontSize: 12, color: RafikiColors.muted),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              item['title'] as String,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: RafikiColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _Stars(rating: rating),
                const SizedBox(width: 6),
                Text(
                  rating.toStringAsFixed(2),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: RafikiColors.ink),
                ),
                const SizedBox(width: 4),
                Text(
                  '($reviews reviews)',
                  style: const TextStyle(fontSize: 11, color: RafikiColors.muted),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(color: RafikiColors.ink),
                      children: [
                        TextSpan(
                          text: 'KSh ${price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: RafikiColors.indigo,
                          ),
                        ),
                        TextSpan(
                          text: '  ${item['price_unit'] ?? ''}',
                          style: const TextStyle(fontSize: 11, color: RafikiColors.muted),
                        ),
                      ],
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BookingPage(item: item),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RafikiColors.indigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: const Text('Book', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
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

class _Stars extends StatelessWidget {
  final double rating;
  const _Stars({required this.rating});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final full = i < rating.floor();
        final half = !full && i < rating;
        return Icon(
          full ? Icons.star : (half ? Icons.star_half : Icons.star_border),
          size: 14,
          color: RafikiColors.amber,
        );
      }),
    );
  }
}