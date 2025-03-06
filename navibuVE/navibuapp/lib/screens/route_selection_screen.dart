import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:navibuapp/utils/device_utility.dart';
import 'package:navibuapp/utils/helpers.dart';
import 'package:navibuapp/utils/animation_loader.dart';

class RouteSelectionScreen extends StatefulWidget {
  final int userId;

  const RouteSelectionScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<RouteSelectionScreen> createState() => _RouteSelectionScreenState();
}

class _RouteSelectionScreenState extends State<RouteSelectionScreen> {
  List<Map<String, dynamic>> allRoutes = [];
  List<Map<String, dynamic>> filteredRoutes = [];
  List<Map<String, dynamic>> selectedRoutes = [];
  bool isLoading = true;
  String searchQuery = '';
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchRoutes();
  }

  Future<void> fetchRoutes() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:5000/api/routes'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          allRoutes = List<Map<String, dynamic>>.from(data['routes']);
          filteredRoutes = allRoutes;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load routes');
      }
    } catch (e) {
      setState(() => isLoading = false);
      THelperFunctions.showAlert(
        context,
        'Hata',
        'Rotalar yüklenirken bir hata oluştu.',
      );
    }
  }

  void filterRoutes(String query) {
    setState(() {
      searchQuery = query;
      if (query.isEmpty) {
        filteredRoutes = allRoutes;
      } else {
        filteredRoutes = allRoutes.where((route) =>
          route['route_short_name']
              .toString()
              .toLowerCase()
              .contains(query.toLowerCase())
        ).toList();
      }
    });
  }

  Future<void> saveSelectedRoutes() async {
    if (selectedRoutes.isEmpty) {
      THelperFunctions.showAlert(
        context,
        'Uyarı',
        'Lütfen en az bir rota seçiniz.',
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      for (var route in selectedRoutes) {
        final response = await http.post(
          Uri.parse('http://localhost:5000/api/user_routes/add_favorite_route'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'user_id': widget.userId,
            'route_id': route['id'],
          }),
        );

        if (response.statusCode != 200) {
          throw Exception('Failed to save route');
        }
      }

      // Show success animation
      await showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TAnimationLoader.success(width: 100, height: 100),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Rotalarınız başarıyla kaydedildi!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.green),
                ),
              ),
            ],
          ),
        ),
      );

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      setState(() => isLoading = false);
      THelperFunctions.showAlert(
        context,
        'Hata',
        'Rotalar kaydedilirken bir hata oluştu.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rota Seçimi'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: searchController,
              onChanged: filterRoutes,
              decoration: InputDecoration(
                hintText: 'Rota ara...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),
          if (isLoading)
            Center(child: TAnimationLoader.loading(width: 100, height: 100))
          else
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredRoutes.length,
                      itemBuilder: (context, index) {
                        final route = filteredRoutes[index];
                        final isSelected = selectedRoutes.contains(route);

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text(route['route_short_name'].toString()),
                            ),
                            title: Text(route['route_short_name']),
                            subtitle: Text(
                              route['route_long_name'],
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Icon(
                              isSelected
                                  ? Icons.check_circle
                                  : Icons.check_circle_outline,
                              color: isSelected ? Colors.green : Colors.grey,
                            ),
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  selectedRoutes.remove(route);
                                } else {
                                  selectedRoutes.add(route);
                                }
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: saveSelectedRoutes,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Seçili Rotaları Kaydet (${selectedRoutes.length})',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
