import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'route_selection_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> userRoutes = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  Future<void> _loadHomeData() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final response = await authService.get('/auth/home');
      
      if (response['success']) {
        setState(() {
          userRoutes = List<Map<String, dynamic>>.from(response['routes']);
          isLoading = false;
        });
      } else {
        setState(() {
          error = response['message'];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Veriler yüklenirken bir hata oluştu';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
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
                  builder: (context) => RouteSelectionScreen(
                    userId: Provider.of<AuthService>(context, listen: false).currentUserId!,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!))
              : SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hatlarım',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: userRoutes.length,
                          itemBuilder: (context, index) {
                            final route = userRoutes[index];
                            return Card(
                              margin: EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Theme.of(context).primaryColor,
                                  child: Text(
                                    route['route_short_name'],
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                                title: Text(route['route_long_name']),
                                trailing: Icon(Icons.arrow_forward_ios),
                                onTap: () {
                                  // TODO: Navigate to route detail screen
                                },
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
} 