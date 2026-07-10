import 'package:flutter/material.dart';

import '../../core/utils/avatar_util.dart';
import '../../core/utils/chat_media_util.dart';
import '../../theme/rpx.dart';

/// 头像组件。对齐 im-uniapp components/head-image/head-image.vue。
class HeadImage extends StatefulWidget {
  const HeadImage({
    super.key,
    this.url,
    this.name,
    this.size = 96,
    this.online = false,
  });

  final String? url;
  final String? name;
  final double size;
  final bool online;

  @override
  State<HeadImage> createState() => _HeadImageState();
}

class _HeadImageState extends State<HeadImage> {
  bool _loadError = false;
  bool _imageReady = false;
  String? _resolvedUrl;

  static const _colors = [
    Color(0xFF5DAA31),
    Color(0xFFC7515A),
    Color(0xFFE03697),
    Color(0xFF85029B),
    Color(0xFFC9B455),
    Color(0xFF326EB6),
  ];

  @override
  void initState() {
    super.initState();
    _syncResolvedUrl();
  }

  @override
  void didUpdateWidget(covariant HeadImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) _syncResolvedUrl();
  }

  @override
  Widget build(BuildContext context) {
    final size = rpx(context, widget.size);
    final imageUrl = _resolvedUrl;
    final blocked =
        imageUrl != null &&
        NetworkImageFailCache.isTemporarilyBlocked(imageUrl);
    final showImage = imageUrl != null && !_loadError && !blocked;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipOval(
            child: Stack(
              fit: StackFit.expand,
              children: [
                _textAvatar(context, size),
                if (showImage)
                  AnimatedOpacity(
                    opacity: _imageReady ? 1 : 0,
                    duration: const Duration(milliseconds: 100),
                    curve: Curves.easeOut,
                    child: Image.network(
                      imageUrl,
                      width: size,
                      height: size,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                      frameBuilder: (context, child, frame, syncLoaded) {
                        if (syncLoaded || frame != null) {
                          NetworkImageFailCache.markSucceeded(imageUrl);
                          _markImageReady();
                        }
                        return child;
                      },
                      errorBuilder: (_, _, _) {
                        NetworkImageFailCache.markFailed(imageUrl);
                        _markLoadError();
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
              ],
            ),
          ),
          if (widget.online)
            Positioned(
              right: rpx(context, 2),
              bottom: rpx(context, 2),
              child: Container(
                width: rpx(context, 18),
                height: rpx(context, 18),
                decoration: BoxDecoration(
                  color: const Color(0xFF5DAA31),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: rpx(context, 2),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _syncResolvedUrl() {
    final next = AvatarUtil.pick(origin: widget.url);
    if (next == _resolvedUrl && !_loadError) return;
    _resolvedUrl = next;
    _loadError = false;
    _imageReady = false;
  }

  void _markImageReady() {
    if (!mounted || _imageReady) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_imageReady) setState(() => _imageReady = true);
    });
  }

  void _markLoadError() {
    if (!mounted || _loadError) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_loadError) {
        setState(() {
          _loadError = true;
          _imageReady = false;
        });
      }
    });
  }

  Widget _textAvatar(BuildContext context, double size) {
    final name = widget.name ?? '';
    final text = _avatarText(name);
    final colorIndex = name.isEmpty ? 0 : name.codeUnitAt(0) % _colors.length;
    return Container(
      width: size,
      height: size,
      color: _colors[colorIndex],
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: rpx(context, widget.size * 0.45),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _avatarText(String name) {
    if (name.isEmpty) return '';
    final code = name.codeUnitAt(0);
    final isChinese = code >= 0x4e00 && code <= 0x9fa5;
    if (isChinese) return name.substring(0, 1);
    if (name.length >= 2) {
      return name.substring(0, 2).toUpperCase();
    }
    return name.substring(0, 1).toUpperCase();
  }
}
