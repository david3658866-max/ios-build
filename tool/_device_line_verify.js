const fs = require('fs');
const { spawnSync } = require('child_process');

const adb =
  process.env.LOCALAPPDATA + '\\Android\\Sdk\\platform-tools\\adb.exe';
const out = 'E:/0000IM/00code/my-im/im-flutter/build/_device_verify2';
const d = 'ZE223JPF9T';
fs.mkdirSync(out, { recursive: true });

const FAIL = '\u8fde\u63a5\u5931\u8d25'; // 连接失败
const CONNECTING = '\u8fde\u63a5\u4e2d'; // 连接中
const LOCAL = '\u672c\u5730\u8c03\u8bd5'; // 本地调试
const HINT = '\u8fde\u63a5\u5f02\u5e38\u65f6\u53ef\u5207\u6362'; // 连接异常时可切换
const RETRY = '\u91cd\u65b0\u68c0\u6d4b'; // 重新检测
const RETRYING = '\u68c0\u6d4b\u4e2d'; // 检测中
const LINE = '\u7ebf\u8def'; // 线路

function sh(args) {
  return spawnSync(adb, ['-s', d, ...args], {
    encoding: 'utf8',
    maxBuffer: 30 * 1024 * 1024,
  });
}

function cap(name) {
  const r = spawnSync(adb, ['-s', d, 'exec-out', 'screencap', '-p'], {
    maxBuffer: 30 * 1024 * 1024,
  });
  fs.writeFileSync(out + '/' + name, r.stdout);
  console.log('CAP', name, r.stdout.length);
}

function sleep(ms) {
  Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, ms);
}

function tap(x, y) {
  sh(['shell', 'input', 'tap', String(x), String(y)]);
  console.log('TAP', x, y);
}

function pullUi(name) {
  sh(['shell', 'uiautomator', 'dump', '/sdcard/uidump.xml']);
  sh(['pull', '/sdcard/uidump.xml', out + '/' + name]);
  return fs.readFileSync(out + '/' + name, 'utf8');
}

function findChip(xml) {
  const re = new RegExp(
    'text="([^"]*(?:' +
      FAIL +
      '|' +
      LOCAL +
      '|' +
      LINE +
      '\\d+)[^"]*)"[^>]*bounds="\\[(\\d+),(\\d+)\\]\\[(\\d+),(\\d+)\\]"',
  );
  const re2 = new RegExp(
    'content-desc="([^"]*(?:' +
      FAIL +
      '|' +
      LOCAL +
      '|' +
      LINE +
      '\\d+)[^"]*)"[^>]*bounds="\\[(\\d+),(\\d+)\\]\\[(\\d+),(\\d+)\\]"',
  );
  const m = xml.match(re) || xml.match(re2);
  if (!m) return null;
  return {
    text: m[1],
    x: Math.floor((+m[2] + +m[4]) / 2),
    y: Math.floor((+m[3] + +m[5]) / 2),
  };
}

console.log('PHASE healthy');
sh(['shell', 'cmd', 'connectivity', 'airplane-mode', 'disable']);
sh(['shell', 'settings', 'put', 'global', 'airplane_mode_on', '0']);
sleep(1200);
cap('01_login_healthy.png');
let xml = pullUi('uidump_healthy.xml');
console.log('UI_fail', xml.includes(FAIL));
console.log('UI_connecting', xml.includes(CONNECTING));
console.log('UI_local', xml.includes(LOCAL));

console.log('PHASE coldstart');
sh(['shell', 'am', 'force-stop', 'com.cyberis.vortek']);
sleep(500);
let i = 0;
const timer = setInterval(() => {
  try {
    cap('splash_' + String(i).padStart(2, '0') + '.png');
  } catch (_) {}
  i++;
  if (i >= 10) clearInterval(timer);
}, 180);
sleep(200);
sh(['shell', 'am', 'start', '-n', 'com.cyberis.vortek/.MainActivity']);
sleep(4000);
cap('02_after_cold.png');
sleep(2500);
cap('03_settled.png');
xml = pullUi('uidump_settled.xml');
console.log('SETTLED_fail', xml.includes(FAIL));
console.log('SETTLED_connecting', xml.includes(CONNECTING));

console.log('PHASE airplane');
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
sleep(1000);
sh(['shell', 'am', 'force-stop', 'com.cyberis.vortek']);
sleep(400);
sh(['shell', 'am', 'start', '-n', 'com.cyberis.vortek/.MainActivity']);
sleep(4500);
cap('04_airplane_login.png');
xml = pullUi('uidump_air.xml');
console.log('AIR_fail', xml.includes(FAIL));
const chip = findChip(xml);
console.log('CHIP', chip);
if (chip) {
  tap(chip.x, chip.y);
  sleep(1200);
  cap('05_panel_open.png');
  const pxml = pullUi('uidump_panel.xml');
  const lineItems = [
    ...pxml.matchAll(new RegExp('text="(' + LINE + '\\d+)"', 'g')),
  ].map((x) => x[1]);
  const uniq = [...new Set(lineItems)];
  console.log('PANEL_count', uniq.length, 'sample', uniq.slice(0, 10).join(','));
  console.log('PANEL_hint', pxml.includes(HINT));
  console.log('PANEL_retry', pxml.includes(RETRY) || pxml.includes(RETRYING));
  tap(80, 1000);
  sleep(900);
  cap('06_after_outside_tap.png');
  const cxml = pullUi('uidump_after_close.xml');
  console.log('CLOSED', !cxml.includes(HINT));
  const chip2 = findChip(cxml) || chip;
  tap(chip2.x, chip2.y);
  sleep(1000);
  cap('07_panel_reopen.png');
  pullUi('uidump_panel2.xml');
  tap(980, 230);
  sleep(800);
  cap('08_after_x_or_corner.png');
  const c2 = pullUi('uidump_after_x.xml');
  console.log('CLOSED2', !c2.includes(HINT));
} else {
  const texts = [...xml.matchAll(/text="([^"]+)"/g)]
    .map((x) => x[1])
    .filter((t) => t.trim())
    .slice(0, 50);
  console.log('NO_CHIP texts=', texts.join(' | '));
}

console.log('PHASE recover');
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
sleep(2500);
sh(['shell', 'am', 'force-stop', 'com.cyberis.vortek']);
sleep(400);
sh(['shell', 'am', 'start', '-n', 'com.cyberis.vortek/.MainActivity']);
sleep(5000);
cap('09_recovered.png');
xml = pullUi('uidump_recovered.xml');
console.log('RECOVER_fail', xml.includes(FAIL));
console.log('RECOVER_connecting', xml.includes(CONNECTING));
console.log('DONE');
