root = exports ? this

navigator.getUserMedia = navigator.getUserMedia or navigator.webkitGetUserMedia or navigator.mozGetUserMedia or navigator.msGetUserMedia

setupAudioStream = (audioCtx, analyser, distortion, biquadFilter, convolver, gainNode) ->
  if navigator.getUserMedia
    navigator.getUserMedia { audio: true }, ((stream) ->
      source = audioCtx.createMediaStreamSource(stream)
      source.connect analyser
      analyser.connect distortion
      distortion.connect biquadFilter
      biquadFilter.connect convolver
      convolver.connect gainNode
      gainNode.connect audioCtx.destination
    ), (err) ->
      console.log err
  else
    console.log 'getUserMedia not supported'

createAudioAnalyser = (audioCtx) ->
  analyser = audioCtx.createAnalyser()
  analyser.minDecibels = -90
  analyser.maxDecibels = -10
  analyser.smoothingTimeConstant = 0.85
  analyser.fftSize = 32
  analyser

root.getAudioAnalyser = ->
  audioCtx = new ((window.AudioContext or window.webkitAudioContext))
  analyser = createAudioAnalyser(audioCtx)
  distortion = audioCtx.createWaveShaper()
  gainNode = audioCtx.createGain()
  biquadFilter = audioCtx.createBiquadFilter()
  convolver = audioCtx.createConvolver()
  setupAudioStream audioCtx, analyser, distortion, biquadFilter, convolver, gainNode
  analyser

root.getDataArray = (analyser) ->
  bufferLength = analyser.frequencyBinCount
  new Uint8Array(bufferLength)

# analyser = getAudioAnalyser()
# dataArray = getDataArray(analyser)
# draw = ->
#   requestAnimationFrame(draw);
#   analyser.getByteTimeDomainData(dataArray)
#   console.log(dataArray)
# draw();
