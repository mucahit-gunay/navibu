import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../utils/animation_loader.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _userData;
  List<dynamic>? _routes;

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  Future<void> _loadHomeData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final authService = Provider.of<AuthService>(context, listen: false);
      final response = await authService.getHomeData();

      setState(() {
        _userData = response['user'];
        _routes = response['routes'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.logout();
      Navigator.of(context).pushReplacementNamed('/login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadHomeData,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: TAnimationLoader.loading());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TAnimationLoader.error(),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.red)),
            ElevatedButton(
              onPressed: _loadHomeData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_routes == null || _routes!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TAnimationLoader.error(),
            const Text('No routes available'),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _routes!.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final route = _routes![index];
        return Card(
          elevation: 4,
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            title: Text(route['route_long_name'] ?? ''),
            subtitle: Text(route['route_short_name'] ?? ''),
            trailing: IconButton(
              icon: Icon(
                route['favorite'] ? Icons.favorite : Icons.favorite_border,
                color: route['favorite'] ? Colors.red : null,
              ),
              onPressed: () {
                // TODO: Implement favorite toggle
              },
            ),
          ),
        );
      },
    );
  }
} 