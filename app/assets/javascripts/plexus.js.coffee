$ = jQuery

tab_change_handler = (event) ->
  target = $(event.target)
  container = target.parent().closest('div')
  container.find('input').val('#' + target.attr('id'))
  console.log('Selected tab #' + target.attr('id'))

fixPage = ->
  $('.properties dfn,.attachments dfn').each (i) ->
    s = $(this).text()
    if s[s.length - 1] != ':'
      s = s + ':'
    $(this).text(s)

  $('.action-links a').each (i) ->
    s = $(this).text()
    if s[0] != '['
      s = '[' + s
    if s[s.length - 1] != ']'
      s = s + ']'
    $(this).text(s)

  $('table.zebra')
    .find('tr:nth-child(odd)').removeClass('odd').addClass('even').end()
    .find('tr:nth-child(even)').removeClass('even').addClass('odd')

$(document).ready ->
  fixPage()

  # -- highlights predecessors and successors of a data set on hover
  $('.data-set').hover(
    (->
      related = $(this).attr('data-pred') + $(this).attr('data-succ')
      $('.data-set').each ->
    	  if related.indexOf($(this).attr('id')) >= 0
	        $(this).addClass('highlighted')
      false),
    (->
      $('.data-set').removeClass('highlighted')))

  $('.tabs-container').tabContainer().
    find('> div').bind('tab-opened', tab_change_handler).end().
    find('> ul > li:first > a').tabSelect()

  # -- enable ajax templating via jquery.djtch.js
  $.djtch.setup
    preUpdateHook:  fixPage
    postUpdateHook: fixPage

  $(document).djtchEnable()
