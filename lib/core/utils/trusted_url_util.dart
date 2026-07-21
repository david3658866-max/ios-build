import '../config/app_constants.dart';
import '../line/line_config.dart';

/// Trusted host checks for scan / external / notice links.
abstract final class TrustedUrlUtil {
  TrustedUrlUtil._();

  static const Set<String> _staticHosts = {
    'www.xingyu.com',
    'xingyu.com',
  };

  static const List<String> _trustedSuffixes = [
    '.bgznp.com',
    '.de010.com',
    '.xingyu.com',
  ];

  static bool isTrustedHttpUrl(String? raw) {
    if (raw == null || raw.trim().isEmpty) return false;
    final uri = Uri.tryParse(raw.trim());
    return uri != null && isTrustedUri(uri);
  }

  static bool isTrustedUri(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    if (scheme != 'http' && scheme != 'https') return false;
    final host = uri.host.toLowerCase();
    if (host.isEmpty) return false;
    if (host == 'localhost' || host == '127.0.0.1') {
      return true;
    }
    if (_staticHosts.contains(host)) return true;
    for (final suffix in _trustedSuffixes) {
      if (host == suffix.substring(1) || host.endsWith(suffix)) {
        return true;
      }
    }
    for (final line in kProductionLines) {
      if (host == line.host.toLowerCase()) return true;
      final scanHost = Uri.tryParse(line.scanUrl)?.host.toLowerCase();
      if (scanHost != null && scanHost.isNotEmpty && host == scanHost) {
        return true;
      }
    }
    for (final url in [
      AppConstants.protocolUrl,
      AppConstants.privacyUrl,
      AppConstants.apkDownloadUrl,
    ]) {
      final h = Uri.tryParse(url)?.host.toLowerCase();
      if (h != null && h == host) return true;
    }
    if (kLocalDevLanHost.isNotEmpty && host == kLocalDevLanHost.toLowerCase()) {
      return true;
    }
    return false;
  }
}
