$(document).ready ->

  socket = io()

  socket.on 'connect', ->
    console.log 'connected'

  socket.on 'anim response', (msg) ->
    console.log msg

  $('.menu-item').click ->
    mapping = 
      'bg-btn': 'bg-menu'
      'fg-btn': 'fg-menu'
      'color-btn': 'color-menu'
    menu_id = '#' + mapping[$(this).attr('id')]
    $(menu_id).show()
    $('#main-menu').hide()
 
  $('.anim-selector').click ->
    splitted = $(this).attr('id').split('-')
    socket.emit 'anim request', {'anim_type': splitted[0], 'anim_id': splitted[1]}
    $(this).parent().hide()
    $('#main-menu').show()
 
  $('.menu-item').each ->
    $(this).css content: 'url(../images/' + $(this).attr('id') + '-up.png)'
