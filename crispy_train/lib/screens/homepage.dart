import 'package:crispy_train/api_services.dart';
import 'package:crispy_train/auth/loginpage.dart';
import 'package:crispy_train/main.dart';
import 'package:crispy_train/screens/addObject.dart';
import 'package:crispy_train/screens/singleobjectscreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final user = FirebaseAuth.instance.currentUser;

  ApiServices _apiservice = Get.find<ApiServices>();
  List<dynamic> objectList = [];
  bool _isLoading = true;
  signout() async {
    await FirebaseAuth.instance.signOut();
    Get.to(() => Phonehome());
  }

  @override
  void initState() {
    _loadData();
    super.initState();
  }

  void _loadData() async {
    try {
      final data = await _apiservice.fetchObjects();
      if (mounted) {
        setState(() {
          objectList.addAll(data);
        });
      }
    } catch (e) {
      if (mounted) {
        // Handle error - show snackbar, dialog, etc.
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load data: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Homepage"),

        backgroundColor: AppColors.primaryColor,
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryColor, AppColors.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.home, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Text(
                        'All Objects',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: objectList.length,
              itemBuilder: (context, index) {
                final item = objectList[index];
                final data = item["data"];

                // Helper functions
                String formatKey(String key) {
                  switch (key.toLowerCase()) {
                    case 'color':
                    case 'Color':
                      return 'Color';
                    case 'capacity':
                    case 'Capacity':
                    case 'capacity gb':
                    case 'capacity GB':
                      return 'Storage';
                    case 'price':
                    case 'Price':
                      return 'Price';
                    case 'generation':
                    case 'Generation':
                      return 'Generation';
                    case 'year':
                    case 'Year':
                      return 'Year';
                    case 'cpu model':
                    case 'CPU model':
                      return 'Processor';
                    case 'hard disk size':
                    case 'Hard disk size':
                      return 'Storage';
                    case 'strap colour':
                    case 'Strap Colour':
                      return 'Strap Color';
                    case 'case size':
                    case 'Case Size':
                      return 'Case Size';
                    case 'description':
                    case 'Description':
                      return 'Description';
                    case 'screen size':
                    case 'Screen size':
                      return 'Screen Size';
                    default:
                      return key;
                  }
                }

                String formatValue(dynamic value) {
                  if (value is num) {
                    if (value > 50 && value < 10000) {
                      return '\$${value.toString()}';
                    }
                    return value.toString();
                  }
                  return value.toString();
                }

                IconData getIconForSpec(String key) {
                  switch (key.toLowerCase()) {
                    case 'color':
                    case 'strap color':
                      return Icons.palette;
                    case 'storage':
                      return Icons.storage;
                    case 'price':
                      return Icons.attach_money;
                    case 'generation':
                      return Icons.update;
                    case 'year':
                      return Icons.calendar_today;
                    case 'processor':
                      return Icons.memory;
                    case 'case size':
                      return Icons.crop_din;
                    case 'description':
                      return Icons.description;
                    case 'screen size':
                      return Icons.tablet_mac;
                    default:
                      return Icons.info;
                  }
                }

                // Create a list of all available specifications
                List<MapEntry<String, String>> specs = [];

                if (data != null && data is Map<String, dynamic>) {
                  data.forEach((key, value) {
                    if (value != null) {
                      String displayKey = formatKey(key);
                      String displayValue = formatValue(value);
                      specs.add(MapEntry(displayKey, displayValue));
                    }
                  });
                }

                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Get.to(() => Singleobjectscreen(id: item["id"])),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.grey[850]!, Colors.grey[800]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey[700]!.withOpacity(0.5),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header with device icon and ID
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryLight.withOpacity(
                                        0.2,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.phone_android,
                                      color: AppColors.primaryLight,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "ID: ${item['id'] ?? 'No ID'}",
                                          style: TextStyle(
                                            color: Colors.grey[400],
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryLight
                                                .withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: AppColors.primaryLight
                                                  .withOpacity(0.3),
                                              width: 1,
                                            ),
                                          ),
                                          child: Text(
                                            "DEVICE",
                                            style: TextStyle(
                                              color: AppColors.primaryLight,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Device name
                              Text(
                                item['name'] ?? 'No Name',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Specifications section
                              if (specs.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[900]!.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey[700]!.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.info_outline,
                                            color: Colors.grey[400],
                                            size: 16,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            "Specifications",
                                            style: TextStyle(
                                              color: Colors.grey[300],
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),

                                      // Dynamic specifications
                                      ...specs.asMap().entries.map((entry) {
                                        final spec = entry.value;
                                        final isLast =
                                            entry.key == specs.length - 1;

                                        return Padding(
                                          padding: EdgeInsets.only(
                                            bottom: isLast ? 0 : 8,
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                width: 4,
                                                height: 16,
                                                decoration: BoxDecoration(
                                                  color: AppColors.primaryLight,
                                                  borderRadius:
                                                      BorderRadius.circular(2),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Icon(
                                                getIconForSpec(spec.key),
                                                color: Colors.grey[500],
                                                size: 16,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                flex: 2,
                                                child: Text(
                                                  "${spec.key}:",
                                                  style: TextStyle(
                                                    color: Colors.grey[400],
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                flex: 3,
                                                child: Text(
                                                  spec.value,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ],
                                  ),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[900]!.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey[700]!.withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color: Colors.grey[600],
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "No specs available",
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 14,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),

      // Replace your existing floatingActionButton in Homepage with this:
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Add Object FAB
          FloatingActionButton(
            heroTag: "add_object",
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddObjectScreen(),
                ),
              );
              // Refresh the list if object was created successfully
              if (result == true) {
                setState(() {
                  objectList.clear();
                });
                _loadData();
              }
            },
            backgroundColor: AppColors.primaryLight,
            child: Icon(Icons.add, color: Colors.white),
          ),

          const SizedBox(height: 16),

          // Sign Out FAB
          FloatingActionButton(
            heroTag: "sign_out",
            onPressed: () => showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: Colors.grey[850],
                title: Text("Sign Out", style: TextStyle(color: Colors.white)),
                content: Text(
                  "Are you sure you want to sign out?",
                  style: TextStyle(color: Colors.grey[300]),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      "Cancel",
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      signout();
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: Text("Sign Out"),
                  ),
                ],
              ),
            ),
            backgroundColor: Colors.red,
            child: Icon(Icons.logout, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
