const fs = require('fs');
const { spawnSync } = require('child_process');

const adb =
  process.env.LOCALAPPDATA + '\\Android\\Sdk\\platform-tools\\adb.exe';
const out = 'E:/0000IM/00code/my-im/im-flutter/build/_device_verify2';
const d = 'ZE223JPF9T';
fs.mkdirSync(out, { recursive: true });

function sh(a) {
  return spawnSync(adb, ['-s', d, ...a], {
    encoding: 'utf8',
    maxBuffer: 20 * 1024 * 1024,
  });
}
function cap(n) {
  const r = spawnSync(adb, ['-s', d, 'exec-out', 'screencap', '-p'], {
    maxBuffer: 20 * 1024 * 1024,
  });
  fs.writeFileSync(out + '/' + n, r.stdout);
  console.log('CAP', n, r.stdout.length);
}
function sleep(ms) {
  Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, ms);
}
function tap(x, y) {
  sh(['shell', 'input', 'tap', String(x), String(y)]);
  console.log('TAP', x, y);
}
function dump(n) {
  sh(['shell', 'uiautomator', 'dump', '/sdcard/uidump.xml']);
  sh(['pull', '/sdcard/uidump.xml', out + '/' + n]);
  return fs.readFileSync(out + '/' + n, 'utf8');
}
function descs(xml) {
  return [...xml.matchAll(/content-desc="([^"]+)"/g)].map((m) => m[1]);
}
function hasPanel(xml) {
  const d = descs(xml).join('|');
  return (
    d.includes('\u7ebf\u8def') || // 线路
    d.includes('\u68c0\u6d4b') || // 检测
    d.includes('\u5f02\u5e38') // 异常
  );
}

sh(['shell', 'cmd', 'connectivity', 'airplane-mode', 'enable']);
sh(['shell', 'settings', 'put', 'global', 'airplane_mode_on', '1']);
sh([
  'shell',
  'am',
  'broadcast',
  '-a',
  'android.intent.action.AIRPLANE_MODE',
  '--ez',
  'state',
  'true',
]);
sleep(800);
sh(['shell', 'am', 'force-stop', 'com.cyberis.vortek']);
sleep(400);
sh(['shell', 'am', 'start', '-n', 'com.cyberis.vortek/.MainActivity']);
sleep(5000);
cap('p01_air.png');
let xml = dump('p01.xml');
console.log('DESCS', descs(xml).join(' || '));

const points = [
  [920, 150],
  [860, 150],
  [980, 160],
  [900, 180],
  [800, 160],
  [950, 140],
];
let openedAt = null;
for (const [x, y] of points) {
  tap(x, y);
  sleep(1100);
  cap('p_tap_' + x + '_' + y + '.png');
  xml = dump('p_after_' + x + '.xml');
  console.log('AFTER', x, y, descs(xml).join(' || '));
  if (hasPanel(xml)) {
    openedAt = [x, y];
    console.log('PANEL_OPEN_AT', x, y);
    break;
  }
}

if (openedAt) {
  tap(200, 1200);
  sleep(900);
  cap('p03_outside.png');
  xml = dump('p03.xml');
  console.log('CLOSED_OUTSIDE', !hasPanel(xml), descs(xml).join(' || '));

  tap(openedAt[0], openedAt[1]);
  sleep(1100);
  cap('p04_reopen.png');
  tap(1000, 220);
  sleep(900);
  cap('p05_closebtn.png');
  xml = dump('p05.xml');
  console.log('CLOSED_X', !hasPanel(xml), descs(xml).join(' || '));
} else {
  console.log('PANEL_NOT_OPENED');
}

sh(['shell', 'cmd', 'connectivity', 'airplane-mode', 'disable']);
sh(['shell', 'settings', 'put', 'global', 'airplane_mode_on', '0']);
sh([
  'shell',
  'am',
  'broadcast',
  '-a',
  'android.intent.action.AIRPLANE_MODE',
  '--ez',
  'state',
  'false',
]);
sleep(1500);
console.log('DONE_PANEL');
