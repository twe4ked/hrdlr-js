pre = document.querySelector('pre')
frame = null
sounds = {
  jump: new Audio('sounds/jump.m4a')
  intro: new Audio('sounds/intro.m4a')
  splat: new Audio('sounds/splat.m4a')
}

sounds.intro.play()

getRandomInt = (min, max) ->
  return Math.floor(Math.random() * (max - min + 1) + min)

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

class Player
  constructor: (@sprite) ->
    @jumpPos = null
    @posX = 0
    @posY = 2

  tick: ->
    if !@fallingPos? || @fallingPos < 4
      @posX++
    if @fallingPos == 8
      @sprite.changeState 'recovering'
    if @fallingPos >= 16
      @sprite.changeState 'running'
      @fallingPos = null

    if @jumpPos?
      if @jumpPos < 4
        @jumpPos++
      else
        @jumpPos = null
        @posY = 2
        @sprite.changeState 'running'

    if hurdles.get(@posX+1, @posX+2).length
      unless @jumpPos?
        @fallingPos = 0
        @sprite.changeState 'falling'
        sounds.splat.play()
    else if @fallingPos?
      @fallingPos++
      if @fallingPos == 1
        @sprite.changeState 'fallen'

  jump: ->
    return if @jumpPos?
    return if @fallingPos?
    @jumpPos = 0
    @posY = 1
    @sprite.changeState 'jumping'
    sounds.jump.play()

player = new Player(playerSprite)

document.addEventListener 'keypress', (event) ->
  if event.keyCode == 32
    player.jump()

document.addEventListener 'touchstart', ->
  player.jump()

drawSprite = (spriteFrame, x, y) ->
  spriteFrameLines = spriteFrame.split('\n')
  for i in [0..spriteFrameLines.length-1]
    frame[i+y] = frame[i+y].slice(0, x) + spriteFrameLines[i] + frame[i+y].slice(x+spriteFrameLines[i].length)

clearFrame = ->
  frame = [
    new Array(81).join('-'),
    new Array(81).join(' '),
    new Array(81).join(' '),
    new Array(81).join(' '),
    new Array(81).join(' '),
    new Array(81).join('-')
  ]

hurdles = new Items(50, 10, 20)

viewportX = -3

tick = ->
  clearFrame()

  player.tick()
  playerSprite.tick()

  for hurdle_x in hurdles.get(0+player.posX+viewportX, 80+player.posX+viewportX)
    drawSprite('#', hurdle_x-player.posX-viewportX, 4)

  drawSprite(playerSprite.currentFrame, -viewportX, player.posY)

  pre.innerText = frame.join('\n')

  setTimeout(tick, 100)

tick()
