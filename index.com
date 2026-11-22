<!DOCTYPE html>
<html lang="en">

<body>
HSK 3 Units
Loading...

  Learn
  Review
  Listen
  Practice
  Stats

<script>
// DATA: edit here. SAMPLE words only, please check against your book.
var UNITS = [
  { id:1, words:[
    { hz:"帮助", py:"bāngzhù", en:"to help", pos:"verb",
      ex:"谢谢你帮助我。", exPy:"Xièxie nǐ bāngzhù wǒ.", exEn:"Thank you for helping me." },
    { hz:"比较", py:"bǐjiào", en:"fairly; to compare", pos:"adverb",
      ex:"今天比较冷。", exPy:"Jīntiān bǐjiào lěng.", exEn:"Today is fairly cold." },
    { hz:"水果", py:"shuǐguǒ", en:"fruit", pos:"noun",
      ex:"我喜欢吃水果。", exPy:"Wǒ xǐhuan chī shuǐguǒ.", exEn:"I like eating fruit." }
  ]},
  { id:2, words:[] }, { id:3, words:[] }, { id:4, words:[] }, { id:5, words:[] },
  { id:6, words:[] }, { id:7, words:[] }, { id:8, words:[] }, { id:9, words:[] },
  { id:10, words:[] }, { id:11, words:[] }, { id:12, words:[] }, { id:13, words:[] },
  { id:14, words:[] }, { id:15, words:[] }
];

// SAVED DATA (stored on the phone)
var progress = {}, cards = {}, settings = { front:"hz" };
try { progress = JSON.parse(localStorage.getItem("hsk3") || "{}"); } catch (e) {}
try { cards = JSON.parse(localStorage.getItem("hsk3cards") || "{}"); } catch (e) {}
try { settings = JSON.parse(localStorage.getItem("hsk3set") || '{"front":"hz"}'); } catch (e) {}

function saveAll() {
  try {
    localStorage.setItem("hsk3", JSON.stringify(progress));
    localStorage.setItem("hsk3cards", JSON.stringify(cards));
    localStorage.setItem("hsk3set", JSON.stringify(settings));
  } catch (e) {}
}

function today() { return Math.floor(Date.now() / 86400000); }

function allWords() {
  var list = [];
  for (var i = 0; i < UNITS.length; i++) {
    for (var j = 0; j < UNITS[i].words.length; j++) { list.push(UNITS[i].words[j]); }
  }
  return list;
}

function findWord(hz) {
  var all = allWords();
  for (var i = 0; i < all.length; i++) { if (all[i].hz === hz) return all[i]; }
  return null;
}

function setNav(id) {
  var ids = ["learn","review","listen","practice","stats"];
  for (var i = 0; i < ids.length; i++) {
    document.getElementById("n-" + ids[i]).className = (ids[i] === id) ? "on" : "";
  }
}

function soon(name) {
  setNav(name.toLowerCase());
  document.getElementById("t").textContent = name;
  document.getElementById("app").innerHTML = '' + name + ' is coming in a later stage.';
}

function showHome() {
  setNav("learn");
  document.getElementById("t").textContent = "HSK 3 Units";
  var html = "";
  for (var i = 0; i < UNITS.length; i++) {
    var u = UNITS[i], done = 0;
    for (var j = 0; j < u.words.length; j++) { if (progress[u.words[j].hz]) done++; }
    var pct = u.words.length ? Math.round(100 * done / u.words.length) : 0;
    html += ' Unit ' + u.id + ' (' + done + '/' + u.words.length + ')';
  }
  document.getElementById("app").innerHTML = html;
}

function showUnit(id) {
  setNav("learn");
  var u = UNITS[id - 1];
  document.getElementById("t").textContent = "Unit " + id;
  var html = '';
  for (var j = 0; j < u.words.length; j++) {
    var w = u.words[j];
    html += '' + w.hz + '' + w.py + '' + w.en + ' (' + w.pos + ')' + w.ex + '' + w.exPy + '' + w.exEn + '';
  }
  document.getElementById("app").innerHTML = html;
}

function toggle(j, id) {
  var hz = UNITS[id - 1].words[j].hz;
  progress[hz] = !progress[hz];
  if (progress[hz] && !cards[hz]) { cards[hz] = { due: today(), interval: 0, ease: 2.5 }; }
  saveAll();
  showUnit(id);
}

// ===== END OF PART 1. Part 2 goes directly below this line. =====
// ---------------- REVIEW: spaced repetition ----------------
var queue = [], current = null, flipped = false;

function dueList() {
  var list = [], t = today();
  for (var hz in cards) {
    if (cards.hasOwnProperty(hz) && cards[hz].due <= t && findWord(hz)) { list.push(hz); }
  }
  return list;
}

function showReview() {
  setNav("review");
  document.getElementById("t").textContent = "Review";
  var due = dueList();
  var total = 0; for (var k in cards) { if (cards.hasOwnProperty(k)) total++; }
  var html = '' + due.length + ' cards due today (' + total + ' in your deck)';
  html += ' Show on the front:';
  if (due.length > 0) {
    html += '';
  } else if (total === 0) {
    html += ' Your deck is empty. In Learn, open a unit and tap Mark as learned on some words to add them.';
  } else {
    html += ' All done for today. Come back tomorrow.';
  }
  document.getElementById("app").innerHTML = html;
}

function setFront(f) { settings.front = f; saveAll(); showReview(); }

function startReview() {
  queue = dueList();
  nextCard();
}

function nextCard() {
  if (queue.length === 0) { showReview(); return; }
  current = queue[0];
  flipped = false;
  drawCard();
}

function drawCard() {
  var w = findWord(current);
  var f = settings.front;
  var frontText = (f === "hz") ? w.hz : (f === "py") ? w.py : w.en;
  var html = '' + queue.length + ' left in this session';
  html += '' + frontText + '';
  if (!flipped) {
    html += ' Tap the card to see the answer';
  } else {
    html += '' + w.hz + '' + w.py + '' + w.en + '' + w.ex + '' + w.exPy + '' + w.exEn + '';
    html += '';
  }
  document.getElementById("app").innerHTML = html;
}

function flip() { if (!flipped) { flipped = true; drawCard(); } }

// Simple scheduling: Again = see again soon, others grow the gap
function rate(r) {
  var c = cards[current];
  if (r === 0) {
    c.interval = 0; c.ease = Math.max(1.3, c.ease - 0.2); c.due = today();
    queue.push(queue.shift());
  } else {
    if (r === 1) { c.interval = Math.max(1, Math.round((c.interval || 1) * 1.2)); c.ease = Math.max(1.3, c.ease - 0.15); }
    if (r === 2) { c.interval = c.interval ? Math.round(c.interval * c.ease) : 1; }
    if (r === 3) { c.interval = c.interval ? Math.round(c.interval * c.ease * 1.4) : 3; c.ease = c.ease + 0.15; }
    c.due = today() + c.interval;
    queue.shift();
  }
  saveAll();
  nextCard();
}

showHome();
``


