import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Horizontal strip of product images with a `+` tile for adding more.
///
/// Holds a mutable list of [XFile] (local picks) plus existing remote
/// URLs (used when editing). The form-layer builds the multipart upload
/// from [localImages]; [remoteImages] are display-only unless the user
/// wants to remove them (we tag removed ones in [removedRemoteIds]).
class ProductImagePicker extends StatefulWidget {
  const ProductImagePicker({
    super.key,
    required this.localImages,
    required this.onChanged,
    this.remoteImages = const [],
    this.onRemoveRemote,
  });

  final List<XFile> localImages;
  final ValueChanged<List<XFile>> onChanged;
  final List<RemoteProductImage> remoteImages;
  final ValueChanged<int>? onRemoveRemote;

  @override
  State<ProductImagePicker> createState() => _ProductImagePickerState();
}

class _ProductImagePickerState extends State<ProductImagePicker> {
  final _picker = ImagePicker();

  Future<void> _pick() async {
    final picked = await _picker.pickMultiImage(
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (picked.isEmpty) return;
    widget.onChanged([...widget.localImages, ...picked]);
  }

  void _removeLocal(int i) {
    final next = [...widget.localImages]..removeAt(i);
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      for (var i = 0; i < widget.remoteImages.length; i++)
        _Thumbnail(
          image: Image.network(
            widget.remoteImages[i].url,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const ColoredBox(
              color: AppColors.gray200,
              child: Icon(Icons.broken_image_outlined,
                  color: AppColors.gray500),
            ),
          ),
          onRemove: widget.onRemoveRemote == null
              ? null
              : () => widget.onRemoveRemote!(widget.remoteImages[i].id),
        ),
      for (var i = 0; i < widget.localImages.length; i++)
        _Thumbnail(
          image: Image.file(File(widget.localImages[i].path), fit: BoxFit.cover),
          onRemove: () => _removeLocal(i),
        ),
      _AddTile(onTap: _pick),
    ];

    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tiles.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (_, i) => tiles[i],
      ),
    );
  }
}

class RemoteProductImage {
  const RemoteProductImage({required this.id, required this.url});
  final int id;
  final String url;
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.image, required this.onRemove});
  final Widget image;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: image,
            ),
          ),
          if (onRemove != null)
            Positioned(
              top: 4,
              right: 4,
              child: InkWell(
                onTap: onRemove,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(4),
                  child: const Icon(
                    Icons.close,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.gray300,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        alignment: Alignment.center,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined, color: AppColors.gray500),
            SizedBox(height: 4),
            Text(
              'Add',
              style: TextStyle(fontSize: 11, color: AppColors.gray500),
            ),
          ],
        ),
      ),
    );
  }
}
