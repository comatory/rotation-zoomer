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
    @parseOptions opts
    # Get current rotation degrees (passed as options or as data attribute)
    @deg = @opts.initialRotation
    @initialize()

  # Get defaults or passed options
  parseOptions: (opts) ->
    @opts = {}
    @opts =
      rotateButton: $(opts.rotateButton) || $('<button>').addClass('rotation-zoomer-rotate-cw')
      antiRotateButton: $(opts.antiRotateButton) || $('<button>').addClass('rotation-zoomer-rotate-acw')
      stepping: opts.stepping || 90
      initialRotation: opts.initialRotation || @$el.data('initial-rotation' || opts.initialRotationDataAttr) || 0

  initialize: ->
    # Wrapper element for fixing size after rotation
    wrapper = $('<div>').addClass('rotation-zoomer-wrapper')
    @$el.wrap(wrapper)
    @$wrapper = @$el.parents('.rotation-zoomer-wrapper').first()
    @bindControls()
    @transform()

  # Set degrees for transformation
  rotate: (dir = true) ->
    degrees = @degrees(dir)
    @$wrapper.data({
        dir: dir
        degrees: degrees
      })
    @transform()

  rotateDefault: =>
    @rotate()

  rotateACW: =>
    @rotate(dir = false)

  degrees: (dir) ->
    @deg = if dir
      # Handle correct number of degrees for clock wise rotation
      @calculateCW()
    else
      # Handle correct number of degrees for anti clock wise rotation
      @calculateACW()
    @deg

  calculateCW: ->
     if (@deg + @opts.stepping >= 360) then 0 else @deg + @opts.stepping

  calculateACW: ->
     if (@deg - @opts.stepping <= 0) then 360 else @deg - @opts.stepping

  # Generate CSS properties
  wrapperCSS: ->
    base =
      transform: "rotate(#{@deg}deg)"
      display: "inline-block"
      margin: '0px'
      padding: '0px'

    if @deg == 90 || 270
      base.width = @prev.height
      base.height = @prev.width
    else
      base.width = @prev.width
      base.height = @prev.height
    base

  elCSS: ->
    base = {}
    if @deg == 90 || 270
      base.width = '100%'
      base.height = 'auto'
    else
      base.width = 'auto'
      base.height = '100%'
    base

  # Add CSS transform
  transform: ->
    @prevDimensions()
    @$wrapper.css(@wrapperCSS())
    @$el.css(@elCSS())
    @curDimensions()
    console.log(@prev)
    console.log(@current)

  prevDimensions: ->
    @prev = @dimensionObject()

  curDimensions: ->
    @current = @dimensionObject()

  dimensionObject: () ->
    $.extend({}, {
      width: @$wrapper.outerWidth(),
      height: @$wrapper.outerHeight()
      }, @$wrapper.offset()
    )

  # Rotation buttons bind
  bindControls: ->
    @opts.rotateButton.on 'click', @rotateDefault
    @opts.antiRotateButton.on 'click', @rotateACW
