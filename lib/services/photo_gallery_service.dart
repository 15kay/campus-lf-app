import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;
import 'analytics_service.dart';

class PhotoGalleryService {
  static final ImagePicker _picker = ImagePicker();
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  // Maximum number of images per report
  static const int maxImagesPerReport = 10;
  
  // Maximum file size (5MB)
  static const int maxFileSizeBytes = 5 * 1024 * 1024;
  
  // Supported image formats
  static const List<String> supportedFormats = ['jpg', 'jpeg', 'png', 'webp'];

  // Pick single image
  static Future<PhotoResult?> pickSingleImage({
    ImageSource source = ImageSource.gallery,
    int? imageQuality,
    double? maxWidth,
    double? maxHeight,
  }) async {
    try {
      final hasPermission = await _checkPermissions(source);
      if (!hasPermission) {
        return PhotoResult(
          success: false,
          error: 'Permission denied',
        );
      }

      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: imageQuality ?? 85,
        maxWidth: maxWidth ?? 1920,
        maxHeight: maxHeight ?? 1920,
      );

      if (image == null) {
        return PhotoResult(
          success: false,
          error: 'No image selected',
        );
      }

      // Validate image
      final validation = await _validateImage(image);
      if (!validation.isValid) {
        return PhotoResult(
          success: false,
          error: validation.error,
        );
      }

      // Log analytics
      await AnalyticsService.logFeatureUsed(
        featureName: 'image_picked',
        parameters: {
          'source': source.toString(),
          'file_size': await image.length(),
        },
      );

      return PhotoResult(
        success: true,
        images: [PhotoItem.fromXFile(image)],
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error picking single image: $e');
      }
      
      await AnalyticsService.logError(
        errorType: 'image_pick_error',
        errorMessage: e.toString(),
      );

      return PhotoResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  // Pick multiple images
  static Future<PhotoResult?> pickMultipleImages({
    int? maxImages,
    int? imageQuality,
    double? maxWidth,
    double? maxHeight,
  }) async {
    try {
      final hasPermission = await _checkPermissions(ImageSource.gallery);
      if (!hasPermission) {
        return PhotoResult(
          success: false,
          error: 'Permission denied',
        );
      }

      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: imageQuality ?? 85,
        maxWidth: maxWidth ?? 1920,
        maxHeight: maxHeight ?? 1920,
      );

      if (images.isEmpty) {
        return PhotoResult(
          success: false,
          error: 'No images selected',
        );
      }

      // Limit number of images
      final limitedImages = images.take(maxImages ?? maxImagesPerReport).toList();

      // Validate all images
      final validImages = <PhotoItem>[];
      final errors = <String>[];

      for (final image in limitedImages) {
        final validation = await _validateImage(image);
        if (validation.isValid) {
          validImages.add(PhotoItem.fromXFile(image));
        } else {
          errors.add('${image.name}: ${validation.error}');
        }
      }

      if (validImages.isEmpty) {
        return PhotoResult(
          success: false,
          error: 'No valid images selected. ${errors.join(', ')}',
        );
      }

      // Log analytics
      await AnalyticsService.logFeatureUsed(
        featureName: 'multiple_images_picked',
        parameters: {
          'total_selected': images.length,
          'valid_images': validImages.length,
          'invalid_images': errors.length,
        },
      );

      return PhotoResult(
        success: true,
        images: validImages,
        warnings: errors.isNotEmpty ? errors : null,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error picking multiple images: $e');
      }
      
      await AnalyticsService.logError(
        errorType: 'multiple_image_pick_error',
        errorMessage: e.toString(),
      );

      return PhotoResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  // Upload images to Firebase Storage
  static Future<List<String>> uploadImages({
    required List<PhotoItem> images,
    required String reportId,
    Function(int, int)? onProgress,
  }) async {
    final uploadedUrls = <String>[];
    
    try {
      for (int i = 0; i < images.length; i++) {
        final image = images[i];
        
        // Create unique filename
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final extension = path.extension(image.name).toLowerCase();
        final fileName = '${reportId}_${timestamp}_$i$extension';
        
        // Upload to Firebase Storage
        final ref = _storage.ref().child('report_images/$reportId/$fileName');
        
        UploadTask uploadTask;
        if (image.bytes != null) {
          uploadTask = ref.putData(image.bytes!);
        } else if (image.file != null) {
          uploadTask = ref.putFile(image.file!);
        } else {
          continue;
        }

        // Monitor upload progress
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          if (onProgress != null) {
            final progress = (snapshot.bytesTransferred / snapshot.totalBytes * 100).round();
            onProgress(i + 1, images.length);
          }
        });

        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();
        uploadedUrls.add(downloadUrl);
      }

      // Log analytics
      await AnalyticsService.logFeatureUsed(
        featureName: 'images_uploaded',
        parameters: {
          'image_count': uploadedUrls.length,
          'report_id': reportId,
        },
      );

      return uploadedUrls;
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading images: $e');
      }
      
      await AnalyticsService.logError(
        errorType: 'image_upload_error',
        errorMessage: e.toString(),
      );
      
      return uploadedUrls; // Return partial results
    }
  }

  // Delete image from Firebase Storage
  static Future<bool> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      
      await AnalyticsService.logFeatureUsed(
        featureName: 'image_deleted',
      );
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting image: $e');
      }
      return false;
    }
  }

  // Create photo gallery widget
  static Widget createPhotoGallery({
    required List<String> imageUrls,
    int initialIndex = 0,
    bool enableRotation = true,
    bool enableZoom = true,
    Color? backgroundColor,
    Widget? loadingWidget,
    Widget? errorWidget,
    Function(int)? onPageChanged,
  }) {
    return PhotoViewGallery.builder(
      scrollPhysics: const BouncingScrollPhysics(),
      builder: (BuildContext context, int index) {
        return PhotoViewGalleryPageOptions(
          imageProvider: CachedNetworkImageProvider(imageUrls[index]),
          initialScale: PhotoViewComputedScale.contained,
          minScale: PhotoViewComputedScale.contained * 0.5,
          maxScale: PhotoViewComputedScale.covered * 2.0,
          heroAttributes: PhotoViewHeroAttributes(tag: imageUrls[index]),
          errorBuilder: (context, error, stackTrace) {
            return errorWidget ?? const Center(
              child: Icon(
                Icons.error,
                color: Colors.red,
                size: 50,
              ),
            );
          },
        );
      },
      itemCount: imageUrls.length,
      loadingBuilder: (context, event) {
        return loadingWidget ?? const Center(
          child: CircularProgressIndicator(),
        );
      },
      backgroundDecoration: BoxDecoration(
        color: backgroundColor ?? Colors.black,
      ),
      pageController: PageController(initialPage: initialIndex),
      onPageChanged: onPageChanged,
      enableRotation: enableRotation,
    );
  }

  // Create image thumbnail widget
  static Widget createImageThumbnail({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => placeholder ?? Container(
          width: width,
          height: height,
          color: Colors.grey[300],
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
        errorWidget: (context, url, error) => errorWidget ?? Container(
          width: width,
          height: height,
          color: Colors.grey[300],
          child: const Icon(
            Icons.error,
            color: Colors.red,
          ),
        ),
      ),
    );
  }

  // Create image grid widget
  static Widget createImageGrid({
    required List<String> imageUrls,
    int crossAxisCount = 3,
    double mainAxisSpacing = 4.0,
    double crossAxisSpacing = 4.0,
    double childAspectRatio = 1.0,
    Function(int)? onImageTap,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: imageUrls.length,
      itemBuilder: (context, index) {
        return createImageThumbnail(
          imageUrl: imageUrls[index],
          placeholder: placeholder,
          errorWidget: errorWidget,
          onTap: () => onImageTap?.call(index),
        );
      },
    );
  }

  // Show full screen image gallery
  static void showFullScreenGallery({
    required BuildContext context,
    required List<String> imageUrls,
    int initialIndex = 0,
    bool enableRotation = true,
    Color? backgroundColor,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: backgroundColor ?? Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(
              '${initialIndex + 1} of ${imageUrls.length}',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          body: createPhotoGallery(
            imageUrls: imageUrls,
            initialIndex: initialIndex,
            enableRotation: enableRotation,
            backgroundColor: backgroundColor,
            onPageChanged: (index) {
              // Update app bar title if needed
            },
          ),
        ),
      ),
    );
  }

  // Check permissions
  static Future<bool> _checkPermissions(ImageSource source) async {
    if (source == ImageSource.camera) {
      final status = await Permission.camera.status;
      if (status.isDenied) {
        final result = await Permission.camera.request();
        return result.isGranted;
      }
      return status.isGranted;
    } else {
      final status = await Permission.photos.status;
      if (status.isDenied) {
        final result = await Permission.photos.request();
        return result.isGranted;
      }
      return status.isGranted;
    }
  }

  // Validate image
  static Future<ImageValidation> _validateImage(XFile image) async {
    try {
      // Check file size
      final fileSize = await image.length();
      if (fileSize > maxFileSizeBytes) {
        return ImageValidation(
          isValid: false,
          error: 'File size too large (max ${maxFileSizeBytes ~/ (1024 * 1024)}MB)',
        );
      }

      // Check file extension
      final extension = path.extension(image.name).toLowerCase().replaceAll('.', '');
      if (!supportedFormats.contains(extension)) {
        return ImageValidation(
          isValid: false,
          error: 'Unsupported format. Supported: ${supportedFormats.join(', ')}',
        );
      }

      return ImageValidation(isValid: true);
    } catch (e) {
      return ImageValidation(
        isValid: false,
        error: 'Error validating image: $e',
      );
    }
  }

  // Get image metadata
  static Future<ImageMetadata?> getImageMetadata(String imageUrl) async {
    try {
      // This would typically extract EXIF data
      // For now, return basic metadata
      return ImageMetadata(
        url: imageUrl,
        fileName: path.basename(imageUrl),
        uploadDate: DateTime.now(), // This should come from storage metadata
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error getting image metadata: $e');
      }
      return null;
    }
  }

  // Compress image
  static Future<PhotoItem?> compressImage({
    required PhotoItem image,
    int quality = 85,
    double? maxWidth,
    double? maxHeight,
  }) async {
    try {
      // This would use image compression library
      // For now, return the original image
      return image;
    } catch (e) {
      if (kDebugMode) {
        print('Error compressing image: $e');
      }
      return null;
    }
  }

  // Create image collage
  static Future<Uint8List?> createImageCollage({
    required List<String> imageUrls,
    int maxImages = 4,
    double width = 400,
    double height = 400,
  }) async {
    try {
      // This would create a collage from multiple images
      // Implementation would require image manipulation library
      // For now, return null
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating image collage: $e');
      }
      return null;
    }
  }
}

// Data models
class PhotoItem {
  final String name;
  final File? file;
  final Uint8List? bytes;
  final String? path;

  PhotoItem({
    required this.name,
    this.file,
    this.bytes,
    this.path,
  });

  factory PhotoItem.fromXFile(XFile xFile) {
    return PhotoItem(
      name: xFile.name,
      file: File(xFile.path),
      path: xFile.path,
    );
  }

  factory PhotoItem.fromBytes(String name, Uint8List bytes) {
    return PhotoItem(
      name: name,
      bytes: bytes,
    );
  }
}

class PhotoResult {
  final bool success;
  final List<PhotoItem>? images;
  final String? error;
  final List<String>? warnings;

  PhotoResult({
    required this.success,
    this.images,
    this.error,
    this.warnings,
  });
}

class ImageValidation {
  final bool isValid;
  final String? error;

  ImageValidation({
    required this.isValid,
    this.error,
  });
}

class ImageMetadata {
  final String url;
  final String fileName;
  final DateTime uploadDate;
  final int? width;
  final int? height;
  final int? fileSize;
  final String? format;

  ImageMetadata({
    required this.url,
    required this.fileName,
    required this.uploadDate,
    this.width,
    this.height,
    this.fileSize,
    this.format,
  });
}