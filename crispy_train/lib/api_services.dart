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
      final response = await http.get(Uri.parse("$baseurl/$id"));
      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        return data;
      } else {
        throw Exception("Error getting single Object: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error Occurred: $e");
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

  // PUT - Full update (existing method)
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

  // PATCH - Partial update (new method)
  Future<Map<String, dynamic>> patchObject({
    required String id,
    String? name,
    Map<String, dynamic>? data,
  }) async {
    // Build the request body with only the fields that need to be updated
    final Map<String, dynamic> body = {};

    if (name != null) {
      body["name"] = name;
    }

    if (data != null && data.isNotEmpty) {
      body["data"] = data;
    }

    // If no fields to update, throw an exception
    if (body.isEmpty) {
      throw Exception("No fields provided for update");
    }

    try {
      // Try PATCH first
      var response = await http.patch(
        Uri.parse("$baseurl/$id"),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      // If PATCH is successful, return the result
      if (response.statusCode == 200) {
        Map<String, dynamic> responseData = json.decode(response.body);
        return responseData;
      }

      // If PATCH is not supported (405), fallback to PUT with full object
      if (response.statusCode == 405) {
        try {
          // First get the current object

          final currentObject = await getSingleObject(id);

          // Merge the changes with the current object
          Map<String, dynamic> fullData = Map<String, dynamic>.from(
            currentObject['data'] ?? {},
          );
          if (data != null) {
            fullData.addAll(data);
          }

          final String fullName = name ?? currentObject['name'] ?? '';

          // Use PUT with full object
          final putResponse = await http.put(
            Uri.parse("$baseurl/$id"),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({"name": fullName, "data": fullData}),
          );

          if (putResponse.statusCode == 200) {
            Map<String, dynamic> responseData = json.decode(putResponse.body);
            return responseData;
          } else {
            throw Exception(
              "PUT request failed. Status code: ${putResponse.statusCode}, Body: ${putResponse.body}",
            );
          }
        } catch (e) {
          throw Exception("Error during PUT fallback: $e");
        }
      } else {
        // Other PATCH errors
        throw Exception(
          "PATCH request failed. Status code: ${response.statusCode}, Body: ${response.body}",
        );
      }
    } catch (e) {
      // Handle network errors and other exceptions
      if (e.toString().contains('Status code: 405')) {
        // This shouldn't happen now, but just in case

        return await updateObject(
          id: id,
          name: name ?? (await getSingleObject(id))['name'],
          data: data ?? {},
        );
      }

      throw Exception("Error updating object: $e");
    }
  }

  // PATCH - Update only name (convenience method)
  Future<Map<String, dynamic>> updateObjectName({
    required String id,
    required String name,
  }) async {
    return await patchObject(id: id, name: name);
  }

  // PATCH - Update only data (convenience method)
  Future<Map<String, dynamic>> updateObjectData({
    required String id,
    required Map<String, dynamic> data,
  }) async {
    return await patchObject(id: id, data: data);
  }

  // PATCH - Update specific data field (convenience method)
  Future<Map<String, dynamic>> updateObjectField({
    required String id,
    required String fieldKey,
    required dynamic fieldValue,
  }) async {
    return await patchObject(id: id, data: {fieldKey: fieldValue});
  }

  // DELETE - Delete object
  Future<bool> deleteObject(String id) async {
    try {
      final response = await http.delete(Uri.parse("$baseurl/$id"));

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception(
          "Failed to delete object. Status code: ${response.statusCode}",
        );
      }
    } catch (e) {
      throw Exception("Error deleting object: $e");
    }
  }
}
