pico-8 cartridge // http://www.pico-8.com
version 39
__lua__

f =     {['g'] = 0.2,
         ['default floor'] = 124,
         ['floor'] = 124,
         ['celling'] = 5,
         ['default lw'] = 1,
         ['default rw'] = 127,
         ['friction'] = 0.75,
         ['max points'] = 11,
         ['counter'] = 100,
         ['status'] = ''}

s =     {['x'] = 15,
         ['y'] = 10,
         ['vertical speed'] = 0,
         ['horizontal speed'] = 0,
         ['radius'] = 4,
         ['m'] = 1.5,
         ['in collision'] = false}

n =     {['h'] = 80,
         ['l'] = 62,
         ['r'] = 63}

p =     {['x'] = 15,
         ['init x'] = 15,
         ['y'] = 127 - 10,
         ['vertical speed'] = 0,
         ['horizontal speed'] = 3,
         ['radius'] = 7,
         ['m'] = 3,
         ['points'] = 0,
         ['jump speed'] = 8,
         ['in collision'] = false,
         ['name'] = 'p1'}

p2 =    {['x'] = f['default rw'] - 15,
         ['init x'] = f['default rw'] - 15,
         ['y'] = 127 - 10,
         ['vertical speed'] = 0,
         ['horizontal speed'] = 3,
         ['radius'] = 7,
         ['m'] = 3,
         ['points'] = 0,
         ['jump speed'] = 8,
         ['in collision'] = false,
         ['name'] = 'cpu'}


function shallow_copy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end



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


function ball_player_collided(ball, player)
  ball_fin_x = ball['x']
  ball_fin_y = ball['y']
  p_fin_x = player['x']
  p_fin_y = player['y']

  hypotenuse = sqrt(((ball_fin_x - p_fin_x) ^ 2) + ((ball_fin_y - p_fin_y) ^ 2))

  if (hypotenuse <= ball['radius'] + player['radius']) then
    return true
  else
    return false
  end
end


function ball_net_collided(field, ball, net)

  -- https://stackoverflow.com/a/402010/10354619

  net_x = (net['r'] + net['l']) / 2
  net_y = (net['h'] + field['floor']) / 2
  net_height = abs(net['h'] - field['floor'])
  net_width = abs(net['r'] - net['l'])

  delta_x = abs(ball['x'] + ball['horizontal speed'] - net_x)
  delta_y = abs(ball['y'] + ball['vertical speed'] - net_y)

  if (delta_x > net_width / 2 + ball['radius']) then return false end
  if (delta_y > net_height / 2 + ball['radius']) then return false end 

  if (delta_x <= net_width / 2) then return true end
  if (delta_y <= net_height / 2) then return true end

  corner_distance_sq = (delta_x - net_width / 2) ^ 2 + (delta_y - net_height / 2) ^ 2
  return (corner_distance_sq <= ball['radius'] ^ 2)

end


function ball_move(field, ball, net, p1, p2)

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
    sfx(3)
    ball['vertical speed'] *= new_impulse
    ball['y'] = field['celling']
  elseif (not ball_player_collided(ball, p1) and not ball_player_collided(ball, p2)) then
    ball['y'] += ball['vertical speed']
  end

  if (ball['x'] + ball['horizontal speed'] + ball['radius'] >= field['right wall']) then
    sfx(3)
    ball['horizontal speed'] *= new_impulse
    ball['x'] = field['right wall'] - ball['radius'] + ball['horizontal speed']
  elseif (ball['x'] + ball['horizontal speed'] - ball['radius'] <= field['left wall']) then
    sfx(3)
    ball['horizontal speed'] *= new_impulse
    ball['x'] = field['left wall'] + ball['radius'] + ball['horizontal speed']
  elseif (ball_net_collided(field, ball, net) == true) then
    sfx(3)
    if (ball['x'] > net['l'] and ball['horizontal speed'] >= 0) then
      ball['vertical speed'] *= new_impulse
      repeat
        ball['y'] += ball['vertical speed']
      until (ball_net_collided(field, ball, net) == false)
    elseif (ball['x'] < net['r'] and ball['horizontal speed'] <= 0) then
      ball['vertical speed'] *= new_impulse
      repeat
        ball['y'] += ball['vertical speed']
      until (ball_net_collided(field, ball, net) == false)
    else
      ball['horizontal speed'] *= new_impulse
      repeat
        ball['x'] += ball['horizontal speed']
      until (ball_net_collided(field, ball, net) == false)
    end
    
  elseif (not ball_player_collided(ball, p1) and not ball_player_collided(ball, p2)) then
    ball['x'] += ball['horizontal speed']
  end

  return ball
end




function ball_player_collision(field, ball, net, player)

  ball_fin_x = ball['x']
  ball_fin_y = ball['y']
  p_fin_x = player['x']
  p_fin_y = player['y']

  hypotenuse = sqrt(((ball_fin_x - p_fin_x) ^ 2) + ((ball_fin_y - p_fin_y) ^ 2))
  vertical =   p_fin_y - ball_fin_y
  horizontal =  p_fin_x - ball_fin_x  
  relation = ball['radius'] / player['radius']

  ball2 = shallow_copy(ball)

  if (player['x'] < net['l']) then
    d = -ball2['radius'] * 2
  else
    d = ball2['radius'] * 2
  end

  ball2['x'] -= horizontal / hypotenuse * 5 + d

  if (hypotenuse <= ball['radius'] + player['radius']) then
    ball['vertical speed'] = vertical / hypotenuse * -5 + player['vertical speed'] / 5
    ball['horizontal speed'] = horizontal / hypotenuse * -5
    sfx(0)

    if (ball_net_collided(field, ball, net) == true) then
      ball['horizontal speed'] *= -1
      if (ball ['vertical speed'] == 0) then
        ball['vertical speed'] = -7
      end
    end

    repeat
      hypotenuse = sqrt((ball['x'] - player['x']) ^ 2 + (ball['y'] - player['y']) ^ 2)
      ball['x'] += ball['horizontal speed'] / 7
      ball['y'] += ball['vertical speed'] / 7
    until(hypotenuse - ball['radius'] - player['radius'] > 4)

    ball['in collision'] = true
  else 
    ball['in collision'] = false
  end


  return ball
end


function ai_core(field, player, ball, side)
  x_lambda = player['x'] - ball['x']
  y_lambda = abs(player['y'] - ball['y'])

  if (side == 'r') then
    lambda_l = -11
    lambda_r = -6
  else
    lambda_r = 11
    lambda_l = 6
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

  f['counter'] = f['counter'] + 1
  
  s = ball_player_collision(f, s, n, p)
  s = ball_player_collision(f, s, n, p2)

  s['vertical speed'] += f['g'] * s['m']
  p['vertical speed'] += f['g'] * p['m']
  p2['vertical speed'] += f['g'] * p2['m']
  
  f['left wall'] = f['default lw']
  f['right wall'] = f['default rw']

  p  = player_move(f, p,  s, n, btn(4, 0), btn(1, 0), btn(0, 0), 'l')
  p2 = player_move(f, p2, s, n, btn(4, 1), btn(1, 1), btn(0, 1), 'r')

  p2 = ai(f, p2, s, n, 'l')
  --p =  ai(f, p, s, n, 'r')

  s = ball_move(f, s, n, p, p2)

  


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
    s['y'] = 10
    s['vertical speed'] = 0
    s['horizontal speed'] = 0

  end
--]]

  if (p['points'] == f['max points'] or p2['points'] == f['max points']) then


    if (p['points'] == f['max points']) then
      f['status'] = p['name'] .. ' won'
    else
      f['status'] = p2['name'] .. ' won'
    end

    s['x'] = p['init x']
    f['counter'] = 0
    p['points'] = 0
    p2['points'] = 0
  end

end


build = 2

 
function _draw()
  cls(135)

  if (f['counter'] < 100) then
    print(f['status'], 50, 60)
  end

  
  rectfill(n['l'], 127, n['r'], n['h'], 0)
  circfill(s['x'], s['y'], s['radius'], 2)
  circfill(p['x'], p['y'], p['radius'], 0)
  circfill(p2['x'], p2['y'], p2['radius'], 0)
  print(p['points'] .. ':' .. p2['points'], 5, 5, 0)
  print('v. ' .. build, 5, 13, 0)
  print('???????   jump', 128-40, 5, 0)
  print('???????????? move', 128-40, 13, 0)


end





__label__
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffff00ffffff000fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00000ffffffffffffff000f0f0f000f000fffff
ffffff0fff0ff0f0ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00f0f00ffffffffffffff0ff0f0f000f0f0fffff
ffffff0ffffff000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff000f000ffffffffffffff0ff0f0f0f0f000fffff
ffffff0fff0ff0f0ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00f0f00ffffffffffffff0ff0f0f0f0f0fffffff
fffff000fffff000fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00000ffffffffffffff00fff00f0f0f0fffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00000fff00000ffffff000ff00f0f0f000fffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff000ff00f00ff000fffff000f0f0f0f0f0fffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00fff00f00fff00fffff0f0f0f0f0f0f00ffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff000ff00f00ff000fffff0f0f0f0f000f0fffffff
fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00000fff00000ffffff0f0f00fff0ff000fffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff222fffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2222222fffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2222222fffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff222222222ffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff222222222ffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff222222222ffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2222222fffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2222222fffffffffffffffffff00000fffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff222fffffffffffffffffff000000000fffffffffffffffffffffff
fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00000000000ffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0000000000000fffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0000000000000fffffffffffffffffffff
fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff000000000000000ffffffffffffffffffff
fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff000000000000000ffffffffffffffffffff
fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff000000000000000ffffffffffffffffffff
fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff000000000000000ffffffffffffffffffff
fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff000000000000000ffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0000000000000fffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0000000000000fffffffffffffffffffff
fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00000000000ffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff000000000fffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffffffffffffffffff00000fffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffffff00000ffffffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffff000000000ffffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffff00000000000fffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffffff0000000000000ffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffffff0000000000000ffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffff000000000000000fffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffff000000000000000fffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffff000000000000000fffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffff000000000000000fffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffff000000000000000fffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffffff0000000000000ffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffffff0000000000000ffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffff00000000000fffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffff000000000ffffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffffff00000ffffffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff

__sfx__
000100000b65000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0004000018550195501d5502155000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000400001c5501a550195501855000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100000115000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 01424344

