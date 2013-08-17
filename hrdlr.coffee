sounds = {
  jump: new Audio('sounds/jump.m4a')
  intro: new Audio('sounds/intro.m4a')
  splat: new Audio('sounds/splat.m4a')
  coin_get: new Audio('sounds/coin_get.m4a')
  high_score: new Audio('sounds/high_score.m4a')
}

sounds.intro.play()

setText = (element, text) ->
  while element.firstChild
    element.removeChild element.firstChild
  element.appendChild document.createTextNode(text)

getRandomInt = (min, max) ->
  return Math.floor(Math.random() * (max - min + 1) + min)

defaultName = "HURDLURR ##{getRandomInt(10000, 90000)}"
name = localStorage.name || defaultName
name = window.prompt 'Name:', name
name = defaultName unless name?.length
localStorage.name = name

class Sprite
  constructor: (@config) ->
    @frames = @config.frames
    @states = @config.states
    @changeState(Object.keys(@states)[0])

  changeState: (state) ->
    @currentState = state
    @frameIndex = -1

  tick: ->
    @frameIndex++
    if @frameIndex >= @states[@currentState].length
      @frameIndex = 0
    frameName = @states[@currentState][@frameIndex]
    @currentFrame = @frames[frameName]

class Items
  constructor: (@initial, @step_min, @step_max) ->
    @items = [@initial]
    @deleted = []

  get: (x1, x2) ->
    # populate till the end of the range
    while @items[@items.length-1] < x2
      @items.push @items[@items.length-1] + getRandomInt(@step_min, @step_max)
    # remove old entries
    if @items.size > 1000
      @items = @items.slice(@items.length-1000)
    # return items in requested range (without deleted items)
    items = []
    for x in @items
      if x >= x1 && x <= x2 && @deleted.indexOf(x) < 0
        items.push x
    items

  delete: (items) ->
    @deleted.push items...

playerSprite = new Sprite
  frames:
    run1:
      '''
       o
      <|-
      / >
      '''
    run2:
      '''
       o
      /|~
      --\\
      '''
    jump:
      '''
       o/
      /|
      ---
      '''
    falling:
      '''
         o
       </_
      //
      '''
    fallen:
      '''


      \\_\\_o
      '''
    recovering:
      '''
        o
      </-
      /|
      '''
    blank: ''
  states:
    running: [
      'run1',
      'run1',
      'run2',
      'run2',
    ]
    jumping: [
      'jump',
    ]
    falling: [
      'falling',
    ]
    fallen: [
      'fallen',
    ]
    recovering: [
      'recovering',
      'blank',
      'recovering',
      'blank',
      'run1',
      'blank',
      'run1',
      'blank',
    ]

coinSprite = new Sprite
  frames:
    normal: 'O'
    back: '0'
    side: '|'
  states:
    rotating: [
      'normal',
      'normal',
      'normal',
      'side',
      'side',
      'side',
      'back',
      'back',
      'back',
      'side',
      'side',
      'side',
    ]

class Player
  constructor: (@sprite) ->
    @jumpPos = null
    @posX = 0
    @posY = 2
    @score = 0
    @highScore = 0

  tick: ->
    if !@fallingPos? || @fallingPos < 4
      @posX++
    if @fallingPos == 8
      @sprite.changeState 'recovering'
    if @fallingPos >= 16
      @sprite.changeState 'running'
      @fallingPos = null

    hurdleIntersect = hurdles.get(@posX+1, @posX+2).length

    if @jumpPos?
      if @jumpPos < 4
        @jumpPos++
        coinIntersects = coins.get(@posX+1, @posX+2)
        if coinIntersects.length
          coins.delete coinIntersects
          sounds.coin_get.play()
          @addToScore 1
          @sendScores()
      else
        @jumpPos = null
        if @jumpedOverHurdle && !hurdleIntersect
          @addToScore 1
          @sendScores()
          @jumpedOverHurdle = false
        @posY = 2
        @sprite.changeState 'running'

    if hurdleIntersect
      if @jumpPos?
        @jumpedOverHurdle = true
      else
        @fallingPos = 0
        @jumpedOverHurdle = false
        @sprite.changeState 'falling'
        sounds.splat.play()
        if @score > @highScore
          @highScore = @score
        @score = 0
        @sendScores()
    else if @fallingPos?
      @fallingPos++
      if @fallingPos == 1
        @sprite.changeState 'fallen'

  addToScore: (n) ->
    oldScore = @score
    @score += n
    if oldScore < @highScore && @score >= @highScore
      sounds.high_score.play()

  sendScores: ->
    socket.emit 'message', JSON.stringify
      name: localStorage.name
      score: @score

  jump: ->
    return if @jumpPos?
    return if @fallingPos?
    @jumpPos = 0
    @posY = 1
    @sprite.changeState 'jumping'
    sounds.jump.play()

player = new Player(playerSprite)

players = {}

renderScores = ->
  items = []
  for name, data of players
    items.push
      name: name
      score: data.score

  items = items.sort (a, b) ->
    switch true
      when a.score == b.score
        0
      when a.score > b.score
        -1
      else
        1

  output = ''
  for item in items
    output += "#{item.name}: #{item.score}\n"
  setText document.getElementById('scores'), output

onScoreMessage = (message) ->
  data = JSON.parse message
  players[data.name] = data
  renderScores()

document.addEventListener 'keypress', (event) ->
  if event.keyCode == 32
    player.jump()

document.addEventListener 'touchstart', ->
  player.jump()

socket = io.connect location.origin
socket.on 'message', (data, callback) ->
  onScoreMessage data

class Frame
  constructor: (id, @width, @height) ->
    @element = document.getElementById(id)

  clear: ->
    @lines = []
    @lines.push new Array(@width+1).join('-')
    for i in [1..@height-2]
      @lines.push new Array(@width+1).join(' ')
    @lines.push new Array(@width+1).join('-')

  draw: (x, y, spriteFrame) ->
    spriteFrameLines = spriteFrame.split('\n')
    for i in [0..spriteFrameLines.length-1]
      @lines[i+y] =
        @lines[i+y].slice(0, x) +
        spriteFrameLines[i] +
        @lines[i+y].slice(x+spriteFrameLines[i].length)

  drawRight: (y, spriteFrame) ->
    width = spriteFrame.split('\n')[0].length
    @draw @width - width, y, spriteFrame

  render: ->
    setText @element, @lines.join('\n')

frame = new Frame('frame', 80, 6)

hurdles = new Items(50, 10, 20)
coins = new Items(75, 20, 50)

viewportX = -3

tick = ->
  player.tick()
  playerSprite.tick()
  coinSprite.tick()

  frame.clear()

  for hurdle_x in hurdles.get(0+player.posX+viewportX, 80+player.posX+viewportX)
    frame.draw hurdle_x-player.posX-viewportX, 4, '#'

  for x in coins.get(0+player.posX+viewportX, 80+player.posX+viewportX)
    frame.draw x-player.posX-viewportX, 1, coinSprite.currentFrame

  frame.draw -viewportX, player.posY, playerSprite.currentFrame

  frame.drawRight 1, "High score:      "
  frame.drawRight 1, "#{player.highScore} "
  frame.drawRight 2, "Score:           "
  frame.drawRight 2, "#{player.score} "

  frame.render()

  setTimeout(tick, 100)

tick()
