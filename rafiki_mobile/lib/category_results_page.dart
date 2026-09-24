// rafiki_mobile/lib/category_results_page.dart
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

class CategoryResultsPage extends StatefulWidget {
  final String categorySlug;
  final String categoryName;
  const CategoryResultsPage({
    super.key,
    required this.categorySlug,
    required this.categoryName,
  });

  @override
  State<CategoryResultsPage> createState() => _CategoryResultsPageState();
}

class _CategoryResultsPageState extends State<CategoryResultsPage> {
  late Future<Map<String, dynamic>> _future;
  bool _verifiedOnly = false;
  String _sort = 'rating_desc';

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _future = ApiService.getServices(
        category: widget.categorySlug,
        county: 'Nairobi',
        verifiedOnly: _verifiedOnly,
        sort: _sort,
        limit: 50,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RafikiColors.bg,
      appBar: AppBar(
        title: Text(widget.categoryName),
        backgroundColor: RafikiColors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Verified only'),
                  selected: _verifiedOnly,
                  onSelected: (v) {
                    setState(() => _verifiedOnly = v);
                    _load();
                  },
                  selectedColor: RafikiColors.indigo.withOpacity(0.15),
                  checkmarkColor: RafikiColors.indigo,
                  labelStyle: TextStyle(
                    color: _verifiedOnly ? RafikiColors.indigo : RafikiColors.muted,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: RafikiColors.border),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _sort,
                    isDense: true,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: RafikiColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: RafikiColors.border),
                      ),
                    ),
                    style: const TextStyle(fontSize: 13, color: RafikiColors.ink, fontWeight: FontWeight.w600),
                    items: const [
                      DropdownMenuItem(value: 'rating_desc', child: Text('Top rated')),
                      DropdownMenuItem(value: 'price_asc',  child: Text('Price: low to high')),
                      DropdownMenuItem(value: 'price_desc', child: Text('Price: high to low')),
                      DropdownMenuItem(value: 'newest',     child: Text('Newest')),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _sort = v);
                      _load();
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: RafikiColors.indigo),
                  );
                }
                if (snapshot.hasError) {
                  return _ErrorState(error: '${snapshot.error}', onRetry: _load);
                }
                final data = snapshot.data ?? {'count': 0, 'results': []};
                final results = (data['results'] as List?) ?? [];

                if (results.isEmpty) return const _EmptyState();

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                  itemCount: results.length,
                  itemBuilder: (context, i) {
                    return _ProviderCard(item: results[i] as Map<String, dynamic>);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

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

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.search_off, size: 56, color: RafikiColors.muted),
            SizedBox(height: 12),
            Text('No providers found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: RafikiColors.ink)),
            SizedBox(height: 6),
            Text('Try removing the "Verified only" filter',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: RafikiColors.muted)),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
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
              onPressed: onRetry,
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