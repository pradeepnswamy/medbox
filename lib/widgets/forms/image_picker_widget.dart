import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../config/app_colors.dart';

/// Reusable medicine photo card used on both AddMedicineScreen and
/// MedicineDetailScreen.
///
/// Renders one of three states:
///   1. **In-flight** — [pickedFile] is set (just picked, not yet written to disk).
///   2. **Saved**     — [savedPath] points to a file in the app's documents dir.
///   3. **Empty**     — neither set; shows a placeholder prompting the user to add a photo.
///
/// Tap always calls [onTap]; the parent decides what sheet to show (add/change/remove).
class ImagePickerWidget extends StatelessWidget {
  /// A newly picked image that has not yet been copied to the documents dir.
  final XFile? pickedFile;

  /// Absolute path to a previously saved photo (from the app's documents dir).
  final String? savedPath;

  /// Called when the user taps anywhere on the card.
  final VoidCallback onTap;

  final double height;

  const ImagePickerWidget({
    super.key,
    this.pickedFile,
    this.savedPath,
    required this.onTap,
    this.height = 160,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = pickedFile != null ||
        (savedPath != null && File(savedPath!).existsSync());

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: hasImage ? Colors.black : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: hasImage ? _buildImage() : _buildPlaceholder(),
      ),
    );
  }

  Widget _buildImage() {
    final Widget image;
    if (pickedFile != null) {
      image = Image.file(
        File(pickedFile!.path),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    } else {
      image = Image.file(
        File(savedPath!),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => _buildPlaceholder(),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        image,
        // Change overlay pill — bottom-right
        Positioned(
          bottom: 10,
          right: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit_rounded, size: 13, color: Colors.white),
                SizedBox(width: 4),
                Text(
                  'Change',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.camera_alt_rounded,
            color: AppColors.primary,
            size: 24,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Add medicine photo',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Tap to photograph the box',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
