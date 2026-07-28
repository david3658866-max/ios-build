const fs = require('fs');
const path = 'E:/0000IM/00code/my-im/im-flutter/lib/core/utils/chat_image_prepare_util.dart';
let t = fs.readFileSync(path, 'utf8');

if (!t.includes('isServerAcceptedFileName')) {
  t = t.replace(
    "return cleaned.substring(dot + 1);\n  }\n\n  static Future<({String path, int bytes})?> _toJpegUnderLimit(",
    "return cleaned.substring(dot + 1);\n  }\n\n  static bool isServerAcceptedFileName(String nameOrPath) {\n    return serverImageExtensions.contains(_extOf(nameOrPath));\n  }\n\n  static Future<({String path, int bytes})?> _toJpegUnderLimit("
  );
}

if (!t.includes('final absPath = file.absolute.path')) {
  t = t.replace(
    "final ext = _extOf(path);\n      final bytes = await file.length();",
    "final absPath = file.absolute.path;\n      final ext = _extOf(absPath);\n      final bytes = await file.length();"
  );
  t = t.replace(
    "return ChatPreparedImage(\n          path: path,\n          width: width,\n          height: height,\n          bytes: bytes,\n        );",
    "return ChatPreparedImage(\n          path: absPath,\n          width: width,\n          height: height,\n          bytes: bytes,\n        );"
  );
  t = t.replace(
    "final prepared = await _toJpegUnderLimit(\n        path,\n        preferQuality: needsCompress ? 85 : 92,\n      );\n      if (prepared == null) {\n        log.w('[ChatImagePrepare] compress failed path=$path');",
    "final prepared = await _toJpegUnderLimit(\n        absPath,\n        preferQuality: needsCompress ? 85 : 92,\n      );\n      if (prepared == null) {\n        log.w('[ChatImagePrepare] compress failed path=$absPath');"
  );
}

t = t.replace(
  'return (path: result.path, bytes: outBytes);',
  'return (path: outFile.absolute.path, bytes: outBytes);'
);

fs.writeFileSync(path, t, 'utf8');
console.log('hasMethod', t.includes('isServerAcceptedFileName'));
console.log('hasAbs', t.includes('final absPath = file.absolute.path'));
console.log('hex', fs.readFileSync(path).slice(0,4).toString('hex'));