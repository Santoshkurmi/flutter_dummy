import 'dart:io';
import 'package:flutter/material.dart';
import '../services/local_image_cache_service.dart';

class CachedImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget Function(BuildContext context, Object error, StackTrace? stackTrace) errorBuilder;
  final Widget? placeholder;

  const CachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    required this.errorBuilder,
    this.placeholder,
  });

  @override
  State<CachedImage> createState() => _CachedImageState();
}

class _CachedImageState extends State<CachedImage> {
  String? _localPath;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(covariant CachedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    final url = widget.imageUrl.trim();
    if (url.isEmpty || !url.startsWith('http')) {
      if (mounted) {
        setState(() {
          _localPath = null;
          _isLoading = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // 1. Check if cached already
      final cachedPath = await LocalImageCacheService.getCachedPath(url);
      if (cachedPath != null) {
        if (mounted) {
          setState(() {
            _localPath = cachedPath;
            _isLoading = false;
          });
        }
        return;
      }

      // 2. Download and cache
      final path = await LocalImageCacheService.cacheImage(url);
      if (mounted) {
        setState(() {
          _localPath = path;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      if (widget.placeholder != null) {
        return SizedBox(
          width: widget.width,
          height: widget.height,
          child: Center(child: widget.placeholder),
        );
      }
      return _buildDefaultPlaceholder();
    }

    final url = widget.imageUrl.trim();
    if (url.isEmpty || !url.startsWith('http')) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: Center(
          child: widget.errorBuilder(context, Exception('Invalid URL'), null),
        ),
      );
    }

    Widget buildErrorWidget(BuildContext context, Object error, StackTrace? stackTrace) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: Center(
          child: widget.errorBuilder(context, error, stackTrace),
        ),
      );
    }

    if (_localPath != null) {
      final file = File(_localPath!);
      if (file.existsSync()) {
        return Image.file(
          file,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          errorBuilder: (context, error, stackTrace) {
            // Fallback to network if local file load fails
            return Image.network(
              url,
              width: widget.width,
              height: widget.height,
              fit: widget.fit,
              errorBuilder: buildErrorWidget,
            );
          },
        );
      }
    }

    // Direct network load fallback if caching failed completely
    return Image.network(
      url,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      errorBuilder: buildErrorWidget,
    );
  }

  Widget _buildDefaultPlaceholder() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.black.withValues(alpha: 0.04),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2.0,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
          ),
        ),
      ),
    );
  }
}
