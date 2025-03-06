import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/dialog_service.dart';
import 'login_screen.dart';
import 'route_selection_screen.dart';

class HomeScreen extends StatefulWidget {
  final int userId;

  HomeScreen({required this.userId});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> userRoutes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserRoutes();
  }

  Future<void> fetchUserRoutes() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('http://localhost:5000/api/user/${widget.userId}/routes'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          userRoutes = List<Map<String, dynamic>>.from(data['routes']);
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

  void logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Navibu'),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RouteSelectionScreen(userId: widget.userId),
                ),
              ).then((_) => fetchUserRoutes()); // Refresh after coming back
            },
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: logout,
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Hatlarım',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: userRoutes.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Henüz hat seçmediniz',
                                  style: TextStyle(fontSize: 16),
                                ),
                                SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => RouteSelectionScreen(
                                          userId: widget.userId,
                                        ),
                                      ),
                                    ).then((_) => fetchUserRoutes());
                                  },
                                  child: Text('Hat Seç'),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: userRoutes.length,
                            padding: EdgeInsets.all(16),
                            itemBuilder: (context, index) {
                              final route = userRoutes[index];
                              return Card(
                                margin: EdgeInsets.only(bottom: 12),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
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
                                      Icon(Icons.directions_bus),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: fetchUserRoutes,
        child: Icon(Icons.refresh),
      ),
    );
  }
} 