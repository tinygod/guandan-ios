let pageHTML = #"""
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>GuanDan! — Web Table</title>
<style>
  body { margin:0; background:radial-gradient(ellipse at center,#125248,#0D3B34 60%,#092A25);
         font-family:-apple-system,system-ui,sans-serif; color:#fff; height:100vh; overflow:hidden; }
  #top { text-align:center; padding:6px; }
  .plaque { display:inline-block; border:1px solid #d4af5e; background:rgba(0,0,0,.45);
            border-radius:10px; padding:2px 16px; color:#efd9a0; }
  .plaque small { display:block; font-size:9px; letter-spacing:2px; color:#d4af5e; }
  #table { display:flex; justify-content:space-between; align-items:flex-start; padding:0 16px; height:200px; }
  .seat { text-align:center; width:230px; }
  .avatar { width:44px;height:44px;border-radius:50%;background:#b34b42;display:inline-flex;
            align-items:center;justify-content:center;font-weight:800;font-size:18px; }
  .avatar.team { background:#125248; }
  .avatar.turn { box-shadow:0 0 0 3px #d4af5e; }
  .cnt { font-size:11px;background:rgba(0,0,0,.4);border-radius:8px;padding:1px 8px; }
  .play { min-height:64px; margin-top:4px; }
  .play .label { font-size:9px;font-weight:900;background:#d4af5e;color:#1a1b18;
                 border-radius:8px;padding:1px 6px; }
  .passchip { font-size:12px;color:#8fc4ba;background:rgba(0,0,0,.35);
              border-radius:10px;padding:2px 10px; }
  #centre { text-align:center; }
  #pills { margin-top:8px; height:48px; }
  #pills button { font-size:17px;font-weight:700;color:#fff;border:0;border-radius:24px;
                  padding:10px 30px;margin:0 8px;cursor:pointer; }
  #passB { background:#125248; } #hintB { background:#125248; }
  #playB { background:#e85d4e; } #playB:disabled { opacity:.35; }
  .card { display:inline-block; position:relative; background:#fefdfa; color:#1a1b18;
          border-radius:7px; border:1px solid rgba(0,0,0,.18);
          box-shadow:0 2px 4px rgba(0,0,0,.3); vertical-align:bottom; }
  .card.red { color:#a8281f; }
  .card .ix { position:absolute; top:2px; left:5px; font-weight:900; white-space:nowrap; }
  .card .pip { position:absolute; bottom:6%; width:100%; text-align:center; }
  .card.sel { filter:brightness(.72); }
  .card .wildtag { position:absolute; bottom:4px; left:3px; background:#e85d4e; color:#fff;
                   font-size:8px; font-weight:900; border-radius:6px; padding:0 4px; }
  #hand { position:fixed; bottom:-18px; left:0; right:0; display:flex;
          justify-content:center; align-items:flex-end; }
  .col { position:relative; }
  #msg { position:fixed; bottom:170px; width:100%; text-align:center;
         color:#efd9a0; font-size:14px; pointer-events:none; }
  #result { position:fixed; inset:0; background:rgba(0,0,0,.65); display:none;
            align-items:center; justify-content:center; }
  #result .panel { background:#0D3B34; border:1px solid rgba(255,255,255,.2);
                   border-radius:20px; padding:24px 36px; text-align:center; }
  #result button { font-size:16px;font-weight:700;color:#fff;background:#e85d4e;border:0;
                   border-radius:20px;padding:10px 28px;margin-top:14px;cursor:pointer; }
  #feedback { position:fixed; top:8px; right:10px; font-size:11px; color:#8fc4ba; }
</style>
</head>
<body>
<div id="top">
  <div class="plaque"><small>CURRENT LEVEL</small><b id="lvl">–</b>
  <small id="teams">us – · them –</small></div>
</div>
<div id="table">
  <div class="seat" id="seat-west"></div>
  <div class="seat" style="flex:1">
    <div id="seat-north"></div>
    <div id="centre">
      <div class="play" id="yourPlay"></div>
      <div id="pills">
        <button id="passB" onclick="act('pass')">Pass</button>
        <button id="hintB" onclick="hint()">Hint 💡</button>
        <button id="playB" onclick="playSel()">Play ▸</button>
      </div>
    </div>
  </div>
  <div class="seat" id="seat-east"></div>
</div>
<div id="msg"></div>
<div id="hand"></div>
<div id="result"><div class="panel" id="resultPanel"></div></div>
<div id="feedback">engine = iOS app · bots: Lena🔥 charger / Coach Wu balanced / Marco🧊 controller</div>
<script>
let sel = new Set();
let lastHandKey = "";

function cardDiv(c, w, clickable) {
  const d = document.createElement('div');
  d.className = 'card' + (c.red ? ' red' : '') + (sel.has(c.id) ? ' sel' : '');
  d.style.width = w + 'px'; d.style.height = (w * 1.4) + 'px';
  const ixSize = Math.round(w * .34);
  if (c.suit === '🃏') {
    d.innerHTML = `<div class="ix" style="font-size:${Math.round(w*.2)}px;writing-mode:vertical-lr;letter-spacing:1px;">JOKER</div>
                   <div class="pip" style="font-size:${Math.round(w*.4)}px">🃏</div>`;
  } else {
    d.innerHTML = `<div class="ix" style="font-size:${ixSize}px">${c.rank}<span style="font-size:${Math.round(ixSize*.75)}px"> ${c.suit}</span></div>
                   <div class="pip" style="font-size:${Math.round(w*.42)}px">${c.suit}</div>`;
  }
  if (c.wild) d.innerHTML += '<div class="wildtag">WILD</div>';
  if (clickable) d.onclick = () => { sel.has(c.id) ? sel.delete(c.id) : sel.add(c.id); render(); };
  return d;
}

let lastState = null;
function render() {
  if (!lastState) return;
  const s = lastState;
  document.getElementById('lvl').textContent = s.level + 's';
  document.getElementById('teams').textContent = `us ${s.usLevel}s · them ${s.themLevel}s`;

  for (const k of ['north','east','west']) {
    const seat = s.seats[k];
    const el = document.getElementById('seat-' + k);
    el.innerHTML = `<span class="avatar team ${seat.turn?'turn':''}">${seat.name[0]}</span>
      <div style="font-size:11px;color:#8fc4ba">${seat.name} <span class="cnt">${seat.count}</span></div>
      <div class="play" id="play-${k}"></div>`;
    renderPlay(document.getElementById('play-' + k), seat.play);
  }
  renderPlay(document.getElementById('yourPlay'), s.yourPlay,
             s.tribute || (s.yourTurn && !s.mayPass ? 'Your lead — play anything' : ''));

  document.getElementById('pills').style.visibility = s.yourTurn ? 'visible' : 'hidden';
  document.getElementById('passB').style.display = s.mayPass ? '' : 'none';
  document.getElementById('playB').disabled = sel.size === 0;

  // hand
  const hand = document.getElementById('hand');
  const key = s.hand.map(c => c.id).join(',') + [...sel].join('|');
  if (key !== lastHandKey) {
    lastHandKey = key;
    hand.innerHTML = '';
    // group by rank into columns
    const cols = [];
    for (const c of s.hand) {
      const last = cols[cols.length - 1];
      const groupKey = c.wild ? 'wild' : c.rank + (c.suit === '🃏' ? c.big : '');
      if (last && last.key === groupKey) last.cards.push(c);
      else cols.push({ key: groupKey, cards: [c] });
    }
    const maxStack = Math.max(...cols.map(c => c.cards.length), 1);
    const w = Math.min(72, Math.max(34,
      Math.min(window.innerWidth * 0.96 / (cols.length * 0.92),
               150 / (1.4 + 0.4 * (maxStack - 1)) * 1.0 )));
    const step = w * 0.42;
    for (const col of cols) {
      const cd = document.createElement('div');
      cd.className = 'col';
      cd.style.width = (w * 0.92) + 'px';
      cd.style.height = (w * 1.4 + (col.cards.length - 1) * step) + 'px';
      col.cards.forEach((c, i) => {
        const el = cardDiv(c, w, true);
        el.style.position = 'absolute';
        el.style.bottom = ((col.cards.length - 1 - i) * step) + 'px';
        el.style.zIndex = i + 1;
        cd.appendChild(el);
      });
      hand.appendChild(cd);
    }
  }

  // result
  const r = document.getElementById('result');
  if (s.result) {
    r.style.display = 'flex';
    const medals = ['🥇','🥈','🥉','4th'];
    let html = `<h2>${s.result.teams[0] === 'us' ? 'Round Won! 🎉' : 'Round Lost'}</h2>`;
    if (s.result.matchOver) html = `<h2>${s.result.matchWinner === 'us' ? 'MATCH WON! 🏆' : 'Match Lost'}</h2>`;
    s.result.order.forEach((n, i) => {
      html += `<div style="margin:4px;font-size:15px">${medals[i]} ${n}
               <span style="color:${s.result.teams[i]==='us'?'#efd9a0':'#8fc4ba'};font-size:12px">
               ${s.result.teams[i]==='us'?'your team':'opponents'}</span></div>`;
    });
    html += `<button onclick="act('next')">${s.result.matchOver ? 'New Match' : 'Next Hand'}</button>`;
    document.getElementById('resultPanel').innerHTML = html;
  } else r.style.display = 'none';
}

function renderPlay(el, play, fallback) {
  if (!el) return;
  if (play && play.cards) {
    el.innerHTML = '';
    play.cards.forEach(c => el.appendChild(cardDiv(c, 34, false)));
    el.innerHTML += ` <span class="label">${play.label}</span>`;
  } else if (play && play.pass) {
    el.innerHTML = '<span class="passchip">Pass</span>';
  } else {
    el.innerHTML = fallback ? `<span style="color:#8fc4ba;font-size:13px">${fallback}</span>` : '';
  }
}

async function poll() {
  try {
    const s = await (await fetch('/state')).json();
    lastState = s;
    render();
  } catch (e) {}
  setTimeout(poll, 600);
}
async function act(p) {
  sel.clear(); lastHandKey = '';
  const r = await (await fetch('/' + p, { method: 'POST' })).json();
  if (r.error) flash(r.error);
}
async function playSel() {
  const r = await (await fetch('/play', { method: 'POST',
    body: JSON.stringify({ ids: [...sel] }) })).json();
  if (r.error) flash(r.error); else { sel.clear(); lastHandKey = ''; }
}
async function hint() {
  const r = await (await fetch('/hint')).json();
  sel = new Set(r.ids); lastHandKey = ''; render();
}
function flash(t) {
  const m = document.getElementById('msg');
  m.textContent = t; setTimeout(() => { if (m.textContent === t) m.textContent = ''; }, 1800);
}
poll();
</script>
</body>
</html>
"""#
