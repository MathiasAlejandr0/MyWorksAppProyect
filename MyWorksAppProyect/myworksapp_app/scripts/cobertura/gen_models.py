import re,os,sys,json
import pathlib; ROOT=str(pathlib.Path(__file__).resolve().parents[2])
def find_block(src, start):
    i=src.index('{', start); depth=0
    for j in range(i,len(src)):
        if src[j]=='{': depth+=1
        elif src[j]=='}':
            depth-=1
            if depth==0: return src[i:j+1]
    return src[i:]
def classify(after, key, body):
    a=after[:80]
    if re.match(r"\s*as\s+String", a): t='str'
    elif re.match(r"\s*as\s+int", a): t='int'
    elif re.match(r"\s*as\s+(num|double)", a): t='num'
    elif re.match(r"\s*as\s+bool", a): t='bool'
    elif re.match(r"\s*as\s+List", a): t='list'
    elif re.match(r"\s*as\s+Map", a): t='map'
    else: t='?'
    return t
def guess(key,t,body):
    k=key.lower()
    dateish = (k.endswith('_en') or k.endswith('at') and key[-2:]=='At' or any(s in k for s in ['fecha','date','_at','timestamp','marca_tiempo','vence','expira'])) and not any(s in k for s in ['monto','precio'])
    if t in ('str','?') and dateish: return '2026-01-02T03:04:05.000Z'
    if re.search(r"DateTime\.(tryParse|parse)\(\s*(\(?\s*)?%s\[['\"]%s['\"]\]"%('[a-z]+',re.escape(key)), body) or (t in('str','?') and dateish and 'DateTime' in body):
        return '2026-01-02T03:04:05.000Z'
    if t=='int': return 1 if not any(s in k for s in ['resuelto','habilitad','activo','leido','es_']) else 1
    if t=='num': return 1500.0
    if t=='bool': return True
    if t=='list': return []
    if t=='map': return {}
    if t=='str': return 'v_'+key
    # unknown
    if any(s in k for s in ['monto','precio','total','tarifa','comision','calificacion','puntaje','latitud','longitud','lat','lng','cantidad','conteo','peso','radio','distancia','porcentaje','latitude','longitude','rating','price','amount','score','count','radius']): return 1000
    if k.startswith('es_') or k.startswith('tiene_') or k in ('activo','leido','habilitada','verificado'): return True
    return 'v_'+key
out=[]
files=[]
for dp,_,fs in os.walk(ROOT+'/lib'):
    for f in fs:
        if f.endswith('.dart'): files.append(os.path.join(dp,f))
tests=[]
for path in sorted(files):
    src=open(path).read()
    for m in re.finditer(r"factory\s+(\w+)\.(fromMap|fromJson|fromRow)\s*\(\s*Map<String,\s*dynamic>\s+(\w+)\s*\)", src):
        cls,ctor,var=m.groups()
        body=find_block(src,m.end())
        keys={}
        for km in re.finditer(r"%s\[['\"]([\w]+)['\"]\]"%re.escape(var), body):
            key=km.group(1)
            if key in keys: continue
            keys[key]=guess(key,classify(body[km.end():],key,body),body)
        # class body
        cm=re.search(r"class\s+%s\b[^{]*"%cls, src)
        cbody=find_block(src,cm.end()) if cm else ''
        getters=re.findall(r"^\s+(?:[\w<>?,\s]+)\s+get\s+(\w+)\s*(?:=>|\{)", cbody, re.M)
        getters=[g for g in getters if not g.startswith('_')]
        methods=[mm for mm in re.findall(r"^  (?!static)(?:[\w<>?,\s()]+?)\s+(\w+)\(\)\s*(?:\{|=>)", cbody, re.M) if not mm.startswith('_') and mm not in ('toMap','toJson','copyWith','toString',cls)]
        has=lambda n: re.search(r"\b%s\s*\("%n, cbody) is not None
        tests.append(dict(path=path[len(ROOT)+5:],cls=cls,ctor=ctor,sample=keys,getters=sorted(set(getters)),methods=sorted(set(methods)),
          toMap='toMap' if has('toMap') else ('toJson' if has('toJson') else None),
          copyWith=has('copyWith'), static=bool(re.search(r"static\s+\w+\s+fromMap",cbody))))
os.makedirs(ROOT+'/build',exist_ok=True); json.dump(tests,open(ROOT+'/build/models.json','w'),indent=1,ensure_ascii=False)
print(len(tests))
