/// メディアファイルパスのユーティリティ。
/// DBには相対パス（例: "media/img_123.jpg"）を保存し、
/// 表示時にドキュメントディレクトリと結合して絶対パスに変換する。
class MediaPathHelper {
  MediaPathHelper._();

  /// 保存済みパス（相対 or 旧形式の絶対）を現在の絶対パスに変換する。
  /// - 相対パス "media/xxx.jpg" → "{docsPath}/media/xxx.jpg"
  /// - 旧形式の絶対パス（UUID変化後も対応）→ /Documents/ 以降を抽出して再構築
  static String resolve(String storedPath, String docsPath) {
    if (!storedPath.startsWith('/')) {
      return '$docsPath/$storedPath';
    }
    const marker = '/Documents/';
    final idx = storedPath.indexOf(marker);
    if (idx != -1) {
      return '$docsPath/${storedPath.substring(idx + marker.length)}';
    }
    return storedPath;
  }

  /// 絶対パスから相対パスへ変換（保存時に使用）。
  static String toRelative(String absolutePath, String docsPath) {
    if (absolutePath.startsWith(docsPath)) {
      final relative = absolutePath.substring(docsPath.length);
      return relative.startsWith('/') ? relative.substring(1) : relative;
    }
    const marker = '/Documents/';
    final idx = absolutePath.indexOf(marker);
    if (idx != -1) {
      return absolutePath.substring(idx + marker.length);
    }
    return absolutePath;
  }
}
