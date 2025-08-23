import 'package:crispy_train/api_services.dart';
import 'package:crispy_train/main.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EditObjectScreen extends StatefulWidget {
  final String objectId;
  const EditObjectScreen({super.key, required this.objectId});

  @override
  State<EditObjectScreen> createState() => _EditObjectScreenState();
}

class _EditObjectScreenState extends State<EditObjectScreen> {
  final ApiServices _apiService = Get.find<ApiServices>();
  final _formKey = GlobalKey<FormState>();

  // Controllers for form fields
  final _nameController = TextEditingController();
  final _yearController = TextEditingController();
  final _priceController = TextEditingController();
  final _cpuController = TextEditingController();
  final _storageController = TextEditingController();
  final _colorController = TextEditingController();
  final _capacityController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  Map<String, dynamic> _originalObject = {};

  // Original values for comparison
  String _originalName = '';
  Map<String, dynamic> _originalData = {};

  // Dynamic fields for custom specifications
  List<MapEntry<TextEditingController, TextEditingController>> _customFields =
      [];
  List<MapEntry<String, String>> _originalCustomFields = [];

  @override
  void initState() {
    super.initState();
    _loadObjectData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _yearController.dispose();
    _priceController.dispose();
    _cpuController.dispose();
    _storageController.dispose();
    _colorController.dispose();
    _capacityController.dispose();
    _descriptionController.dispose();

    // Dispose custom field controllers
    for (var field in _customFields) {
      field.key.dispose();
      field.value.dispose();
    }
    super.dispose();
  }

  Future<void> _loadObjectData() async {
    try {
      final objectData = await _apiService.getSingleObject(widget.objectId);

      if (mounted) {
        setState(() {
          _originalObject = objectData;
          _isLoading = false;
        });

        // Store original values for comparison
        _originalName = objectData['name'] ?? '';
        _originalData = Map<String, dynamic>.from(objectData['data'] ?? {});

        // Populate form fields
        _populateForm(objectData);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load object data: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _populateForm(Map<String, dynamic> objectData) {
    // Set name
    _nameController.text = objectData['name'] ?? '';

    // Set data fields if they exist
    final data = objectData['data'] as Map<String, dynamic>?;
    if (data != null) {
      // Populate common fields
      _yearController.text = data['year']?.toString() ?? '';
      _priceController.text = data['price']?.toString() ?? '';
      _cpuController.text = data['CPU model']?.toString() ?? '';
      _storageController.text = data['Hard disk size']?.toString() ?? '';
      _colorController.text = data['color']?.toString() ?? '';
      _capacityController.text = data['capacity']?.toString() ?? '';
      _descriptionController.text = data['description']?.toString() ?? '';

      // Handle custom fields
      final commonFields = {
        'year',
        'price',
        'CPU model',
        'Hard disk size',
        'color',
        'capacity',
        'description',
      };

      for (var entry in data.entries) {
        if (!commonFields.contains(entry.key)) {
          final keyController = TextEditingController(text: entry.key);
          final valueController = TextEditingController(
            text: entry.value?.toString() ?? '',
          );
          _customFields.add(MapEntry(keyController, valueController));
          _originalCustomFields.add(
            MapEntry(entry.key, entry.value?.toString() ?? ''),
          );
        }
      }
    }
  }

  void _addCustomField() {
    setState(() {
      _customFields.add(
        MapEntry(TextEditingController(), TextEditingController()),
      );
    });
  }

  void _removeCustomField(int index) {
    setState(() {
      _customFields[index].key.dispose();
      _customFields[index].value.dispose();
      _customFields.removeAt(index);

      // Also remove from original if it exists
      if (index < _originalCustomFields.length) {
        _originalCustomFields.removeAt(index);
      }
    });
  }

  // Check what fields have actually changed
  Map<String, dynamic> _getChangedFields() {
    Map<String, dynamic> changedData = {};

    // Check common fields for changes
    final currentData = {
      'year': _yearController.text.isNotEmpty
          ? (int.tryParse(_yearController.text) ?? _yearController.text)
          : null,
      'price': _priceController.text.isNotEmpty
          ? (double.tryParse(_priceController.text) ?? _priceController.text)
          : null,
      'CPU model': _cpuController.text.isNotEmpty ? _cpuController.text : null,
      'Hard disk size': _storageController.text.isNotEmpty
          ? _storageController.text
          : null,
      'color': _colorController.text.isNotEmpty ? _colorController.text : null,
      'capacity': _capacityController.text.isNotEmpty
          ? _capacityController.text
          : null,
      'description': _descriptionController.text.isNotEmpty
          ? _descriptionController.text
          : null,
    };

    // Compare each field with original
    currentData.forEach((key, value) {
      final originalValue = _originalData[key];

      // Handle different comparison scenarios
      bool hasChanged = false;

      if (originalValue == null && value != null) {
        hasChanged = true; // New field added
      } else if (originalValue != null && value == null) {
        hasChanged = true; // Field removed (set to empty)
      } else if (originalValue != null && value != null) {
        hasChanged = originalValue.toString() != value.toString();
      }

      if (hasChanged) {
        if (value != null) {
          changedData[key] = value;
        }
      }
    });

    // Handle custom fields
    for (int i = 0; i < _customFields.length; i++) {
      final field = _customFields[i];
      final key = field.key.text;
      final value = field.value.text;

      if (key.isNotEmpty && value.isNotEmpty) {
        // Check if this is a new field or changed field
        bool isNew = true;
        bool hasChanged = false;

        for (final originalField in _originalCustomFields) {
          if (originalField.key == key) {
            isNew = false;
            hasChanged = originalField.value != value;
            break;
          }
        }

        if (isNew || hasChanged) {
          changedData[key] = value;
        }
      }
    }

    return changedData;
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Product name is required')));
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Check if name changed
      final nameChanged = _nameController.text.trim() != _originalName;

      // Get changed data fields
      final changedData = _getChangedFields();

      // If nothing changed, show message and return
      if (!nameChanged && changedData.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No changes detected'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Prepare patch request
      String? newName = nameChanged ? _nameController.text.trim() : null;
      Map<String, dynamic>? dataToUpdate = changedData.isNotEmpty
          ? changedData
          : null;

      // Debug information
      print("Update Request:");
      print("Name changed: $nameChanged, New name: $newName");
      print("Data changes: $dataToUpdate");
      print("Object ID: ${widget.objectId}");

      final result = await _apiService.patchObject(
        id: widget.objectId,
        name: newName,
        data: dataToUpdate,
      );

      print("Update successful: $result");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Object updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Get.back(result: true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update object: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? hint,
    bool required = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        validator: required
            ? (value) => value?.isEmpty == true ? '$label is required' : null
            : null,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: AppColors.primaryLight),
          labelStyle: TextStyle(color: Colors.grey[400]),
          hintStyle: TextStyle(color: Colors.grey[600]),
          filled: true,
          fillColor: Colors.grey[800]!.withOpacity(0.6),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[700]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.primaryLight, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[700]!),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Object'),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        actions: [
          if (!_isLoading && _errorMessage == null)
            TextButton.icon(
              onPressed: _isSaving ? null : _saveChanges,
              icon: Icon(Icons.save, color: Colors.white, size: 20),
              label: Text(
                'Save',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading object data...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error Loading Data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[400]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _loadObjectData();
              },
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card with PATCH indicator
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.orange.withOpacity(0.8),
                    Colors.deepOrange.withOpacity(0.6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.edit, color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Edit Product',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green, width: 1),
                        ),
                        child: Text(
                          'PATCH',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'ID: ${widget.objectId}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Only modified fields will be sent to the server',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Required Fields Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[700]!.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Required Information',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _nameController,
                    label: 'Product Name',
                    icon: Icons.devices,
                    hint: 'e.g., Apple MacBook Pro 16',
                    required: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Optional Fields Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[700]!.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.settings,
                        color: AppColors.primaryLight,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Specifications',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _yearController,
                    label: 'Year',
                    icon: Icons.calendar_today,
                    keyboardType: TextInputType.number,
                    hint: '2019',
                  ),
                  _buildTextField(
                    controller: _priceController,
                    label: 'Price',
                    icon: Icons.attach_money,
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    hint: '1849.99',
                  ),
                  _buildTextField(
                    controller: _cpuController,
                    label: 'Processor',
                    icon: Icons.memory,
                    hint: 'Intel Core i9',
                  ),
                  _buildTextField(
                    controller: _storageController,
                    label: 'Storage',
                    icon: Icons.storage,
                    hint: '1 TB',
                  ),
                  _buildTextField(
                    controller: _colorController,
                    label: 'Color',
                    icon: Icons.palette,
                    hint: 'Space Gray',
                  ),
                  _buildTextField(
                    controller: _capacityController,
                    label: 'Capacity',
                    icon: Icons.sd_storage,
                    hint: '256 GB',
                  ),
                  _buildTextField(
                    controller: _descriptionController,
                    label: 'Description',
                    icon: Icons.description,
                    hint: 'Product description',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Custom Fields Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[700]!.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.add_box,
                        color: AppColors.primaryLight,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Custom Specifications',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _addCustomField,
                        icon: Icon(Icons.add, size: 16),
                        label: Text('Add Field'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryLight,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  ..._customFields.asMap().entries.map((entry) {
                    final index = entry.key;
                    final field = entry.value;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[800]!.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: field.key,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Field Name',
                                labelStyle: TextStyle(color: Colors.grey[400]),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: AppColors.primaryLight,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: field.value,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Field Value',
                                labelStyle: TextStyle(color: Colors.grey[400]),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: AppColors.primaryLight,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            onPressed: () => _removeCustomField(index),
                            icon: Icon(Icons.delete, color: Colors.red),
                          ),
                        ],
                      ),
                    );
                  }).toList(),

                  if (_customFields.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[800]!.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.grey[500]),
                          const SizedBox(width: 12),
                          Text(
                            'Add custom fields to extend product specifications',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey[600]!),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSaving
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            'Save Changes',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
