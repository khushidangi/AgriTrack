import { useState, useEffect } from 'react'
import { BarChart, Bar, XAxis, YAxis, Tooltip, Legend, ResponsiveContainer, CartesianGrid } from 'recharts'

const api = (path, opts) => fetch(`/api${path}`, opts).then(r => r.json())
const FORM0 = { farmer_id: '', crop_id: '', season_id: '', yield_amount: '', rainfall_amount: '' }

const css = `
*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
:root {
  --bg: #0d0f0e; --surface: #141917; --border: #1f2823;
  --green: #4afa8a; --green-dim: #2a6b44; --amber: #f5c842;
  --text: #e8ede9; --muted: #5a6860; --danger: #f25c5c;
  --head: 'Syne', sans-serif; --mono: 'DM Mono', monospace;
}
body { background: var(--bg); color: var(--text); font-family: var(--mono); font-size: 13px; }
.shell { max-width: 1160px; margin: 0 auto; padding: 32px 20px; }

header { display: flex; align-items: baseline; gap: 14px; margin-bottom: 32px; border-bottom: 1px solid var(--border); padding-bottom: 18px; }
header h1 { font-family: var(--head); font-size: 22px; font-weight: 800; color: var(--green); }
header span { color: var(--muted); font-size: 11px; letter-spacing: 2px; text-transform: uppercase; }

.stats { display: grid; grid-template-columns: repeat(4,1fr); gap: 10px; margin-bottom: 24px; }
.stat { background: var(--surface); border: 1px solid var(--border); border-top: 2px solid var(--green-dim); padding: 16px 18px; }
.stat-val { font-family: var(--head); font-size: 26px; font-weight: 700; color: var(--green); margin-bottom: 5px; }
.stat-lbl { color: var(--muted); font-size: 10px; letter-spacing: 1.5px; text-transform: uppercase; }

.chart-box { background: var(--surface); border: 1px solid var(--border); margin-bottom: 20px; }
.box-head { padding: 12px 18px; border-bottom: 1px solid var(--border); font-size: 10px; letter-spacing: 2px; text-transform: uppercase; color: var(--muted); display: flex; align-items: center; gap: 8px; }
.box-head::before { content: ''; width: 6px; height: 6px; background: var(--green); display: inline-block; }

.grid { display: grid; grid-template-columns: 360px 1fr; gap: 18px; }
.box { background: var(--surface); border: 1px solid var(--border); }
.form-body { padding: 18px; }
.row { margin-bottom: 11px; }
.row label { display: block; font-size: 10px; letter-spacing: 1.5px; text-transform: uppercase; color: var(--muted); margin-bottom: 4px; }
.row select, .row input {
  width: 100%; background: var(--bg); border: 1px solid var(--border);
  color: var(--text); padding: 8px 11px; font-family: var(--mono); font-size: 13px; outline: none;
}
.row select:focus, .row input:focus { border-color: var(--green); }
.btn { width: 100%; padding: 10px; background: var(--green); color: #0d0f0e; border: none; font-family: var(--head); font-size: 12px; font-weight: 700; letter-spacing: 1px; text-transform: uppercase; cursor: pointer; margin-top: 4px; }
.btn:hover { opacity: .85; }
.btn:disabled { opacity: .4; cursor: not-allowed; }
.msg { margin-top: 10px; padding: 8px 11px; font-size: 12px; border-left: 3px solid var(--green); background: #1a2e1e; color: var(--green); }
.msg.err { border-color: var(--danger); background: #2e1a1a; color: var(--danger); }

.tbl-wrap { overflow-x: auto; }
table { width: 100%; border-collapse: collapse; }
thead th { padding: 10px 14px; text-align: left; font-size: 10px; letter-spacing: 1.5px; text-transform: uppercase; color: var(--muted); border-bottom: 1px solid var(--border); }
tbody tr { border-bottom: 1px solid var(--border); }
tbody tr:hover { background: rgba(74,250,138,.03); }
tbody td { padding: 10px 14px; }
tbody td:nth-child(5), tbody td:nth-child(6) { color: var(--green); font-weight: 500; }
.del { background: transparent; color: var(--danger); border: 1px solid var(--danger); padding: 3px 9px; font-size: 11px; cursor: pointer; font-family: var(--mono); }
.del:hover { background: var(--danger); color: #0d0f0e; }
.empty { text-align: center; color: var(--muted); padding: 36px; }

@media (max-width: 820px) {
  .grid { grid-template-columns: 1fr; }
  .stats { grid-template-columns: repeat(2,1fr); }
}
`

export default function App() {
  const [farmers,  setFarmers]  = useState([])
  const [crops,    setCrops]    = useState([])
  const [seasons,  setSeasons]  = useState([])
  const [records,  setRecords]  = useState([])
  const [chart,    setChart]    = useState([])
  const [stats,    setStats]    = useState({})
  const [form,     setForm]     = useState(FORM0)
  const [saving,   setSaving]   = useState(false)
  const [msg,      setMsg]      = useState(null)

  const load = async () => {
    const [f, c, s, r, ch, st] = await Promise.all([
      api('/farmers'), api('/crops'), api('/seasons'),
      api('/records'), api('/chart'), api('/stats')
    ])
    setFarmers(f); setCrops(c); setSeasons(s)
    setRecords(r); setChart(ch); setStats(st)
  }

  useEffect(() => { load() }, [])

  const submit = async () => {
    if (!form.farmer_id || !form.crop_id || !form.season_id || !form.yield_amount) {
      setMsg({ text: 'Please fill all required fields.', ok: false }); return
    }
    setSaving(true); setMsg(null)
    const res = await api('/records', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        farmer_id:       +form.farmer_id,
        crop_id:         +form.crop_id,
        season_id:       +form.season_id,
        yield_amount:    +form.yield_amount,
        rainfall_amount: form.rainfall_amount ? +form.rainfall_amount : null
      })
    })
    setSaving(false)
    if (res.success) { setMsg({ text: 'Record saved!', ok: true }); setForm(FORM0); load() }
    else setMsg({ text: res.error || 'Error saving record.', ok: false })
  }

  const del = async (id) => { await api(`/records/${id}`, { method: 'DELETE' }); load() }
  const set = k => e => setForm(f => ({ ...f, [k]: e.target.value }))

  return (
    <>
      <style>{css}</style>
      <div className="shell">

        <header>
          <h1>AgriDB</h1>
          <span>Crop Yield &amp; Weather Analysis</span>
        </header>

        <div className="stats">
          <div className="stat"><div className="stat-val">{stats.total_farmers ?? '—'}</div><div className="stat-lbl">Farmers</div></div>
          <div className="stat"><div className="stat-val">{stats.avg_yield ?? '—'}</div><div className="stat-lbl">Avg Yield (kg)</div></div>
          <div className="stat"><div className="stat-val">{stats.total_records ?? '—'}</div><div className="stat-lbl">Records</div></div>
          <div className="stat"><div className="stat-val" style={{fontSize:17,paddingTop:5}}>{stats.top_crop ?? '—'}</div><div className="stat-lbl">Top Crop</div></div>
        </div>

        <div className="chart-box">
          <div className="box-head">Yield vs Rainfall by Season</div>
          <div style={{padding:'18px 8px 14px'}}>
            <ResponsiveContainer width="100%" height={210}>
              <BarChart data={chart} margin={{top:0,right:16,left:0,bottom:0}}>
                <CartesianGrid strokeDasharray="3 3" stroke="#1f2823" vertical={false} />
                <XAxis dataKey="season" tick={{fill:'#5a6860',fontSize:11,fontFamily:'DM Mono'}} axisLine={false} tickLine={false} />
                <YAxis yAxisId="l" tick={{fill:'#5a6860',fontSize:11,fontFamily:'DM Mono'}} axisLine={false} tickLine={false} />
                <YAxis yAxisId="r" orientation="right" tick={{fill:'#5a6860',fontSize:11,fontFamily:'DM Mono'}} axisLine={false} tickLine={false} />
                <Tooltip contentStyle={{background:'#141917',border:'1px solid #1f2823',fontFamily:'DM Mono',fontSize:12}} labelStyle={{color:'#e8ede9'}} />
                <Legend wrapperStyle={{fontFamily:'DM Mono',fontSize:11,color:'#5a6860'}} />
                <Bar yAxisId="l" dataKey="avg_yield" name="Avg Yield (kg)" fill="#4afa8a" radius={[2,2,0,0]} />
                <Bar yAxisId="r" dataKey="rainfall"  name="Rainfall (mm)"  fill="#f5c842" radius={[2,2,0,0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>

        <div className="grid">
          <div className="box">
            <div className="box-head">Add Record</div>
            <div className="form-body">
              <div className="row">
                <label>Farmer *</label>
                <select value={form.farmer_id} onChange={set('farmer_id')}>
                  <option value="">Select…</option>
                  {farmers.map(f => <option key={f.Farmer_ID} value={f.Farmer_ID}>{f.Name}</option>)}
                </select>
              </div>
              <div className="row">
                <label>Crop *</label>
                <select value={form.crop_id} onChange={set('crop_id')}>
                  <option value="">Select…</option>
                  {crops.map(c => <option key={c.Crop_ID} value={c.Crop_ID}>{c.Crop_Name}</option>)}
                </select>
              </div>
              <div className="row">
                <label>Season *</label>
                <select value={form.season_id} onChange={set('season_id')}>
                  <option value="">Select…</option>
                  {seasons.map(s => <option key={s.Season_ID} value={s.Season_ID}>{s.Season_Name} {s.Year}</option>)}
                </select>
              </div>
              <div className="row">
                <label>Yield (kg) *</label>
                <input type="number" min="0" placeholder="e.g. 4500" value={form.yield_amount} onChange={set('yield_amount')} />
              </div>
              <div className="row">
                <label>Rainfall (mm)</label>
                <input type="number" min="0" placeholder="optional" value={form.rainfall_amount} onChange={set('rainfall_amount')} />
              </div>
              <button className="btn" onClick={submit} disabled={saving}>{saving ? 'Saving…' : 'Save Record'}</button>
              {msg && <div className={`msg${msg.ok ? '' : ' err'}`}>{msg.text}</div>}
            </div>
          </div>

          <div className="box">
            <div className="box-head">Records</div>
            <div className="tbl-wrap">
              <table>
                <thead>
                  <tr>
                    <th>Farmer</th><th>Crop</th><th>Season</th>
                    <th>Rainfall mm</th><th>Yield kg</th><th></th>
                  </tr>
                </thead>
                <tbody>
                  {records.length === 0
                    ? <tr><td colSpan={6} className="empty">No records yet</td></tr>
                    : records.map(r => (
                      <tr key={r.Yield_ID}>
                        <td>{r.farmer}</td>
                        <td>{r.crop}</td>
                        <td>{r.season}</td>
                        <td>{r.rainfall ?? '—'}</td>
                        <td>{r.yield}</td>
                        <td><button className="del" onClick={() => del(r.Yield_ID)}>del</button></td>
                      </tr>
                    ))
                  }
                </tbody>
              </table>
            </div>
          </div>
        </div>

      </div>
    </>
  )
}
