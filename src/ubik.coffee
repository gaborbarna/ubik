framesize = 20
videos = 
  bg: {0: 'bg_0.mp4', 1: 'bg_1.mp4', 2: 'bg_2.mp4', 3: 'bg_3.mp4', 4: 'bg_4.mp4'}
  fg: {0: 'fg_0.mp4', 1: 'fg_1.mp4', 2: 'fg_2.mp4', 3: 'fg_3.mp4', 4: 'fg_4.mp4'}


class Animation
  constructor: (@id) ->
  update: (delta, now, audioData) ->
  start: ->
  stop: ->

class VideoAnimation extends Animation
  constructor: (@id) ->

  getVideoTexture: (url) ->
    videoTexture = new (THREEx.VideoTexture)(url)
    videoTexture.minFilter = THREE.LinearFilter
    videoTexture

  getMaterial: (videoTexture) ->
    new (THREE.MeshBasicMaterial)(map: videoTexture.texture)

  update: (delta, now, audioData) ->
    @videoTexture.update delta, now

  start: ->
    video = @videoTexture.video
    video.play()

  stop: ->
    @videoTexture.video.pause()

class CircleVideoAnimation extends VideoAnimation
  constructor: (@id) ->
    @url = videos.fg[@id]
    @videoTexture = @getVideoTexture(@url)
    material = @getMaterial(@videoTexture)
    @mesh = getCircleMesh(material, 0.2)
    @mesh.position.set 0, 0, 0.1

class BoxAnimation extends Animation
  constructor: (@id) ->
    material = @getMaterial()
    @mesh = @getBoxMesh(material)
    @mesh.position.set 0, 0, 0.1

  getMaterial: ->
    new THREE.MeshLambertMaterial {color: 0xCC0000}

  getBoxMesh: (material) ->
    side = 0.15
    rings = 16
    new THREE.Mesh(new THREE.BoxGeometry(side, side, side), material)

  update: (delta, now, audioData) ->
    @mesh.rotation.x += 0.1 if audioData[0] > 140
    @mesh.rotation.y += 0.1 if audioData[1] > 140

class PlaneVideoAnimation extends VideoAnimation
  constructor: (@id) ->
    @url = videos.bg[@id]
    @videoTexture = @getVideoTexture(@url)
    material = @getMaterial(@videoTexture)
    @mesh = getPlaneMesh(material)

setupRenderer = ->
  renderer = new (THREE.WebGLRenderer)(antialias: true)
  renderer.setClearColor new (THREE.Color)('lightgrey'), 1
  renderer.setSize 1920 - (framesize * 2), 1080 - (framesize * 2)
  renderer

setupCamera = (scene) ->
  camera = new (THREE.PerspectiveCamera)(45, (1920 - (framesize * 2)) / (1080 - (framesize * 2)), 0.1, 10000)
  camera.position.set 0, 0, 1
  camera.lookAt scene.position
  camera

setupLight = ->
  light = new (THREE.PointLight)(0xFFFF00)
  light.position.set 10, 0, 10
  light

getCircleMesh = (material, radius) ->
  segments = 128
  circleGeometry = new (THREE.CircleGeometry)(radius, segments)
  new (THREE.Mesh)(circleGeometry, material)

getPlaneMesh = (material) ->
  planeGeometry = new (THREE.PlaneGeometry)(1.5, 0.83)
  new (THREE.Mesh)(planeGeometry, material)

startLoop = (render_fn, current_animations, audioData) ->
  lastTimeMsec = null
  animate = (nowMsec) ->
    setTimeout (-> requestAnimationFrame animate), 1000 / 30
    lastTimeMsec = lastTimeMsec or nowMsec - (1000 / 60)
    deltaMsec = Math.min(200, nowMsec - lastTimeMsec)
    lastTimeMsec = nowMsec
    _.forEach current_animations, (anim, key) ->
      anim.update(deltaMsec/1000, nowMsec/1000, audioData)
    render_fn()
  requestAnimationFrame(animate)

removeVideoAnim = (animations, anim_id, scene) ->
  anim = animations[anim_id]
  anim.stop()
  scene.remove anim.mesh

addVideoAnim = (anim_type, url, scene, current_animations) ->
  current_animations[anim_type]
  scene.add mesh

createStats = ->
  stats = new Stats
  document.body.appendChild stats.domElement
  stats.domElement.style.position = 'absolute'
  stats.domElement.style.left = '0px'
  stats.domElement.style.bottom = '0px'
  stats

addAnim = (anim_type, anim_id, scene, anims, current_anims) ->
  anim = anims[anim_type][anim_id]
  anim.start()
  current_anims[anim_type] = anim
  scene.add anim.mesh

removeAnim = (anim_type, current_anims, scene) ->
  old_anim = current_anims[anim_type]
  old_anim.stop()
  scene.remove old_anim.mesh

setAnim = (anim_type, anim_id, scene, anims, current_anims) ->
  if anim_type == 'color'
    $('body').css 'background-color': '#' + anim_id
  else
    removeAnim anim_type, current_anims, scene
    addAnim anim_type, anim_id, scene, anims, current_anims

setupSocket = (scene, anims, current_anims) ->
  socket = io('http://ubikeklektik.herokuapp.com/')
  socket.on 'connect', ->
    console.log 'connected'
  socket.on 'anim response', (msg) ->
    console.log msg
    setAnim msg.anim_type, msg.anim_id, scene, anims, current_anims

initAnims = (scene) ->
  anims =
    bg:
      _.map videos.bg, (v, k) -> new PlaneVideoAnimation k
    fg:
      [new BoxAnimation 0] #_.map videos.fg, (v, k) -> new CircleVideoAnimation k
  anims.bg[0].start()
  anims.fg[0].start()
  scene.add anims.bg[0].mesh
  scene.add anims.fg[0].mesh
  anims

getBackgroundCircle = ->
  material = new THREE.MeshLambertMaterial {color: 0x000000}
  mesh = getCircleMesh(material, 0.223)
  mesh.position.set 0, 0, 0.001
  mesh

window.onload = ->
  analyser = getAudioAnalyser()
  audioData = getDataArray analyser  
  renderer = setupRenderer()
  document.body.appendChild renderer.domElement
  scene = new (THREE.Scene)
  camera = setupCamera(scene)
  stats = createStats()
  anims = initAnims(scene)
  current_anims =
     bg: anims.bg[0]
     fg: anims.fg[0]
  background_circle = getBackgroundCircle()
  scene.add background_circle
  light = setupLight()
  scene.add light
  setupSocket scene, anims, current_anims
  render_fn = ->
    renderer.render scene, camera
    stats.update()
    analyser.getByteTimeDomainData(audioData);
  startLoop render_fn, current_anims, audioData
