// rafiki_mobile/lib/main.dart
import 'package:flutter/material.dart';
import 'api_service.dart';
import 'category_results_page.dart';
import 'auth_page.dart';
import 'auth_state.dart';
import 'my_bookings_page.dart';
import 'search_page.dart';

void main() {
  runApp(const RafikiApp());
}

// ---------- Global tab switcher (used by home search bar) ----------
final ValueNotifier<int> tabIndex = ValueNotifier<int>(0);

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

IconData iconForCategory(String name) {
  final n = name.toLowerCase();
  if (n.contains('salon')) return Icons.content_cut;
  if (n.contains('barber')) return Icons.face_retouching_natural;
  if (n.contains('manicure') || n.contains('pedicure')) return Icons.back_hand;
  if (n.contains('spa') || n.contains('massage')) return Icons.spa;
  if (n.contains('car wash')) return Icons.local_car_wash;
  if (n.contains('car servic')) return Icons.car_repair;
  if (n.contains('towing')) return Icons.local_shipping;
  if (n.contains('battery')) return Icons.battery_charging_full;
  if (n.contains('car hire')) return Icons.directions_car;
  if (n.contains('pickup')) return Icons.local_shipping;
  if (n.contains('tractor')) return Icons.agriculture;
  if (n.contains('mechanic')) return Icons.build;
  if (n.contains('plumber')) return Icons.plumbing;
  if (n.contains('electrician')) return Icons.electrical_services;
  if (n.contains('carpentry')) return Icons.handyman;
  if (n.contains('painting')) return Icons.format_paint;
  if (n.contains('interior')) return Icons.chair;
  if (n.contains('masonry')) return Icons.foundation;
  if (n.contains('roofing')) return Icons.roofing;
  if (n.contains('pest') || n.contains('fumigation')) return Icons.pest_control;
  if (n.contains('locksmith')) return Icons.lock;
  if (n.contains('cleaning')) return Icons.cleaning_services;
  if (n.contains('laundry')) return Icons.local_laundry_service;
  if (n.contains('waste')) return Icons.delete_outline;
  if (n.contains('solar')) return Icons.solar_power;
  if (n.contains('borehole')) return Icons.water_drop;
  if (n.contains('gas')) return Icons.propane_tank;
  if (n.contains('water')) return Icons.water;
  if (n.contains('security')) return Icons.shield;
  if (n.contains('pet')) return Icons.pets;
  if (n.contains('wedding')) return Icons.favorite;
  if (n.contains('catering')) return Icons.restaurant;
  if (n.contains('cake')) return Icons.cake;
  if (n.contains('photograph')) return Icons.camera_alt;
  if (n.contains('tent')) return Icons.holiday_village;
  if (n.contains('dj') || n.contains('mc')) return Icons.music_note;
  if (n.contains('chef')) return Icons.restaurant_menu;
  if (n.contains('tuition')) return Icons.school;
  if (n.contains('music')) return Icons.piano;
  if (n.contains('coding')) return Icons.code;
  if (n.contains('swimming')) return Icons.pool;
  if (n.contains('chess')) return Icons.grid_4x4;
  if (n.contains('it support')) return Icons.computer;
  if (n.contains('tailoring')) return Icons.checkroom;
  if (n.contains('fitness')) return Icons.fitness_center;
  return Icons.work_outline;
}

class RafikiApp extends StatelessWidget {
  const RafikiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rafiki',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: RafikiColors.bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: RafikiColors.indigo,
          primary: RafikiColors.indigo,
          secondary: RafikiColors.coral,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: RafikiColors.indigo,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const PhoneFrame(child: HomeShell()),
    );
  }
}

class PhoneFrame extends StatelessWidget {
  final Widget child;
  const PhoneFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 700) return child;
    return Container(
      color: const Color(0xFF1F2937),
      child: Center(
        child: Container(
          width: 400,
          height: 850,
          margin: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(42),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: child,
        ),
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final _pages = const [
    HomePage(),
    SearchPage(),
    MyBookingsPage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    tabIndex.addListener(_onTabChange);
  }

  @override
  void dispose() {
    tabIndex.removeListener(_onTabChange);
    super.dispose();
  }

  void _onTabChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[tabIndex.value],
      bottomNavigationBar: NavigationBar(
        selectedIndex: tabIndex.value,
        onDestinationSelected: (i) => tabIndex.value = i,
        backgroundColor: Colors.white,
        indicatorColor: RafikiColors.indigo.withOpacity(0.15),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.search_outlined), selectedIcon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(icon: Icon(Icons.calendar_today_outlined), selectedIcon: Icon(Icons.calendar_today), label: 'Bookings'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Map<String, dynamic>>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = ApiService.getCategories();
  }

  void _reload() {
    setState(() {
      _categoriesFuture = ApiService.getCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RafikiColors.bg,
      body: RefreshIndicator(
        onRefresh: () async => _reload(),
        color: RafikiColors.indigo,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                height: 220,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [RafikiColors.indigo, RafikiColors.coral],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Rafiki',
                          style: TextStyle(color: Colors.white, fontSize: 32,
                            fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                        SizedBox(height: 4),
                        Text('Local Services · Kenya',
                          style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                        Spacer(),
                        Text('Karibu Rafiki!',
                          style: TextStyle(color: Colors.white70, fontSize: 14)),
                        SizedBox(height: 4),
                        Text('Find trusted service providers near you',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ---- Home search bar → switches to Search tab ----
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: GestureDetector(
                  onTap: () => tabIndex.value = 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: RafikiColors.border),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.search, color: RafikiColors.muted),
                        SizedBox(width: 12),
                        Text('Search for a service...',
                          style: TextStyle(fontSize: 15, color: RafikiColors.muted)),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Text('Popular Categories',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: RafikiColors.ink)),
              ),
            ),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _categoriesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(child: CircularProgressIndicator(color: RafikiColors.indigo)),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          const Icon(Icons.cloud_off, size: 48, color: RafikiColors.muted),
                          const SizedBox(height: 12),
                          const Text('Could not reach Rafiki backend',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: RafikiColors.ink)),
                          const SizedBox(height: 6),
                          Text('${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12, color: RafikiColors.muted)),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _reload,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: RafikiColors.indigo,
                              foregroundColor: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final cats = snapshot.data ?? [];
                if (cats.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: Text('No categories found')),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 160,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.95,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final c = cats[i];
                        return _CategoryCard(
                          name: c['name'] as String,
                          icon: iconForCategory(c['name'] as String),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CategoryResultsPage(
                                  categorySlug: c['slug'] as String,
                                  categoryName: c['name'] as String,
                                ),
                              ),
                            );
                          },
                        );
                      },
                      childCount: cats.length,
                    ),
                  ),
                );
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String name;
  final IconData icon;
  final VoidCallback? onTap;
  const _CategoryCard({required this.name, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: RafikiColors.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: RafikiColors.indigo.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: RafikiColors.indigo, size: 28),
                ),
                const SizedBox(height: 10),
                Flexible(
                  child: Text(name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: RafikiColors.ink)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RafikiColors.bg,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: RafikiColors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: AnimatedBuilder(
        animation: AuthState.instance,
        builder: (context, _) {
          final auth = AuthState.instance;

          if (!auth.isLoggedIn) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.person_outline, size: 72, color: RafikiColors.muted),
                    const SizedBox(height: 16),
                    const Text('You are not signed in',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: RafikiColors.ink)),
                    const SizedBox(height: 8),
                    const Text('Sign in to make bookings',
                      style: TextStyle(fontSize: 13, color: RafikiColors.muted)),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: 220, height: 48,
                      child: ElevatedButton(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AuthPage()),
                          );
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

          final u = auth.user!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: RafikiColors.border),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: RafikiColors.indigo.withOpacity(0.12),
                      child: Text(
                        _initials(u['full_name'] as String),
                        style: const TextStyle(color: RafikiColors.indigo,
                          fontWeight: FontWeight.w800, fontSize: 20),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(u['full_name'] as String,
                            style: const TextStyle(fontSize: 17,
                              fontWeight: FontWeight.w700, color: RafikiColors.ink)),
                          const SizedBox(height: 3),
                          Text(u['phone'] as String,
                            style: const TextStyle(fontSize: 13, color: RafikiColors.muted)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: RafikiColors.indigo.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              (u['role'] as String).toUpperCase(),
                              style: const TextStyle(fontSize: 10,
                                fontWeight: FontWeight.w800, color: RafikiColors.indigo),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _menuItem(context, Icons.location_on_outlined, 'My Area', u['county'] ?? 'Nairobi'),
              _menuItem(context, Icons.history, 'My Bookings', 'See all bookings'),
              _menuItem(context, Icons.payment, 'Payment Methods', 'M-Pesa'),
              _menuItem(context, Icons.help_outline, 'Help & Support', ''),
              const SizedBox(height: 20),
              SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () {
                    auth.logout();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Signed out')),
                    );
                  },
                  icon: const Icon(Icons.logout, color: RafikiColors.coral),
                  label: const Text('Sign Out',
                    style: TextStyle(color: RafikiColors.coral, fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: RafikiColors.coral),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  Widget _menuItem(BuildContext context, IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RafikiColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: RafikiColors.indigo),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                  style: const TextStyle(fontSize: 14,
                    fontWeight: FontWeight.w600, color: RafikiColors.ink)),
                if (subtitle.isNotEmpty)
                  Text(subtitle,
                    style: const TextStyle(fontSize: 12, color: RafikiColors.muted)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: RafikiColors.muted, size: 20),
        ],
      ),
    );
  }
}