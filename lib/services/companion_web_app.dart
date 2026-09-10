class CompanionWebApp {
  static const String htmlContent = '''
<!DOCTYPE html>
<html lang="id">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <title>Poker Companion Controller</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; user-select: none; -webkit-user-select: none; }
    body { background-color: #0d1317; color: #f1f5f9; height: 100vh; display: flex; flex-direction: column; padding: 12px; overflow: hidden; }
    
    /* Header */
    .header { display: flex; justify-content: space-between; align-items: center; background: #16222a; padding: 10px 14px; border-radius: 14px; border: 1px solid #2c3e50; }
    .player-select { background: #1e2e38; color: #fff; border: 1px solid #10b981; padding: 6px 10px; border-radius: 8px; font-weight: bold; font-size: 14px; }
    .status-badge { display: flex; align-items: center; gap: 6px; font-size: 11px; color: #94a3b8; font-weight: 600; }
    .dot { width: 8px; height: 8px; border-radius: 50%; background: #ef5350; }
    .dot.connected { background: #10b981; box-shadow: 0 0 8px #10b981; }

    /* Chips info */
    .chip-info { margin-top: 10px; display: flex; justify-content: space-between; background: #16222a; padding: 10px 14px; border-radius: 12px; border: 1px solid #2c3e50; }
    .chip-val { font-size: 18px; font-weight: 900; color: #ffc107; }
    .pot-val { font-size: 14px; font-weight: bold; color: #10b981; }

    /* Cards Secret Section */
    .cards-section { flex: 1; margin: 12px 0; background: radial-gradient(circle, #0e4d34 0%, #072e1f 100%); border-radius: 18px; border: 4px solid #2e1c14; display: flex; flex-direction: column; align-items: center; justify-content: center; position: relative; overflow: hidden; box-shadow: inset 0 0 20px rgba(0,0,0,0.8); }
    .privacy-shield { position: absolute; inset: 0; background: rgba(13, 19, 23, 0.96); display: flex; flex-direction: column; align-items: center; justify-content: center; z-index: 10; border-radius: 14px; transition: opacity 0.2s ease; cursor: pointer; }
    .privacy-shield.peeking { opacity: 0; pointer-events: none; }
    .shield-icon { font-size: 40px; margin-bottom: 8px; }
    .shield-text { font-size: 13px; font-weight: bold; color: #ffc107; text-align: center; padding: 0 20px; }

    .cards-container { display: flex; gap: 12px; }
    .card { width: 90px; height: 130px; background: #fafafa; border-radius: 10px; border: 2px solid #cbd5e1; display: flex; flex-direction: column; justify-content: space-between; padding: 8px; box-shadow: 0 8px 16px rgba(0,0,0,0.5); font-weight: 900; position: relative; }
    .card.red { color: #dc2626; }
    .card.black { color: #1e293b; }
    .card-corner { font-size: 20px; line-height: 1; }
    .card-suit { font-size: 18px; }
    .card-center { position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%); font-size: 44px; opacity: 0.85; }

    /* Community Cards Preview */
    .community-bar { display: flex; gap: 6px; margin-top: 10px; }
    .mini-card { width: 32px; height: 46px; background: #1e2e38; border: 1px solid #2c3e50; border-radius: 5px; display: flex; align-items: center; justify-content: center; font-size: 12px; font-weight: bold; }
    .mini-card.filled { background: #fff; border-color: #cbd5e1; }

    /* Actions Dock */
    .turn-banner { font-size: 13px; font-weight: 900; text-align: center; color: #ffc107; margin-bottom: 8px; letter-spacing: 1px; }
    .turn-banner.active { color: #10b981; animation: pulse 1.2s infinite; }
    @keyframes pulse { 0%, 100% { opacity: 1; } 50% { opacity: 0.4; } }

    .actions-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 8px; margin-top: 4px; }
    .btn { padding: 14px; border-radius: 12px; border: none; font-weight: 900; font-size: 14px; color: #fff; cursor: pointer; transition: transform 0.1s; display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 2px; }
    .btn:active { transform: scale(0.96); }
    .btn:disabled { opacity: 0.35; cursor: not-allowed; }
    .btn-fold { background: #e53935; }
    .btn-check { background: #0288d1; }
    .btn-call { background: #2e7d32; }
    .btn-raise { background: #f57c00; grid-column: span 2; }
    .btn-allin { background: #8e24aa; grid-column: span 2; }

    .raise-controls { display: flex; flex-direction: column; gap: 6px; margin-top: 6px; background: #16222a; padding: 10px; border-radius: 12px; border: 1px solid #f57c00; }
    .raise-slider { width: 100%; accent-color: #f57c00; }
    .raise-val { text-align: center; font-weight: bold; color: #ffc107; font-size: 15px; }
  </style>
</head>
<body>

  <!-- Header -->
  <div class="header">
    <select id="playerSelect" class="player-select" onchange="onPlayerChanged()">
      <option value="">-- Pilih Pemain --</option>
      <option value="host">👑 Bandar / Host Game (Spectator)</option>
    </select>
    <button onclick="promptTopUp()" style="background:#10b981; color:#fff; border:none; padding:6px 10px; border-radius:8px; font-weight:bold; font-size:12px; cursor:pointer;">➕ Top-Up</button>
    <div class="status-badge">
      <div id="statusDot" class="dot"></div>
      <span id="statusText">Terhubung</span>
    </div>
  </div>

  <!-- Chip & Pot -->
  <div class="chip-info">
    <div>
      <div style="font-size: 10px; color: #94a3b8;">CHIP SAYA</div>
      <div id="myChips" class="chip-val">0</div>
    </div>
    <div style="text-align: right;">
      <div style="font-size: 10px; color: #94a3b8;">TOTAL POT / BET</div>
      <div id="totalPot" class="pot-val">Pot: 0 | Bet: 0</div>
    </div>
  </div>

  <!-- Secret Cards Area -->
  <div class="cards-section">
    <button onclick="togglePrivacy()" style="position: absolute; top: 8px; right: 8px; z-index: 20; background: rgba(0,0,0,0.6); border: 1px solid #ffc107; color: #ffc107; border-radius: 6px; padding: 4px 8px; font-size: 11px; font-weight: bold; cursor: pointer;">👁️ Toggle</button>

    <div id="privacyShield" class="privacy-shield peeking" onclick="togglePrivacy()">
      <div class="shield-icon">🙈</div>
      <div class="shield-text">TEKAN UNTUK MEMBUKA KARTU SAKU</div>
    </div>

    <div id="cardsContainer" class="cards-container">
      <div class="card black"><div class="card-corner">?</div></div>
      <div class="card black"><div class="card-corner">?</div></div>
    </div>

    <div id="communityBar" class="community-bar"></div>
  </div>


  <!-- Action Controls -->
  <div>
    <div id="turnBanner" class="turn-banner">Menunggu giliran...</div>

    <div class="actions-grid">
      <button id="btnFold" class="btn btn-fold" onclick="sendAction('fold')" disabled>FOLD</button>
      <button id="btnCheckCall" class="btn btn-check" onclick="sendCheckOrCall()" disabled>CHECK</button>
      
      <div id="raiseBox" class="raise-controls" style="display: none; grid-column: span 2;">
        <div id="raiseValueText" class="raise-val">Raise: 0</div>
        <input type="range" id="raiseSlider" class="raise-slider" oninput="updateRaiseLabel()">
        <div style="display: flex; gap: 4px;">
          <button class="btn btn-raise" style="padding: 8px;" onclick="confirmRaise()">KONFIRMASI RAISE</button>
          <button class="btn btn-fold" style="padding: 8px; width: 60px;" onclick="toggleRaiseBox(false)">❌</button>
        </div>
      </div>

      <button id="btnRaiseOpen" class="btn btn-raise" onclick="toggleRaiseBox(true)" disabled>RAISE / BET</button>
      <button id="btnAllIn" class="btn btn-allin" onclick="sendAction('allIn')" disabled>ALL-IN</button>
    </div>
  </div>

  <script>
    let ws;
    let gameState = null;
    let selectedPlayerId = localStorage.getItem('selectedPlayerId') || '';

    function connect() {
      const loc = window.location;
      const wsUri = (loc.protocol === 'https:' ? 'wss://' : 'ws://') + loc.host + '/ws';
      ws = new WebSocket(wsUri);

      ws.onopen = () => {
        document.getElementById('statusDot').classList.add('connected');
        document.getElementById('statusText').innerText = 'Online';
        if (selectedPlayerId) {
          ws.send(JSON.stringify({ type: 'select_player', playerId: selectedPlayerId }));
        }
      };

      ws.onclose = () => {
        document.getElementById('statusDot').classList.remove('connected');
        document.getElementById('statusText').innerText = 'Offline';
        setTimeout(connect, 2000);
      };

      ws.onmessage = (evt) => {
        const msg = JSON.parse(evt.data);
        if (msg.type === 'state') {
          gameState = msg.state;
          renderState();
        }
      };
    }

    function promptTopUp() {
      if (!gameState || !gameState.players || gameState.players.length === 0) return;
      const playerList = gameState.players.map((p, i) => (i + 1) + '. ' + p.name + ' (' + p.chips + ' chip)').join('\n');
      const idxStr = prompt('Top-Up Chip Pemain:\nPilih nomor pemain (1-' + gameState.players.length + '):\n' + playerList, '1');
      if (!idxStr) return;
      const idx = parseInt(idxStr) - 1;
      if (isNaN(idx) || idx < 0 || idx >= gameState.players.length) {
        alert('Nomor pemain tidak valid!');
        return;
      }
      const targetPlayer = gameState.players[idx];
      const amtStr = prompt('Masukkan jumlah chip yang ingin ditambahkan untuk ' + targetPlayer.name + ':', '1000');
      if (!amtStr) return;
      const amt = parseInt(amtStr);
      if (isNaN(amt) || amt <= 0) {
        alert('Jumlah chip tidak valid!');
        return;
      }
      ws.send(JSON.stringify({ type: 'add_chips', targetPlayerId: targetPlayer.id, amount: amt }));
    }

    function renderState() {
      if (!gameState) return;

      // Render player dropdown
      const select = document.getElementById('playerSelect');
      select.innerHTML = '<option value="">-- Pilih Pemain --</option><option value="host">👑 Bandar / Host Game (Spectator)</option>';
      gameState.players.forEach(p => {
        if (p.isTakenByOther && p.id !== selectedPlayerId) return;
        const opt = document.createElement('option');
        opt.value = p.id;
        const roleStr = p.roleLabel || 'Player';
        opt.innerText = p.name + ' (' + p.chips + ' chip) - ' + roleStr;
        if (p.id === selectedPlayerId) opt.selected = true;
        select.appendChild(opt);
      });
      if (selectedPlayerId === 'host') {
        const optHost = select.querySelector('option[value="host"]');
        if (optHost) optHost.selected = true;
      }


      const me = gameState.players.find(p => p.id === selectedPlayerId);
      if (me) {
        document.getElementById('myChips').innerText = me.chips + ' chip';
        renderCards(me.holeCards);
      } else {
        document.getElementById('myChips').innerText = '0';
        renderCards([]);
      }

      document.getElementById('totalPot').innerText = 'Pot: ' + gameState.pot + ' | Bet: ' + gameState.currentBet;

      // Render Community Cards
      const commBox = document.getElementById('communityBar');
      commBox.innerHTML = '';
      (gameState.communityCards || []).forEach(c => {
        const div = document.createElement('div');
        div.className = 'mini-card filled';
        div.style.color = (c.suit === '♥' || c.suit === '♦') ? '#dc2626' : '#1e293b';
        div.innerText = c.rank + c.suit;
        commBox.appendChild(div);
      });

      // Render Action Dock
      const isLobby = gameState.street === 'lobby';
      const isMyTurn = me && gameState.currentTurnPlayerId === me.id && gameState.street !== 'showdown' && gameState.street !== 'handEnded' && !isLobby;
      const banner = document.getElementById('turnBanner');

      if (isLobby) {
        banner.innerText = '⏳ HP TERHUBUNG! Menunggu Host Memulai Game...';
        banner.classList.remove('active');
      } else if (isMyTurn) {
        banner.innerText = '🔴 GILIRAN ANDA BEAKSI!';
        banner.classList.add('active');
      } else {
        banner.innerText = 'Menunggu giliran ' + (gameState.currentTurnPlayerName || '') + '...';
        banner.classList.remove('active');
      }


      const btnFold = document.getElementById('btnFold');
      const btnCheckCall = document.getElementById('btnCheckCall');
      const btnRaiseOpen = document.getElementById('btnRaiseOpen');
      const btnAllIn = document.getElementById('btnAllIn');

      btnFold.disabled = !isMyTurn;
      btnCheckCall.disabled = !isMyTurn;
      btnRaiseOpen.disabled = !isMyTurn || (me && me.chips <= gameState.callAmount);
      btnAllIn.disabled = !isMyTurn || (me && me.chips === 0);

      if (isMyTurn && me) {
        const callAmt = gameState.callAmount;
        if (callAmt === 0 || me.currentRoundBet === gameState.currentBet) {
          btnCheckCall.className = 'btn btn-check';
          btnCheckCall.innerText = 'CHECK';
        } else {
          btnCheckCall.className = 'btn btn-call';
          btnCheckCall.innerText = 'CALL ' + Math.min(callAmt, me.chips);
        }

        // Setup slider bounds
        const slider = document.getElementById('raiseSlider');
        slider.min = gameState.minRaise;
        slider.max = gameState.maxRaise;
        slider.value = gameState.minRaise;
        updateRaiseLabel();
      }
    }

    function renderCards(cards) {
      const container = document.getElementById('cardsContainer');
      container.innerHTML = '';
      if (!cards || cards.length === 0) {
        container.innerHTML = '<div class="card black"><div class="card-corner">?</div></div><div class="card black"><div class="card-corner">?</div></div>';
        return;
      }
      cards.forEach(c => {
        const isRed = c.suit === '♥' || c.suit === '♦';
        const colorClass = isRed ? 'red' : 'black';
        const html = '<div class="card ' + colorClass + '"><div class="card-corner">' + c.rank + '<br>' + c.suit + '</div><div class="card-center">' + c.suit + '</div></div>';
        container.innerHTML += html;
      });
    }

    function togglePrivacy() {
      document.getElementById('privacyShield').classList.toggle('peeking');
    }


    function onPlayerChanged() {
      selectedPlayerId = document.getElementById('playerSelect').value;
      localStorage.setItem('selectedPlayerId', selectedPlayerId);
      if (ws && ws.readyState === WebSocket.OPEN) {
        ws.send(JSON.stringify({ type: 'select_player', playerId: selectedPlayerId }));
      }
      renderState();
    }

    function sendAction(actionType, extraData = {}) {
      if (!ws || ws.readyState !== WebSocket.OPEN) return;
      ws.send(JSON.stringify({
        type: 'action',
        playerId: selectedPlayerId,
        action: actionType,
        ...extraData
      }));
      toggleRaiseBox(false);
    }

    function sendCheckOrCall() {
      if (!gameState || !selectedPlayerId) return;
      const me = gameState.players.find(p => p.id === selectedPlayerId);
      if (gameState.callAmount === 0 || (me && me.currentRoundBet === gameState.currentBet)) {
        sendAction('check');
      } else {
        sendAction('call');
      }
    }

    function toggleRaiseBox(show) {
      document.getElementById('raiseBox').style.display = show ? 'flex' : 'none';
    }

    function updateRaiseLabel() {
      const val = document.getElementById('raiseSlider').value;
      document.getElementById('raiseValueText').innerText = 'Raise ke: ' + val + ' chip';
    }

    function confirmRaise() {
      const val = parseInt(document.getElementById('raiseSlider').value, 10);
      sendAction('raise', { amount: val });
    }

    connect();
  </script>
</body>
</html>
''';
}
