###
 jquery.djtch.js - Dynamic Javascript Templating in Client-side HTML

 Requires jquery (>= 1.3) and jquery.forms

 @author olaf.delgado-friedrichs@anu.edu.au
###

$ = jQuery

$.djtch =
  options:
    preUpdateHook: null
    postUpdateHook: null

  setup: (options) -> $.extend(this.options, options || {})

anchor = (seed, item) ->
  id = $(item).attr('id')
  pattern = '.dj-anchor' + (if id then '#' + id else '')

  while context and context.length > 0
    res = if context.is(pattern) then context else context.find(pattern)
    if res and res.length > 0
      return res
    if !context.parent()
      break;
    context = context.parent().closest('.dj-context,.dj-anchor')

  $(pattern)

content = (item) ->
  if $(item).hasClass('.dj-children')
    $(item).children()
  else
    $(item)

update = (seed, html) ->
  newStuff = $(html)

  if $.djtch.options.preUpdateHook
    $.djtch.options.preUpdateHook(newStuff)

  newStuff.djtchEnable()

  newStuff.find('.dj-replace').each ->
    anchor(seed, this).replaceWith(content(this))

  newStuff.find('.dj-append').each -> anchor(seed, this).append(content(this))

  newStuff.find('.dj-prepend').each -> anchor(seed, this).prepend(content(this))

  newStuff.find('.dj-after').each -> anchor(seed, this).after(content(this))

  newStuff.find('.dj-before').each -> anchor(seed, this).before(content(this))

  if $.djtch.options.postUpdateHook
    $.djtch.options.postUpdateHook()

handlers =
  linkClicked: ->
    link = $(this)
    $.get(
      link.attr('href'),
      (html) ->
        update(link, html)
        if link.hasClass('.dj-once')
          link.unbind('click'))
    false

  deleteLinkClicked: ->
    link = $(this)
    if confirm(link.attr('confirm') || 'Really delete this?')
      $.post(
        link.attr('href'),
        $.param { '_method': 'delete' },
        (html, status) ->
          update(link, html))
    false

  activeScroll: (event) ->
    win = $(window)
    link = event.data
    doc = $(document)

    if link && link.attr('href')
      if win.scrollTop() + 1.1 * win.height() > doc.height()
        stopScrollHandler()
        $.get(
          link.attr('href'),
          (html) ->
            update(link, html)
        )
    else
      stopScrollHandler()

    false

  formSubmitted: ->
    input = $(this)
    form = input.closest('form')
    form.append("<input type='hidden' name='" + input.attr('name') +
                "' value='" + input.attr('value') + "' class='tmp'>")
    form.ajaxSubmit(
       url: form.attr('action')
       success: (html, status) ->
         $("input.tmp", form).remove()
         update(form, html)
    )
    false

stopScrollHandler = ->
  $(window).unbind('scroll', handlers.activeScroll)

$.fn.extend
  djtchLink: -> this.click(handlers.linkClicked)

  djtchDeleteLink: -> this.click(handlers.deleteLinkClicked)

  djtchOnScrollLink: ->
    if this.length > 0
      ev = 'scroll'
      fn = handlers.activeScroll
      $(window)
        .unbind(ev, fn)
        .bind(ev, this, fn)
        .triggerHandler(ev)
    this.hide().after(this.text())

  djtchForm: ->
    this.find('input[type=submit]')
      .click(handlers.formSubmitted).end()

  djtchEnable: ->
    this
      .find('.dj-link').djtchLink().end()
      .find('.dj-delete').djtchDeleteLink().end()
      .find('.dj-scroll').djtchOnScrollLink().end()
      .find('.dj-form').djtchForm().end()

