const cfg = window.ROTA_CONFIG || {};
if (!cfg.SUPABASE_URL || cfg.SUPABASE_URL.includes('COLE_AQUI')) {
  console.warn('Configure o Supabase em config.js');
}
const sb = window.supabase.createClient(cfg.SUPABASE_URL, cfg.SUPABASE_KEY);

function qs(name){ return new URLSearchParams(location.search).get(name); }
function esc(s){ return String(s ?? '').replace(/[&<>"']/g,m=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[m])); }
function token(){ return crypto.randomUUID().replaceAll('-',''); }
function base(){ return location.href.replace(/[^/]+(?:\?.*)?$/,''); }
function hav(a,b){
  const R=6371, r=Math.PI/180;
  const dLat=(b.lat-a.lat)*r,dLon=(b.lng-a.lng)*r;
  const x=Math.sin(dLat/2)**2+Math.cos(a.lat*r)*Math.cos(b.lat*r)*Math.sin(dLon/2)**2;
  return 2*R*Math.asin(Math.sqrt(x));
}
function fmtKm(n){ return `${Number(n||0).toFixed(2)} km`; }
