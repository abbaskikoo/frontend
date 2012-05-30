circle = $.sammy "body", ->

  # Page
  class Page
    constructor: (@name, @title) ->

    init: (cx) =>
      document.title = "Circle - " + @title

      # Render content
      @render(cx)

      # Land at the right anchor on the page
      @scroll window.location.hash

      # Fetch page-specific libraries
      @lib() if @lib?

    render: (cx) =>
      $("body").attr("id","#{@name}-page").html HAML['header'](renderContext)
      $("body").append HAML[@name](renderContext)
      $("body").append HAML['footer'](renderContext)

    load: (cx) =>
      $.getScript "/assets/views/outer/#{@name}/#{@name}.hamlc", =>
         @init(cx)

    scroll: (hash) =>
      if hash == '' or hash == '#' then hash = "body"
      $('html, body').animate({scrollTop: $(hash).offset().top}, 0)

    display: (cx) =>
      if HAML? and HAML[@name]?
        @init(cx)
      else
        @load(cx)

  # Doc
  class Docs extends Page
    filename: (cx) =>
      name = cx.params.splat[0]
      if name
        name.replace('/', '').replace('-', '_').replace(/#.*/, '')
      else
        "docs"

    categories: (cx) =>
      HAML['categories']()

    render: (cx) =>
      name = @filename cx
      $("body").attr("id","#{@name}-page").html(HAML['header'](renderContext))
      $("body").append(HAML['title'](renderContext))
      $("#title h1").text("Documentation")
      $("body").append("<div id='content'><section class='article'></section></div>")
      $(".article").append(@categories()).append(HAML[name](renderContext))
      $("body").append(HAML['footer'](renderContext))

    load: (cx) =>
      $.getScript "/assets/views/outer/docs/docs.js.dieter", =>
        @init(cx)

  # Pages
  home = new Page("home", "Continuous Integration made easy")
  about = new Page("about", "About Us")
  privacy = new Page("privacy", "Privacy and Security")
  docs = new Docs("docs", "Documentation")

  # Per-Page Libs
  highlight = =>
    if !hljs?
      $.getScript "/assets/js/vendor/highlight.pack.js", =>
        $("pre code").each (i, e) => hljs.highlightBlock e

    else
      $("pre code").each (i, e) => hljs.highlightBlock e

  placeholder = =>
    if !Modernizr.input.placeholder
      $.getScript "/assets/js/vendor/jquery.placeholder.js", =>
        $("input, textarea").placeholder()


  home.lib = placeholder
  about.lib = placeholder
  docs.lib = highlight

  # Google analytics
  @bind 'event-context-after', ->
    if window._gaq? # we dont use ga in test mode
      window._gaq.push @path

  # Airbrake
  @bind 'error', (e, data) ->
    if data? and data.error? and window.Hoptoad?
      window.Hoptoad.notify data.error

  # Navigation
  @get "/about.*", (cx) -> about.display(cx)
  @get "/privacy.*", (cx) -> privacy.display(cx)
  @get "/docs(.*)", (cx) -> docs.display(cx)
  @get "/", (cx) -> home.display(cx)


# Global polyfills
if $.browser.msie and $.browser.version > 6 and $.browser.version < 9
  $.getScript("/assets/js/vendor/selectivizr-1.0.2.js")

# Run the application
$ -> circle.run window.location.pathname.replace(/\/$/, '')
