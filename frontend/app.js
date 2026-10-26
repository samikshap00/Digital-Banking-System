const SUPABASE_URL = 'https://qzxsozkisgpzflgzovyz.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_V0oUds1BTrxX4gjcKWjZFg_fyLcBOY4';
const configured = !SUPABASE_URL.includes('YOUR-PROJECT');
const client = configured ? supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY) : null;
let demoMode = false;
const $ = (id) => document.getElementById(id);
const money = (n) => new Intl.NumberFormat('en-IN',{style:'currency',currency:'INR'}).format(Number(n||0));

function showApp(profile, accounts, transactions, staffAccounts = []) {
  $('authPanel').classList.add('hidden'); $('appPanel').classList.remove('hidden');
  $('welcome').textContent = `Welcome back, ${profile?.full_name || 'Customer'}`;
  $('userBadge').textContent = (profile?.role || 'customer').toUpperCase();
  const total = accounts.reduce((s,a)=>s+Number(a.balance),0);
  $('summaryCards').innerHTML = `<div class="stat"><small>Total balance</small><strong>${money(total)}</strong></div><div class="stat"><small>Accounts</small><strong>${accounts.length}</strong></div><div class="stat"><small>Transactions</small><strong>${transactions.length}</strong></div>`;
  $('accountsList').innerHTML = accounts.map(a=>`<div class="account"><div class="account-line"><strong>${a.account_type.toUpperCase()} ACCOUNT</strong><span class="balance">${money(a.balance)}</span></div><div class="account-number">${a.account_number} · ${a.status}</div></div>`).join('') || '<p class="muted">No accounts found.</p>';
  $('fromAccount').innerHTML = accounts.map(a=>`<option value="${a.account_id}">${a.account_number} (${money(a.balance)})</option>`).join('');
  $('transactionsList').innerHTML = transactions.slice(0,6).map(t=>`<div class="transaction"><div class="transaction-line"><strong>${t.transaction_type}</strong><span>${money(t.amount)}</span></div><small>${t.status} · ${t.description || 'Banking transaction'}</small></div>`).join('') || '<p class="muted">No activity yet.</p>';
  if(profile?.role === 'staff' || profile?.role === 'admin') $('staffPanel').classList.remove('hidden');
  if(profile?.role === 'staff' || profile?.role === 'admin') $('staffAccounts').innerHTML = staffAccounts.map(a=>`<div class="staff-row"><div class="account-line"><strong>${a.full_name}</strong><span class="balance">${money(a.balance)}</span></div><div class="account-number">${a.account_number} · ${a.account_type} · ${a.status} · ${a.branch_name}</div></div>`).join('') || '<p class="muted">No accounts available for review.</p>';
}

function openDemo() { demoMode=true; showApp({full_name:'Aarav Kulkarni',role:'customer'},[{account_id:'demo-1',account_number:'DBS100001',account_type:'savings',balance:48500,status:'active'},{account_id:'demo-2',account_number:'DBS100002',account_type:'current',balance:12750,status:'active'}],[{transaction_type:'transfer',amount:1500,status:'completed',description:'Rent payment'},{transaction_type:'deposit',amount:5000,status:'completed',description:'Monthly deposit'},{transaction_type:'withdrawal',amount:800,status:'completed',description:'ATM withdrawal'}]); }

async function loadData() { const {data:{user}}=await client.auth.getUser(); if(!user)return; const {data:profile}=await client.from('profiles').select('*').eq('user_id',user.id).single(); const [{data:accounts},{data:transactions}]=await Promise.all([client.from('accounts').select('*').eq('user_id',user.id).order('created_at'),client.from('transactions').select('*').order('created_at',{ascending:false}).limit(20)]); let staffAccounts=[]; if(profile?.role==='staff'||profile?.role==='admin'){const {data}=await client.from('account_summary').select('*').order('full_name'); staffAccounts=data||[]} showApp(profile,accounts||[],transactions||[],staffAccounts); }

$('demoBtn').onclick=openDemo;
$('signInBtn').onclick=async()=>{if(!configured){$('authMessage').textContent='Add your Supabase URL and publishable key in app.js first, or use the demo preview.';return} const {error}=await client.auth.signInWithPassword({email:$('email').value,password:$('password').value}); $('authMessage').textContent=error?error.message:'Signed in.'; if(!error)loadData();};
$('signOutBtn').onclick=async()=>{if(!demoMode)await client.auth.signOut(); location.reload();};
$('refreshBtn').onclick=()=>demoMode?openDemo():loadData();
$('transferBtn').onclick=async()=>{if(demoMode){$('transferMessage').textContent='Demo preview: connect Supabase to execute a real transfer.';return} const destination=$('toAccount').value.trim(); const {error}=await client.rpc('transfer_money',{p_from_account:$('fromAccount').value,p_to_account_number:destination,p_amount:Number($('amount').value),p_description:$('description').value}); $('transferMessage').textContent=error?error.message:'Transfer completed.'; if(!error)loadData();};
