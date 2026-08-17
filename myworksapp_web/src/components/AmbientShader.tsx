interface AmbientShaderProps {
  category: string;
}

export function AmbientShader({ category }: AmbientShaderProps) {
  const getGlowColor = () => {
    switch (category) {
      case 'plumbing':
        return 'rgba(0, 122, 255, 0.15)'; // Blue Aqua
      case 'electrical':
        return 'rgba(255, 149, 0, 0.15)'; // Gold Amber
      case 'cleaning':
        return 'rgba(52, 199, 89, 0.15)'; // Emerald Green
      default:
        return 'rgba(240, 120, 42, 0.15)'; // Orange Accent
    }
  };

  return (
    <div 
      style={{
        position: 'fixed',
        top: 0,
        left: 0,
        right: 0,
        height: '400px',
        pointerEvents: 'none',
        zIndex: 0,
        background: `radial-gradient(circle at 50% 0%, ${getGlowColor()} 0%, transparent 70%)`,
        transition: 'background 0.8s ease',
      }}
    />
  );
}
