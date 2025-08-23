import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiServices {
  final baseurl = "https://api.restful-api.dev/objects";

  Future<List<dynamic>> fetchObjects() async {
    try {
      final response = await http.get(Uri.parse(baseurl));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data;
      } else {
        throw Exception(
          "Failed to load objects. Status code: ${response.statusCode}",
        );
      }
    } catch (e) {
      throw Exception("Failed to load objects: $e");
    }
  }

  Future<Map<String, dynamic>> getSingleObject(String id) async {
    try {
      final reponse = await http.get(Uri.parse("$baseurl/$id"));
      if (reponse.statusCode == 200) {
        Map<String, dynamic> data = json.decode(reponse.body);
        return data;
      } else {
        throw Exception("Error getting single Object: ${reponse.statusCode}");
      }
    } catch (e) {
      throw Exception("Error Occured: $e");
    }
  }

  Future<Map<String, dynamic>> createObject({
    required String name,
    required Map<String, dynamic> data,
  }) async {
    try {
      final body = {"name": name, "data": data};

      final response = await http.post(
        Uri.parse(baseurl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        Map<String, dynamic> responseData = json.decode(response.body);
        return responseData;
      } else {
        throw Exception(
          "Failed to create object. Status code: ${response.statusCode}",
        );
      }
    } catch (e) {
      throw Exception("Error creating object: $e");
    }
  }

  Future<Map<String, dynamic>> updateObject({
    required String id,
    required String name,
    required Map<String, dynamic> data,
  }) async {
    try {
      final body = {"name": name, "data": data};

      final response = await http.put(
        Uri.parse("$baseurl/$id"),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> responseData = json.decode(response.body);
        return responseData;
      } else {
        throw Exception(
          "Failed to update object. Status code: ${response.statusCode}",
        );
      }
    } catch (e) {
      throw Exception("Error updating object: $e");
    }
  }
}
