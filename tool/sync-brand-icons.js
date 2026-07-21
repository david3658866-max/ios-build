/**
 * 从仓库根 logo.jpg 同步 Flutter 品牌图（含安全边距 + 圆角，避免裁切）。
 * 用法: node tool/sync-brand-icons.js [logo路径，默认 ../../logo.jpg]
 */
const fs = require('fs');
const path = require('path');
const sharp = require(path.join(
  __dirname,
  '../../im-platform/scripts/node_modules/sharp',
));

const flutterRoot = path.join(__dirname, '..');
const defaultLogo = path.resolve(flutterRoot, '../../logo.jpg');
const logoPath = path.resolve(process.argv[2] || defaultLogo);
const outDir = path.join(flutterRoot, 'assets', 'image');
const uniStaticDir = path.join(flutterRoot, '../im-uniapp/static/image');

const LAUNCHER_SCALE = 0.76;
const SPLASH_SCALE = 0.52;
const LOGIN_SCALE = 0.92;
/** 圆角半径占 logo 边长比例（对齐 About 页 40rpx / 160rpx ≈ 25%） */
const CORNER_RATIO = 0.24;

async function sampleBgHex() {
  const meta = await sharp(logoPath).metadata();
  const sample = Math.max(4, Math.min(32, Math.floor(Math.min(meta.width, meta.height) / 8)));
  const left = Math.max(0, meta.width - sample);
  const top = Math.max(0, meta.height - sample);
  const { data } = await sharp(logoPath)
    .extract({
      left,
      top,
      width: Math.min(sample, meta.width - left),
      height: Math.min(sample, meta.height - top),
    })
    .raw()
    .toBuffer({ resolveWithObject: true });
  return `#${[data[0], data[1], data[2]]
    .map((v) => v.toString(16).padStart(2, '0'))
    .join('')}`.toUpperCase();
}

async function roundedLogoBuffer(inner, cornerRatio = CORNER_RATIO) {
  const radius = Math.max(8, Math.round(inner * cornerRatio));
  const fg = await sharp(logoPath)
    .rotate()
    .resize(inner, inner, { fit: 'contain' })
    .ensureAlpha()
    .toBuffer();
  const maskSvg = Buffer.from(
    `<svg xmlns="http://www.w3.org/2000/svg" width="${inner}" height="${inner}">` +
      `<rect width="${inner}" height="${inner}" rx="${radius}" ry="${radius}" fill="white"/></svg>`,
  );
  return sharp(fg).composite([{ input: maskSvg, blend: 'dest-in' }]).png().toBuffer();
}

async function launcherIcon(size, scale, outPath) {
  const inner = Math.round(size * scale);
  const bg = await sharp(logoPath).rotate().resize(size, size, { fit: 'cover' }).toBuffer();
  const fg = await sharp(logoPath).rotate().resize(inner, inner, { fit: 'contain' }).toBuffer();
  await sharp(bg).composite([{ input: fg, gravity: 'center' }]).png().toFile(outPath);
}

/** 白底 + 圆角 logo（启动闪屏） */
async function splashIcon(size, scale, outPath) {
  const inner = Math.round(size * scale);
  const fg = await roundedLogoBuffer(inner);
  await sharp({
    create: {
      width: size,
      height: size,
      channels: 4,
      background: { r: 255, g: 255, b: 255, alpha: 1 },
    },
  })
    .composite([{ input: fg, gravity: 'center' }])
    .png()
    .toFile(outPath);
}

/** 圆角 logo 资源（关于我们 / 登录 Hero） */
async function logoAsset(size, scale, outPath) {
  const inner = Math.round(size * scale);
  const fg = await roundedLogoBuffer(inner);
  await sharp({
    create: {
      width: size,
      height: size,
      channels: 4,
      background: { r: 255, g: 255, b: 255, alpha: 0 },
    },
  })
    .composite([{ input: fg, gravity: 'center' }])
    .png()
    .toFile(outPath);
}

async function main() {
  if (!fs.existsSync(logoPath)) {
    throw new Error(`找不到 logo: ${logoPath}`);
  }
  fs.mkdirSync(outDir, { recursive: true });
  fs.mkdirSync(uniStaticDir, { recursive: true });
  fs.copyFileSync(logoPath, path.join(outDir, 'logo.jpg'));

  const bgHex = await sampleBgHex();
  console.log('adaptive_icon_background:', bgHex);

  await launcherIcon(1024, LAUNCHER_SCALE, path.join(outDir, 'app_icon.png'));
  await logoAsset(512, LOGIN_SCALE, path.join(outDir, 'app_logo.png'));
  await splashIcon(512, SPLASH_SCALE, path.join(outDir, 'app_splash_logo.png'));
  await launcherIcon(1024, LAUNCHER_SCALE, path.join(outDir, 'app_icon_wide.png'));

  fs.copyFileSync(
    path.join(outDir, 'app_logo.png'),
    path.join(uniStaticDir, 'app_logo.png'),
  );

  console.log('已写入:', outDir);
  console.log(
    `  launcher=${LAUNCHER_SCALE} splash=${SPLASH_SCALE} corner=${CORNER_RATIO}`,
  );

  const uniIconDir = path.join(flutterRoot, '../im-uniapp/unpackage/res/icons');
  fs.mkdirSync(uniIconDir, { recursive: true });
  const uniSizes = [20, 29, 40, 58, 60, 72, 76, 80, 87, 96, 120, 144, 152, 167, 180, 192, 1024];
  for (const size of uniSizes) {
    await launcherIcon(size, LAUNCHER_SCALE, path.join(uniIconDir, `logo${size}x${size}.png`));
  }
  console.log('uniapp icons:', uniIconDir);
  console.log('uniapp static:', uniStaticDir);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
