import itertools
from model import PAQ, CTX
def feasible_side(order, actors, assoc):
    pos = {u:i for i,u in enumerate(order)}
    iv = sorted((min(pos[u] for u in assoc[a]), max(pos[u] for u in assoc[a]), a) for a in actors)
    for (s1,e1,_),(s2,e2,_) in zip(iv, iv[1:]):
        if s2 < e1: return None
        if s2 == e1 and s1 == e1 == e2: pass
    return [a for *_, a in iv]
def solve(ucs, assoc, rel=(), fixed_left=()):
    acts = list(assoc)
    best = None
    for order in itertools.permutations(ucs):
        pos = {u:i for i,u in enumerate(order)}
        if any(abs(pos[a]-pos[b]) != 1 for a,b,_ in rel): continue
        for mask in range(2**len(acts)):
            L = [a for i,a in enumerate(acts) if not mask>>i & 1]
            R = [a for i,a in enumerate(acts) if mask>>i & 1]
            if any(f not in L for f in fixed_left): continue
            if R and any(rr for rr in rel) and False: pass
            l = feasible_side(order, L, assoc); r = feasible_side(order, R, assoc)
            if l is not None and r is not None:
                EXT={'SA','T','TS','S'}
                inv = sum(1 for i in range(len(order)) for j in range(i+1,len(order)) if order[i]>order[j])
                score = 3*sum(a in EXT for a in L) + 3*sum(a not in EXT for a in R) + 0.2*inv + 0.5*abs(len(L)-len(R))
                if best is None or score < best[0]: best = (score, order, l, r)
    return best
if __name__ == '__main__':
    for p in PAQ:
        print(p['n'], solve(p['ucs'], p['assoc'], p['rel'], fixed_left=[g for gg in p['gen'] for g in gg]))
    ctx = {k:[str(x) for x in v] for k,v in CTX.items()}
    print('ctx', solve([str(i) for i in range(1,7)], ctx))
