const fs = require('fs');
const sources = [
  'C:/Users/Administrator/.cursor/projects/e-0000IM-00code/terminals/341826.txt',
  'E:/0000IM/00code/my-im/im-flutter/tool/_splash_warmup_flutter.txt',
  'E:/0000IM/00code/my-im/im-flutter/tool/_splash_warmup_logcat_all.txt',
  'E:/0000IM/00code/my-im/im-flutter/tool/_splash_warmup_logcat_dump.txt',
];
const keys = /warmup|\[Line\]|\[Smoke\]|\[Auth\]|bootstrap|reuse startup|auth warmup|probeAllBatched|preferred|splash|LineProbe|startup auth|I\/flutter/i;
const out = [];
for (const s of sources) {
  if (!fs.existsSync(s)) {
    out.push('MISSING ' + s);
    continue;
  }
  out.push('==== ' + s + ' ====');
  const text = fs.readFileSync(s, 'utf8');
  for (const l of text.split(/\r?\n/)) {
    if (keys.test(l)) out.push(l);
  }
}
const p = 'E:/0000IM/00code/my-im/im-flutter/tool/_splash_warmup_key.txt';
fs.writeFileSync(p, out.join('\n'), 'utf8');
console.log('wrote', p, 'count', out.length);