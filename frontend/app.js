const SUPABASE_URL = 'https://qzxsozkisgpzflgzovyz.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_V0oUds1BTrxX4gjcKWjZFg_fyLcBOY4';
const client = supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
const $ = (id) => document.getElementById(id);
const money = (n) => new Intl.NumberFormat('en-IN',{style:'currency',currency:'INR'}).format(Number(n||0));

const roleCopy = {
  customer: 'Personal banking: manage your accounts, saved beneficiaries, and transfers.',
  staff: 'Operations duty: review masked account records and apply permitted temporary status actions.',
  admin: 'System authority: oversee accounts, provision accounts, and manage beneficiary records.'
};

function masked(number) { return `XXXX-XXXX-${String(number || '').slice(-4)}`; }
function renderAccountRows(rows, mode) {
  return rows.map(a => {
    const actions = mode === 'staff'
      ? (a.status === 'active' || a.status === 'frozen' ? `<button class="small-action ${a.status === 'active' ? 'freeze-action' : ''}" data-account="${a.account_id}" data-status="${a.status === 'active' ? 'frozen' : 'active'}">${a.status === 'active' ? 'Freeze' : 'Reactivate'}</button>` : '<span class="muted">Admin only</span>')
      : `<select class="status-select" data-account="${a.account_id}"><option ${a.status==='active'?'selected':''}>active</option><option ${a.status==='frozen'?'selected':''}>frozen</option><option ${a.status==='closed'?'selected':''}>closed</option></select><button class="small-action" data-save-status="${a.account_id}">Save</button>`;
    return `<div class="staff-row"><div class="account-line"><div><strong>${masked(a.account_number || a.masked_account_number)}</strong><div class="account-number">${a.account_type} · ${a.branch_name || ''} · <span class="status status-${a.status}">${a.status}</span></div></div><span class="balance">${money(a.balance)}</span></div><div class="row-actions">${actions}</div></div>`;
  }).join('') || '<p class="muted">No account records found.</p>';
}

function showApp(profile, accounts, transactions, extra = {}) {
  const role = profile?.role || 'customer';
  $('authPanel').classList.add('hidden'); $('appPanel').classList.remove('hidden');
  $('welcome').textContent = `${role[0].toUpperCase()+role.slice(1)} workspace`;
  $('userBadge').textContent = role.toUpperCase();
  $('roleSummary').textContent = roleCopy[role] || roleCopy.customer;
  $('customerPanel').classList.toggle('hidden', role !== 'customer');
  $('staffPanel').classList.toggle('hidden', role !== 'staff');
  $('adminPanel').classList.toggle('hidden', role !== 'admin');

  if (role === 'customer') {
    const total = accounts.reduce((sum,a)=>sum+Number(a.balance),0);
    $('summaryCards').innerHTML = `<div class="stat"><small>Available balance</small><strong>${money(total)}</strong></div><div class="stat"><small>Accounts</small><strong>${accounts.length}</strong></div><div class="stat"><small>Recent activity</small><strong>${transactions.length+(extra.recoveryEvents||[]).length}</strong></div>`;
    $('accountsList').innerHTML = accounts.map(a=>`<div class="account"><div class="account-line"><strong>${a.account_type.toUpperCase()} ACCOUNT</strong><span class="balance">${money(a.balance)}</span></div><div class="account-number">${a.account_number} · <span class="status status-${a.status}">${a.status}</span></div></div>`).join('') || '<p class="muted">No accounts found.</p>';
    $('fromAccount').innerHTML = accounts.filter(a=>a.status==='active').map(a=>`<option value="${a.account_id}">${a.account_number} (${money(a.balance)})</option>`).join('');
    const accountById = new Map(accounts.map(a=>[a.account_id,a.account_number]));
    const activity = [
      ...transactions.map(t=>({...t,kind:'transaction'})),
      ...(extra.recoveryEvents||[]).map(e=>({...e,kind:'recovery',transaction_type:'Interrupted transfer'}))
    ].sort((a,b)=>new Date(b.created_at)-new Date(a.created_at)).slice(0,10);
    $('transactionsList').innerHTML = activity.map(t=>t.kind==='recovery'
      ? `<div class="transaction recovery-transaction"><div class="transaction-line"><strong>Interrupted transfer · rolled back</strong><span>${money(t.amount)}</span></div><small><span class="status status-rolled_back">rolled back</span> · From ${masked(accountById.get(t.from_account_id)||'Unknown')} to ${t.to_account_masked} · ${t.detail} · ${new Date(t.created_at).toLocaleString()}</small></div>`
      : `<div class="transaction"><div class="transaction-line"><strong>${t.transaction_type}</strong><span>${money(t.amount)}</span></div><small><span class="status status-${t.status}">${t.status}</span> · ${t.description || 'Banking transaction'} · ${new Date(t.created_at).toLocaleString()}</small></div>`
    ).join('') || '<p class="muted">No activity yet.</p>';
    $('beneficiariesList').innerHTML = (extra.beneficiaries||[]).map(b=>`<div class="account"><div class="account-line"><strong>${b.nickname}</strong><span class="muted">${b.bank_name}</span></div><div class="account-number">${b.beneficiary_name} · ${masked(b.beneficiary_account_number)}</div></div>`).join('') || '<p class="muted">No beneficiaries saved.</p>';
  }

  if (role === 'staff') {
    const rows=extra.accounts||[];
    const frozen=rows.filter(a=>a.status==='frozen').length;
    $('staffSummary').innerHTML=`<div class="mini-stat"><strong>${rows.length}</strong><span>Accounts reviewed</span></div><div class="mini-stat"><strong>${frozen}</strong><span>Frozen accounts</span></div><div class="mini-stat"><strong>${rows.filter(a=>a.status==='active').length}</strong><span>Active accounts</span></div>`;
    $('staffAccounts').innerHTML=renderAccountRows(rows,'staff');
    $('staffAccounts').querySelectorAll('[data-account]').forEach(button=>button.onclick=async()=>{const {error}=await client.rpc('staff_set_account_status',{p_account_id:button.dataset.account,p_status:button.dataset.status}); $('staffMessage').textContent=error?error.message:'Account status updated.'; if(!error)loadData();});
  }

  if (role === 'admin') {
    const metrics=extra.metrics?.[0]||{};
    $('adminMetrics').innerHTML=[['Customers',metrics.customer_count],['Staff',metrics.staff_count],['Accounts',metrics.account_count],['Active',metrics.active_count],['Frozen',metrics.frozen_count],['Closed',metrics.closed_count],['Deposits in system',money(metrics.total_balance)],['Transfers today',metrics.transfers_today]].map(([label,value])=>`<div class="admin-metric"><span>${label}</span><strong>${value??0}</strong></div>`).join('');
    $('adminAccounts').innerHTML=renderAccountRows(extra.accounts||[],'admin');
    $('adminAccounts').querySelectorAll('[data-save-status]').forEach(button=>button.onclick=async()=>{const accountId=button.dataset.saveStatus;const status=$(`status-${accountId}`).value;const {error}=await client.rpc('admin_set_account_status',{p_account_id:accountId,p_status:status});$('adminMessage').textContent=error?error.message:'Account status saved.';if(!error)loadData();});
    $('adminAccounts').querySelectorAll('.status-select').forEach(select=>select.id=`status-${select.dataset.account}`);
    $('adminBeneficiaries').innerHTML=(extra.beneficiaries||[]).map(b=>`<div class="beneficiary-admin-row"><div><strong>${b.nickname} · ${b.beneficiary_name}</strong><div class="account-number">Customer: ${b.customer_name} · ${b.customer_email}</div><div class="account-number">${b.masked_account_number} · ${b.bank_name} · IFSC ${b.ifsc_code}</div></div><button class="small-action danger-action" data-delete-beneficiary="${b.beneficiary_id}">Remove</button></div>`).join('') || '<p class="muted">No beneficiary records found.</p>';
    $('adminBeneficiaries').querySelectorAll('[data-delete-beneficiary]').forEach(button=>button.onclick=async()=>{if(!window.confirm('Remove this beneficiary record?'))return;const {error}=await client.rpc('admin_delete_beneficiary',{p_beneficiary_id:button.dataset.deleteBeneficiary});$('beneficiaryMessage').textContent=error?error.message:'Beneficiary record removed.';if(!error)loadData();});
    $('newAccountOwner').innerHTML=(extra.profiles||[]).filter(u=>u.role==='customer').map(u=>`<option value="${u.user_id}">${u.full_name} (${u.email})</option>`).join('');
    $('newAccountBranch').innerHTML=(extra.branches||[]).map(b=>`<option value="${b.branch_id}">${b.branch_name}</option>`).join('');
  }
}

async function loadData() {
  const {data:{user},error:userError}=await client.auth.getUser();
  if(userError)throw userError;
  if(!user)return;
  const {data:profile,error:profileError}=await client.from('profiles').select('*').eq('user_id',user.id).single();
  if(profileError)throw profileError;
  if(!profile)throw new Error('No banking profile is linked to this Auth user.');
  if(profile.role==='customer'){
    const [{data:accounts,error:e1},{data:transactions,error:e2},{data:beneficiaries,error:e3},{data:recoveryEvents,error:e4}]=await Promise.all([
      client.from('accounts').select('*').eq('user_id',user.id).order('created_at'),
      client.from('transactions').select('*').order('created_at',{ascending:false}).limit(20),
      client.from('beneficiaries').select('*').eq('user_id',user.id).order('nickname'),
      client.from('recovery_demo_events').select('*').eq('user_id',user.id).order('created_at',{ascending:false}).limit(20)
    ]);
    const error=e1||e2||e3||e4;if(error)throw error;
    showApp(profile,accounts||[],transactions||[],{beneficiaries:beneficiaries||[],recoveryEvents:recoveryEvents||[]});return;
  }
  if(profile.role==='staff'){
    const {data:accounts,error}=await client.from('account_summary').select('*').order('status');
    if(error)throw error;showApp(profile,[],[],{accounts:accounts||[]});return;
  }
  const [{data:accounts,error:e1},{data:profiles,error:e2},{data:branches,error:e3},{data:metrics,error:e4},{data:beneficiaries,error:e5}]=await Promise.all([
    client.from('account_summary').select('*').order('status'),
    client.from('profiles').select('user_id,full_name,email,role').order('role'),
    client.from('branches').select('branch_id,branch_name').order('branch_name'),
    client.rpc('admin_dashboard_metrics'),
    client.rpc('admin_list_beneficiaries')
  ]);
  const error=e1||e2||e3||e4||e5;if(error)throw error;
  showApp(profile,[],[],{accounts:accounts||[],profiles:profiles||[],branches:branches||[],metrics:metrics||[],beneficiaries:beneficiaries||[]});
}

$('signInBtn').onclick=async()=>{
  const {error}=await client.auth.signInWithPassword({email:$('email').value.trim(),password:$('password').value});
  if(error){$('authMessage').textContent=error.message;return}
  $('authMessage').textContent='Signed in.';
  try{await loadData()}catch(loadError){$('authMessage').textContent=loadError.message}
};
$('signOutBtn').onclick=async()=>{const {error}=await client.auth.signOut();if(error)$('authMessage').textContent=error.message;location.reload()};
$('refreshBtn').onclick=async()=>{try{await loadData()}catch(error){$('transferMessage').textContent=error.message}};
$('transferBtn').onclick=async()=>{
  const source=$('fromAccount').value,destination=$('toAccount').value.trim(),amount=Number($('amount').value);
  if(!source||!destination||!Number.isFinite(amount)||amount<=0){$('transferMessage').textContent='Choose an active source account, enter a destination account number, and enter a positive amount.';return}
  const {error}=await client.rpc('transfer_money',{p_from_account:source,p_to_account_number:destination,p_amount:amount,p_description:$('description').value||null});
  $('transferMessage').textContent=error?error.message:'Transfer completed.';
  if(!error)await loadData();
};
$('recoveryDemoBtn').onclick=async()=>{
  const source=$('fromAccount').value,destination=$('toAccount').value.trim(),amount=Number($('amount').value);
  if(!source||!destination||!Number.isFinite(amount)||amount<=0){$('transferMessage').textContent='Choose an active source account, enter a destination account number, and enter a positive amount.';return}
  const {data:{user}}=await client.auth.getUser();
  const before=await client.from('accounts').select('balance,account_number').eq('account_id',source).single();
  if(before.error){$('transferMessage').textContent=before.error.message;return}
  const eventsBefore=await client.from('recovery_demo_events').select('event_id',{count:'exact',head:true}).eq('user_id',user.id);
  const ledgerBefore=await client.from('transactions').select('transaction_id',{count:'exact',head:true}).eq('initiated_by',user.id).eq('description','RECOVERY DEMO - intentionally interrupted');
  if(eventsBefore.error||ledgerBefore.error){$('transferMessage').textContent=(eventsBefore.error||ledgerBefore.error).message;return}
  const result=await client.rpc('demo_interrupted_transfer',{p_from_account:source,p_to_account_number:destination,p_amount:amount});
  if(result.error){$('transferMessage').textContent=result.error.message;return}
  const [after,eventsAfter,ledgerAfter]=await Promise.all([
    client.from('accounts').select('balance').eq('account_id',source).single(),
    client.from('recovery_demo_events').select('event_id',{count:'exact',head:true}).eq('user_id',user.id),
    client.from('transactions').select('transaction_id',{count:'exact',head:true}).eq('initiated_by',user.id).eq('description','RECOVERY DEMO - intentionally interrupted')
  ]);
  const unchanged=after.data&&Number(before.data.balance)===Number(after.data.balance);
  const eventRecorded=(eventsAfter.count||0)===(eventsBefore.count||0)+1;
  const ledgerUnchanged=ledgerAfter.count===ledgerBefore.count;
  $('transferMessage').textContent=result.data?.status==='rolled_back'&&unchanged&&eventRecorded&&ledgerUnchanged
    ? 'Rollback confirmed. The attempted transfer was recorded in activity history; account balances and the financial ledger remain unchanged.'
    : 'The recovery event returned, but one or more consistency checks could not be confirmed.';
  await loadData();
};
$('createAccountBtn').onclick=async()=>{
  const {error}=await client.rpc('admin_create_account',{p_user_id:$('newAccountOwner').value,p_account_number:$('newAccountNumber').value.trim(),p_account_type:$('newAccountType').value,p_opening_balance:Number($('newAccountBalance').value||0),p_branch_id:$('newAccountBranch').value});
  $('adminMessage').textContent=error?error.message:'Account opened successfully.';
  if(!error)await loadData();
};
client.auth.getSession().then(async({data,error})=>{
  if(error){$('authMessage').textContent=error.message;return}
  if(data.session)try{await loadData()}catch(loadError){$('authMessage').textContent=loadError.message}
});
