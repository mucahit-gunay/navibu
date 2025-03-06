import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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
  List<int> selectedRouteIds = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchRoutes();
  }

  Future<void> fetchRoutes() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('http://localhost:5000/api/routes'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          routes = List<Map<String, dynamic>>.from(data['routes']);
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        DialogService.showError(
          context,
          message: 'Hatlar yüklenirken bir hata oluştu.',
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      DialogService.showError(
        context,
        message: 'Bağlantı hatası. Lütfen internet bağlantınızı kontrol edin.',
      );
    }
  }

  Future<void> saveSelectedRoutes() async {
    if (selectedRouteIds.isEmpty) {
      DialogService.showError(
        context,
        message: 'Lütfen en az bir hat seçin.',
      );
      return;
    }

    await DialogService.showLoading(context, message: 'Hatlar kaydediliyor...');

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/api/user/${widget.userId}/routes'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'route_ids': selectedRouteIds,
        }),
      );

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (response.statusCode == 200) {
        await DialogService.showSuccess(
          context,
          message: 'Hatlar başarıyla kaydedildi!',
          onDismiss: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HomeScreen(userId: widget.userId),
              ),
            );
          },
        );
      } else {
        DialogService.showError(
          context,
          message: 'Hatlar kaydedilemedi. Lütfen tekrar deneyin.',
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Remove loading dialog
        DialogService.showError(
          context,
          message: 'Bağlantı hatası. Lütfen internet bağlantınızı kontrol edin.',
        );
      }
    }
  }

  void toggleRouteSelection(int routeId) {
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
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Lütfen kullanmak istediğiniz hatları seçin',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: routes.isEmpty
                        ? Center(
                            child: Text(
                              'Hiç hat bulunamadı',
                              style: TextStyle(fontSize: 16),
                            ),
                          )
                        : ListView.builder(
                            itemCount: routes.length,
                            padding: EdgeInsets.all(16),
                            itemBuilder: (context, index) {
                              final route = routes[index];
                              final routeId = route['id'];
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
                                  onTap: () => toggleRouteSelection(routeId),
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
                                          onChanged: (_) => toggleRouteSelection(routeId),
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
                        onPressed: saveSelectedRoutes,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
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
