const fs = require('fs');
const t = fs.readFileSync('C:/Users/Administrator/.cursor/projects/e-0000IM-00code/terminals/341826.txt', 'utf8');
const keys = /\[Smoke\]|\[Line\]|\[Auth\]|warmup|probeAllBatched|preferred|reuse startup|bootstrap/;
const hits = [];
for (const l of t.split(/\r?\n/)) {
  if (!keys.test(l)) continue;
  // skip box drawing-only lines
  const m = l.match(/I\/flutter[^:]*:\s*(.*)$/);
  const body = m ? m[1] : l;
  if (/^[┌└│─\s]+$/.test(body)) continue;
  if (body.includes('Error:') && !body.includes('[Line]')) continue;
  hits.push(body.replace(/^[│\s│]*[│?]?\s*/, '').replace(/^[^\x20-\x7E\u4e00-\u9fff\[\]]+/, ''));
}
const uniq = [];
for (const h of hits) {
  if (uniq.length === 0 || uniq[uniq.length - 1] !== h) uniq.push(h);
}
const out = uniq.filter(h => /\[Smoke\]|\[Line\]|\[Auth\]|warmup|probeAllBatched|preferred|reuse/i.test(h));
fs.writeFileSync('E:/0000IM/00code/my-im/im-flutter/tool/_splash_warmup_seq.txt', out.join('\n'), 'utf8');
console.log(out.join('\n'));
console.log('\n--- HAS warmup on splash:', out.some(l => /warmup lines on splash/i.test(l)));
console.log('HAS probeAllBatched:', out.some(l => /probeAllBatched/i.test(l)));
console.log('HAS preferred:', out.some(l => /preferred/i.test(l)));
console.log('HAS reuse startup:', out.some(l => /reuse startup/i.test(l)));