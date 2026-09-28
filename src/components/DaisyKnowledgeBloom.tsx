import React, { useEffect, useRef } from 'react';

const TAU = Math.PI * 2;
const glyphs = ['∞', '✦', '∴', '◌', 'λ', '01', '✧', '∿'];
const palette = ['#7df9d2', '#83d7ff', '#bca8ff', '#ffe58a', '#ff9bd8'];

type Particle = {
  x: number;
  y: number;
  r: number;
  phase: number;
  speed: number;
  color: string;
  glyph: string;
};

type Bloom = {
  x: number;
  y: number;
  radius: number;
  phase: number;
  rotation: number;
  hue: number;
};

function seeded(seed: number) {
  let value = seed >>> 0;
  return () => {
    value = (value * 1664525 + 1013904223) >>> 0;
    return value / 4294967296;
  };
}

function roundedPath(ctx: CanvasRenderingContext2D, x: number, y: number, radius: number, sides: number, rotation: number) {
  ctx.beginPath();
  for (let i = 0; i <= sides; i += 1) {
    const angle = rotation + (i / sides) * TAU;
    const wobble = radius * (0.84 + 0.16 * Math.sin(i * 2.7 + rotation));
    const px = x + Math.cos(angle) * wobble;
    const py = y + Math.sin(angle) * wobble;
    if (i === 0) ctx.moveTo(px, py);
    else ctx.lineTo(px, py);
  }
  ctx.closePath();
}

function drawDaisy(ctx: CanvasRenderingContext2D, bloom: Bloom, time: number, width: number, height: number) {
  const x = bloom.x * width;
  const y = bloom.y * height;
  const pulse = 1 + Math.sin(time * 0.0007 + bloom.phase) * 0.08;
  const radius = bloom.radius * pulse;
  const petalCount = 9 + Math.floor((bloom.phase * 10) % 5);

  ctx.save();
  ctx.translate(x, y);
  ctx.rotate(bloom.rotation + Math.sin(time * 0.00012 + bloom.phase) * 0.2);
  ctx.globalCompositeOperation = 'lighter';

  const halo = ctx.createRadialGradient(0, 0, 0, 0, 0, radius * 2.2);
  halo.addColorStop(0, `hsla(${bloom.hue}, 90%, 78%, .14)`);
  halo.addColorStop(0.6, `hsla(${bloom.hue + 35}, 95%, 70%, .045)`);
  halo.addColorStop(1, 'transparent');
  ctx.fillStyle = halo;
  ctx.beginPath();
  ctx.arc(0, 0, radius * 2.2, 0, TAU);
  ctx.fill();

  for (let i = 0; i < petalCount; i += 1) {
    const angle = (i / petalCount) * TAU;
    ctx.save();
    ctx.rotate(angle);
    const petal = ctx.createLinearGradient(0, 0, radius * 1.7, 0);
    petal.addColorStop(0, `hsla(${bloom.hue}, 100%, 78%, .42)`);
    petal.addColorStop(0.35, `hsla(${bloom.hue + 22}, 100%, 82%, .16)`);
    petal.addColorStop(1, 'transparent');
    ctx.fillStyle = petal;
    ctx.beginPath();
    ctx.ellipse(radius * 0.8, 0, radius * 0.95, radius * 0.17, 0, 0, TAU);
    ctx.fill();
    ctx.restore();
  }

  const core = ctx.createRadialGradient(-radius * 0.12, -radius * 0.12, 0, 0, 0, radius * 0.36);
  core.addColorStop(0, '#fffbe1');
  core.addColorStop(0.35, `hsla(${bloom.hue + 35}, 100%, 72%, .95)`);
  core.addColorStop(1, `hsla(${bloom.hue}, 100%, 55%, .08)`);
  ctx.fillStyle = core;
  ctx.beginPath();
  ctx.arc(0, 0, radius * 0.32, 0, TAU);
  ctx.fill();

  ctx.strokeStyle = `hsla(${bloom.hue + 20}, 100%, 84%, .3)`;
  ctx.lineWidth = 0.7;
  ctx.beginPath();
  ctx.arc(0, 0, radius * 0.57, 0, TAU);
  ctx.stroke();
  ctx.restore();
}

export const DaisyKnowledgeBloom: React.FC = () => {
  const canvasRef = useRef<HTMLCanvasElement>(null);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const context = canvas.getContext('2d');
    if (!context) return;

    let width = 0;
    let height = 0;
    let frame = 0;
    let start = performance.now();
    let seedIndex = Math.floor(Date.now() / 18000);
    let random = seeded(seedIndex);
    let particles: Particle[] = [];
    let blooms: Bloom[] = [];

    const resize = () => {
      const ratio = Math.min(window.devicePixelRatio || 1, 2);
      width = window.innerWidth;
      height = window.innerHeight;
      canvas.width = Math.floor(width * ratio);
      canvas.height = Math.floor(height * ratio);
      canvas.style.width = `${width}px`;
      canvas.style.height = `${height}px`;
      context.setTransform(ratio, 0, 0, ratio, 0, 0);

      random = seeded(seedIndex);
      particles = Array.from({ length: Math.min(150, Math.max(70, Math.floor(width / 9))) }, () => ({
        x: random(),
        y: random(),
        r: 0.5 + random() * 1.8,
        phase: random() * TAU,
        speed: 0.00005 + random() * 0.00012,
        color: palette[Math.floor(random() * palette.length)],
        glyph: glyphs[Math.floor(random() * glyphs.length)]
      }));
      blooms = Array.from({ length: 11 }, () => ({
        x: 0.08 + random() * 0.84,
        y: 0.1 + random() * 0.78,
        radius: 22 + random() * 55,
        phase: random() * TAU,
        rotation: random() * TAU,
        hue: 150 + random() * 130
      }));
    };

    const observer = new ResizeObserver(resize);
    observer.observe(document.body);
    resize();

    const render = (now: number) => {
      const elapsed = now - start;
      const nextSeed = Math.floor(Date.now() / 18000);
      if (nextSeed !== seedIndex) {
        seedIndex = nextSeed;
        resize();
        start = now;
      }

      const drift = elapsed * 0.00004;
      const gradient = context.createRadialGradient(width * 0.5, height * 0.42, 0, width * 0.5, height * 0.5, Math.max(width, height) * 0.8);
      gradient.addColorStop(0, '#0c1b2a');
      gradient.addColorStop(0.45, '#07131f');
      gradient.addColorStop(1, '#02060c');
      context.fillStyle = gradient;
      context.fillRect(0, 0, width, height);

      context.globalCompositeOperation = 'lighter';
      for (let i = 0; i < 4; i += 1) {
        const x = width * (0.2 + i * 0.22) + Math.sin(drift * (i + 2)) * width * 0.09;
        const y = height * (0.25 + (i % 2) * 0.4) + Math.cos(drift * (i + 3)) * height * 0.08;
        const haze = context.createRadialGradient(x, y, 0, x, y, Math.min(width, height) * 0.32);
        haze.addColorStop(0, `hsla(${165 + i * 38}, 90%, 65%, .055)`);
        haze.addColorStop(1, 'transparent');
        context.fillStyle = haze;
        context.fillRect(0, 0, width, height);
      }

      const nodes = particles.map((particle, index) => ({
        x: (particle.x * width + Math.sin(elapsed * particle.speed + particle.phase) * 18 + width) % width,
        y: (particle.y * height + Math.cos(elapsed * particle.speed * 1.3 + particle.phase) * 16 + height) % height,
        particle,
        index
      }));

      context.lineWidth = 0.45;
      for (let i = 0; i < nodes.length; i += 1) {
        const a = nodes[i];
        for (let j = i + 1; j < nodes.length && j < i + 9; j += 1) {
          const b = nodes[j];
          const dx = a.x - b.x;
          const dy = a.y - b.y;
          const distance = Math.sqrt(dx * dx + dy * dy);
          if (distance < 125) {
            context.strokeStyle = `rgba(109, 226, 215, ${0.1 * (1 - distance / 125)})`;
            context.beginPath();
            context.moveTo(a.x, a.y);
            context.quadraticCurveTo((a.x + b.x) / 2, (a.y + b.y) / 2 + Math.sin(elapsed * 0.001 + i) * 8, b.x, b.y);
            context.stroke();
          }
        }
      }

      nodes.forEach(({ x, y, particle, index }) => {
        const alpha = 0.3 + 0.3 * Math.sin(elapsed * 0.001 + particle.phase);
        context.fillStyle = particle.color;
        context.globalAlpha = alpha;
        context.beginPath();
        context.arc(x, y, particle.r, 0, TAU);
        context.fill();
        if (index % 13 === 0) {
          context.font = `${9 + (index % 3)}px ui-monospace, monospace`;
          context.fillText(particle.glyph, x + 5, y - 5);
        }
      });

      context.globalAlpha = 1;
      blooms.forEach((bloom) => drawDaisy(context, bloom, elapsed, width, height));

      // A slowly rotating “brain halo”: two lobes made of living neural arcs.
      context.globalCompositeOperation = 'lighter';
      const cx = width * 0.5 + Math.sin(elapsed * 0.00013) * width * 0.08;
      const cy = height * 0.53 + Math.cos(elapsed * 0.00017) * height * 0.06;
      context.strokeStyle = 'rgba(176, 154, 255, .14)';
      context.lineWidth = 1.1;
      for (let side = -1; side <= 1; side += 2) {
        context.beginPath();
        context.ellipse(cx + side * 24, cy, 72, 92, side * 0.13, Math.PI * 0.2, Math.PI * 1.8);
        context.stroke();
      }
      context.strokeStyle = 'rgba(132, 244, 218, .16)';
      for (let i = 0; i < 7; i += 1) {
        const y = cy - 53 + i * 17;
        context.beginPath();
        context.moveTo(cx - 40, y);
        context.bezierCurveTo(cx - 14, y - 12, cx - 7, y + 12, cx + 3, y);
        context.bezierCurveTo(cx + 16, y - 12, cx + 20, y + 12, cx + 43, y - 4);
        context.stroke();
      }

      context.globalCompositeOperation = 'source-over';
      context.globalAlpha = 1;
      frame = requestAnimationFrame(render);
    };

    frame = requestAnimationFrame(render);
    return () => {
      cancelAnimationFrame(frame);
      observer.disconnect();
    };
  }, []);

  return <canvas ref={canvasRef} className="daisy-knowledge-bloom" aria-hidden="true" />;
};
