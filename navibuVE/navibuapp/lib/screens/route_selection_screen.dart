import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/dialog_service.dart';
import 'home_screen.dart';

class RouteSelectionScreen extends StatefulWidget {
  final int userId;

  RouteSelectionScreen({required this.userId});

  @override
  _RouteSelectionScreenState createState() => _RouteSelectionScreenState();
}

class _RouteSelectionScreenState extends State<RouteSelectionScreen> {
  List<Map<String, dynamic>> routes = [];
  List<Map<String, dynamic>> filteredRoutes = [];
  List<int> selectedRouteIds = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchRoutes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterRoutes(String query) {
    print('Search query: $query'); // Debug print

    setState(() {
      if (query.isEmpty) {
        filteredRoutes = List.from(routes);
        print('Empty query, showing all ${routes.length} routes'); // Debug print
      } else {
        filteredRoutes = routes.where((route) {
          final shortName = route['route_short_name']?.toString().toLowerCase() ?? '';
          final longName = route['route_long_name']?.toString().toLowerCase() ?? '';
          print('Checking route: $shortName - $longName'); // Debug print
          
          // Make the search more flexible
          return shortName.contains(query.toLowerCase()) || 
                 longName.contains(query.toLowerCase()) ||
                 shortName.replaceAll(' ', '').contains(query.toLowerCase().replaceAll(' ', ''));
        }).toList();
        print('Found ${filteredRoutes.length} matches'); // Debug print
      }
    });
  }

  Future<void> _fetchRoutes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final response = await authService.get('/api/routes');
      
      print('API Response: $response'); // Debug print
      
      if (response['success']) {
        final routesList = List<Map<String, dynamic>>.from(response['data']['routes']);
        print('Loaded ${routesList.length} routes'); // Debug print
        print('First route: ${routesList.isNotEmpty ? routesList.first : "No routes"}'); // Debug print
        
        setState(() {
          routes = routesList;
          filteredRoutes = List.from(routes);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response['message'] ?? 'Hatlar yüklenirken bir hata oluştu';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching routes: $e'); // Debug print
      setState(() {
        _error = 'Bağlantı hatası. Lütfen internet bağlantınızı kontrol edin.';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSelectedRoutes() async {
    if (selectedRouteIds.isEmpty) {
      DialogService.showError(
        context,
        message: 'Lütfen en az bir hat seçin.',
      );
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final response = await authService.post(
        '/api/user/${widget.userId}/routes',
        data: {'route_ids': selectedRouteIds},
      );

      if (response['success']) {
        await DialogService.showSuccess(
          context,
          message: 'Hatlar başarıyla kaydedildi!',
          onDismiss: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()),
            );
          },
        );
      } else {
        setState(() {
          _error = response['message'] ?? 'Hatlar kaydedilemedi. Lütfen tekrar deneyin.';
          _isSaving = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Bağlantı hatası. Lütfen internet bağlantınızı kontrol edin.';
        _isSaving = false;
      });
    }
  }

  void _toggleRouteSelection(int routeId) {
    setState(() {
      if (selectedRouteIds.contains(routeId)) {
        selectedRouteIds.remove(routeId);
      } else {
        selectedRouteIds.add(routeId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text('Hat Seçimi'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  if (_error != null)
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          'Lütfen kullanmak istediğiniz hatları seçin',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16),
                        TextField(
                          controller: _searchController,
                          onChanged: _filterRoutes,
                          decoration: InputDecoration(
                            hintText: 'Hat numarası veya ismi ile ara...',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: filteredRoutes.isEmpty
                        ? Center(
                            child: Text(
                              _searchController.text.isEmpty
                                  ? 'Hiç hat bulunamadı'
                                  : 'Arama sonucu bulunamadı',
                              style: TextStyle(fontSize: 16),
                            ),
                          )
                        : ListView.builder(
                            itemCount: filteredRoutes.length,
                            padding: EdgeInsets.all(16),
                            itemBuilder: (context, index) {
                              final route = filteredRoutes[index];
                              final routeId = route['route_id'];
                              final isSelected = selectedRouteIds.contains(routeId);

                              return Card(
                                margin: EdgeInsets.only(bottom: 12),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: isSelected 
                                        ? Theme.of(context).primaryColor 
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: InkWell(
                                  onTap: () => _toggleRouteSelection(routeId),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Center(
                                            child: Text(
                                              route['route_short_name'],
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 16),
                                        Expanded(
                                          child: Text(
                                            route['route_long_name'],
                                            style: TextStyle(fontSize: 16),
                                          ),
                                        ),
                                        Checkbox(
                                          value: isSelected,
                                          onChanged: (_) => _toggleRouteSelection(routeId),
                                          activeColor: Theme.of(context).primaryColor,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveSelectedRoutes,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isSaving
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                'Devam Et',
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
