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
         ['m'] = 1.5}

n =     {['h'] = 80 - s['radius'],
         ['l'] = 62,
         ['r'] = 65}

p =     {['x'] = 15,
         ['init x'] = 15,
         ['y'] = 127 - 10,
         ['vertical speed'] = 0,
         ['horizontal speed'] = 3,
         ['radius'] = 8,
         ['m'] = 3,
         ['points'] = 0,
         ['jump speed'] = 8}

p2 =    {['x'] = f['default rw'] - 15,
         ['init x'] = f['default rw'] - 15,
         ['y'] = 127 - 10,
         ['vertical speed'] = 0,
         ['horizontal speed'] = 3,
         ['radius'] = 8,
         ['m'] = 3,
         ['points'] = 0,
         ['jump speed'] = 8}




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
    player['vertical speed'] -= player['jump speed']
  elseif (player['y'] >= field['floor']) then
    player['y'] = field['floor']
  end



  if (side == 'l') then

    player = player_horizontal_move(player, ball, net[side], field['default lw'] - player['radius'] * 2, btn_r, btn_l)

  elseif (side == 'r') then

    player = player_horizontal_move(player, ball, field['default rw'] + player['radius'] * 2, net[side], btn_r, btn_l)
   
  end

  player['y'] += player['vertical speed']


  return player

end


function ball_move(field, ball)

  new_impulse = -1 * field['friction']

  if ((abs(ball['vertical speed']) < field['g'] * 1.1) and (ball['y'] >= field['floor'])) then
    ball['vertical speed'] = 0
  end

  if (ball['y'] >= field['floor']) then
    ball['horizontal speed'] *= field['friction'] * 1.2
  end

  if (ball['y'] > field['floor']) then
    ball['vertical speed'] *= new_impulse
    ball['y'] = field['floor']
  elseif (ball['y'] < field['celling']) then
    ball['vertical speed'] *= new_impulse
    ball['y'] = field['celling']
  else
    ball['y'] += ball['vertical speed']
  end

  if (ball['x'] + ball['horizontal speed'] + ball['radius'] >= field['right wall']) then
    ball['horizontal speed'] *= new_impulse
    ball['x'] = field['right wall'] - ball['radius']
  elseif (ball['x'] + ball['horizontal speed'] - ball['radius'] <= field['left wall']) then
    ball['horizontal speed'] *= new_impulse
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
    ball['vertical speed'] = vertical / hypotenuse * -5 + player['vertical speed'] / 5
    ball['horizontal speed'] = horizontal / hypotenuse * -5
    sfx(0)
  end

  

  return ball
end


function ball_net_collision( ... )
  -- body
end



function ai_core(field, player, ball, side)
  x_lambda = player['x'] - ball['x']
  y_lambda = abs(player['y'] - ball['y'])

  if (side == 'r') then
    lambda_l = -8
    lambda_r = -3
  else
    lambda_r = 8
    lambda_l = 3
  end

  if (x_lambda > lambda_l) then
    player['x'] -= player['horizontal speed']
  end

  if (x_lambda < lambda_r) then
    player['x'] += player['horizontal speed']
  end


    if (y_lambda < 90 and player['y'] >= field['floor'] and ball['vertical speed'] > 1) then
      player['vertical speed'] -= player['jump speed']
      player['y'] -= 1
    end
  return player
end

function ai(field, player, ball, net, side)
  
  if (side == 'r') then
    if (ball['x'] < net['r']) then ai_core(field, player, ball, side) end
  else
    if (ball['x'] > net['l']) then ai_core(field, player, ball, side) end
  end

  return player

end


function _update()
  
  
  s['vertical speed'] += f['g'] * s['m']
  p['vertical speed'] += f['g'] * p['m']
  p2['vertical speed'] += f['g'] * p2['m']
  
  f['left wall'] = count_wall(f, s, n, 'l')
  f['right wall'] = count_wall(f, s, n, 'r')


  p  = player_move(f, p,  s, n, btn(4, 0), btn(1, 0), btn(0, 0), 'l')
  p2 = player_move(f, p2, s, n, btn(4, 1), btn(1, 1), btn(0, 1), 'r')

  p2 = ai(f, p2, s, n, 'l')
  --p =  ai(f, p, s, n, 'r')

  s = ball_move(f, s)
  
  s = ball_player_collision(s, p)
  s = ball_player_collision(s, p2)


  if (s['y'] >= f['floor']) then
    if (s['x'] >= n['r']) then
      p['points'] += 1
      s['x'] = p['init x']
      sfx(1)
    elseif (s['x'] <= n['l']) then
      p2['points'] += 1
      s['x'] = p2['init x']
      sfx(2)
    end

    
    
    p['x'] = p['init x']
    p2['x'] = p2['init x']
    p['y'] = f['floor']
    p2['y'] = f['floor']
    s['y'] = 0
    s['horizontal speed'] = 0


  end

  
 



end
 
function _draw()
  cls(7)
  rectfill(n['l'], 127, n['r'], n['h'], 0)
  circfill(s['x'], s['y'], s['radius'], 8)
  circfill(p['x'], p['y'], p['radius'], 0)
  circfill(p2['x'], p2['y'], p2['radius'], 0)
  print(p['points'] .. ' : ' .. p2['points'], 5, 5, 0)
end





__label__
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777000777777777777700077777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777070777777077777707077777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777070777777777777707077777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777070777777077777707077777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777000777777777777700077777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777888777777777777777777777777777777777777777777777000077777777777777777777777777777777777777777777777777777777777777
77777777777788888887777777777777777777777777777777777777777777000077777777777777777777777777777777777777777777777777777777777777
77777777777788888887777777777777777777777777777777777777777777000077777777777777777777777777777777777777777777777777777777777777
77777777777888888888777777777777777777777777777777777777777777000077777777777777777777777777777777777777777777777777777777777777
77777777777888888888777777777777777777777777777777777777777777000077777777777777777777777777777777777777777777777777777777777777
77777777777888888888777777777777777777777777777777777777777777000077777777777777777777777777777777777777777777777777777777777777
77777777777788888887777777777777777777777777777777777777777777000077777777777777777777777777777777777777777777777777777777777777
77777777777788888887777777777777777777777777777777777777777777000077777777777777777777777777777777777777777777777777777777777777
77777777777777888777777777777777777777777777777777777777777777000077777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777000077777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777000077777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777000077777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777000077777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777000077777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777000077777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777000077777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777000077777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777000077777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777000077777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777000077777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777000077777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777000077777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777000077777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777000077777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777000077777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777000077777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777000077777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777000077777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777000077777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777000077777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777000077777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777000077777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777000077777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777000077777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777000077777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777000077777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777000077777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777000077777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777000077777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777000077777777777777777777777777777777777777777777777777777777777777
77777777777770000077777777777777777777777777777777777777777777000077777777777777777777777777777777777777777777000007777777777777
77777777777000000000777777777777777777777777777777777777777777000077777777777777777777777777777777777777777700000000077777777777
77777777770000000000077777777777777777777777777777777777777777000077777777777777777777777777777777777777777000000000007777777777
77777777700000000000007777777777777777777777777777777777777777000077777777777777777777777777777777777777770000000000000777777777
77777777000000000000000777777777777777777777777777777777777777000077777777777777777777777777777777777777700000000000000077777777
77777777000000000000000777777777777777777777777777777777777777000077777777777777777777777777777777777777700000000000000077777777
77777770000000000000000077777777777777777777777777777777777777000077777777777777777777777777777777777777000000000000000007777777
77777770000000000000000077777777777777777777777777777777777777000077777777777777777777777777777777777777000000000000000007777777
77777770000000000000000077777777777777777777777777777777777777000077777777777777777777777777777777777777000000000000000007777777
77777770000000000000000077777777777777777777777777777777777777000077777777777777777777777777777777777777000000000000000007777777
77777770000000000000000077777777777777777777777777777777777777000077777777777777777777777777777777777777000000000000000007777777
77777777000000000000000777777777777777777777777777777777777777000077777777777777777777777777777777777777700000000000000077777777

__sfx__
000100000b65000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0004000018550195501d5502155000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000400001c5501a550195501855000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 01424344

