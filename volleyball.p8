pico-8 cartridge // http://www.pico-8.com
version 39
__lua__



f =     {['g'] = 0.2,
         ['default floor'] = 124,
         ['floor'] = 124,
         ['celling'] = 5,
         ['default lw'] = 1,
         ['default rw'] = 127,
         ['friction'] = 0.75}

s =     {['x'] = 15,
         ['y'] = 0,
         ['vertical speed'] = 0,
         ['horizontal speed'] = 0,
         ['radius'] = 4,
         ['m'] = 1}

n =     {['h'] = 70,
         ['l'] = 63,
         ['r'] = 64}

p =     {['x'] = 15,
         ['y'] = 127 - 10,
         ['vertical speed'] = 0,
         ['horizontal speed'] = 3,
         ['radius'] = 8,
         ['m'] = 3}

p2 =    {['x'] = 15,
         ['y'] = 127 - 10,
         ['vertical speed'] = 0,
         ['horizontal speed'] = 3,
         ['radius'] = 8,
         ['m'] = 3}
p2['x'] = f['default rw'] - 15




function count_wall(field, ball, net, side)
  if (ball['y'] < net['h']) then
    return field['default ' .. side .. 'w']
  elseif (side == 'r') then 
    if (ball['x'] > net['r']) then
      return field['default rw']
    else
      return net['r']
    end
  elseif (side == 'l') then
    if (ball['x'] < net['l']) then
      return field['default lw']
    else
      return net['l']
    end
  end
end


function player_horizontal_move(player, ball, comp1, comp2, btn_r, btn_l)
  if (btn_r and player['x'] + player['radius'] + ball['radius'] <= comp1) then
    player['x'] += player['horizontal speed']
  end
  
  if (btn_l and player['x'] - player['radius'] - ball['radius'] >= comp2) then
    player['x'] -= player['horizontal speed']
  end

  return player
end


function player_move(field, player, ball, net, btn_jump, btn_r, btn_l, side)
  if (player['y'] >= field['floor']) then
    player['vertical speed'] = 0
  end

  if (btn_jump and player['y'] >= field['floor']) then
    player['vertical speed'] -= 8
  elseif (player['y'] >= field['floor']) then
    player['y'] = field['floor']
  end



  if (side == 'l') then

    player = player_horizontal_move(player, ball, net[side], field['default ' .. side .. 'w'], btn_r, btn_l)

  elseif (side == 'r') then

    player = player_horizontal_move(player, ball, field['default ' .. side .. 'w'], net[side], btn_r, btn_l)
  
  end

  player['y'] += player['vertical speed']


  return player

end


function ball_move(field, ball)
  if ((abs(ball['vertical speed']) < field['g'] * 1.1) and (ball['y'] >= field['floor'])) then
    ball['vertical speed'] = 0
  end

  if (ball['y'] >= field['floor']) then
    ball['horizontal speed'] = field['friction'] * 1.2 * ball['horizontal speed']
  end

  if (ball['y'] > field['floor']) then
    ball['vertical speed'] = -1 * field['friction'] * ball['vertical speed']
    ball['y'] = field['floor']
  elseif (ball['y'] < field['celling']) then
    ball['vertical speed'] = -1 * field['friction'] * ball['vertical speed']
    ball['y'] = field['celling']
  else
    ball['y'] += ball['vertical speed']
  end

  if (ball['x'] + ball['horizontal speed'] >= field['right wall']) then
    ball['horizontal speed'] = -1 * field['friction'] * ball['horizontal speed']
    ball['x'] = field['right wall'] - ball['radius']
  elseif (ball['x'] + ball['horizontal speed'] <= field['left wall']) then
    ball['horizontal speed'] = -1 * field['friction'] * ball['horizontal speed']
    ball['x'] = field['left wall'] + ball['radius']
  else
    ball['x'] += ball['horizontal speed']
  end

  return ball
end


function ball_player_collision(ball, player)
  hypotenuse = sqrt((ball['x'] - player['x']) ^ 2 + (ball['y'] - player['y']) ^ 2)
  vertical =  player['y'] - ball['y']
  horizontal = player['x'] - ball['x'] 

  if (hypotenuse <= ball['radius'] + player['radius']) then
    ball['vertical speed'] = vertical / hypotenuse * -5
    ball['horizontal speed'] = horizontal / hypotenuse * -5
  end

  return ball
end


function _update()
  
  
  s['vertical speed'] += f['g'] * s['m']
  p['vertical speed'] += f['g'] * p['m']
  p2['vertical speed'] += f['g'] * p2['m']
  
  f['left wall'] = count_wall(f, s, n, 'l')
  f['right wall'] = count_wall(f, s, n, 'r')


  p  = player_move(f, p,  s, n, btn(4, 0), btn(1, 0), btn(0, 0), 'l')
  p2 = player_move(f, p2, s, n, btn(4, 1), btn(1, 1), btn(0, 1), 'r')

  s = ball_move(f, s)
  
  s = ball_player_collision(s, p)
  s = ball_player_collision(s, p2)


end
 
function _draw()
  cls(1)
  rectfill(n['l'], 127, n['r'], n['h'], 12)
  circfill(s['x'], s['y'], s['radius'], 15)
  circfill(p['x'], p['y'], p['radius'], 12)
  circfill(p2['x'], p2['y'], p2['radius'], 14)
end
