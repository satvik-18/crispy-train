
# Download & Live Demo

Installable Android APK: https://drive.google.com/file/d/16rIGPZ88ZO7cNNIqAiz-DkIB3fK__n6x/view?usp=sharing

Hosting URL: https://frontend-f5abf.web.app

<img width="902" height="725" alt="image" src="https://github.com/user-attachments/assets/cf390ba5-7a55-42ea-a30e-048ee84ca817" />


Live Web Version: Visit App
## Table of Contents
1. [Project Overview](#project-overview)
2. [Architecture](#architecture)
3. [Dependencies](#dependencies)
4. [Authentication System](#authentication-system)
5. [API Services](#api-services)
6. [UI Screens](#ui-screens)
7. [State Management](#state-management)
8. [Theming](#theming)
9. [Setup & Installation](#setup--installation)
10. [API Reference](#api-reference)
11. [Best Practices](#best-practices)
12. [Troubleshooting](#troubleshooting)

## Project Overview

This is a Flutter-based CRUD (Create, Read, Update, Delete) application that demonstrates full-stack mobile development with:

- **Firebase Authentication** (Phone OTP verification)
- **RESTful API Integration** (using restful-api.dev)
- **Modern Material 3 UI** with dark/light theme support
- **State Management** using GetX
- **Advanced PATCH operations** with PUT fallback
- **Comprehensive error handling**

### Key Features
- Phone number authentication with OTP
- View all objects in a responsive list
- Add new objects with custom fields
- Edit objects with intelligent PATCH requests
- Delete objects with confirmation
- Dark/Light theme toggle
- Pull-to-refresh functionality
- Loading states and error handling

## Architecture

```
lib/
├── auth/
│   ├── loginpage.dart          # Phone authentication UI
│   └── otppage.dart           # OTP verification UI
├── screens/
│   ├── wrapper.dart           # Authentication wrapper
│   ├── homepage.dart          # Main objects list screen
│   ├── addObject.dart         # Create new object screen
│   ├── editObject.dart        # Edit existing object screen
│   └── singleobjectscreen.dart # Object details screen
├── api_services.dart          # RESTful API service layer
├── firebase_options.dart      # Firebase configuration
└── main.dart                  # App entry point & theme controller
```

### Design Pattern
- **MVC Pattern**: Separation of UI, business logic, and data
- **Repository Pattern**: ApiServices acts as data repository
- **Singleton Pattern**: GetX dependency injection for services
- **Observer Pattern**: State management with GetX reactive programming

## Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  get: ^4.6.5
  
  # HTTP & API
  http: ^0.13.5
  
  # Firebase
  firebase_core: ^2.15.0
  firebase_auth: ^4.7.2
  
  # UI Components
  pinput: ^3.0.1          # OTP input field
  
  # Utils
  cupertino_icons: ^1.0.2
```

## Authentication System

### Firebase Phone Authentication Flow

#### 1. Phone Input (`loginpage.dart`)
```dart
// Key validation logic
String? validatePhoneNumber(String? value) {
  if (value == null || value.isEmpty) return 'Please enter a phone number';
  if (value.length != 10) return 'Phone number must be 10 digits';
  if (!RegExp(r'^[0-9]+$').hasMatch(value)) return 'Phone number must contain only digits';
  return null;
}

// Firebase phone verification
await FirebaseAuth.instance.verifyPhoneNumber(
  phoneNumber: '+91${phoneController.text.trim()}',
  verificationCompleted: (credential) => autoSignIn(credential),
  verificationFailed: (error) => handleError(error),
  codeSent: (verificationId, resendToken) => navigateToOTP(verificationId),
  timeout: const Duration(seconds: 60),
);
```

#### 2. OTP Verification (`otppage.dart`)
```dart
// OTP verification and sign-in
PhoneAuthCredential credential = PhoneAuthProvider.credential(
  verificationId: widget.vid,
  smsCode: code,
);
await FirebaseAuth.instance.signInWithCredential(credential);
```

#### 3. Authentication State Management (`wrapper.dart`)
```dart
StreamBuilder(
  stream: FirebaseAuth.instance.authStateChanges(),
  builder: (context, snapshot) {
    return snapshot.hasData ? Homepage() : Phonehome();
  },
)
```

### Security Features
- Phone number format validation
- OTP timeout handling
- Auto-verification for eligible devices
- Comprehensive error handling
- Secure credential management

## API Services

### RESTful API Integration (`api_services.dart`)

The app integrates with [restful-api.dev](https://restful-api.dev) for CRUD operations.

#### Base Configuration
```dart
class ApiServices {
  final baseurl = "https://api.restful-api.dev/objects";
  
  // HTTP headers for all requests
  final headers = {'Content-Type': 'application/json'};
}
```

#### CRUD Operations

##### 1. **CREATE** - Add New Object
```dart
Future<Map<String, dynamic>> createObject({
  required String name,
  required Map<String, dynamic> data,
}) async {
  final body = {"name": name, "data": data};
  
  final response = await http.post(
    Uri.parse(baseurl),
    headers: headers,
    body: json.encode(body),
  );
  
  if (response.statusCode == 200 || response.statusCode == 201) {
    return json.decode(response.body);
  } else {
    throw Exception("Failed to create object. Status code: ${response.statusCode}");
  }
}
```

##### 2. **READ** - Fetch Objects
```dart
// Get all objects
Future<List<dynamic>> fetchObjects() async {
  final response = await http.get(Uri.parse(baseurl));
  
  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    throw Exception("Failed to load objects. Status code: ${response.statusCode}");
  }
}

// Get single object
Future<Map<String, dynamic>> getSingleObject(String id) async {
  final response = await http.get(Uri.parse("$baseurl/$id"));
  
  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    throw Exception("Error getting single Object: ${response.statusCode}");
  }
}
```

##### 3. **UPDATE** - Advanced PATCH with PUT Fallback
```dart
Future<Map<String, dynamic>> patchObject({
  required String id,
  String? name,
  Map<String, dynamic>? data,
}) async {
  // Build request body with only changed fields
  final Map<String, dynamic> body = {};
  if (name != null) body["name"] = name;
  if (data != null && data.isNotEmpty) body["data"] = data;
  
  if (body.isEmpty) {
    throw Exception("No fields provided for update");
  }

  try {
    // Try PATCH first
    var response = await http.patch(
      Uri.parse("$baseurl/$id"),
      headers: headers,
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }

    // Fallback to PUT if PATCH not supported (405)
    if (response.statusCode == 405) {
      final currentObject = await getSingleObject(id);
      
      // Merge changes with current data
      Map<String, dynamic> fullData = Map<String, dynamic>.from(
        currentObject['data'] ?? {},
      );
      if (data != null) fullData.addAll(data);
      
      final fullName = name ?? currentObject['name'] ?? '';
      
      // Use PUT with complete object
      final putResponse = await http.put(
        Uri.parse("$baseurl/$id"),
        headers: headers,
        body: json.encode({"name": fullName, "data": fullData}),
      );

      if (putResponse.statusCode == 200) {
        return json.decode(putResponse.body);
      }
    }
    
    throw Exception("Update failed. Status code: ${response.statusCode}");
  } catch (e) {
    throw Exception("Error updating object: $e");
  }
}
```

##### 4. **DELETE** - Remove Object
```dart
Future<bool> deleteObject(String id) async {
  final response = await http.delete(Uri.parse("$baseurl/$id"));
  
  if (response.statusCode == 200) {
    return true;
  } else {
    throw Exception("Failed to delete object. Status code: ${response.statusCode}");
  }
}
```

#### Convenience Methods
```dart
// Update only name
Future<Map<String, dynamic>> updateObjectName({
  required String id,
  required String name,
}) => patchObject(id: id, name: name);

// Update only data
Future<Map<String, dynamic>> updateObjectData({
  required String id,
  required Map<String, dynamic> data,
}) => patchObject(id: id, data: data);

// Update specific field
Future<Map<String, dynamic>> updateObjectField({
  required String id,
  required String fieldKey,
  required dynamic fieldValue,
}) => patchObject(id: id, data: {fieldKey: fieldValue});
```

## UI Screens

### 1. Homepage (`homepage.dart`)

**Purpose**: Main screen displaying all objects in a responsive list

#### Key Features:
- **Pull-to-refresh** functionality
- **Dynamic card layout** with gradient backgrounds
- **Smart field formatting** (e.g., "CPU model" → "Processor")
- **Icon mapping** for different specifications
- **Floating action buttons** for Add/SignOut

#### Dynamic Field Formatting:
```dart
String formatKey(String key) {
  switch (key.toLowerCase()) {
    case 'cpu model': return 'Processor';
    case 'hard disk size': return 'Storage';
    case 'strap colour': return 'Strap Color';
    // ... more mappings
    default: return key;
  }
}

IconData getIconForSpec(String key) {
  switch (key.toLowerCase()) {
    case 'color': return Icons.palette;
    case 'storage': return Icons.storage;
    case 'price': return Icons.attach_money;
    // ... more icon mappings
    default: return Icons.info;
  }
}
```

### 2. Add Object Screen (`addObject.dart`)

**Purpose**: Create new objects with dynamic field support

#### Key Features:
- **Required vs Optional sections**
- **Dynamic custom fields** (add/remove capability)
- **Input validation** with visual feedback
- **Type-aware data conversion** (string to number when appropriate)
- **Gradient UI design** with Material 3

#### Dynamic Field Management:
```dart
List<MapEntry<TextEditingController, TextEditingController>> _customFields = [];

void _addCustomField() {
  setState(() {
    _customFields.add(MapEntry(TextEditingController(), TextEditingController()));
  });
}

void _removeCustomField(int index) {
  setState(() {
    _customFields[index].key.dispose();
    _customFields[index].value.dispose();
    _customFields.removeAt(index);
  });
}
```

### 3. Edit Object Screen (`editObject.dart`)

**Purpose**: Edit existing objects with intelligent change detection

#### Key Features:
- **PATCH indicator** showing efficient update method
- **Change detection** - only modified fields are sent
- **Original value preservation** for comparison
- **Merge conflict resolution** for custom fields
- **Loading states** during fetch and save operations

#### Change Detection Logic:
```dart
Map<String, dynamic> _getChangedFields() {
  Map<String, dynamic> changedData = {};
  
  // Compare each field with original
  currentData.forEach((key, value) {
    final originalValue = _originalData[key];
    bool hasChanged = false;
    
    if (originalValue == null && value != null) {
      hasChanged = true; // New field added
    } else if (originalValue != null && value == null) {
      hasChanged = true; // Field removed
    } else if (originalValue != null && value != null) {
      hasChanged = originalValue.toString() != value.toString();
    }
    
    if (hasChanged && value != null) {
      changedData[key] = value;
    }
  });
  
  return changedData;
}
```

### 4. Single Object Screen (`singleobjectscreen.dart`)

**Purpose**: Display detailed object information with edit/delete capabilities

#### Key Features:
- **Hero header design** with gradient background
- **Specifications grid** with consistent formatting
- **Icon-based field representation**
- **Confirmation dialogs** for destructive actions
- **Responsive layout** adapting to different screen sizes

#### Specifications Display:
```dart
// Dynamic specifications grid
...((objectInfo["data"] as Map<String, dynamic>).entries.map((entry) {
  final formattedKey = formatKey(entry.key);
  final formattedValue = formatValue(entry.value);
  
  return SpecificationCard(
    icon: getIconForSpec(formattedKey),
    label: formattedKey,
    value: formattedValue,
  );
}).toList())
```

## State Management

### GetX Integration

#### Dependency Injection
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Register services
  Get.put(ApiServices());
  Get.put(ThemeController());
  
  runApp(const MyApp());
}
```

#### Theme Controller
```dart
class ThemeController extends GetxController {
  var isDark = true.obs;

  void toggleTheme() {
    isDark.value = !isDark.value;
  }
}
```

#### Reactive UI Updates
```dart
// Reactive theme switching
return Obx(() => GetMaterialApp(
  theme: ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primaryColor,
      brightness: themeController.isDark.value 
        ? Brightness.dark 
        : Brightness.light,
    ),
  ),
  home: Wrapper(),
));
```

## Theming

### Color System
```dart
class AppColors {
  static const Color primaryColor = Colors.deepPurple;
  static const Color secondaryColor = Colors.grey;
  static const Color backgroundColor = Colors.white;
  static const Color primaryLight = Color.fromARGB(255, 167, 135, 255);
}
```

### Material 3 Integration
- **Dynamic color schemes** based on seed color
- **Elevation and shadows** for depth perception
- **Rounded corners** and modern design language
- **Adaptive components** for different platforms

### Dark/Light Theme Support
- **Automatic system theme** detection
- **Manual theme toggle** with persistent state
- **Consistent color application** across all screens
- **Accessibility compliance** with proper contrast ratios

## Setup & Installation

### Prerequisites
- Flutter SDK (>=3.0.0)
- Dart SDK (>=2.17.0)
- Android Studio / VS Code
- Firebase project setup

### Installation Steps

1. **Clone the repository**
```bash
git clone <repository-url>
cd crispy_train
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Firebase Setup**
```bash
# Install FlutterFire CLI
npm install -g firebase-tools
dart pub global activate flutterfire_cli

# Configure Firebase
flutterfire configure
```

4. **Update Firebase Options**
Replace the contents of `lib/firebase_options.dart` with your project configuration.

5. **Run the app**
```bash
flutter run
```

### Environment Configuration

#### Android Configuration
```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.RECEIVE_SMS" />
<uses-permission android:name="android.permission.READ_SMS" />
```

#### iOS Configuration
```xml
<!-- ios/Runner/Info.plist -->
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

## API Reference

### RESTful API Endpoints

Base URL: `https://api.restful-api.dev/objects`

| Method | Endpoint | Description | Request Body |
|--------|----------|-------------|--------------|
| GET | `/` | Get all objects | None |
| GET | `/{id}` | Get single object | None |
| POST | `/` | Create object | `{"name": string, "data": object}` |
| PUT | `/{id}` | Update object (full) | `{"name": string, "data": object}` |
| PATCH | `/{id}` | Update object (partial) | `{"name"?: string, "data"?: object}` |
| DELETE | `/{id}` | Delete object | None |

### Response Format

#### Success Response
```json
{
  "id": "string",
  "name": "string",
  "data": {
    "key1": "value1",
    "key2": "value2"
  },
  "createdAt": "2023-01-01T00:00:00.000Z"
}
```

#### Error Response
```json
{
  "error": {
    "message": "Error description",
    "code": "ERROR_CODE"
  }
}
```

## Best Practices

### Code Organization
- **Separation of Concerns**: UI, business logic, and data layers
- **Consistent naming**: camelCase for variables, PascalCase for classes
- **Error handling**: Try-catch blocks with meaningful error messages
- **Resource management**: Proper disposal of controllers and listeners

### Performance Optimization
- **Lazy loading**: Objects loaded on demand
- **Efficient rebuilds**: Using GetX for targeted UI updates
- **Image optimization**: Placeholder images and caching
- **Memory management**: Disposing controllers in `dispose()` method

### Security Considerations
- **Input validation**: All user inputs validated before API calls
- **Error sanitization**: Sensitive information not exposed in error messages
- **Network security**: HTTPS enforcement for API calls
- **Authentication tokens**: Secure storage and automatic refresh

### UI/UX Guidelines
- **Loading states**: Visual feedback during async operations
- **Error states**: User-friendly error messages with retry options
- **Empty states**: Informative messages when no data available
- **Accessibility**: Semantic labels and screen reader support

## Troubleshooting

### Common Issues

#### 1. Firebase Authentication Issues
```dart
// Problem: Phone verification not working
// Solution: Check phone number format and Firebase configuration

// Ensure proper format
phoneNumber: '+91${phoneNumber}' // Include country code

// Check Firebase console settings
// - Enable Phone Authentication
// - Add SHA-1 fingerprints for Android
// - Configure iOS bundle identifier
```

#### 2. API Connection Issues
```dart
// Problem: Network requests failing
// Solution: Check internet permissions and API availability

// Android permissions (android/app/src/main/AndroidManifest.xml)
<uses-permission android:name="android.permission.INTERNET" />

// Test API endpoint manually
curl -X GET "https://api.restful-api.dev/objects"
```

#### 3. State Management Issues
```dart
// Problem: UI not updating after data changes
// Solution: Ensure proper GetX reactive programming

// Use .obs for reactive variables
var isDark = true.obs;

// Wrap UI in Obx for automatic updates
return Obx(() => YourWidget());

// Call update() after manual changes
update();
```

#### 4. Build Issues
```bash
# Clean build cache
flutter clean
flutter pub get

# Reset pub cache
flutter pub cache repair

# Regenerate platform files
flutter create --platforms android,ios .
```

### Debugging Tips

#### 1. Enable Debug Logging
```dart
// Add to main.dart for development
import 'package:flutter/foundation.dart';

if (kDebugMode) {
  print("Debug information: $debugInfo");
}
```

#### 2. Network Debugging
```dart
// Log HTTP requests/responses
final response = await http.get(uri);
print("Request: ${uri.toString()}");
print("Response: ${response.statusCode} - ${response.body}");
```

#### 3. State Debugging
```dart
// Monitor GetX state changes
class ThemeController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    ever(isDark, (bool value) {
      print("Theme changed to: ${value ? 'Dark' : 'Light'}");
    });
  }
}
```

### Performance Monitoring

#### 1. Build Size Analysis
```bash
flutter build apk --analyze-size
flutter build ios --analyze-size
```

#### 2. Memory Usage
```dart
// Monitor memory usage in debug mode
import 'dart:developer' as developer;

void checkMemoryUsage() {
  developer.Timeline.startSync('memory_check');
  // Your code here
  developer.Timeline.finishSync();
}
```

#### 3. Network Performance
```bash
# Test API response times
curl -w "@curl-format.txt" -s -o /dev/null "https://api.restful-api.dev/objects"
```

---

## Conclusion

This Flutter CRUD application demonstrates modern mobile development practices with:

- **Robust authentication** using Firebase Phone Auth
- **Efficient API integration** with smart PATCH/PUT fallback
- **Modern UI/UX** with Material 3 design system
- **Reactive state management** using GetX
- **Comprehensive error handling** and user feedback
- **Performance optimization** and best practices

The codebase is designed to be maintainable, scalable, and production-ready, serving as a solid foundation for more complex applications.

For additional support or contributions, please refer to the project repository and follow the established coding standards.

