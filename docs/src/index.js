if ('serviceWorker' in navigator) {
  window.addEventListener('load', () => {
    navigator.serviceWorker
      .register('sw.js')
      .then(reg => console.log('Service Worker: Registered (Pages)'))
      .catch(err => console.log(`Service Worker: Error: ${err}`));
  });
}
    
import './styles/index.scss';
import * as tf from '@tensorflow/tfjs';
import yolo from 'tfjs-yolo';

const button = document.getElementById('button');
const loading = document.getElementById('loading');
const webcam = document.getElementById('webcam');
const prediction = document.getElementById('prediction');
const text = document.getElementById('text');
const buttongroup = document.getElementById('buttongroup');
const canvas = document.getElementById('canvas');
const ctx = canvas.getContext('2d');

let cnt = 0;
const totalModel = 11;
Promise.all = (all => {
  return function then(reqs){
    if (reqs.length === totalModel && cnt < totalModel*2)
      reqs.map(req => {
        return req.then(r => {
          loading.setAttribute('percent', (++cnt/totalModel*50).toFixed(1));
          if (cnt === totalModel*2){
            button.style.display = 'block';
            setTimeout(() => loading.style.display = 'none');
          }
        });
      });
    return all.apply(this, arguments);
  }
})(Promise.all);

let myYolo;
let boxes;

(async function main() {
  try {
    await setupWebCam();
    myYolo = await yolo.v2tiny(
      "./dist/model/weights_manifest.json", 
      "./dist/model/tensorflowjs_model.pb"
    );
    button.addEventListener('click', () => {
      button.style.display = 'none';
      setTimeout(() => capture(), 10);
    });
    window.addEventListener('resize', event => clear());
    canvas.addEventListener('click', () => showBoxes());
    document.getElementById('nothanks').addEventListener('click', () => clear());
  } catch (e) {
    console.error(e);
  }
})();

async function setupWebCam() {
  if (navigator.mediaDevices && navigator.mediaDevices.getUserMedia) {
    const stream = await navigator.mediaDevices.getUserMedia({
      'audio': false,
      'video': {facingMode: 'environment'}
    });
    window.stream = stream;
    webcam.srcObject = stream;
  }
}

async function capture() {
  const winW = window.innerWidth;
  const winH = window.innerHeight;
  const vidW = webcam.videoWidth;
  const vidH = webcam.videoHeight;

  canvas.height = winH;
  canvas.width = winW;

  if (winH > winW)
    ctx.drawImage(webcam, (winW - vidW * winH / vidH) / 2, 0, vidW * winH / vidH, winH);
  else
    ctx.drawImage(webcam, 0, (winH - vidH * winW / vidW) / 2, winW, vidH * winW / vidW);

  await predict();
  showResult();
  buttongroup.style.display = 'block';
}

async function predict() {
  console.log(`${tf.memory().numTensors} tensors`);

  const start = performance.now();
  boxes = await myYolo(canvas, { numClasses: 1, classNames: ["hotdog"], scoreThreshold: .6 });
  const end = performance.now();

  console.log(`${end - start} ms`);
  console.log(`${tf.memory().numTensors} tensors`);
  console.log(boxes);
}

function showResult() {
  if (boxes && boxes.length > 0) {
    prediction.classList.add("hotdog");
  } else {
    prediction.classList.add("nothotdog");
  }
  text.classList.add("text");
}

function showBoxes() {
  if (boxes)
    boxes.map((box) => {
      ctx.lineWidth = 3;
      ctx.rect(box["left"], box["top"], box["width"], box["height"]);
      ctx.font="18px sans-serif";
      ctx.fillStyle = "#25d5fd";
      ctx.fillText(box["score"].toFixed(2), box["left"] + 5, box["top"] + 20);
      ctx.strokeStyle = "#25d5fd";
      ctx.stroke();
    });
}

function clear() {
  ctx.clearRect(0, 0, canvas.width, canvas.height);
  text.className = '';
  prediction.className = 'slide-in';
  if (buttongroup.style.display === 'block' ) {
    buttongroup.style.display = 'none';
    button.style.display = 'block';
  }
}

