# Define jQuery plugin
do ($) ->
  $.fn.rotationZoomer = (opts = {}) ->
      # Allow multiple declarations
      this.each (index, el) ->
        new rotationZoomer(el, opts)

# Main class
class rotationZoomer

  # Receive DOM element and user options
  constructor: (el, opts) ->
    @$el = $(el)
    @el = el
    @opts = opts
    @parseOptions()
    @initialize()

  initialize: ->
    @width = @$el.width()
    @height = @$el.height()

    # Used for changing width & height on canvas element
    @dimensions =
      vert:
        w: @width
        h: @height
      hor:
        w: @height
        h: @width

    # Keeps track of current zoomer window
    @zoomer = null
    # Is zoomer opened?
    @zoomerIsOpened = false

    @initializeCanvas()

  initializeCanvas: ->
    # This replaces original element
    @$canvas = $('<canvas>')
    # Copy some CSS styles
    @$canvas.css({
      position: @$el.css('position')
      display: @$el.css('display')
      })
    # Put new element next to original element
    @$el.parents().first().append(@$canvas)
    @$el.css('display', 'none')
    # Create canvas context
    @context = @$canvas.get(0).getContext('2d')
    @bindControls()
    @transform()

  parseOptions: ->
    @options =
      rotation: @opts.rotation || 0
      rotateButton: @opts.rotateButton
      antiRotateButton: @opts.antiRotateButton
      zoomerWidth: @opts.ZoomerWidth || 150
      zoomerHeight: @opts.ZoomerHeight || 100
      scale: @opts.scale || 2.5

    @options.closeOnClick = @opts.closeOnClick == undefined ? false : @opts.closeOnClick
    @options.closeOnClickOutside = @opts.closeOnClickOutside == undefined ? true : @opts.closeOnClickOutside
    @options.showZoomerAfterRotation = @opts.showZoomerAfterRotation == undefined ? true : @opts.showZoomerAfterRotation

    # Invoke warning, correct options
    if @opts.closeOnClick == false && @opts.closeOnClickOutside == false
      @options.closeOnClick = true
      @options.closeOnClickOutside = false
      warning = "You passed invalid options:\n"
      warning += "Options 'closeOnClick' and 'closeOnClickOutside' were both set to false. You cannot do this.\n"
      warning += "Option 'closeOnClick' was set to true as a default."
      console.warn(warning)

    console.log(@options)

    # Set intial rotation
    @deg = @options.rotation
    # Return
    @options

  # Event handlers
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

    @$canvas.on 'click', @handleClick

  # Set rotation-zoomer element's dimensions
  setWidthAndHeight: ->
    if @hasHorizontalRotation()
      @width = @dimensions.hor.w
      @height = @dimensions.hor.h
    else
      @width = @dimensions.vert.w
      @height = @dimensions.vert.h

  # Transform rotation zoomer element accordingly
  transform: ->
    @setWidthAndHeight()
    @context.canvas.width = @width
    @context.canvas.height = @height
    @redraw()

  rotate: ->
    # Context is saved so it can be reinitialized later for zooemr windows
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
    @closeZoomer() unless @options.showZoomerAfterRotation

  # Clockwise rotation detected
  rotateCW: ->
    @deg = if @deg + 90 >= 360
            0
          else
            @deg + 90
    @transform()
    @deg

  # Anti-clockwise rotation detected
  rotateACW: ->
    @deg = if @deg - 90 < 0
            270
          else
            @deg - 90
    @transform()
    @deg

  # Is it rotated on its side?
  hasHorizontalRotation: ->
    @deg == 90 || @deg == 270

  # Delete everything from rotation zoomer canvas
  clear: ->
    @context.clearRect(0, 0, @context.canvas.width, @context.canvas.height)

  # Called after rotatio
  redraw: ->
    @clear()
    @rotate()
    @draw()

  draw: ->
    if @hasHorizontalRotation()
      @context.drawImage(@el, 0, 0, @height, @width)
    else
      @context.drawImage(@el, 0, 0, @width, @height)

  # Click handler on rotation zoomer canvas
  # Get coordinates relative to rotation zoomer canvas
  handleClick: (e) =>
    @coords =
      x: e.clientX - @context.canvas.getBoundingClientRect().left
      y: e.clientY - @context.canvas.getBoundingClientRect().top

    # See whether zoomer was clicked
    if @checkClickedArea()
      @closeZoomer()
      @redraw()
    else if @zoomerIsOpened == false && @zoomer == null
      @zoom(e)
    else
      # Don't do anything, keep zoomer closed or opened
      return

  didClickOnZoomer: ->
    @zoomerIsOpened = @zoomer.inBounds(@coords)
    @zoomerIsOpened

  checkClickedArea: ->
    # Need to open zoome when there's none
    return false unless @zoomer
    res = @didClickOnZoomer()
    # Always close on any click with these options
    if @options.closeOnClick && @options.closeOnClickOutside
      return true
    else if @options.closeOnClick
      return res
    else
      return !res

  zoom: (e) =>
    @openZoomer()

  closeZoomer: ->
    @zoomer = null
    @zoomerIsOpened = false

  # New zoomer
  openZoomer: ->
    @sourceCoords =
      x: -@coords.x + ((@options.zoomerWidth / 2) / @options.scale)
      y: -@coords.y + ((@options.zoomerHeight / 2) / @options.scale)
    # Off-screen canvas element, used only for extracting the right
    # portion of image from rotation zoomer canvas
    zoomerContext = $('<canvas>').get(0).getContext('2d')
    zoomerContext.canvas.width = @options.zoomerWidth
    zoomerContext.canvas.height = @options.zoomerHeight
    # Scale and translate
    zoomerContext.scale(@options.scale, @options.scale)
    zoomerContext.translate(@sourceCoords.x, @sourceCoords.y)
    zoomerContext.drawImage(@context.canvas, 0, 0)

    # Add zoomer data to object
    @zoomer = new Zoomer(zoomerContext, @options, @coords.x, @coords.y)

    @initializeZoomer()

  initializeZoomer: ->
    return unless @zoomer || @zoomerIsOpened
    # Reset rotation zoomer canvas (context is translated during rotation)
    @context.restore()

    # Draw zoomer on canvas
    @context.drawImage(
      @zoomer.context.canvas, @zoomer.originX(), @zoomer.originY(),
      @zoomer.context.canvas.width, @zoomer.context.canvas.height
    )
    # Add borders
    @context.strokeRect(
      @zoomer.originX(), @zoomer.originY(),
      @zoomer.context.canvas.width, @zoomer.context.canvas.height
      )

# Represents zoomer window on canvas
class Zoomer
  constructor: (context, instanceOptions, x, y) ->
    # Copy over canvas attributes
    @context = $.extend(true, {}, context)
    # Options from rotation zoomer plugin
    @instanceOptions = instanceOptions
    # True origin X
    @x = x
    # True origin Y
    @y = y
    # Is zoomer opened?
    @bounds =
      top: @originY()
      left: @originX()
      width: @instanceOptions.zoomerWidth
      height: @instanceOptions.zoomerHeight

  # Center content of zoomer window horizontally
  originX: ->
    @x - @instanceOptions.zoomerWidth / 2

  # Center content of zoomer window vertically
  originY: ->
    @y - @instanceOptions.zoomerHeight / 2

  # Check if current clicked area contains instance of zoomer
  inBounds: (coords) ->
    coords.x in @axisX() && coords.y in @axisY()

  # Calculate X-axis bounds
  axisY: ->
    [@bounds.top..(@bounds.top + @bounds.height)]

  # Calculate X-axis bounds
  axisX: ->
    [@bounds.left..(@bounds.left + @bounds.width)]
