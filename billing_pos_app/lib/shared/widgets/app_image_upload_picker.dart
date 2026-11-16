import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "../../core/services/image_upload_service.dart";
import "../../core/theme/app_colors.dart";
import "app_toast.dart";

class AppImageUploadPicker extends ConsumerStatefulWidget {
  final String? initialImageUrl;
  final ValueChanged<String> onImageUploaded;
  final VoidCallback? onImageRemoved;
  final String label;
  final String hintText;
  final double previewHeight;
  final double previewWidth;

  const AppImageUploadPicker({
    super.key,
    this.initialImageUrl,
    required this.onImageUploaded,
    this.onImageRemoved,
    this.label = "Image",
    this.hintText = "JPG, PNG, or WEBP (up to 10MB)",
    this.previewHeight = 110,
    this.previewWidth = 110,
  });

  @override
  ConsumerState<AppImageUploadPicker> createState() => _AppImageUploadPickerState();
}

class _AppImageUploadPickerState extends ConsumerState<AppImageUploadPicker> {
  String? _currentImageUrl;
  bool _isUploading = false;
  late TextEditingController _urlController;
  bool _showUrlField = false;

  @override
  void initState() {
    super.initState();
    _currentImageUrl = widget.initialImageUrl;
    _urlController = TextEditingController(text: widget.initialImageUrl ?? "");
  }

  @override
  void didUpdateWidget(covariant AppImageUploadPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialImageUrl != oldWidget.initialImageUrl) {
      _currentImageUrl = widget.initialImageUrl;
      _urlController.text = widget.initialImageUrl ?? "";
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _handleUpload() async {
    setState(() => _isUploading = true);

    try {
      final uploadService = ref.read(imageUploadServiceProvider);
      final result = await uploadService.pickAndUploadImage();

      if (mounted) {
        if (result.success && result.imageUrl != null) {
          setState(() {
            _currentImageUrl = result.imageUrl;
            _urlController.text = result.imageUrl!;
          });
          widget.onImageUploaded(result.imageUrl!);
          AppToast.showSuccess(context, "Image uploaded successfully!");
        } else if (result.errorMessage != null && result.errorMessage != "No file selected.") {
          AppToast.showError(context, result.errorMessage!);
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(context, "Failed to upload image: $e");
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _handleRemove() {
    setState(() {
      _currentImageUrl = null;
      _urlController.clear();
    });
    if (widget.onImageRemoved != null) {
      widget.onImageRemoved!();
    }
  }

  void _onManualUrlChanged(String value) {
    final trimmed = value.trim();
    setState(() {
      _currentImageUrl = trimmed.isNotEmpty ? trimmed : null;
    });
    widget.onImageUploaded(trimmed);
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = _currentImageUrl != null && _currentImageUrl!.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary),
            ),
            InkWell(
              onTap: () => setState(() => _showUrlField = !_showUrlField),
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  _showUrlField ? "Hide URL" : "Edit URL Directly",
                  style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.outline),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Image Thumbnail / Placeholder
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: widget.previewWidth,
                  height: widget.previewHeight,
                  color: const Color(0xFFF1F5F9),
                  child: hasImage
                      ? Image.network(
                          _currentImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Center(
                            child: Icon(Icons.broken_image_rounded, size: 30, color: Colors.grey),
                          ),
                        )
                      : Center(
                          child: Icon(
                            Icons.image_outlined,
                            size: 32,
                            color: AppColors.primary.withValues(alpha: 0.4),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),

              // Upload Action & Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasImage ? "Image Loaded" : "No image selected",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: hasImage ? AppColors.success : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.hintText,
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isUploading ? null : _handleUpload,
                          icon: _isUploading
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.cloud_upload_outlined, size: 16),
                          label: Text(
                            _isUploading
                                ? "Uploading..."
                                : (hasImage ? "Change Image" : "Upload Image"),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                        ),
                        if (hasImage)
                          OutlinedButton.icon(
                            onPressed: _isUploading ? null : _handleRemove,
                            icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                            label: const Text(
                              "Remove",
                              style: TextStyle(fontSize: 12, color: AppColors.error),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Optional direct URL editor
        if (_showUrlField) ...[
          const SizedBox(height: 10),
          TextFormField(
            controller: _urlController,
            decoration: const InputDecoration(
              labelText: "Image URL",
              hintText: "https://api.pozo.dev/pozo-common-image-api/upload?fileId=...",
              prefixIcon: Icon(Icons.link, size: 18),
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            style: const TextStyle(fontSize: 12),
            onChanged: _onManualUrlChanged,
          ),
        ],
      ],
    );
  }
}
