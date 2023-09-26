import {vec3, vec4} from 'gl-matrix';
const Stats = require('stats-js');
import * as DAT from 'dat.gui';
import Icosphere from './geometry/Icosphere';
import Square from './geometry/Square';
import OpenGLRenderer from './rendering/gl/OpenGLRenderer';
import Camera from './Camera';
import {setGL, gl} from './globals';
import ShaderProgram, {Shader} from './rendering/gl/ShaderProgram';

// Define an object with application parameters and button callbacks
// This will be referred to by dat.GUI's functions that add GUI elements.
const controls = {
  tesselations: 5,
  'load scene': loadScene, // A function pointer, essentially
  color1: [90, 15, 15],
  color2: [255, 230, 135],
  fbmOctaves: 8,
  fbmStrength: 0.6,
  'restore': restoreDefault,
};

let icosphere: Icosphere;
let square: Square;
let prevTesselations: number = 5;
let time: number;

// Add controls to the gui
const gui = new DAT.GUI();
gui.add(controls, 'tesselations', 0, 8).step(1);
gui.add(controls, 'load scene');
gui.addColor(controls, 'color1');
gui.addColor(controls, 'color2');
gui.add(controls, 'fbmOctaves', 1, 14).step(1);
gui.add(controls, 'fbmStrength', 0.1, 1.2).step(0.1);
gui.add(controls, 'restore');

function loadScene() {
  icosphere = new Icosphere(vec3.fromValues(0, 0, 0), 1, controls.tesselations);
  icosphere.create();
  square = new Square(vec3.fromValues(0, 0, 0));
  square.create();
}

function restoreDefault() {
  controls.tesselations = 5;
  controls.color1 = [90, 15, 15];
  controls.color2 = [256, 230, 135];
  controls.fbmOctaves = 8;
  controls.fbmStrength = 0.6;
  gui.updateDisplay();
}

function main() {
  // Initial display for framerate
  const stats = Stats();
  stats.setMode(0);
  stats.domElement.style.position = 'absolute';
  stats.domElement.style.left = '0px';
  stats.domElement.style.top = '0px';
  document.body.appendChild(stats.domElement);
  time = 0;

  // get canvas and webgl context
  const canvas = <HTMLCanvasElement> document.getElementById('canvas');
  const gl = <WebGL2RenderingContext> canvas.getContext('webgl2');
  if (!gl) {
    alert('WebGL 2 not supported!');
  }
  // `setGL` is a function imported above which sets the value of `gl` in the `globals.ts` module.
  // Later, we can import `gl` from `globals.ts` to access it
  setGL(gl);

  // Initial call to load scene
  loadScene();

  const camera = new Camera(vec3.fromValues(0, 0, 5), vec3.fromValues(0, 0, 0));

  const renderer = new OpenGLRenderer(canvas);
  renderer.setClearColor(0.2, 0.2, 0.2, 1);
  gl.enable(gl.DEPTH_TEST);

  const fireball = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/fireball-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/fireball-frag.glsl')),
  ]);

  const background = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/background-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/background-frag.glsl')),
  ]);


  // This function will be called every frame
  function tick() {
    camera.update();
    stats.begin();
    gl.viewport(0, 0, window.innerWidth, window.innerHeight);
    renderer.clear();
    time += 1;

    if(controls.tesselations != prevTesselations)
    {
      prevTesselations = controls.tesselations;
      icosphere = new Icosphere(vec3.fromValues(0, 0, 0), 1, prevTesselations);
      icosphere.create();
    }

    fireball.setGeometryColor1(vec4.fromValues(controls.color1[0] / 256, controls.color1[1] / 256, controls.color1[2] / 256, 1));
    fireball.setGeometryColor2(vec4.fromValues(controls.color2[0] / 256, controls.color2[1] / 256, controls.color2[2] / 256, 1));
    fireball.setOctaves(controls.fbmOctaves);
    fireball.setStrength(controls.fbmStrength);
    fireball.setTime(time);

    renderer.render(camera, fireball, [icosphere]);
    stats.end();

    
    background.setGeometryColor1(vec4.fromValues(controls.color1[0] / 256, controls.color1[1] / 256, controls.color1[2] / 256, 1));
    background.setTime(time);

    renderer.render(camera, background, [square]);
 
    // Tell the browser to call `tick` again whenever it renders a new frame
    requestAnimationFrame(tick);
  }

  window.addEventListener('resize', function() {
    renderer.setSize(window.innerWidth, window.innerHeight);
    camera.setAspectRatio(window.innerWidth / window.innerHeight);
    camera.updateProjectionMatrix();
  }, false);

  renderer.setSize(window.innerWidth, window.innerHeight);
  camera.setAspectRatio(window.innerWidth / window.innerHeight);
  camera.updateProjectionMatrix();

  // Start the render loop
  tick();
}

main();
