

# https://developer.mozilla.org/ja/docs/Web/API/CanvasRenderingContext2D/globalCompositeOperation


###
-----------------------------------------------------------------------------------------------------------------
  VALUE
-----------------------------------------------------------------------------------------------------------------
###

# ボールの個数
NUM_BALLS = 30

# ボール最大サイズ
MAX_SIZE = 200

# ボール最小サイズ
MIN_SIZE = 50

# ボール最大速度
MAX_SPEED = MAX_SIZE + 5

# 摩擦値
FRICTION = 0.01

# 色情報
COLORS_CMY = [ "#0ff", "#f0f", "#ff0" ]
COLORS_RGB = [ "red", "#0f0", "blue" ]
# https://coolors.co/app/6f2dbd-a663cc-b298dc-b8d0eb-b9faf8
COLORS_CTM1 = [ "#6F2DBD", "#A663CC", "#B298DC", "#B8D0EB", "#B9FAF8" ]
# https://coolors.co/app/5e2bff-c04cfd-fc6dab-f7f6c5-f3fae1
COLORS_CTM2 = [ "#5E2BFF", "#C04CFD", "#FC6DAB", "#F7F6C5", "#F3FAE1" ]
# https://coolors.co/app/1be7ff-6eeb83-e4ff1a-e8aa14-ff5714
COLORS_CTM3 = [ "#1BE7FF", "#6EEB83", "#E4FF1A", "#E8AA14", "#FF5714" ]

SELECT_COLORS =
  CMY:"CMY"
  RGB:"RGB"
  Custom1:"CTM1"
  Custom2:"CTM2"
  Custom3:"CTM3"

SELECT_BLENDMODE =
  multiply:"multiply"
  screen:"screen"
  overlay:"overlay"
  darken:"darken"
  lighten:"lighten"
  colorDodge:"color-dodge"
  colorBurn:"color-burn"
  hardLight:"hard-light"
  softLight:"soft-light"
  difference:"difference"
  exclusion:"exclusion"
  hue:"hue"
  saturation:"saturation"
  color:"color"
  luminosity:"luminosity"
  normal:"normal"

# コンテキスト取得
cvs1 = document.getElementById "cvs1"
ctx1 = cvs1.getContext "2d"

# 画面サイズ定義
cvs1.width = document.documentElement.clientWidth
cvs1.height = document.documentElement.clientHeight

# タイマー制御
loopTimer = false
resizeTimer = false

# ボールオブジェクト格納
ballCollection = new Array

# ブレンドモードの初期値
isBlendMode = SELECT_BLENDMODE.multiply

# ボールカラーの初期値
isBallColors = COLORS_CMY

# ボール透明度の初期値
isAlpha = 1.0

# ベースカラーの初期値
isBaseColor = "#ffffff"


###
-----------------------------------------------------------------------------------------------------------------
  UTILITY
-----------------------------------------------------------------------------------------------------------------
###

# 通常の乱数
randomOfUniform = -> return Math.random()

# 乱数の加算：分布は直線的になり中央の値の出現率が高くなる
randomOfAdd = -> return ( Math.random() + Math.random() ) / 2

# 乱数の乗算：0.0付近の出現率が高い
randomOfMulti = -> return Math.random() * Math.random()

# 乱数の２乗：0.0付近の出現率が飛び抜けて高い
randomOfSquare = -> _r = Math.random(); return _r * _r

# 乱数の平方根：出現頻度が0.0から1.0まで直線的に増えていく
randomOfSqrt = -> return Math.sqrt Math.random()

# 正規乱数：中心部分が一番出現頻度が高く、中心から離れるほど頻度が急激に減少していく
randomOfNormal = ->
  calc = () ->
    r1 = Math.random()
    r2 = Math.random()
    r = Math.sqrt(-2.0 * Math.log(r1)) * Math.sin(2.0 * Math.PI * r2)
    # 値を0以上1未満になるよう正規化する
    return (r + 3) / 6
  # 0.0未満、1.0以上になるケースがあるためその時は再計算を行う
  loop
    _r = calc()
    if 0 <= _r and _r < 1
      break
  return _r

# 最大値を指定した乱数：max未満, algorithm指定
getMaxRandom = (max, algorithm) ->
  if not algorithm then algorithm = Math.random
  return algorithm() * max

# 最大値を指定した乱整数：max未満, algorithm指定
getMaxIntRandom = (max, algorithm) ->
  return Math.floor getMaxRandom(max, algorithm)

# 範囲指定の乱数：min以上, max未満, algorithm指定
getRangeRandom  = (min, max, algorithm) ->
  if not algorithm then algorithm = Math.random
  return (algorithm() * (max - min)) + min

# 範囲指定の乱整数：min以上, max未満, algorithm指定
getRangeIntRandom = (min, max, algorithm) ->
  return Math.floor getRangeRandom(min, max, algorithm)

# 配列からランダムで値を取り出す
getRandomArrayValue = (arr) ->
  return arr[ getMaxIntRandom(arr.length) ]

getRadians = (angle) ->
  return angle * Math.PI / 180

# X方向のベクトル値
getVx = (radians, speed) ->
  return Math.cos(radians) * speed

# Y方向のベクトル値
getVy = (radians, speed) ->
  return Math.sin(radians) * speed



###
-----------------------------------------------------------------------------------------------------------------
  BALL FUNCTIONS
-----------------------------------------------------------------------------------------------------------------
###

# 背景の描画
drawBase = (cvs, ctx) ->
  ctx.clearRect 0, 0, cvs.width, cvs.height
  # ctx.fillStyle = "#fff"
  # ctx.fillRect 0, 0, cvs.width, cvs.height
  # ctx.strokeStyle = "#000000"
  # ctx.strokeRect 1, 1, cvs.width-2, cvs.height-2
  return

# ボールの描画
drawBall = (ctx, color, x, y, radius, startAngle, endAngle, anticlockwise) ->
  ctx.fillStyle = color
  ctx.strokeStyle = color
  ctx.globalCompositeOperation = isBlendMode
  ctx.globalAlpha = isAlpha
  ctx.beginPath()
  # http://www.html5.jp/canvas/ref/method/arc.html
  ctx.arc x, y, radius, startAngle, endAngle, anticlockwise
  ctx.fill()
  return

# ボール初期位置の重なり判定
isOverlap = (b1, b2) ->
  isHit = false
  dx = b1.nextx - b2.nextx
  dy = b1.nexty - b2.nexty
  distance = dx * dx + dy * dy
  if distance <= (b1.radius + b2.radius) ** 2 then isHit = true
  return isHit

# ボール配置可能か判定
canPutBall = (theBall, balls) ->
  canPut = true
  for i in [0...balls.length]
    if isOverlap(theBall, balls[i]) then canPut = false
  return canPut

# 壁の衝突判定
collideWall = (cvs, balls) ->
  ball = null
  for i in [0...balls.length]
    ball = balls[i]
    if ball.nextx + ball.radius > cvs.width
      ball.vx = ball.vx * -1
      ball.nextx = cvs.width - (ball.radius)
    else if ball.nextx - (ball.radius) < 0
      ball.vx = ball.vx * -1
      ball.nextx = ball.radius
    else if ball.nexty + ball.radius > cvs.height
      ball.vy = ball.vy * -1
      ball.nexty = cvs.height - (ball.radius)
    else if ball.nexty - (ball.radius) < 0
      ball.vy = ball.vy * -1
      ball.nexty = ball.radius
  return

# ボール座標を更新
update = (balls) ->
  for i in [0...balls.length]
    ball = balls[i]
    ball.vx = ball.vx - (ball.vx * FRICTION)
    ball.vy = ball.vy - (ball.vy * FRICTION)
    ball.nextx = ball.x + ball.vx
    ball.nexty = ball.y + ball.vy
  return

# すべてのボールを描画
render = (ctx, balls) ->
  ball = null
  for i in [0...balls.length]
    ball = balls[i]
    ball.x = ball.nextx
    ball.y = ball.nexty
    drawBall ctx, ball.color, ball.x, ball.y, ball.radius, 0, Math.PI * 2, true
  return


###
-----------------------------------------------------------------------------------------------------------------
  DEMO
-----------------------------------------------------------------------------------------------------------------
###

demo = (_cvs, _ctx) ->

  ###
  # ループ停止
  ###
  cancelAnimationFrame loopTimer

  ###
  # 配列をリセット
  ###
  ballCollection = []

  ###
  # 全ボール生成ループ
  ###
  for i in [0...NUM_BALLS]
    ###
    # ボール[i]が配置可能になるまで繰り返す
    ###
    _canPut = false
    while !_canPut
      ###
      # 配置可能になるまでプロパティを再定義
      ###
      _x = getMaxIntRandom(_cvs.width)
      _y = getMaxIntRandom(_cvs.height)
      _radius = getRangeIntRandom(MIN_SIZE, MAX_SIZE, randomOfSquare)
      _speed = MAX_SPEED - _radius
      _angle = getMaxIntRandom(360)
      _radians = getRadians(_angle)
      _vx = getVx(_radians, _speed)
      _vy = getVy(_radians, _speed)
      _color = getRandomArrayValue(isBallColors)
      ###
      # ボールオブジェクトに代入し
      ###
      _ball =
        x: _x
        y: _y
        nextX: _x
        nextY: _y
        radius: _radius
        speed: _speed
        angle: _angle
        vx: _vx
        vy: _vy
        color: _color
      ###
      # 配置可能ならボールオブジェクトを配列へ格納
      ###
      _canPut = canPutBall(_ball,ballCollection)
    ballCollection.push _ball

  ###
  # 毎フレーム処理
  ###
  ticker = ->
    loopTimer = requestAnimationFrame ticker
    drawBase _cvs, _ctx
    update ballCollection
    collideWall _cvs, ballCollection
    render _ctx, ballCollection
    return

  ###
  # ループ開始
  ###
  loopTimer = requestAnimationFrame ticker
  return


###
-----------------------------------------------------------------------------------------------------------------
  INIT/EVENT
-----------------------------------------------------------------------------------------------------------------
###

@restart = ->
  demo(cvs1,ctx1)
  return

@restart()

# mouse = x: 0, y: 0
# onMouseMove = (ev) ->
#   rect = ev.target.getBoundingClientRect()
#   mouse.x = ev.clientX - rect.left
#   mouse.y = ev.clientY - rect.top
#   # この値で動的に速度を調整したかったけど断念
#   addSpeedDeltaX = (mouse.x - (cvs1.width/2))* 0.01
#   addSpeedDeltaY = (mouse.y - (cvs1.height/2))* 0.01
#   # console.log addSpeedDeltaX, addSpeedDeltaY
#   return
# cvs1.addEventListener "mousemove", onMouseMove, false

cvs1.addEventListener "click", @restart, false

onResize = (ev) =>
  cvs1.width = document.documentElement.clientWidth
  cvs1.height = document.documentElement.clientHeight
  # cancelAnimationFrame loopTimer
  if resizeTimer isnt false then clearTimeout(resizeTimer)
  resizeTimer = setTimeout @restart, 100
  return

window.addEventListener("resize", onResize, false)

###
-----------------------------------------------------------------------------------------------------------------
  UI
-----------------------------------------------------------------------------------------------------------------
###


# DAT.UI

DemoCanvas = ->
  @brendMode = SELECT_BLENDMODE.multiply
  @ballsColor = SELECT_COLORS.CMY
  @ballsAlpha = isAlpha
  @bgColor = isBaseColor
  @onClickCanvas = -> window.restart()
  return

demoCanvas = new DemoCanvas()
gui = new dat.GUI()
gui.domElement.style.marginRight = 0

gui.add(demoCanvas,"onClickCanvas")

gui.add(demoCanvas,"brendMode", SELECT_BLENDMODE).onChange (args) =>
  isBlendMode = args
  @restart()
  return

gui.add(demoCanvas,"ballsColor", SELECT_COLORS).onChange (args) =>
  if args is "CMY" then isBallColors = COLORS_CMY
  else if args is "RGB" then isBallColors = COLORS_RGB
  else if args is "CTM1" then isBallColors = COLORS_CTM1
  else if args is "CTM2" then isBallColors = COLORS_CTM2
  else if args is "CTM3" then isBallColors = COLORS_CTM3
  @restart()
  return

gui.add(demoCanvas,"ballsAlpha", 0.1, 1.0).onChange (args) =>
  isAlpha = args
  return

gui.addColor(demoCanvas,"bgColor").onChange ->
  document.body.style.background = demoCanvas.bgColor
  return


# STATS

stats = ( (stats) ->
  fps = 60
  stats = new Stats()
  stats.domElement.style.position = "fixed"
  stats.domElement.style.left = "0px"
  stats.domElement.style.top = "0px"
  stats.domElement.style.zIndex = "9999"
  document.body.appendChild stats.domElement
  setInterval ->
    stats.update()
  , 1000 / fps
  return
)()




