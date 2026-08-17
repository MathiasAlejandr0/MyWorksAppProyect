import { useEffect, useState } from 'react';

export function AppleSpatialBackground() {
  const [mousePos, setMousePos] = useState({ x: 0, y: 0 });

  useEffect(() => {
    const handleMouseMove = (e: MouseEvent) => {
      setMousePos({
        x: (e.clientX / window.innerWidth - 0.5) * 40,
        y: (e.clientY / window.innerHeight - 0.5) * 40,
      });
    };

    window.addEventListener('mousemove', handleMouseMove);
    return () => window.removeEventListener('mousemove', handleMouseMove);
  }, []);

  return (
    <div
      style={{
        position: 'fixed',
        inset: 0,
        pointerEvents: 'none',
        zIndex: 0,
        overflow: 'hidden',
      }}
    >
      {/* 1. Malla Orbe Naranja Calentado */}
      <div
        style={{
          position: 'absolute',
          top: '-10%',
          left: '20%',
          width: '550px',
          height: '550px',
          borderRadius: '50%',
          background: 'radial-gradient(circle, rgba(240, 120, 42, 0.18) 0%, rgba(255, 107, 0, 0) 70%)',
          filter: 'blur(90px)',
          animation: 'meshOrbit1 22s infinite ease-in-out',
          transform: `translate3d(${mousePos.x * 0.5}px, ${mousePos.y * 0.5}px, 0)`,
          transition: 'transform 0.2s ease-out',
        }}
      />

      {/* 2. Malla Orbe Azul Espacial Apple */}
      <div
        style={{
          position: 'absolute',
          top: '30%',
          right: '10%',
          width: '600px',
          height: '600px',
          borderRadius: '50%',
          background: 'radial-gradient(circle, rgba(0, 122, 255, 0.14) 0%, rgba(10, 132, 255, 0) 70%)',
          filter: 'blur(100px)',
          animation: 'meshOrbit2 28s infinite ease-in-out',
          transform: `translate3d(${mousePos.x * -0.6}px, ${mousePos.y * -0.6}px, 0)`,
          transition: 'transform 0.2s ease-out',
        }}
      />

      {/* 3. Malla Orbe Esmeralda Éxito */}
      <div
        style={{
          position: 'absolute',
          bottom: '5%',
          left: '15%',
          width: '500px',
          height: '500px',
          borderRadius: '50%',
          background: 'radial-gradient(circle, rgba(52, 199, 89, 0.12) 0%, rgba(48, 209, 88, 0) 70%)',
          filter: 'blur(90px)',
          animation: 'meshOrbit3 25s infinite ease-in-out',
          transform: `translate3d(${mousePos.x * 0.4}px, ${mousePos.y * 0.4}px, 0)`,
          transition: 'transform 0.2s ease-out',
        }}
      />

      {/* 4. Trama de Retícula Holográfica sutil */}
      <div
        style={{
          position: 'absolute',
          inset: 0,
          backgroundImage: `radial-gradient(rgba(240, 120, 42, 0.04) 1px, transparent 1px)`,
          backgroundSize: '32px 32px',
          opacity: 0.6,
        }}
      />
    </div>
  );
}
