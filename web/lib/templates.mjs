const shell = (title, css, body, script = "") =>
  `<!doctype html><html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>${title}</title><style>*{box-sizing:border-box}body{margin:0;font-family:Inter,Arial,sans-serif;color:#242821;background:#fafaf6}button,input{font:inherit}button{cursor:pointer}button:focus-visible,input:focus-visible{outline:3px solid #8573da;outline-offset:3px}button{border:0;border-radius:8px;padding:10px 16px}input{padding:10px;border:1px solid #ddd;border-radius:8px;min-width:0}main{max-width:950px;margin:auto;padding:32px}h1{letter-spacing:-1.5px}small{color:#788074}header{display:flex;justify-content:space-between;align-items:center;border-bottom:1px solid #e5e7df;padding-bottom:20px}section{margin-top:26px}.row{display:flex;gap:14px;flex-wrap:wrap}.box{padding:20px;background:white;border:1px solid #e8e9e2;border-radius:12px;flex:1}.muted{color:#798073;font-size:13px}@media(max-width:500px){main{padding:20px}.row{gap:9px}.box{padding:14px}}${css}</style></head><body>${body}<script>${script}</script></body></html>`;

const nourish = shell(
  "Nourish — meal planner",
  ".brand{font-weight:800;color:#53683c;font-size:22px}.accent{background:#e6ecd9;color:#53683c}.food{height:85px;border-radius:9px;display:grid;place-items:center;font-size:48px;background:#eee9dd;margin-bottom:14px}.meal{min-width:160px}.meal h3{font-size:15px}.progress{height:7px;background:#eceee5;border-radius:8px;overflow:hidden}.progress i{display:block;background:#82925d;height:100%;width:64%}h1{font-size:32px}.days{display:flex;gap:10px}.days button{flex:1;background:white;border:1px solid #e5e7df;color:#777}.days button.on{background:#596c41;color:white}",
  `<main><header><div class="brand">✳ nourish</div><small>Your daily dose of good.</small></header><section><small>YOUR PERSONAL MEAL PLANNER</small><h1>A little planning. A lot of good.</h1><p class="muted">Make room for food that makes you feel good.</p></section><section class="days">${["M", "T", "W", "T", "F", "S", "S"].map((d, i) => `<button class="${i === 0 ? "on" : ""}" aria-label="Day ${i + 1}" onclick="document.querySelectorAll('.days button').forEach(b=>b.classList.remove('on'));this.classList.add('on');document.getElementById('day').textContent='${["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"][i]}'">${d}</button>`).join("")}</section><section><b id="day">Monday</b><div class="row" style="margin-top:16px">${[
    ["🥑", "Avocado toast", "Breakfast · 380 kcal"],
    ["🥗", "Green goddess bowl", "Lunch · 520 kcal"],
    ["🍜", "Miso noodle bowl", "Dinner · 610 kcal"],
  ]
    .map(
      ([e, n, k]) =>
        `<div class="box meal"><div class="food">${e}</div><h3>${n}</h3><p class="muted">${k}</p><button class="accent" onclick="this.textContent=this.textContent==='✓ Logged'?'Log meal':'✓ Logged';update()">Log meal</button></div>`,
    )
    .join(
      "",
    )}</div></section><section class="box"><div class="row" style="justify-content:space-between"><b>Daily nourishment</b><small id="count">0 of 3 meals logged</small></div><div class="progress" style="margin-top:16px"><i id="progress" style="width:0%"></i></div></section></main>`,
  `function update(){let n=[...document.querySelectorAll('.meal button')].filter(b=>b.textContent==='✓ Logged').length;document.getElementById('count').textContent=n+' of 3 meals logged';document.getElementById('progress').style.width=n/3*100+'%'}`,
);

const orbit = shell(
  "Orbit — a calmer task board",
  "body{background:#f4f2fb;color:#403b56}.brand{font-weight:800;font-size:22px;color:#7864b2}h1{font-size:32px}.column{flex:1;min-width:180px;background:#eeebf6;padding:13px;border-radius:12px}.column h3{font-size:13px;color:#827b96}.task{background:white;padding:16px;border-radius:9px;margin:10px 0;box-shadow:0 2px 3px #33234c05}.task small{display:block;margin:0 0 9px;font-size:10px;color:#8973b8}.task button{padding:5px 8px;margin-top:14px;color:#8874b6;background:#f1ecfa;font-size:11px}.add{background:#7964b3;color:white}",
  `<main><header><div class="brand">◉ orbit</div><small>A little more focus.</small></header><section><small>MY WORKSPACE</small><h1>Make space for your best work.</h1><p class="muted">Big ideas. Small steps. A calmer kind of progress.</p></section><form id="add" class="row"><input aria-label="New task" id="task" placeholder="What would you like to work on?" required style="flex:1"><button class="add">+ Add task</button></form><section class="row" id="board"></section></main>`,
  `const tasks=[{t:'Explore the possibilities',s:0},{t:'Sketch the first version',s:0},{t:'Build something useful',s:1},{t:'Find a good starting point',s:2}];function render(){const board=document.getElementById('board');board.replaceChildren();['To do','In progress','Done'].forEach((name,s)=>{let col=document.createElement('div');col.className='column';let h=document.createElement('h3');h.textContent=name+' · '+tasks.filter(t=>t.s===s).length;col.append(h);tasks.forEach((t,i)=>{if(t.s!==s)return;let card=document.createElement('div');card.className='task';let tag=document.createElement('small');tag.textContent=s===2?'FINISHED':'PROJECT';let text=document.createElement('div');text.textContent=t.t;let btn=document.createElement('button');btn.textContent=s===2?'↶ Reopen':'Move forward →';btn.onclick=()=>{t.s=(s+1)%3;render()};card.append(tag,text,btn);col.append(card)});board.append(col)})}document.getElementById('add').onsubmit=e=>{e.preventDefault();let input=document.getElementById('task');if(!input.value.trim())return;tasks.push({t:input.value.trim(),s:0});input.value='';render()};render();`,
);

const folio = shell(
  "Forma — a portfolio starter",
  "body{background:#eeeae4;color:#33322f}header{border-color:#d6d0c7}.brand{font-weight:bold}h1{font-family:Georgia,serif;font-weight:normal;font-size:clamp(38px,7vw,70px);line-height:1.02;max-width:650px;margin:35px 0}.art{height:180px;overflow:hidden;position:relative;border-radius:3px;flex:1;min-width:180px;display:flex;align-items:center;justify-content:center}.art:first-child{background:#c9d2c2}.art:last-child{background:#c0acd6}.shape{width:110px;height:110px;background:#e8efe3;border-radius:50%;box-shadow:20px 20px 0 #75896b,-20px -20px 0 #b2c3a8;transform:rotate(-25deg)}.type{font-size:70px;font-weight:bold;letter-spacing:-10px;transform:rotate(-12deg);color:#4c335c}a{color:inherit}button{background:#393a32;color:white}",
  `<main><header><div class="brand">forma®</div><small>Independent designer & creative thinker</small></header><h1>Thoughtful design.<br>A fresh perspective.</h1><div class="row" style="align-items:center;justify-content:space-between"><p class="muted">I make brands, digital experiences,<br>and the occasional happy accident.</p><button onclick="document.getElementById('contact').showModal()">Let's make something ↗</button></div><section class="row"><div class="art"><div class="shape"></div></div><div class="art"><div class="type">Aa.</div></div></section><section class="row"><div style="flex:1"><b>01 — A softer kind of everyday</b><p class="muted">Brand strategy · Visual identity</p></div><div style="flex:1"><b>02 — Type with a little personality</b><p class="muted">Art direction · Digital design</p></div></section><dialog id="contact" style="border:0;border-radius:12px;padding:30px"><h2>Let’s work together.</h2><p>Customize this starter with your contact details.</p><button onclick="this.closest('dialog').close()">Back to portfolio</button></dialog></main>`,
);

const pocket = shell(
  "Pocket — personal finance",
  "body{background:#eff4f4}.brand{font-size:22px;font-weight:bold;color:#317b77}h1{font-size:32px}.balance{background:#225e5b;color:white}.balance small{color:#acd3cb}.balance h2{font-size:36px;margin:14px 0}.bars{height:110px;display:flex;align-items:end;gap:14px}.bars i{flex:1;background:#8ac0b8;border-radius:5px 5px 0 0}.expense{display:flex;justify-content:space-between;padding:15px 0;border-bottom:1px solid #eee}.box h3{font-size:14px}.primary{background:#2e7770;color:white}",
  `<main><header><div class="brand">◒ pocket</div><small>A clearer picture of your money.</small></header><section><h1>Small habits. Bigger possibilities.</h1><p class="muted">Your finances, with a little breathing room.</p></section><section class="row"><div class="box balance"><small>AVAILABLE BALANCE · SAMPLE DATA</small><h2 id="balance">$4,280.00</h2><small>Looking good this month ↗</small></div><div class="box"><h3>Your monthly spending</h3><div class="bars">${[36, 67, 50, 84, 58, 100, 65].map((x) => `<i style="height:${x}%"></i>`).join("")}</div></div></section><section class="box"><h3>Recent activity</h3><div id="expenses"><div class="expense"><span>☕ Coffee & a good book</span><b>−$18.50</b></div><div class="expense"><span>🥬 Weekly groceries</span><b>−$64.20</b></div></div><form id="add" class="row" style="margin-top:20px"><input id="name" placeholder="Expense name" aria-label="Expense name" required style="flex:1"><input id="amount" type="number" min="0.01" step="0.01" placeholder="Amount" aria-label="Amount" required style="width:110px"><button class="primary">Add expense</button></form></section></main>`,
  `let balance=4280;document.getElementById('add').onsubmit=e=>{e.preventDefault();let n=document.getElementById('name'),a=document.getElementById('amount'),value=Number(a.value);if(!n.value.trim()||value<=0||!Number.isFinite(value))return;balance-=value;document.getElementById('balance').textContent=balance.toLocaleString('en-US',{style:'currency',currency:'USD'});let row=document.createElement('div');row.className='expense';let name=document.createElement('span');name.textContent=n.value;let sum=document.createElement('b');sum.textContent='−$'+value.toFixed(2);row.append(name,sum);document.getElementById('expenses').prepend(row);e.target.reset()}`,
);

const focus = shell(
  "Still — focus timer",
  "body{background:#292e28;color:#e4e9d9}header{border-color:#475043}.brand{font-family:Georgia,serif;font-size:24px}small,.muted{color:#a5af9c}.center{text-align:center;padding:20px}.clock{width:230px;height:230px;border:2px solid #738164;border-radius:50%;display:grid;place-content:center;margin:30px auto;background:radial-gradient(circle,#414937,#292e28 75%)}#clock{font-size:54px;font-weight:300;letter-spacing:-2px}.primary{background:#c5d6a7;color:#303927}button{background:#424b3b;color:#d3ddc6}h1{font-family:Georgia,serif;font-weight:normal;font-size:35px}",
  `<main><header><div class="brand">still.</div><small>One thing at a time.</small></header><div class="center"><h1>A little space to focus.</h1><p class="muted">Settle in. The rest can wait.</p><div class="clock"><div id="clock" role="timer">25:00</div><small>FOCUS SESSION</small></div><div class="row" style="justify-content:center"><button id="start" class="primary">Begin session</button><button id="reset">Reset</button></div><section><button onclick="setTime(25)">25 min</button> <button onclick="setTime(5)">5 min break</button> <button onclick="setTime(50)">50 min</button></section><p class="muted" id="status">Make a little progress on something that matters.</p></div></main>`,
  `let duration=1500,seconds=1500,timer=null,end=0;function draw(){document.getElementById('clock').textContent=Math.floor(seconds/60).toString().padStart(2,'0')+':'+(seconds%60).toString().padStart(2,'0')}function stop(){clearInterval(timer);timer=null;document.getElementById('start').textContent='Continue session'}function setTime(min){stop();duration=min*60;seconds=duration;draw();document.getElementById('start').textContent='Begin session'}document.getElementById('start').onclick=()=>{if(timer){stop();return}if(seconds<=0)seconds=duration;end=Date.now()+seconds*1000;document.getElementById('start').textContent='Pause session';timer=setInterval(()=>{seconds=Math.max(0,Math.ceil((end-Date.now())/1000));draw();if(!seconds){stop();document.getElementById('status').textContent='A little progress made. Take a breath.'}},200)};document.getElementById('reset').onclick=()=>setTime(duration/60);`,
);

const sprout = shell(
  "Sprout — nutrition API playground",
  "body{background:#f6f7fb}.brand{font-size:22px;font-weight:bold;color:#5b66a0}.endpoint{background:#222b3e;color:#cad4e9;font-family:monospace;padding:17px;border-radius:9px;font-size:13px}.endpoint span{color:#8ad2a8}pre{padding:22px;background:#222b3e;color:#c4d8ef;border-radius:10px;font-size:13px;line-height:1.7;overflow:auto}button{background:#626ea5;color:white}h1{font-size:32px}",
  `<main><header><div class="brand">⌘ sprout</div><small>Nutrition data, ready to build with.</small></header><section><small>INTERACTIVE API STARTER</small><h1>Good data. Better food apps.</h1><p class="muted">Explore a sample nutrition response. Runs entirely in your browser.</p></section><div class="endpoint"><span>GET</span> /api/nutrition?food=<b id="query">avocado</b></div><section class="row"><input id="food" aria-label="Food" placeholder="Try avocado, oats, or banana" style="flex:1" value="avocado"><button id="run">Run request →</button></section><pre id="result"></pre><p class="muted">Demo dataset · per 100g · no external service required</p></main>`,
  `let data={avocado:{calories:160,protein:2,carbs:8.5,fat:14.7},oats:{calories:389,protein:16.9,carbs:66.3,fat:6.9},banana:{calories:89,protein:1.1,carbs:22.8,fat:0.3}};function run(){let name=document.getElementById('food').value.trim().toLowerCase();document.getElementById('query').textContent=name;document.getElementById('result').textContent=JSON.stringify(data[name]?{status:200,food:name,serving:'100g',nutrients:data[name]}:{status:404,message:'Try avocado, oats, or banana'},null,2)}document.getElementById('run').onclick=run;run();`,
);

export const seeds = [
  {
    id: "nourish",
    name: "Nourish",
    tagline: "A little planning. A lot of good.",
    description:
      "A thoughtful meal planner with a weekly view, meal logging, and daily progress. Make healthy routines feel a little more human.",
    category: "Health & wellness",
    author: "Sophie Chen",
    initials: "SC",
    color: "#e7ebdb",
    tags: ["Meal planning", "Wellness"],
    stack: "HTML · CSS · JavaScript",
    forks: 128,
    stars: 346,
    featured: true,
    html: nourish,
  },
  {
    id: "orbit",
    name: "Orbit",
    tagline: "A calmer space for getting things done.",
    description:
      "A minimal task board for big ideas and small steps. Create tasks and move them from to-do to done.",
    category: "Productivity",
    author: "Alex Morgan",
    initials: "AM",
    color: "#e9e3f5",
    tags: ["Task management", "Kanban"],
    stack: "HTML · CSS · JavaScript",
    forks: 96,
    stars: 284,
    html: orbit,
  },
  {
    id: "folio",
    name: "Forma",
    tagline: "A portfolio with a point of view.",
    description:
      "A warm, editorial portfolio for independent creatives. Make the typography, projects, and contact experience your own.",
    category: "Design & creative",
    author: "Jamie Park",
    initials: "JP",
    color: "#e9e2d8",
    tags: ["Portfolio", "Design"],
    stack: "HTML · CSS · JavaScript",
    forks: 84,
    stars: 219,
    html: folio,
  },
  {
    id: "pocket",
    name: "Pocket",
    tagline: "Good money habits start here.",
    description:
      "A personal finance dashboard with a running balance and expense tracking. A clear starting point for your own money tools.",
    category: "Finance",
    author: "Oliver Reed",
    initials: "OR",
    color: "#dcecea",
    tags: ["Finance", "Dashboard"],
    stack: "HTML · CSS · JavaScript",
    forks: 72,
    stars: 198,
    html: pocket,
  },
  {
    id: "focus",
    name: "Still",
    tagline: "A little space to focus.",
    description:
      "A quiet focus timer with work sessions and short breaks. Start, pause, reset, and find your own rhythm.",
    category: "Productivity",
    author: "Maya Williams",
    initials: "MW",
    color: "#dce2d3",
    tags: ["Focus", "Pomodoro"],
    stack: "HTML · CSS · JavaScript",
    forks: 63,
    stars: 176,
    html: focus,
  },
  {
    id: "sprout",
    name: "Sprout API",
    tagline: "The roots of your next food app.",
    description:
      "An interactive nutrition API playground with a browser-based sample dataset. Explore requests and responses before connecting your own backend.",
    category: "Developer tools",
    author: "Leo Martin",
    initials: "LM",
    color: "#e0e5f0",
    tags: ["API starter", "Nutrition"],
    stack: "HTML · CSS · JavaScript",
    forks: 47,
    stars: 143,
    html: sprout,
  },
].map((p, i) => ({
  ...p,
  createdAt: new Date(Date.UTC(2026, 8, 18 - i)).toISOString(),
  license: "MIT",
  seed: true,
  published: true,
  parentId: null,
}));
