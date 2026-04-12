import 'package:flutter/material.dart';

/// Ảnh mạng an toàn: luôn dùng [Image.errorBuilder], không gọi network khi URL rỗng / không phải http(s).
class SafeNetworkImage extends StatelessWidget {
  const SafeNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.filterQuality = FilterQuality.low,
    required this.errorWidget,
  });

  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final AlignmentGeometry alignment;
  final FilterQuality filterQuality;
  final Widget errorWidget;

  static bool looksLikeHttpUrl(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return false;
    final u = Uri.tryParse(t);
    return u != null && u.hasScheme && (u.scheme == 'http' || u.scheme == 'https');
  }

  @override
  Widget build(BuildContext context) {
    if (!looksLikeHttpUrl(url)) return errorWidget;
    return Image.network(
      url.trim(),
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      filterQuality: filterQuality,
      errorBuilder: (_, __, ___) => errorWidget,
    );
  }
}
