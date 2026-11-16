"""Genera docs/casos_de_uso_diagrama.png (diagrama UML de casos de uso). Uso: python docs/_gen_diagrama_casos_de_uso.py"""
import matplotlib; matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.patches import Ellipse, FancyBboxPatch, FancyArrowPatch
import os
OUT=os.path.join(os.path.dirname(os.path.abspath(__file__)), 'casos_de_uso_diagrama.png')
fig,ax=plt.subplots(figsize=(22,16)); ax.set_xlim(0,20); ax.set_ylim(-0.3,15.3); ax.axis('off')
NAVY='#00205B'; ORANGE='#FF5E03'
ax.add_patch(FancyBboxPatch((3.2,0.3),13.6,13.9,boxstyle='round,pad=0.02,rounding_size=0.2',fc='#f7f8fa',ec=NAVY,lw=2))
ax.text(10,13.95,'Sistema MyWorksApp',ha='center',va='center',fontsize=15,fontweight='bold',color=NAVY)
uc={
'09':('Comprar como\ninvitado',5.3,13.0),'10':('Definir contraseña\ntras pagar',5.3,11.8),'01':('Registrarse',5.3,10.4),
'05':('Buscar profesionales\ncon mapa y filtros',5.3,9.2),'06':('Ver perfil y\nhoras libres',5.3,8.0),
'07':('Solicitar servicio\ny reservar hora',8.5,12.6),'08':('Pagar con Webpay\nen garantía',8.5,11.2),'13':('Seguir el pedido\nen vivo',8.5,9.8),
'20':('Cancelar solicitud\ncon reembolso',8.5,8.3),'18':('Calificar al\nprofesional',8.5,6.5),'17':('Recibir conforme\ny liberar pago',8.5,4.8),
'15':('Cobro adicional\n(orden de cambio)',11.6,12.8),'14':('Iniciar trabajo\ncon PIN',11.6,11.5),'23':('Chatear sobre\nun trabajo',11.6,10.2),
'24':('Notificaciones',11.6,9.0),'02':('Iniciar sesión',11.6,7.95),'03':('Recuperar\ncontraseña',11.6,6.9),
'04':('Derechos sobre\nlos datos',11.6,5.85),'21':('Abrir disputa y\nproponer acuerdo',11.6,4.8),'22':('Resolver disputa',11.6,3.5),
'11':('Aceptar o rechazar\npedido',14.7,13.1),'12':('«Voy en camino»\ny GPS',14.7,12.0),'16':('Subir evidencia\ny finalizar',14.7,10.9),
'19':('Calificar al\ncliente',14.7,9.8),'25':('Perfil y\nverificación',14.7,8.7),'26':('Tarifas, horario\ny disponibilidad',14.7,7.6),
'27':('Cobros y cuenta\nbancaria',14.7,6.5),'28':('Consola con\nsegundo factor',14.7,5.3),'29':('Verificar\nprofesionales',14.7,4.2),
'30':('Métricas, pagos\ny liquidación',14.7,3.1),'31':('Invitar\ncolaborador',14.7,2.0),'32':('Procesos\nautomáticos',14.7,0.9),
'33':('Reagendar\nla visita',8.5,3.2),'34':('Atender cola de\nsoporte (soporte/QA)',11.6,2.1),
}
act={'V':('Visitante',1.3,8.6),'CI':('Cliente\ninvitado',1.3,11.9),'CR':('Cliente\nregistrado',1.3,4.6),
     'P':('Profesional',18.7,10.4),'A':('Administrador',18.7,3.8),'C':('Colaborador\ninterno',18.7,6.6),'S':('Sistema\n(pg_cron)',18.7,0.9),'T':('Transbank\nWebpay',1.5,14.4)}
W,H=2.55,0.92
def edge(x0,y0,x1,y1):
    # punto en el borde de la elipse destino (x1,y1) desde (x0,y0)
    import math
    dx,dy=x0-x1,y0-y1; t=1/math.sqrt((dx/(W/2))**2+(dy/(H/2))**2); return x1+dx*t,y1+dy*t
col={'V':'#57606a','CI':'#8250df','CR':ORANGE,'P':NAVY,'A':'#1a7f37','C':'#0969da','S':'#6e7781','T':'#cf222e'}
assoc={'V':['01','05','06'],'CI':['09','10'],'CR':['02','03','04','07','13','17','18','20','21','23','24','15','33'],
       'P':['02','03','04','11','12','14','15','16','19','21','23','24','25','26','27','33'],'A':['28','29','30','31','22'],'C':['28','34'],'S':['32','22'],'T':['08','09']}
for a,lst in assoc.items():
    _,ax0,ay0=act[a]
    sx = ax0+0.45 if ax0<10 and a!='T' else (ax0-0.45 if a!='T' else ax0+0.9)
    sy = ay0 if a!='T' else ay0-0.2
    for u in lst:
        _,x,y=uc[u]; ex,ey=edge(sx,sy,x,y)
        ax.plot([sx,ex],[sy,ey],color=col[a],lw=1.1,alpha=.55,zorder=1)
for k,(lab,x,y) in uc.items():
    ax.add_patch(Ellipse((x,y),W,H,fc='white',ec=NAVY,lw=1.4,zorder=3))
    ax.text(x,y+0.02,f'CU-{k}\n{lab}',ha='center',va='center',fontsize=8.6,zorder=4,linespacing=1.05)
def stick(x,y,lab,c):
    ax.add_patch(plt.Circle((x,y+0.55),0.17,fc='white',ec=c,lw=2,zorder=5))
    ax.plot([x,x],[y+0.38,y-0.1],color=c,lw=2,zorder=5); ax.plot([x-0.3,x+0.3],[y+0.2,y+0.2],color=c,lw=2,zorder=5)
    ax.plot([x,x-0.25],[y-0.1,y-0.5],color=c,lw=2,zorder=5); ax.plot([x,x+0.25],[y-0.1,y-0.5],color=c,lw=2,zorder=5)
    ax.text(x,y-0.85,lab,ha='center',va='center',fontsize=11,fontweight='bold',color=c)
for k,(lab,x,y) in act.items():
    if k=='T':
        ax.add_patch(FancyBboxPatch((x-0.9,y-0.4),1.8,0.8,boxstyle='round,pad=0.02',fc='#fff5f5',ec=col[k],lw=1.5,zorder=5))
        ax.text(x,y,'«sistema externo»\n'+lab.replace('\n',' '),ha='center',va='center',fontsize=9,color=col[k],zorder=6)
    else: stick(x,y,lab,col[k])
# generalización
ax.annotate('',xy=(1.3,9.35),xytext=(1.3,10.75),arrowprops=dict(arrowstyle='-|>',color='#57606a',lw=1.3,mutation_scale=18))
ax.annotate('',xy=(1.3,7.55),xytext=(1.3,5.4),arrowprops=dict(arrowstyle='-|>',color='#57606a',lw=1.3,mutation_scale=18))
# include / extend
rel=[('07','08','«include»'),('09','08','«include»'),('10','09','«extend»'),('18','17','«extend»'),('21','17','«extend»'),('22','21','«extend»')]
for a,b,t in rel:
    _,x0,y0=uc[a]; _,x1,y1=uc[b]
    sx,sy=edge(x1,y1,x0,y0); ex,ey=edge(x0,y0,x1,y1)
    ax.add_patch(FancyArrowPatch((sx,sy),(ex,ey),arrowstyle='->',mutation_scale=14,ls='--',color='#444',lw=1.2,zorder=2))
    ax.text((sx+ex)/2+0.08,(sy+ey)/2,t,fontsize=7.5,color='#444',style='italic',zorder=6,bbox=dict(fc='#f7f8fa',ec='none',pad=0.5))
ax.text(10,-0.1,'Líneas de color: asociación actor–caso de uso. Flecha punteada: «include» (siempre) / «extend» (condicional). Flecha con triángulo: generalización (invitado y registrado son visitantes).',
        ha='center',fontsize=9.5,color='#333')
plt.savefig(OUT,dpi=110,bbox_inches='tight',facecolor='white'); print('ok')
