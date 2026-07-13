'use strict';

/* ========== 数据 ========== */
let NOTES = [
  {id:1,title:'拉格朗日中值定理',type:'概念',subject:'数学分析',chapter:'微分中值定理',conf:0.92,body:'## 定义\n若函数 f(x) 在闭区间 [a,b] 连续,开区间 (a,b) 可导,则存在 ξ∈(a,b) 使得 f′(ξ) = (f(b)-f(a))/(b-a)。',tags:['中值定理','导数'],date:'2026-07-05'},
  {id:2,title:'矩阵行列式计算',type:'计算',subject:'高等代数',chapter:'行列式',conf:0.88,body:'## 题目\n求 n 阶行列式 |A|，其中 a_{ij}=max(i,j)。\n\n## 解法\n利用行变换化为上三角形式。\n\n## 答案\n|A| = n·(-1)^{n-1}',tags:['行列式','矩阵'],date:'2026-07-04'},
  {id:3,title:'极限 ε-δ 定义',type:'概念',subject:'数学分析',chapter:'极限',conf:0.85,body:'## 定义\n对任意 ε>0,存在 δ>0,使得当 0<|x-a|<δ 时,|f(x)-L|<ε。\n\n## 性质\n唯一性、局部有界性、保号性。',tags:['极限','定义'],date:'2026-07-03'},
  {id:4,title:'空间直线方程',type:'计算',subject:'解析几何',chapter:'直线与平面',conf:0.78,body:'## 题目\n求过点(1,2,3)且平行于向量(2,-1,4)的直线方程。\n\n## 解法\n参数方程：x=1+2t, y=2-t, z=3+4t。',tags:['直线','参数方程'],date:'2026-07-02'},
  {id:5,title:'证明向量组线性无关',type:'证明',subject:'高等代数',chapter:'线性空间',conf:0.82,body:'## 命题\n设 α₁,α₂,α₃ 线性无关，证明 α₁+α₂, α₂+α₃, α₃+α₁ 也线性无关。\n\n## 证明\n设 k₁(α₁+α₂)+k₂(α₂+α₃)+k₃(α₃+α₁)=0，整理系数求解。',tags:['线性无关','向量组'],date:'2026-07-01'},
];
let selectedNote = null;

/* ========== Agent 配置 ========== */
const AGENT_URL = 'http://localhost:3000/api/agent/chat';
let sessionId = 's' + Date.now() + '-' + Math.random().toString(36).slice(2,8);

/* ========== 辅助 ========== */
const tc = t => ({'概念':'#22d3ee','计算':'#F0C674','证明':'#5BE3B0','笔记':'#5BE3B0'})[t]||'#a8a8b0';
const sc = s => ({'高等代数':'#9775FA','数学分析':'#FF6B9D','解析几何':'#fb923c'})[s]||'#a8a8b0';
const cc = v => v>0.8?'cd-hi':v>0.5?'cd-md':'cd-lo';
const ts = t => (t||'笔').charAt(0);
const esc = s => String(s).replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));

/* ========== Toast ========== */
const toast = (msg) => {
  const t = document.getElementById('toast');
  t.textContent = msg; t.classList.add('show');
  clearTimeout(t._timer);
  t._timer = setTimeout(() => t.classList.remove('show'), 2000);
};

/* ========== 时钟 ========== */
const tick = () => {
  const d = new Date();
  document.getElementById('sbTime').textContent = d.getHours().toString().padStart(2,'0')+':'+d.getMinutes().toString().padStart(2,'0');
};
tick(); setInterval(tick, 30000);

/* ========== 状态 ========== */
let currentPage = 'home';
let isLoggedIn = true;

/* ========== 页面导航 ========== */
function navigateTo(page) {
  if (currentPage === page) return;
  document.querySelectorAll('.page').forEach(p => p.classList.remove('active'));
  const el = document.getElementById('page-' + page);
  if (el) el.classList.add('active');
  document.querySelectorAll('.tab').forEach(t => t.classList.toggle('active', t.dataset.page === page));
  currentPage = page;
  document.getElementById('headerTitle').textContent =
    {home:'MathMind', notes:'全部笔记', review:'复习计划', me:'我的'}[page] || 'MathMind';
  if (page === 'home') updateHome();
  if (page === 'notes') renderNotesAll();
  if (page === 'review') {} // placeholder
  if (page === 'me') renderMyPage();
}

/* ========== 笔记页渲染 ========== */
function renderNotesAll() {
  const el = document.getElementById('allNotes');
  if (!el) return;
  el.innerHTML = NOTES.length
    ? NOTES.map(noteCardHTML).join('')
    : '<div style="text-align:center;padding:60px 20px;color:var(--text-3)">还没有笔记<br>试试 AI 对话或拍照吧 👇</div>';
}

/* ========== 我的页 + 登录 ========== */
function renderMyPage() {
  document.getElementById('statNotes2').textContent = NOTES.length;
  const avg = NOTES.length ? Math.round(NOTES.reduce((a,n)=>a+n.conf,0)/NOTES.length*100) : 0;
  document.getElementById('statMastered2').textContent = avg + '%';
  const today = new Date().getFullYear()+'-'+(new Date().getMonth()+1)+'-'+new Date().getDate();
  document.getElementById('statToday2').textContent = NOTES.filter(n=>n.date===today).length || '0';
  if (isLoggedIn) {
    document.getElementById('meName').textContent = 'Mini';
    document.getElementById('meEmail').textContent = '已登录 · 模拟账号';
    document.getElementById('meAvatar').textContent = 'M';
    document.getElementById('meLogoutBtn').style.display = 'block';
    document.getElementById('meLoginLabel').textContent = '切换账号';
    document.getElementById('meLoginRow').onclick = openLogin;
  } else {
    document.getElementById('meName').textContent = '未登录';
    document.getElementById('meEmail').textContent = '登录后可同步数据';
    document.getElementById('meAvatar').textContent = '?';
    document.getElementById('meLogoutBtn').style.display = 'none';
    document.getElementById('meLoginLabel').textContent = '登录';
    document.getElementById('meLoginRow').onclick = openLogin;
  }
}

function openLogin(){ document.getElementById('loginPage').classList.add('show'); }
function closeLogin(){ document.getElementById('loginPage').classList.remove('show'); }
function doLogin(){
  closeLogin();
  isLoggedIn = true;
  toast('✓ 模拟账号已登录');
  renderMyPage();
}
function confirmLogout(){
  if (!isLoggedIn) { toast('当前未登录'); return; }
  if (!confirm('确定要退出当前账号吗？')) return;
  isLoggedIn = false;
  toast('✓ 已退出登录');
  renderMyPage();
}

/* ========== 首页渲染 ========== */
function updateHome() {
  const h = new Date().getHours();
  const greet = h<6?'凌晨好':h<11?'上午好':h<13?'中午好':h<18?'下午好':'晚上好';
  document.getElementById('heroGreet').innerHTML = greet + ', <b>Mini</b>';
  const days = ['日','一','二','三','四','五','六'];
  const now = new Date();
  document.getElementById('heroDate').textContent = now.getFullYear()+'年'+(now.getMonth()+1)+'月'+now.getDate()+'日 · 周'+days[now.getDay()];
  document.getElementById('statNotes').textContent = NOTES.length;
  const avgConf = NOTES.length ? Math.round(NOTES.reduce((a,n)=>a+n.conf,0)/NOTES.length*100) : 0;
  document.getElementById('statMastered').textContent = avgConf + '%';
  const today = now.getFullYear()+'-'+(now.getMonth()+1)+'-'+now.getDate();
  document.getElementById('statToday').textContent = NOTES.filter(n=>n.date===today).length || '0';
  document.getElementById('progressDetail').textContent = `${Math.max(1,Math.round(NOTES.length*0.7))} 条`;
  document.getElementById('reminderCount'); // not used in MVP
  // 进度环动画
  const target = avgConf || 75;
  const current = parseInt(document.getElementById('progressText').textContent) || 0;
  animateNumber(document.getElementById('progressText'), current, target, 800, '%');
  const c = 326.7, offset = c * (1 - target/100);
  document.getElementById('progressCircle').style.strokeDashoffset = offset;
  updateReminder();
  renderHomeNotes();
}

function updateReminder() {
  const r = document.getElementById('homeReminder');
  if (!r) return;
  if (NOTES.length === 0) {
    r.classList.add('show');
    r.innerHTML = '👋 欢迎使用 MathMind！试试 AI 对话或拍照，帮你整理知识笔记 ›';
    r.onclick = () => openAIOverlay();
  } else if (NOTES.length < 3) {
    r.classList.add('show');
    r.innerHTML = `⏰ 已有 ${NOTES.length} 条笔记，继续用 AI 充实知识库 ›`;
    r.onclick = () => openAIOverlay();
  } else {
    r.classList.remove('show');
  }
}

// 数字滚动动画
function animateNumber(el, from, to, duration=800, suffix='') {
  const start = performance.now();
  const step = (now) => {
    const t = Math.min(1, (now - start) / duration);
    const eased = 1 - Math.pow(1 - t, 3);
    el.textContent = Math.round(from + (to - from) * eased) + suffix;
    if (t < 1) requestAnimationFrame(step);
  };
  requestAnimationFrame(step);
}

function noteCardHTML(n) {
  return `<div class="note-card" onclick="openNote(${n.id})">
    <div class="note-icon" style="background:linear-gradient(135deg,${tc(n.type)},${sc(n.subject||'')})">${ts(n.type)}</div>
    <div class="note-info">
      <div class="note-meta">
        <span class="nm-subject" style="color:${sc(n.subject||'')}">${n.subject||''}</span>
        <span class="nm-type" style="color:${tc(n.type)}">${n.type}</span>
        <span>${n.date} <span class="cd ${cc(n.conf)}"></span> ${Math.round(n.conf*100)}%</span>
      </div>
      <div class="note-title">${esc(n.title)}</div>
      <div class="note-body">${esc((n.body||'').replace(/^## .+$/gm,'').slice(0,60).trim())}${(n.body||'').length>60?'…':''}</div>
    </div>
  </div>`;
}

function renderHomeNotes() {
  const el = document.getElementById('homeNotes');
  if (!el) return;
  el.innerHTML = NOTES.length
    ? NOTES.map(noteCardHTML).join('')
    : '<div style="text-align:center;padding:60px 20px;color:var(--text-3)">还没有笔记<br>试试 AI 对话或拍照吧 👇</div>';
}

/* ========== 笔记详情 ========== */
function openNote(id) {
  selectedNote = NOTES.find(n => n.id===id);
  if (!selectedNote) return;
  document.getElementById('detailBody').innerHTML = detailHTML(selectedNote);
  document.getElementById('detailOverlay').classList.add('show');
}
function closeDetail(){ document.getElementById('detailOverlay').classList.remove('show'); }
document.getElementById('detailBack').addEventListener('click', closeDetail);

function renderBody(text) {
  return text.split('\n').map(line => {
    if (/^## (.+)$/.test(line)) return '<h3 class="dh3">' + esc(line.replace(/^## /, '')) + '</h3>';
    return esc(line) || '<br>';
  }).join('\n');
}

const detailHTML = (n) => `
    <div class="dfolder" style="color:${sc(n.subject||'')}">${n.subject||''} · ${n.type} · ${n.chapter||''} · 置信度 ${n.conf>0.8?'高':n.conf>0.5?'中':'低'}</div>
    <div class="dtitle">${esc(n.title)}</div>
    <div class="dmeta">
      <span>学科 <b style="color:${sc(n.subject||'')}">${n.subject||''}</b></span>
      <span>类型 <b style="color:${tc(n.type)}">${n.type}</b></span>
      <span>置信度 <span class="cd ${cc(n.conf)}"></span> <b class="num">${Math.round(n.conf*100)}%</b></span>
      <span>${n.date||''}</span>
    </div>
    <div class="dbody">${renderBody(n.body||'')}</div>
    <div class="dtags">${(n.tags||[]).map(t => `<span>#${esc(t)}</span>`).join('')}</div>
    <div class="ai-card">
      <div class="ai-card-title">✦ AI 分析</div>
      <div class="ai-card-body">${n.conf>0.8?'掌握良好，可降级复习频率。':n.conf>0.5?'建议结合同类例题巩固。':'置信度较低，建议优先复习。'}</div>
    </div>
  `;

/* ========== AI 浮层 ========== */
function openAIOverlay(){
  document.getElementById('aiOverlay').classList.add('show');
  setTimeout(()=>document.getElementById('aiInput').focus(),200);
}
function closeAIOverlay(){
  document.getElementById('aiOverlay').classList.remove('show');
}
document.getElementById('aiClose').addEventListener('click', closeAIOverlay);

// 快捷提问
document.getElementById('aiSug').addEventListener('click', e => {
  if (e.target.classList.contains('as')) {
    document.getElementById('aiInput').value = e.target.dataset.q;
    sendToAgent();
  }
});

// 发送按钮 + 回车
document.getElementById('aiSend').addEventListener('click', () => sendToAgent());
document.getElementById('aiInput').addEventListener('keydown', e => {
  if (e.key==='Enter') sendToAgent();
});

// 拍照按钮唤起相机
document.getElementById('aiPhotoBtn').addEventListener('click', openCamera);

async function sendToAgent() {
  const input = document.getElementById('aiInput');
  const text = input.value.trim();
  if (!text) return;
  input.value = '';

  const body = document.getElementById('aiBody');

  // 用户消息
  body.insertAdjacentHTML('beforeend', `<div class="ai-msg user">${esc(text)}</div>`);

  // Loading
  const loadingId = 'ld-'+Date.now();
  body.insertAdjacentHTML('beforeend', `<div class="ai-msg ai" id="${loadingId}"><div class="loading-dots"><span></span><span></span><span></span></div></div>`);
  body.scrollTop = body.scrollHeight;

  try {
    const res = await fetch(AGENT_URL, {
      method: 'POST',
      headers: {'Content-Type':'application/json'},
      body: JSON.stringify({ sessionId, message: text })
    });
    const data = await res.json();

    // 移除 loading
    const ld = document.getElementById(loadingId);
    if (ld) ld.remove();

    // Agent 回复 + 笔记卡片
    let html = `<div class="ai-msg ai">${esc(data.reply||'收到你的消息，我来分析一下。')}`;
    if (data.notes && data.notes.length) {
      data.notes.forEach(n => {
        n.id = n.id || Date.now() + Math.random();
        html += `<div class="note-mini" onclick="saveAgentNote(${JSON.stringify(esc(JSON.stringify(n)))})">
          <div style="font-weight:600;margin-bottom:2px">📝 ${esc(n.title)}</div>
          <div style="font-size:11px;color:var(--text-3)">${esc(n.type||'笔记')} · ${(n.tags||[]).join(', ')}</div>
          <div style="font-size:10px;color:var(--mint);margin-top:4px">点击保存到笔记</div>
        </div>`;
      });
    }
    html += '</div>';
    body.insertAdjacentHTML('beforeend', html);
  } catch(e) {
    const ld = document.getElementById(loadingId);
    if (ld) ld.remove();
    // 离线兜底：关键词回复
    const lq = text.toLowerCase();
    let reply = '';
    if (lq.includes('分析')||lq.includes('题')) reply = '这道题考察核心概念的灵活运用。建议先理清题干条件，再匹配对应的定理或公式。需要我展开讲吗？';
    else if (lq.includes('总结')||lq.includes('知识')) reply = '基于你的笔记，核心知识体系如下：极限 → 中值定理 → 导数 → 积分。当前需要巩固的板块是积分。';
    else if (lq.includes('练习')||lq.includes('题')) reply = '为你生成 3 道练习题：\n1. 求 lim(x→0)(1-cosx)/x²\n2. 用罗尔定理证明 f(x)=x³-3x 在 [0,2] 上的性质\n3. 判断级数 ∑1/n² 的收敛性';
    else if (lq.includes('路径')||lq.includes('推荐')) reply = '推荐学习路径：1.极限基础 → 2.中值定理 → 3.导数应用 → 4.积分计算。当前建议重点复习积分。';
    else reply = '收到！你可以试试问我：分析题目、总结知识、出练习题、推荐学习路径。也支持拍照识别哦 📷';
    body.insertAdjacentHTML('beforeend', `<div class="ai-msg ai">${reply}</div>`);
  }
  body.scrollTop = body.scrollHeight;
}

function saveAgentNote(jsonStr) {
  try {
    const data = JSON.parse(jsonStr.replace(/&amp;/g,'&').replace(/&lt;/g,'<').replace(/&gt;/g,'>').replace(/&quot;/g,'"').replace(/&#39;/g,"'"));
    const now = new Date();
    const dateStr = now.getFullYear()+'-'+(now.getMonth()+1)+'-'+now.getDate();
    const newId = Math.max(0, ...NOTES.map(n=>n.id)) + 1;
    NOTES.unshift({
      id: newId,
      title: data.title,
      type: data.type||'笔记',
      subject: data.subject||'',
      chapter: data.chapter||'',
      conf: 0.75,
      body: data.body||'',
      tags: data.tags||[],
      date: dateStr
    });
    renderHomeNotes();
    updateHome();
    toast('✓ 笔记已保存');
  } catch(e) {
    toast('保存失败，请重试');
  }
}

/* ========== 相机 ========== */
let cameraStream = null;
let capturedImage = null;

async function openCamera() {
  closeAIOverlay();
  try {
    cameraStream = await navigator.mediaDevices.getUserMedia({
      video: { facingMode: 'environment', width: { ideal: 1920 }, height: { ideal: 1080 } },
      audio: false
    });
    const video = document.getElementById('camVideo');
    video.srcObject = cameraStream;
    document.getElementById('camOverlay').classList.add('show');
  } catch(e) {
    toast('无法访问相机，请检查权限');
    // 降级：直接打开 AI 输入
    openAIOverlay();
  }
}

function closeCamera() {
  if (cameraStream) {
    cameraStream.getTracks().forEach(t => t.stop());
    cameraStream = null;
  }
  document.getElementById('camOverlay').classList.remove('show');
  retakePhoto();
}

function switchCamera() {
  if (!cameraStream) return;
  const track = cameraStream.getVideoTracks()[0];
  if (!track) return;
  const facing = track.getSettings().facingMode;
  const newFacing = facing === 'environment' ? 'user' : 'environment';
  track.stop();
  navigator.mediaDevices.getUserMedia({ video: { facingMode: newFacing } })
    .then(s => {
      cameraStream = s;
      document.getElementById('camVideo').srcObject = s;
    })
    .catch(() => toast('切换失败'));
}

function takePhoto() {
  const video = document.getElementById('camVideo');
  const canvas = document.getElementById('camCanvas');
  canvas.width = video.videoWidth;
  canvas.height = video.videoHeight;
  canvas.getContext('2d').drawImage(video, 0, 0);
  capturedImage = canvas.toDataURL('image/jpeg', 0.9);
  document.getElementById('camHint').classList.add('done');
  document.getElementById('camShutter').classList.add('hidden');
  document.getElementById('camRetake').classList.add('show');
  document.getElementById('camConfirm').classList.add('show');
}

function retakePhoto() {
  capturedImage = null;
  document.getElementById('camHint').classList.remove('done');
  document.getElementById('camShutter').classList.remove('hidden');
  document.getElementById('camRetake').classList.remove('show');
  document.getElementById('camConfirm').classList.remove('show');
}

async function confirmPhoto() {
  if (!capturedImage) return;
  closeCamera();
  openAIOverlay();

  const body = document.getElementById('aiBody');
  body.insertAdjacentHTML('beforeend', `<div class="ai-msg user">📷 <i>已发送照片</i></div>`);
  const loadingId = 'ld-'+Date.now();
  body.insertAdjacentHTML('beforeend', `<div class="ai-msg ai" id="${loadingId}"><div class="loading-dots"><span></span><span></span><span></span></div></div>`);
  body.scrollTop = body.scrollHeight;

  try {
    const res = await fetch(AGENT_URL, {
      method: 'POST',
      headers: {'Content-Type':'application/json'},
      body: JSON.stringify({ sessionId, message: '请分析这张照片中的题目', images: [capturedImage] })
    });
    const data = await res.json();
    const ld = document.getElementById(loadingId);
    if (ld) ld.remove();

    let html = `<div class="ai-msg ai">${esc(data.reply||'收到照片，正在分析中...')}`;
    if (data.notes && data.notes.length) {
      data.notes.forEach(n => {
        n.id = Date.now() + Math.random();
        html += `<div class="note-mini" onclick="saveAgentNote(${JSON.stringify(esc(JSON.stringify(n)))})">
          <div style="font-weight:600;margin-bottom:2px">📝 ${esc(n.title)}</div>
          <div style="font-size:11px;color:var(--text-3)">${esc(n.type||'笔记')} · ${(n.tags||[]).join(', ')}</div>
          <div style="font-size:10px;color:var(--mint);margin-top:4px">点击保存到笔记</div>
        </div>`;
      });
    }
    html += '</div>';
    body.insertAdjacentHTML('beforeend', html);
  } catch(e) {
    const ld = document.getElementById(loadingId);
    if (ld) ld.remove();
    body.insertAdjacentHTML('beforeend', `<div class="ai-msg ai">照片已收到。<br>OCR 服务暂不可用，请直接描述题目内容，我来帮你分析。</div>`);
  }
  body.scrollTop = body.scrollHeight;
}

/* ========== 首页滚动 ========== */
function scrollToTop() {
  document.querySelector('.scroll').scrollTo({ top: 0, behavior: 'smooth' });
}

/* ========== 初始化 ========== */
function init() {
  updateHome();
}
init();
