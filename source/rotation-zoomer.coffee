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
    @$el.parents().first().append(@$canvas)
    @$el.css('display', 'none')
    @context = @$canvas.get(0).getContext('2d')
    @transform()

  parseOptions: ->
    @options =
      rotation: @opts.rotation || 0
      rotateButton: @opts.rotateButton
      antiRotateButton: @opts.antiRotateButton

    @deg = @options.rotation
    @bindControls()

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

  setWidthAndHeight: ->
    if @hasHorizontalRotation()
      @width = @dimensions.hor.w
      @height = @dimensions.hor.h
    else
      @width = @dimensions.vert.w
      @height = @dimensions.vert.h

  transform: ->
    console.log('transforming')
    @setWidthAndHeight()
    @context.canvas.width = @width
    @context.canvas.height = @height

    @rotate()

  hasHorizontalRotation: ->
    @deg == 90 || @deg == 270

  redraw: ->
    @context.clearRect(0, 0, @context.canvas.width, @context.canvas.height)
    @draw()

  draw: ->
    if @hasHorizontalRotation()
      @context.drawImage(@el, 0, 0, @height, @width)
    else
      @context.drawImage(@el, 0, 0, @width, @height)


  rotate: ->
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
