import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app.dart';
import '../services/firebase_service.dart';

class ReportPage extends StatefulWidget {
  final void Function(Report) onSubmit;
  const ReportPage({super.key, required this.onSubmit});
  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _itemNameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _locations = const ['Library', 'Lecture Hall', 'Cafeteria', 'Admin', 'Residence', 'Parking', 'Sports Complex', 'Computer Lab', 'Study Hall', 'Auditorium'];
  final _categories = const ['Electronics', 'Bags & Backpacks', 'Clothing', 'Books & Stationery', 'Jewelry & Accessories', 'Keys', 'Documents', 'Sports Equipment', 'Other'];

  String _status = 'Lost';
  String _location = 'Library';
  String _category = 'Electronics';
  DateTime _date = DateTime.now();
  Uint8List? _imageBytes;
  bool _isSubmitting = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _itemNameCtrl.dispose();
    _descCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isSuccess 
          ? const Color(0xFF10B981)
          : const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (uid.isEmpty) {
        if (!mounted) return;
        _showSnackBar('Please log in to submit a report.');
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginPage()));
        return;
      }

      setState(() => _isSubmitting = true);

      try {
        final report = Report(
          reportId: '', // Firebase will generate the ID
          uid: uid,
          itemName: _itemNameCtrl.text.trim(),
          type: _status,
          status: _status,
          description: _descCtrl.text.trim(),
          location: _location,
          date: _date,
          category: _category,
          imageBytes: _imageBytes,
          timestamp: DateTime.now(),
        );
        
        // Submit to Firebase
        final reportId = await FirebaseService.addReport(report);
        
        // Also call the widget callback for UI updates
        final reportWithId = Report(
          reportId: reportId,
          uid: uid,
          itemName: _itemNameCtrl.text.trim(),
          type: _status,
          status: 'Pending',
          description: _descCtrl.text.trim(),
          location: _location,
          date: _date,
          category: _category,
          imageBytes: _imageBytes,
          timestamp: DateTime.now(),
        );
        widget.onSubmit(reportWithId);
        
        // Reset form
        _formKey.currentState!.reset();
        _itemNameCtrl.clear();
        _descCtrl.clear();
        
        setState(() {
          _status = 'Lost';
          _location = 'Library';
          _category = 'Electronics';
          _date = DateTime.now();
          _imageBytes = null;
          _isSubmitting = false;
        });
        
        _showSnackBar('Report submitted successfully!', isSuccess: true);
        
        // Navigate back after successful submission
        if (mounted) {
          Navigator.of(context).pop();
        }
        
      } catch (e) {
        setState(() => _isSubmitting = false);
        if (!mounted) return;
        _showSnackBar('Failed to submit report: $e');
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() => _imageBytes = bytes);
      }
    } catch (e) {
      _showSnackBar('Failed to pick image: $e');
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6366F1),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Report Lost/Found Item',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF6366F1),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSectionHeader('Item Details', Icons.info_outline),
                const SizedBox(height: 16),
                _buildFormCard([
                  _buildTextField(
                    controller: _itemNameCtrl,
                    label: 'Item Name',
                    hint: 'e.g., iPhone 13, Blue Backpack',
                    icon: Icons.label_outline,
                    validator: (value) => value?.trim().isEmpty == true ? 'Please enter item name' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildDropdown(
                    label: 'Status',
                    value: _status,
                    items: ['Lost', 'Found'],
                    icon: Icons.help_outline,
                    onChanged: (value) => setState(() => _status = value!),
                  ),
                  const SizedBox(height: 16),
                  _buildDropdown(
                    label: 'Category',
                    value: _category,
                    items: _categories,
                    icon: Icons.category_outlined,
                    onChanged: (value) => setState(() => _category = value!),
                  ),
                ]),
                
                const SizedBox(height: 24),
                _buildSectionHeader('Location & Date', Icons.location_on_outlined),
                const SizedBox(height: 16),
                _buildFormCard([
                  _buildDropdown(
                    label: 'Location',
                    value: _location,
                    items: _locations,
                    icon: Icons.place_outlined,
                    onChanged: (value) => setState(() => _location = value!),
                  ),
                  const SizedBox(height: 16),
                  _buildDateField(),
                ]),
                
                const SizedBox(height: 24),
                _buildSectionHeader('Description', Icons.description_outlined),
                const SizedBox(height: 16),
                _buildFormCard([
                  _buildTextField(
                    controller: _descCtrl,
                    label: 'Description',
                    hint: 'Provide detailed description...',
                    icon: Icons.notes,
                    maxLines: 4,
                    validator: (value) => value?.trim().isEmpty == true ? 'Please enter description' : null,
                  ),
                ]),
                
                const SizedBox(height: 24),
                _buildSectionHeader('Photo (Optional)', Icons.photo_camera_outlined),
                const SizedBox(height: 16),
                _buildImageSection(),
                
                const SizedBox(height: 32),
                _buildSubmitButton(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF6366F1), size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF6366F1)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required IconData icon,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF6366F1)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: _selectDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFFF9FAFB),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Color(0xFF6366F1)),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Date',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_date.day}/${_date.month}/${_date.year}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return _buildFormCard([
      if (_imageBytes != null) ...[
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(_imageBytes!, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.edit),
                label: const Text('Change Photo'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _imageBytes = null),
                icon: const Icon(Icons.delete, color: Colors.red),
                label: const Text('Remove', style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ),
          ],
        ),
      ] else ...[
        InkWell(
          onTap: _pickImage,
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE5E7EB), style: BorderStyle.solid),
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFFF9FAFB),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate, size: 40, color: Color(0xFF6366F1)),
                  SizedBox(height: 8),
                  Text(
                    'Tap to add photo',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ]);
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isSubmitting ? null : _submit,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                Text('Submitting...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            )
          : const Text('Submit Report', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
    );
  }
}