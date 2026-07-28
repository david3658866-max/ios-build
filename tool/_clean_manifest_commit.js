const { execSync } = require('child_process');
const fs = require('fs');
const p = 'my-im/im-flutter/android/app/src/main/AndroidManifest.xml';
let t = execSync('git show HEAD:' + p, { encoding: 'utf8' });
if (!t.includes('READ_MEDIA_VISUAL_USER_SELECTED')) {
  const needle = 'android:name="android.permission.READ_MEDIA_VIDEO"/>';
  const insert =
    'android:name="android.permission.READ_MEDIA_VIDEO"/>\n' +
    '    <!-- Android 14+ 仅所选照片；声明后可正确识别 limited 并引导允许全部 -->\n' +
    '    <uses-permission\n' +
    '        android:name="android.permission.READ_MEDIA_VISUAL_USER_SELECTED"/>';
  if (!t.includes(needle)) throw new Error('needle missing');
  t = t.replace(needle, insert);
}
fs.writeFileSync(p, t, 'utf8');
console.log('ok visual=', t.includes('READ_MEDIA_VISUAL_USER_SELECTED'), 'backup=', t.includes('allowBackup'));