"""Recalcula percentiles por endpoint, series de tiempo de 5 s y graficos 01-03 desde los CSV crudos de k6.
Uso: RAW_DIR=/tmp python docs/pruebas/analizar_resultados.py
"""
import pandas as pd, numpy as np, json, matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import os
OUT=os.path.dirname(os.path.abspath(__file__))+'/'
RAW=os.environ.get('RAW_DIR','/tmp')  # carpeta con raw_<perfil>.csv (salida --out csv de k6)
prof=['smoke','load','stress','pico']
nombres={'smoke':'Humo (1 VU)','load':'Carga (30 VU)','stress':'Estrés (100 VU)','pico':'Pico (200 VU)'}
res={}
for p in prof:
    df=pd.read_csv(f'{RAW}/raw_{p}.csv',usecols=['metric_name','timestamp','metric_value','name','status','expected_response','extra_tags'])
    t0=df.timestamp.min(); df['t']=df.timestamp-t0
    d=df[df.metric_name=='http_req_duration']
    reqs=df[df.metric_name=='http_reqs']
    vus=df[df.metric_name=='vus']
    b=5
    d=d.assign(bk=(d.t//b)*b); reqs=reqs.assign(bk=(reqs.t//b)*b)
    ts=pd.DataFrame({'rps':reqs.groupby('bk').size()/b,'p95':d.groupby('bk').metric_value.quantile(.95),'p50':d.groupby('bk').metric_value.median()})
    ts['err']=reqs[reqs.expected_response!=True].groupby('bk').size()
    ts=ts.fillna(0)
    v=vus.groupby((vus.t//b)*b).metric_value.max()
    ts['vus']=v.reindex(ts.index).ffill().fillna(0)
    # per endpoint from raw
    ep=d.groupby('name').metric_value.agg(n='count',avg='mean',p50='median',p90=lambda x:x.quantile(.9),p95=lambda x:x.quantile(.95),p99=lambda x:x.quantile(.99),max='max').round(1)
    st=reqs.groupby(['name','status']).size().unstack(fill_value=0)
    res[p]={'ts':ts,'ep':ep,'status':st,'peak_rps':float(ts.rps.max()),'dur':float(df.t.max())}
    ts.to_csv(OUT+f'resultados/ts_{p}.csv')
    print(p,'dur',df.t.max(),'peak rps',ts.rps.max(),'n',len(d))
    print(ep.to_string()); print(st.to_string())
# time series figure
fig,axs=plt.subplots(4,1,figsize=(11,13))
for ax,p in zip(axs,prof):
    ts=res[p]['ts']
    ax.plot(ts.index,ts.rps,color='#1f6feb',label='Peticiones/s (RPS)')
    ax.plot(ts.index,ts.vus,color='#8250df',ls='--',label='Usuarios virtuales (VU)')
    ax.set_ylabel('RPS / VU'); ax.set_xlabel('Segundos desde el inicio')
    a2=ax.twinx(); a2.plot(ts.index,ts.p95,color='#d1242f',label='Latencia p95 (ms)'); a2.plot(ts.index,ts.p50,color='#f0883e',alpha=.8,label='Latencia p50 (ms)')
    a2.axhline(800,color='#d1242f',ls=':',lw=1); a2.set_ylabel('ms'); a2.set_ylim(0,max(1000,ts.p95.max()*1.1))
    ax.set_title(f"{nombres[p]} — errores HTTP: {int(ts.err.sum())}")
    h1,l1=ax.get_legend_handles_labels(); h2,l2=a2.get_legend_handles_labels(); ax.legend(h1+h2,l1+l2,loc='upper left',fontsize=8)
    ax.grid(alpha=.3)
plt.tight_layout(); plt.savefig(OUT+'graficos/01_series_tiempo.png',dpi=130); plt.close()
# p95 per endpoint
eps=['web_portada','web_js','web_css','web_imagen_oficio','rpc_categorias','rest_servicios','rpc_catalogo','rpc_horarios_libres','rest_trabajos_anon_rls','edge_status_preflight','edge_status_get']
thr={'web':500,'rpc':800,'rest':800,'edge':1500}
fig,ax=plt.subplots(figsize=(12,6)); w=0.2; x=np.arange(len(eps))
for i,p in enumerate(prof):
    ax.bar(x+(i-1.5)*w,[res[p]['ep'].loc[e,'p95'] for e in eps],w,label=nombres[p])
for j,e in enumerate(eps):
    ax.hlines(thr[e.split('_')[0]],j-0.45,j+0.45,colors='k',linestyles=':')
ax.set_xticks(x); ax.set_xticklabels(eps,rotation=35,ha='right',fontsize=8); ax.set_ylabel('p95 (ms)')
ax.set_title('Latencia p95 por endpoint y perfil (línea punteada = umbral)'); ax.legend(); ax.grid(axis='y',alpha=.3)
plt.tight_layout(); plt.savefig(OUT+'graficos/02_p95_por_endpoint.png',dpi=130); plt.close()
# histogram pico
df=pd.read_csv(f'{RAW}/raw_load.csv',usecols=['metric_name','metric_value','extra_tags'])
d=df[df.metric_name=='http_req_duration']
fig,ax=plt.subplots(figsize=(10,5))
for tag,c in [('tipo=supabase','#3ecf8e'),('tipo=web','#000000'),('tipo=edge','#d1242f')]:
    ax.hist(d[d.extra_tags==tag].metric_value.clip(upper=1500),bins=75,alpha=.55,label=tag.replace('tipo=',''),color=c)
ax.set_yscale('log'); ax.set_xlabel('Latencia (ms, recortado a 1500)'); ax.set_ylabel('N.º de peticiones (log)')
ax.set_title('Distribución de latencias — perfil Carga (30 VU)'); ax.legend(); ax.grid(alpha=.3)
plt.tight_layout(); plt.savefig(OUT+'graficos/03_histograma_carga.png',dpi=130); plt.close()
json.dump({p:{'peak_rps':res[p]['peak_rps'],'dur':res[p]['dur'],'ep':res[p]['ep'].to_dict('index'),'status':{k:{str(s):int(v) for s,v in r.items()} for k,r in res[p]['status'].to_dict('index').items()}} for p in prof},open(OUT+'resultados/analisis_csv.json','w'),indent=1,default=float)
