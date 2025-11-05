import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'dart:typed_data';
import '../models/item.dart';
import '../services/auth_service.dart';
import '../services/firebase_storage_service.dart';

class ReportScreen extends StatefulWidget {
  final Function(Item) onSubmit;

  const ReportScreen({super.key, required this.onSubmit});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contactController = TextEditingController();
  bool _isLost = true;
  ItemCategory _selectedCategory = ItemCategory.other;
  String? _selectedLocation;
  final List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;
  final int _maxImages = 5;
  // Inline upload tracking for selected images (logged-in users)
  final Map<String, double> _inlineProgress = {};
  final Map<String, String?> _inlineError = {};
  final Map<String, String> _uploadedUrls = {};
  // Submit-phase per-image errors (used to report failures in a Snackbar)
  final Map<String, String> _submitUploadError = {};
  final Map<String, double> _uploadProgress = {};
  bool _showingUploadDialog = false;

  final List<String> _campusLocations = [
    'Main Library',
    'Student Center',
    'Cafeteria',
    'Gymnasium',
    'Computer Lab A',
    'Computer Lab B',
    'Lecture Hall 1',
    'Lecture Hall 2',
    'Lecture Hall 3',
    'Science Building',
    'Engineering Building',
    'Arts Building',
    'Administration Block',
    'Parking Lot A',
    'Parking Lot B',
    'Sports Field',
    'Dormitory A',
    'Dormitory B',
    'Dormitory C',
    'Medical Center',
    'Security Office',
    'Bookstore',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Report Item',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStepCard(
                1,
                'Item Type',
                'What happened to the item?',
                _buildTypeSelector(),
              ),
              const SizedBox(height: 16),
              _buildStepCard(
                2,
                'Category',
                'What type of item is it?',
                _buildCategoryGrid(),
              ),
              const SizedBox(height: 16),
              _buildStepCard(
                3,
                'Photo',
                'Add a photo to help identify the item',
                _buildPhotoSection(),
              ),
              const SizedBox(height: 16),
              _buildStepCard(
                4,
                'Details',
                'Provide information about the item',
                _buildDetailsForm(),
              ),
              const SizedBox(height: 24),
              _buildSubmitButton(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepCard(int step, String title, String subtitle, Widget content) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$step',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildTypeOption(
            'Lost Item',
            'I lost something',
            Icons.search,
            Colors.red,
            _isLost,
            () => setState(() => _isLost = true),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildTypeOption(
            'Found Item',
            'I found something',
            Icons.check_circle,
            Colors.green,
            !_isLost,
            () => setState(() => _isLost = false),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeOption(String title, String subtitle, IconData icon, Color color, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? color : Colors.grey.shade700,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.2,
      children: ItemCategory.values.map((category) {
        final isSelected = _selectedCategory == category;
        return GestureDetector(
          onTap: () => setState(() => _selectedCategory = category),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? Colors.black : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Colors.black : Colors.grey.shade300,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Item.getCategoryIcon(category),
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  Item.getCategoryName(category),
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Photos (${_selectedImages.length}/$_maxImages)',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const Spacer(),
            if (_selectedImages.isNotEmpty)
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedImages.clear();
                  });
                },
                child: const Text(
                  'Clear All',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _selectedImages.length + (_selectedImages.length < _maxImages ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _selectedImages.length) {
                return _buildAddPhotoCard();
              }
              return _buildPhotoCard(_selectedImages[index], index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAddPhotoCard() {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade300,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate,
              size: 32,
              color: Colors.grey.shade500,
            ),
            const SizedBox(height: 8),
            Text(
              'Add Photos',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              'Up to $_maxImages',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoCard(XFile image, int index) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: FutureBuilder<Uint8List>(
              future: image.readAsBytes(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    width: 120,
                    height: 120,
                    color: Colors.grey.shade200,
                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  );
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return Container(
                    width: 120,
                    height: 120,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.broken_image),
                  );
                }
                return Image.memory(
                  snapshot.data!,
                  fit: BoxFit.cover,
                  width: 120,
                  height: 120,
                );
              },
            ),
          ),
          // Inline upload overlay
          if ((_inlineProgress[image.path] ?? 0.0) > 0 && (_inlineProgress[image.path] ?? 0.0) < 1.0)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: LinearProgressIndicator(
                  value: _inlineProgress[image.path],
                  minHeight: 6,
                  backgroundColor: Colors.white24,
                ),
              ),
            ),
          if (_inlineError[image.path] != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.8),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Upload failed', style: TextStyle(color: Colors.white, fontSize: 10)),
                    GestureDetector(
                      onTap: () => _retryInlineUpload(image),
                      child: const Text('Retry', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedImages.removeAt(index);
                  _inlineProgress.remove(image.path);
                  _inlineError.remove(image.path);
                  _uploadedUrls.remove(image.path);
                });
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
          ),
          if (index == 0)
            Positioned(
              bottom: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Main',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailsForm() {
    return Column(
      children: [
        _buildTextField(_titleController, 'Item Name', 'e.g., iPhone 13 Pro'),
        const SizedBox(height: 16),
        _buildTextField(_descriptionController, 'Description', 'Describe the item in detail', maxLines: 3),
        const SizedBox(height: 16),
        _buildLocationDropdown(),
        const SizedBox(height: 16),
        _buildTextField(_contactController, 'Contact Info', 'Phone number or email'),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String hint, {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: Colors.grey.shade600),
        hintStyle: TextStyle(color: Colors.grey.shade400),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: (value) => value?.isEmpty == true ? 'This field is required' : null,
    );
  }

  Widget _buildLocationDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedLocation,
      decoration: InputDecoration(
        labelText: 'Campus Location',
        hintText: 'Select where it was lost/found',
        labelStyle: TextStyle(color: Colors.grey.shade600),
        hintStyle: TextStyle(color: Colors.grey.shade400),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      items: _campusLocations.map((location) {
        return DropdownMenuItem<String>(
          value: location,
          child: Text(location),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedLocation = value;
        });
      },
      validator: (value) => value == null ? 'Please select a location' : null,
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: _isSubmitting
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Submitting...'),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_isLost ? Icons.report : Icons.check_circle),
                  const SizedBox(width: 8),
                  Text(
                    _isLost ? 'Report Lost Item' : 'Report Found Item',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _pickImages() async {
    if (_selectedImages.length >= _maxImages) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Maximum $_maxImages photos allowed'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Add Photos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Select Multiple'),
              onTap: () {
                Navigator.pop(context);
                _pickMultipleImages();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImageFromCamera() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _selectedImages.add(image);
      });
      await _startInlineUpload(image);
    }
  }

  Future<void> _pickImageFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImages.add(image);
      });
      await _startInlineUpload(image);
    }
  }

  Future<void> _pickMultipleImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      final remainingSlots = _maxImages - _selectedImages.length;
      final imagesToAdd = images.take(remainingSlots).toList();
      
      setState(() {
        _selectedImages.addAll(imagesToAdd);
      });
      for (final img in imagesToAdd) {
        await _startInlineUpload(img);
      }
      
      if (images.length > remainingSlots && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Only $remainingSlots photos could be added (max $_maxImages)'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _startInlineUpload(XFile file) async {
    final isGuest = await AuthService.isGuest();
    if (isGuest) return; // Skip uploading in guest mode
    final path = file.path;
    setState(() {
      _inlineProgress[path] = 0.0;
      _inlineError[path] = null;
    });
    try {
      final url = await FirebaseStorageService.uploadImageWithProgress(
        file,
        'items',
        (p) {
          setState(() {
            _inlineProgress[path] = p;
          });
        },
      );
      if (url == null) {
        setState(() {
          _inlineError[path] = 'Upload failed';
        });
      } else {
        setState(() {
          _uploadedUrls[path] = url;
          _inlineProgress[path] = 1.0;
        });
      }
    } catch (e) {
      setState(() {
        _inlineError[path] = 'Upload failed: $e';
      });
    }
  }

  Future<void> _retryInlineUpload(XFile file) async {
    setState(() {
      _inlineError[file.path] = null;
      _inlineProgress[file.path] = 0.0;
    });
    await _startInlineUpload(file);
  }

  void _submitForm() async {
    if (!_validateForm()) return;
    
    setState(() => _isSubmitting = true);
    
    try {
      final isGuest = await AuthService.isGuest();
      final userEmail = await AuthService.getCurrentUserEmail() ?? 'user@wsu.ac.za';
      final List<String> imageUrls = [];
      
      // Auto-fill contact if empty
      if (_contactController.text.trim().isEmpty) {
        _contactController.text = userEmail;
      }

      if (!isGuest && _selectedImages.isNotEmpty) {
        // Initialize progress map
        for (final f in _selectedImages) {
          _uploadProgress[f.path] = 0.0;
        }
        _showUploadProgressDialog();
        // Upload with progress
        for (final file in _selectedImages) {
          final url = await FirebaseStorageService.uploadImageWithProgress(
            file,
            'items',
            (p) {
              setState(() {
                _uploadProgress[file.path] = p;
              });
            },
          );
          if (url != null) {
            imageUrls.add(url);
          } else {
            _submitUploadError[file.path] = 'Upload failed';
          }
        }
        if (_submitUploadError.isNotEmpty && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_submitUploadError.length} photo(s) failed to upload. The report will proceed without them.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        // Guest mode: keep local paths for preview only
        imageUrls.addAll(_selectedImages.map((f) => f.path));
      }
      
      const uuid = Uuid();
      final item = Item(
        id: uuid.v4(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _selectedLocation ?? '',
        dateTime: DateTime.now(),
        isLost: _isLost,
        contactInfo: userEmail,
        category: _selectedCategory,
        imagePath: imageUrls.isNotEmpty ? imageUrls.first : null,
        imagePaths: imageUrls.isNotEmpty ? imageUrls : null,
        likes: const [],
        comments: const [],
      );

      widget.onSubmit(item);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${_isLost ? 'Lost' : 'Found'} item reported successfully!',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        
        if (_showingUploadDialog) Navigator.pop(context);
      }
      _clearForm();
    } catch (e) {
      _showError('Failed to submit report. Please try again.');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _showUploadProgressDialog() {
    _showingUploadDialog = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Uploading photos'),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _selectedImages.map((file) {
              final progress = _uploadProgress[file.path] ?? 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.path.split(RegExp(r'[\\/]')).last,
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: progress > 0 ? progress : null,
                      minHeight: 6,
                      backgroundColor: Colors.grey.shade200,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
  
  bool _validateForm() {
    if (!_formKey.currentState!.validate()) return false;
    
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final contact = _contactController.text.trim();
    
    if (title.length < 3) {
      _showError('Item name must be at least 3 characters');
      return false;
    }
    
    if (title.length > 50) {
      _showError('Item name must be less than 50 characters');
      return false;
    }
    
    if (description.length < 10) {
      _showError('Description must be at least 10 characters');
      return false;
    }
    
    if (description.length > 500) {
      _showError('Description must be less than 500 characters');
      return false;
    }
    
    if (!_isValidContact(contact)) {
      _showError('Please enter a valid phone number or email address');
      return false;
    }
    
    if (_selectedLocation == null) {
      _showError('Please select a campus location');
      return false;
    }
    
    return true;
  }
  
  bool _isValidContact(String contact) {
    final phoneRegex = RegExp(r'^\+27[0-9]{9}$|^0[0-9]{9}$');
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return phoneRegex.hasMatch(contact) || emailRegex.hasMatch(contact);
  }
  
  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  void _clearForm() {
    _titleController.clear();
    _descriptionController.clear();
    _contactController.clear();
    setState(() {
      _selectedImages.clear();
      _selectedCategory = ItemCategory.other;
      _selectedLocation = null;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _contactController.dispose();
    super.dispose();
  }
}