"""Diagramas de casos de uso por paquete, sin cruces de líneas, a tamaño de impresión
(16 cm de ancho, textos de 9,5 a 13 pt). Uso: python3 draw.py <carpeta_salida>"""
import sys, os, textwrap, json
import matplotlib; matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.patches import Ellipse, Rectangle, FancyArrowPatch, Polygon
from model import UC, ACT, PAQ, CTX
from solve import solve
plt.rcParams['font.family'] = 'Liberation Sans'
NAVY = '#0B2A5B'; OR = '#E8661C'; FILL = '#FFF3E8'; GREY = '#555555'
CM = 1 / 2.54
OUT = sys.argv[1] if len(sys.argv) > 1 else os.path.dirname(os.path.abspath(__file__))
os.makedirs(OUT, exist_ok=True)
W_FIG = 16.0
EX0, EX1 = 4.6, 11.4      # elipses (cm)
BX0, BX1 = 4.1, 11.9      # límite del sistema
AXL, AXR = 1.55, 14.45    # actores
SL, SR = 3.05, 12.95      # inicio de las asociaciones (fuera de la etiqueta del actor)
UC_FS, ACT_FS = 10, 10

def uc_lines(k):
    return textwrap.wrap(f'CU-{k} {UC[k]}', 30)

def stick(ax, x, y, lab, c=NAVY):
    # y = altura del torso
    ax.add_patch(plt.Circle((x, y + 0.55), 0.2, fc='white', ec=c, lw=1.6, zorder=5))
    ax.plot([x, x], [y + 0.35, y - 0.25], color=c, lw=1.6, zorder=5)
    ax.plot([x - 0.38, x + 0.38], [y + 0.12, y + 0.12], color=c, lw=1.6, zorder=5)
    ax.plot([x, x - 0.3], [y - 0.25, y - 0.7], color=c, lw=1.6, zorder=5)
    ax.plot([x, x + 0.3], [y - 0.25, y - 0.7], color=c, lw=1.6, zorder=5)
    ax.text(x, y - 0.85, lab, ha='center', va='top', fontsize=ACT_FS, fontweight='bold', color=c,
            linespacing=1.05, zorder=5)

def place(actors, targets_y, top, bottom, gap=2.75):
    ys = [sum(targets_y[a]) / len(targets_y[a]) for a in actors]
    # empuja hacia abajo para respetar la separación, luego hacia arriba si se sale
    for i in range(1, len(ys)):
        ys[i] = min(ys[i], ys[i - 1] - gap)
    ys = [min(y, top - 0.9) for y in ys]
    for i in range(1, len(ys)):
        ys[i] = min(ys[i], ys[i - 1] - gap)
    if ys and ys[-1] < bottom + 1.9:
        shift = bottom + 1.9 - ys[-1]
        ys = [y + shift for y in ys]
        for i in range(len(ys) - 2, -1, -1):
            ys[i] = max(ys[i], ys[i + 1] + gap)
    return dict(zip(actors, ys))

def draw_paquete(p):
    sol = solve(p['ucs'], p['assoc'], p['rel'], fixed_left=[g for gg in p['gen'] for g in gg])
    _, order, L, R = sol
    hs = [max(1.45, 0.5 * len(uc_lines(k)) + 0.75) for k in order]
    gap_uc = 0.75
    total = sum(hs) + gap_uc * (len(order) - 1)
    top = total + 0.9
    y = top - 0.9; cy = {}; eh = {}
    for k, h in zip(order, hs):
        cy[k] = y - h / 2; eh[k] = h; y -= h + gap_uc
    bottom = 0.0
    tys = {a: [cy[u] for u in p['assoc'][a]] for a in p['assoc']}
    nact = max(len(L), len(R))
    need = nact * 2.75 + 0.6
    if need > top - bottom:
        extra = need - (top - bottom); top += extra / 2; bottom -= extra / 2
    H = top - bottom + 2.7
    fig = plt.figure(figsize=(W_FIG * CM, H * CM), dpi=300)
    ax = fig.add_axes([0, 0, 1, 1]); ax.set_xlim(0, W_FIG); ax.set_ylim(bottom - 0.8, bottom - 0.8 + H); ax.axis('off')
    ax.text(W_FIG / 2, top + 1.35, p['titulo'], ha='center', va='center', fontsize=13, fontweight='bold', color=NAVY)
    ax.text(W_FIG / 2, top + 0.75, p['sub'], ha='center', va='center', fontsize=9.5, color=GREY)
    by0 = min(cy[k] - eh[k] / 2 for k in order) - 0.35
    ax.add_patch(Rectangle((BX0, by0), BX1 - BX0, top + 0.3 - by0, fc='none', ec=NAVY, lw=1.3, zorder=1))
    ax.text(BX0 + 0.12, top + 0.15, 'MyWorksApp', ha='left', va='top', fontsize=9.5, color=NAVY)
    for k in order:
        ax.add_patch(Ellipse(((EX0 + EX1) / 2, cy[k]), EX1 - EX0, eh[k], fc=FILL, ec=OR, lw=1.4, zorder=3))
        ls = uc_lines(k)
        ax.text((EX0 + EX1) / 2, cy[k], '\n'.join(ls), ha='center', va='center', fontsize=UC_FS, color='#111111',
                linespacing=1.15, zorder=4)
    yl = place(L, tys, top, bottom); yr = place(R, tys, top, bottom)
    for side, ys, ax_x, sx, ex in (('L', yl, AXL, SL, EX0), ('R', yr, AXR, SR, EX1)):
        for a, ya in ys.items():
            stick(ax, ax_x, ya, ACT[a])
            hand = ax_x + (0.38 if side == 'L' else -0.38)
            ax.plot([hand, sx], [ya + 0.12, ya + 0.12], color=GREY, lw=0.9, zorder=2)
            for u in p['assoc'][a]:
                ax.plot([sx, ex], [ya + 0.12, cy[u]], color=GREY, lw=0.9, zorder=2)
    for a, b, lab in p['rel']:
        ya = cy[a] + (-eh[a] / 2 if cy[a] > cy[b] else eh[a] / 2)
        yb = cy[b] + (eh[b] / 2 if cy[a] > cy[b] else -eh[b] / 2)
        xm = (EX0 + EX1) / 2 + 1.2
        ax.add_patch(FancyArrowPatch((xm, ya), (xm, yb), arrowstyle='-|>', mutation_scale=10, color=OR, lw=1.1,
                                     linestyle=(0, (3, 2)), zorder=4, shrinkA=0, shrinkB=0))
        ax.text(xm + 0.12, (ya + yb) / 2, lab, ha='left', va='center', fontsize=9.5, color=OR, zorder=4)
    if p['gen']:
        tx = 0.22
        parent = p['gen'][0][1]
        yp = yl[parent] + 0.12
        lows = []
        for child, par in p['gen']:
            yc = yl[child] + 0.12
            ax.plot([AXL - 0.38, tx], [yc, yc], color=NAVY, lw=1.0, zorder=2); lows.append(yc)
        ax.plot([tx, tx], [min(lows), yp], color=NAVY, lw=1.0, zorder=2)
        ax.plot([tx, AXL - 0.62], [yp, yp], color=NAVY, lw=1.0, zorder=2)
        ax.add_patch(Polygon([[AXL - 0.42, yp], [AXL - 0.64, yp + 0.12], [AXL - 0.64, yp - 0.12]], closed=True,
                             fc='white', ec=NAVY, lw=1.0, zorder=3))
    f = os.path.join(OUT, f'cu_paquete_{p["n"]}.png')
    fig.savefig(f, dpi=300); fig.savefig(f.replace('.png', '.svg')); plt.close(fig)
    return dict(file=os.path.basename(f), w_cm=W_FIG, h_cm=H, orden=list(order), izq=L, der=R)

def draw_contexto():
    WC = 23.5
    acts = ['V', 'CI', 'CR', 'P', 'A', 'C', 'S', 'SA', 'T', 'TS']
    nombres = {'V': 'Visitante', 'CI': 'Cliente invitado', 'CR': 'Cliente registrado', 'P': 'Profesional',
               'A': 'Administrador', 'C': 'Colaborador interno', 'S': 'Sistema (planificador)',
               'SA': 'Supabase Auth / correo', 'T': 'Transbank Webpay', 'TS': 'Cloudflare Turnstile'}
    x0 = 4.9; colw = (WC - 0.2 - x0) / 6; rowh = 0.95; head = 2.9
    H = 1.9 + head + rowh * len(acts) + 0.9
    fig = plt.figure(figsize=(WC * CM, H * CM), dpi=300)
    ax = fig.add_axes([0, 0, 1, 1]); ax.set_xlim(0, WC); ax.set_ylim(0, H); ax.axis('off')
    ax.text(WC / 2, H - 0.45, 'Diagrama de contexto: actores y paquetes', ha='center', va='center',
            fontsize=13, fontweight='bold', color=NAVY)
    ax.text(WC / 2, H - 1.05, '34 casos de uso en 6 paquetes. ● = el actor participa en el paquete.',
            ha='center', va='center', fontsize=9.5, color=GREY)
    yh = H - 1.9
    ax.add_patch(Rectangle((x0 - 0.05, yh - head - rowh * len(acts) - 0.1), colw * 6 + 0.1, head + rowh * len(acts) + 0.1,
                           fc='none', ec=NAVY, lw=1.1))
    ax.text(x0 + 0.05, yh - 0.02 + 0.3, 'MyWorksApp', ha='left', va='center', fontsize=9.5, color=NAVY)
    for i, p in enumerate(PAQ):
        x = x0 + colw * i
        ax.add_patch(Rectangle((x + 0.06, yh - head + 0.08), colw - 0.12, head - 0.16, fc=FILL, ec=OR, lw=1.2))
        nom = p['titulo'].split(': ', 1)[1]
        ax.text(x + colw / 2, yh - 0.38, f'Paquete {p["n"]}', ha='center', va='center', fontsize=9, color=OR)
        ax.text(x + colw / 2, yh - 1.6, '\n'.join(textwrap.wrap(nom, 17)), ha='center', va='center',
                fontsize=9, fontweight='bold', color=NAVY, linespacing=1.05)
    for j, a in enumerate(acts):
        y = yh - head - rowh * (j + 0.5)
        c = NAVY if a not in ('SA', 'T', 'TS', 'S') else '#6B4E16'
        if j % 2 == 0:
            ax.add_patch(Rectangle((x0, y - rowh / 2), colw * 6, rowh, fc='#F2F4F8', ec='none', zorder=0))
        xs = 0.55
        ax.add_patch(plt.Circle((xs, y + 0.27), 0.1, fc='white', ec=c, lw=1.1))
        ax.plot([xs, xs], [y + 0.17, y - 0.12], color=c, lw=1.1)
        ax.plot([xs - 0.17, xs + 0.17], [y + 0.06, y + 0.06], color=c, lw=1.1)
        ax.plot([xs, xs - 0.14], [y - 0.12, y - 0.33], color=c, lw=1.1)
        ax.plot([xs, xs + 0.14], [y - 0.12, y - 0.33], color=c, lw=1.1)
        ax.text(0.95, y, nombres[a], ha='left', va='center', fontsize=9.5, fontweight='bold', color=c)
        for i, p in enumerate(PAQ):
            if p['n'] in CTX[a]:
                ax.add_patch(plt.Circle((x0 + colw * (i + 0.5), y), 0.15, fc=NAVY, ec=NAVY, zorder=3))
    ax.text(WC / 2, 0.45, 'Cliente invitado y Cliente registrado especializan a Visitante. '
            'En café: actor secundario y sistemas externos.', ha='center', va='center', fontsize=9, color=GREY)
    f = os.path.join(OUT, 'cu_contexto.png')
    fig.savefig(f, dpi=300); fig.savefig(f.replace('.png', '.svg')); plt.close(fig)
    return dict(file='cu_contexto.png', w_cm=WC, h_cm=H)

man = [draw_contexto()] + [draw_paquete(p) for p in PAQ]
json.dump(man, open(os.path.join(OUT, 'manifest.json'), 'w'), ensure_ascii=False, indent=1)
for m in man: print(m)
