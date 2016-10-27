# Define jQuery plugin
do ($) ->
  $.fn.rotationZoomer = (opts = {}) ->
      # Allow multiple declarations
      this.each (index, el) ->
        new rotationZoomer(el, opts)

# Main class
class rotationZoomer
  constructor: (el, opts) ->
    @$el = $(el)
    @el = el
    @opts = opts
    @parseOptions()
    @initialize()

  initialize: ->
    @width = @$el.width()
    @height = @$el.height()
    @dimensions =
      vert:
        w: @width
        h: @height
      hor:
        w: @height
        h: @width

    @initializeCanvas()

  initializeCanvas: ->
    @$canvas = $('<canvas>')
    @$canvas.css({
      position: @$el.css('position')
      display: @$el.css('display')
      })
    @$el.parents().first().append(@$canvas)
    @$el.css('display', 'none')
    @context = @$canvas.get(0).getContext('2d')
    @bindControls()
    @transform()

  parseOptions: ->
    @options =
      rotation: @opts.rotation || 0
      rotateButton: @opts.rotateButton
      antiRotateButton: @opts.antiRotateButton
      zoomerWidth: @opts.ZoomerWidth || 100
      zoomerHeight: @opts.ZoomerHeight || 100
      scale: @opts.scale || 2.5

    @deg = @options.rotation

  bindControls: ->
    if @options.rotateButton
      @$rotateButton = $(@options.rotateButton)

    if @options.antiRotateButton
      @$antiRotateButton = $(@options.antiRotateButton)

    if @$rotateButton
      @$rotateButton.on 'click', =>
        @rotateCW()

    if @$antiRotateButton
      @$antiRotateButton.on 'click', =>
        @rotateACW()

    @$canvas.on 'click', @zoom

  setWidthAndHeight: ->
    if @hasHorizontalRotation()
      @width = @dimensions.hor.w
      @height = @dimensions.hor.h
    else
      @width = @dimensions.vert.w
      @height = @dimensions.vert.h

  transform: ->
    @setWidthAndHeight()
    @context.canvas.width = @width
    @context.canvas.height = @height

    @rotate()

  hasHorizontalRotation: ->
    @deg == 90 || @deg == 270

  clear: ->
    @context.clearRect(0, 0, @context.canvas.width, @context.canvas.height)

  redraw: ->
    @clear()
    @draw()

  draw: ->
    if @hasHorizontalRotation()
      @context.drawImage(@el, 0, 0, @height, @width)
    else
      @context.drawImage(@el, 0, 0, @width, @height)

  rotate: ->
    @context.save()
    switch @deg
      when 90
        @context.translate(@width, 0)
        break
      when 270
        @context.translate(0, @height)
        break
      when 180
        @context.translate(@width, @height)
        break

    @context.rotate((Math.PI / 180) * @deg)
    @redraw()

  rotateCW: ->
    @deg = if @deg + 90 >= 360
            0
          else
            @deg + 90
    @transform()

  rotateACW: ->
    @deg = if @deg - 90 < 0
            270
          else
            @deg - 90
    @transform()

  zoom: (e) =>
    @coords =
      x: e.clientX - @context.canvas.getBoundingClientRect().left
      y: e.clientY - @context.canvas.getBoundingClientRect().top

    @sourceCoords =
      x: -@coords.x + (@options.zoomerWidth / (@options.scale * 2))
      y: -@coords.y + (@options.zoomerWidth / (@options.scale * 2))
    @openZoomer()

  openZoomer: ->
    @zoomerContext.restore() if @zoomerContext
    @$zoomer = $('<canvas>')
    @zoomerContext = @$zoomer.get(0).getContext('2d')

    @zoomerContext.canvas.width = @options.zoomerWidth
    @zoomerContext.canvas.height = @options.zoomerHeight
    @zoomerContext.save()
    @zoomerContext.scale(@options.scale, @options.scale)
    @zoomerContext.translate(@sourceCoords.x, @sourceCoords.y)
    @zoomerContext.drawImage(@context.canvas, 0, 0)

    # $debug = $('#debug')
    # debugCtx = $debug.get(0).getContext('2d')
    # debugCtx.width = @zoomerContext.canvas.width
    # debugCtx.height = @zoomerContext.canvas.height
    # debugCtx.drawImage(@zoomerContext.canvas, 0, 0)

    @context.restore()
    @context.drawImage(@zoomerContext.canvas, @coords.x - @zoomerWidthWindow(), @coords.y - @zoomerHeightWindow(), @zoomerContext.canvas.width, @zoomerContext.canvas.height)
    @context.strokeRect(@coords.x - @zoomerWidthWindow(), @coords.y - @zoomerHeightWindow(), @zoomerContext.canvas.width, @zoomerContext.canvas.height)

  zoomerWidthWindow: ->
    @options.zoomerWidth / 2

  zoomerHeightWindow: ->
    @options.zoomerHeight / 2
