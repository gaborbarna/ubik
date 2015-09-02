navigator.getUserMedia = (navigator.getUserMedia ||
                          navigator.webkitGetUserMedia ||
                          navigator.mozGetUserMedia ||
                          navigator.msGetUserMedia);

function setupAudioStream(audioCtx, analyser, distortion, biquadFilter, convolver, gainNode) {
    if (navigator.getUserMedia) {
	navigator.getUserMedia(
	    {audio: true},
	    function(stream) {
		source = audioCtx.createMediaStreamSource(stream);
		source.connect(analyser);
		analyser.connect(distortion);
		distortion.connect(biquadFilter);
		biquadFilter.connect(convolver);
		convolver.connect(gainNode);
		gainNode.connect(audioCtx.destination);
            },
	    function(err) {
		console.log(err);
	    }
	);
    } else {
	console.log('getUserMedia not supported');
    }
};

function createAudioAnalyser(audioCtx) {
    var analyser = audioCtx.createAnalyser();
    analyser.minDecibels = -90;
    analyser.maxDecibels = -10;
    analyser.smoothingTimeConstant = 0.85;
    analyser.fftSize = 32;
    return analyser;
};

function getAudioAnalyser() {
    var audioCtx = new (window.AudioContext || window.webkitAudioContext)();
    var analyser = createAudioAnalyser(audioCtx);
    var distortion = audioCtx.createWaveShaper();
    var gainNode = audioCtx.createGain();
    var biquadFilter = audioCtx.createBiquadFilter();
    var convolver = audioCtx.createConvolver();
    setupAudioStream(audioCtx, analyser, distortion, biquadFilter, convolver, gainNode);
    return analyser;
};

function getDataArray(analyser) {
    var bufferLength = analyser.frequencyBinCount;
    return new Uint8Array(bufferLength);
};

// var analyser = getAnalyser();
// var dataArray = getDataArray(analyser);

// function draw() {
//     drawVisual = requestAnimationFrame(draw);
//     analyser.getByteTimeDomainData(dataArray);
//     if (dataArray[0] > 150) {
// 	console.log(dataArray);
//     }
// };

// draw();
