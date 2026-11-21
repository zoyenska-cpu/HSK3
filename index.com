<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<meta name="apple-mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-title" content="HSK 3">
<title>HSK 3 Study</title>
<style>
  /* Theme colours: light by default, dark follows the phone */
  :root { --bg:#f6f7fb; --card:#ffffff; --text:#1c1e26; --muted:#6b7080; --accent:#d9381e; --bar:#e3e5ee; }
  @media (prefers-color-scheme: dark) {
    :root { --bg:#14151a; --card:#1f2128; --text:#f1f2f6; --muted:#9aa0b4; --accent:#ff6a4d; --bar:#2c2f3a; }
  }
  * { box-sizing:border-box; -webkit-tap-highlight-color:transparent; }
  body { margin:0; background:var(--bg); color:var(--text);
    font-family:-apple-system,'PingFang SC','Noto Sans SC',sans-serif; padding-bottom:84px; }
  header { padding:20px 16px 8px; font-size:22px; font-weight:700; }
  .unit { background:var(--card); margin:10px 16px; padding:16px; border-radius:14px; min-height:64px; }
  .unit h3 { margin:0 0 8px; font-size:17px; }
  .bar { height:8px; background:var(--bar); border-radius:4px; overflow:hidden; }
  .bar > div { height:100%; background:var(--accent); }
  .word { background:var(--card); margin:8px 16px; padding:14px; border-radius:14px; }
  .hanzi { font-size:34px; }
  .pinyin { color:var(--accent); font-size:18px; }
  .meta { color:var(--muted); font-size:14px; }
  .ex { margin-top:8px; font-size:15px; }
  button { font-size:16px; padding:12px 16px; border:0; border-radius:12px; background:var(--accent); color:#fff; min-height:44px; }
  nav { position:fixed; bottom:0; left:0; right:0; display:flex; background:var(--card);
    padding-bottom:env(safe-area-inset-bottom); border-top:1px solid var(--bar); }
  nav div { flex:1; text-align:center; padding:14px 0; font-size:13px; color:var(--muted); }
  nav div.active { color:var(--accent); font-weight:700; }
</style>
</head>
<body>
<header id="title">HSK 3 Units</header>
<main id="app"></main>
<nav>
  <div class="active">Learn</div><div>Review</div><div>Listen</div><div>Practice</div><div>Stats</div>
</nav>

<script>
/* =====================================================================
   DATA: EDIT HERE. One object per unit. Add your own words to the
   words array of any unit. unitConfirmed:false means the placement of
   words in this unit is NOT yet checked against your coursebook.
   Word fields: hz = characters, py = pinyin, en = meaning,
   pos = part of speech, ex = example sentence, exPy = its pinyin,
   exEn = its translation, isNew = new at HSK 3 level.
   SAMPLE DATA ONLY: please check these against your official list.
   Note: Chinese and tone marks are written as \u codes so they survive
   any file-encoding problems. You can type normal characters later.
   ===================================================================== */
const UNITS = [
  { id:1, title:'Unit 1', unitConfirmed:false, words:[
    { hz:'\u5e2e\u52a9', py:'b\u0101ngzh\u00f9', en:'to help', pos:'verb', isNew:true,
      ex:'\u8c22\u8c22\u4f60\u5e2e\u52a9\u6211\u3002', exPy:'Xi\u00e8xie n\u01d0 b\u0101ngzh\u00f9 w\u01d2.', exEn:'Thank you for helping me.' },
    { hz:'\u6bd4\u8f83', py:'b\u01d0ji\u00e0o', en:'fairly; to compare', pos:'adverb', isNew:true,
      ex:'\u4eca\u5929\u6bd4\u8f83\u51b7\u3002', exPy:'J\u012bnti\u0101n b\u01d0ji\u00e0o l\u011bng.', exEn:'Today is fairly cold.' },
    { hz:'\u6c34\u679c', py:'shu\u01d0gu\u01d2', en:'fruit', pos:'noun', isNew:false,
      ex:'\u6211\u559c\u6b22\u5403\u6c34\u679c\u3002', exPy:'W\u01d2 x\u01d0huan ch\u012b shu\u01d0gu\u01d2.', exEn:'I like eating fruit.' }
  ]},
  { id:2, title:'Unit 2', unitConfirmed:false, words:[] },
  { id:3, title:'Unit 3', unitConfirmed:false, words:[] },
  { id:4, title:'Unit 4', unitConfirmed:false, words:[] },
  { id:5, title:'Unit 5', unitConfirmed:false, words:[] },
  { id:6, title:'Unit 6', unitConfirmed:false, words:[] },
  { id:7, title:'Unit 7', unitConfirmed:false, words:[] },
  { id:8, title:'Unit 8', unitConfirmed:false, words:[] },
  { id:9, title:'Unit 9', unitConfirmed:false, words:[] },
  { id:10, title:'Unit 10', unitConfirmed:false, words:[] },
  { id:11, title:'Unit 11', unitConfirmed:false, words:[] },
  { id:12, title:'Unit 12', unitConfirmed:false, words:[] },
  { id:13, title:'Unit 13', unitConfirmed:false, words:[] },
  { id:14, title:'Unit 14', unitConfirmed:false, words:[] },
  { id:15, title:'Unit 15', unitConfirmed:false, words:[] }
];

/* Progress is saved in the phone's local storage */
const KEY = 'hsk3-progress';
const progress = JSON.parse(localStorage.getItem(KEY) || '{}');
function save() { localStorage.setItem(KEY, JSON.stringify(progress)); }

const app = document.getElementById('app');
const title = document.getElementById('title');

/* Home screen: list of units with progress bars */
function showHome() {
  title.textContent = 'HSK 3 Units';
  app.innerHTML = UNITS.map(u => {
    const done = u.words.filter(w => progress[w.hz]).length;
    const pct = u.words.length ? Math.round(100 * done / u.words.length) : 0;
    return '<div class="unit" onclick="showUnit(' + u.id + ')">' +
      '<h3>' + u.title + ' <span class="meta">(' + done + '/' + u.words.length + ')</span></h3>' +
      '<div class="bar"><div style="width:' + pct + '%"></div></div></div>';
  }).join('');
}

/* Unit screen: words with example sentences */
function showUnit(id) {
  const u = UNITS.find(x => x.id === id);
  title.textContent = u.title;
  let html = '<div class="word"><button onclick="showHome()">Back</button>' +
    (u.unitConfirmed ? '' : '<p class="meta">Unit placement not yet confirmed against your book.</p>') + '</div>';
  html += u.words.map(w =>
    '<div class="word"><div class="hanzi">' + w.hz + '</div>' +
    '<div class="pinyin">' + w.py + '</div>' +
    '<div>' + w.en + ' <span class="meta">(' + w.pos + (w.isNew ? ', new at HSK 3' : '') + ')</span></div>' +
    '<div class="ex">' + w.ex + '<br><span class="meta">' + w.exPy + '<br>' + w.exEn + '</span></div>' +
    '<p><button onclick="toggle(\'' + w.hz + '\',' + id + ')">' + (progress[w.hz] ? 'Learned (tap to undo)' : 'Mark as learned') + '</button></p></div>'
  ).join('');
  app.innerHTML = html;
}

function toggle(hz, unitId) {
  progress[hz] = !progress[hz];
  save();
  showUnit(unitId);
}

showHome();
</script>
</body>
</html>
