/* Persistent orbital backdrop. One renderer is shared by every game view. */
(() => {
  'use strict';
  const host = document.getElementById('orbitalBackground');
  if (!host || !window.THREE) return;
  let renderer, scene, camera, earth, clouds, stars, raf = 0, last = 0, quality = 'high', paused = false;
  const reduced = matchMedia('(prefers-reduced-motion: reduce)').matches;
  try {
    renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true, powerPreference: 'low-power' });
    renderer.setClearColor(0x040912, 1);
    renderer.outputEncoding = THREE.sRGBEncoding;
    renderer.toneMapping = THREE.ACESFilmicToneMapping;
    renderer.toneMappingExposure = 1.05;
    host.appendChild(renderer.domElement);
    scene = new THREE.Scene();
    camera = new THREE.PerspectiveCamera(45, 1, .1, 1200);
    camera.position.set(0, 0, 10);
    const loader = new THREE.TextureLoader();
    const maps = window.STEarthTextures || {};
    const load = (path, srgb) => { const t = loader.load(path); if (srgb) t.encoding = THREE.sRGBEncoding; t.anisotropy = 4; return t; };
    const planet = new THREE.Group();
    planet.rotation.z = .19;
    scene.add(planet);
    earth = new THREE.Mesh(new THREE.SphereGeometry(6.5, 64, 40), new THREE.MeshPhongMaterial({
      map: load(maps.surface, true), normalMap: load(maps.normal), normalScale: new THREE.Vector2(.45, .45),
      specularMap: load(maps.specular), specular: new THREE.Color('#142534').convertSRGBToLinear(), shininess: 30
    }));
    earth.rotation.y = 2.4;
    planet.add(earth);
    clouds = new THREE.Mesh(new THREE.SphereGeometry(6.52, 56, 36), new THREE.MeshPhongMaterial({ map: load(maps.clouds, true), transparent: true, opacity: .78, depthWrite: false, alphaTest: .025 }));
    clouds.rotation.y = 2.43;
    planet.add(clouds);
    const halo = (radius, strength, side) => new THREE.Mesh(new THREE.SphereGeometry(radius, 48, 32), new THREE.ShaderMaterial({
      uniforms: { strength: { value: strength } },
      vertexShader: 'varying vec3 n;varying vec3 p;void main(){vec4 w=modelMatrix*vec4(position,1.);p=w.xyz;n=normalize(mat3(modelMatrix)*normal);gl_Position=projectionMatrix*viewMatrix*w;}',
      fragmentShader: 'uniform float strength;varying vec3 n;varying vec3 p;void main(){float r=pow(1.-abs(dot(normalize(n),normalize(cameraPosition-p))),4.2);gl_FragColor=vec4(.24,.55,1.,r*strength);}',
      transparent: true, blending: THREE.AdditiveBlending, side, depthWrite: false
    }));
    planet.add(halo(6.68, .7, THREE.BackSide));
    planet.add(halo(6.55, .16, THREE.FrontSide));
    const sun = new THREE.DirectionalLight('#fff0da', 1.45); sun.position.set(-8, 10, 8); scene.add(sun);
    scene.add(new THREE.HemisphereLight('#adc9e9', '#172b49', .38));
    const bounce = new THREE.DirectionalLight('#5595e4', .35); bounce.position.set(0, -8, -4); scene.add(bounce);
    const positions = [], colors = [], sizes = [], phases = [];
    let seed = 740291;
    const random = () => { seed = (Math.imul(seed, 1664525) + 1013904223) >>> 0; return seed / 4294967296; };
    for (let i = 0; i < 2200; i++) {
      const theta = random() * Math.PI * 2, y = random() * 2 - 1, r = 350 + random() * 450, q = Math.sqrt(1 - y * y);
      positions.push(Math.cos(theta) * q * r, y * r, Math.sin(theta) * q * r);
      const c = new THREE.Color(random() < .15 ? '#a9c9ff' : random() > .9 ? '#ffe0b4' : '#dce8f5').multiplyScalar(.35 + random() * .65);
      colors.push(c.r, c.g, c.b); sizes.push(.6 + Math.pow(random(), 3) * 2.2); phases.push(random() * 6.28);
    }
    const geometry = new THREE.BufferGeometry();
    geometry.setAttribute('position', new THREE.Float32BufferAttribute(positions, 3));
    geometry.setAttribute('color', new THREE.Float32BufferAttribute(colors, 3));
    geometry.setAttribute('aSize', new THREE.Float32BufferAttribute(sizes, 1));
    geometry.setAttribute('aPhase', new THREE.Float32BufferAttribute(phases, 1));
    stars = new THREE.Points(geometry, new THREE.ShaderMaterial({
      uniforms: { time: { value: 0 }, dpr: { value: 1 } }, vertexColors: true, transparent: true, depthWrite: false, blending: THREE.AdditiveBlending,
      vertexShader: 'attribute float aSize;attribute float aPhase;uniform float time;uniform float dpr;varying vec3 c;varying float a;void main(){c=color;a=.82+.18*sin(time*.5+aPhase);gl_PointSize=aSize*dpr;gl_Position=projectionMatrix*modelViewMatrix*vec4(position,1.);}',
      fragmentShader: 'varying vec3 c;varying float a;void main(){float d=length(gl_PointCoord-vec2(.5));gl_FragColor=vec4(c*a,smoothstep(.5,.08,d));}'
    }));
    scene.add(stars);
    const resize = () => {
      const w = innerWidth, h = innerHeight;
      renderer.setPixelRatio(quality === 'high' ? Math.min(devicePixelRatio || 1, 1.35) : .75);
      renderer.setSize(w, h);
      camera.aspect = w / h; camera.updateProjectionMatrix();
      planet.position.set(camera.aspect * 4.1, -6.1, -6);
      stars.material.uniforms.dpr.value = renderer.getPixelRatio();
    };
    addEventListener('resize', resize); resize();
    const frame = time => {
      raf = requestAnimationFrame(frame);
      if (paused || document.hidden || quality === 'off' || time - last < (quality === 'high' ? 33 : 100)) return;
      const dt = last ? Math.min((time - last) / 1000, .1) : 0; last = time;
      if (!reduced) { earth.rotation.y += dt * .004; clouds.rotation.y += dt * .006; stars.material.uniforms.time.value = time / 1000; }
      renderer.render(scene, camera);
    };
    raf = requestAnimationFrame(frame);
    window.STBackground = {
      setQuality(value) { quality = ['high', 'low', 'off'].includes(value) ? value : 'high'; host.hidden = quality === 'off'; if (quality !== 'off') { resize(); last = 0; } },
      setPaused(value) { paused = !!value; },
      get diagnostics() { return { quality, calls: renderer.info.render.calls, triangles: renderer.info.render.triangles, textures: renderer.info.memory.textures }; }
    };
    renderer.domElement.addEventListener('webglcontextlost', event => { event.preventDefault(); host.hidden = true; });
  } catch (error) {
    host.hidden = true;
    window.STBackground = { setQuality() {}, setPaused() {}, diagnostics: { quality: 'fallback' } };
  }
})();
