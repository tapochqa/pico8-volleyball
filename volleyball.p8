pico-8 cartridge // http://www.pico-8.com
version 39
__lua__


s =     {
         ['net h'] = 70,
         ['net l'] = 63,
         ['net r'] = 64,
         ['x'] = 15,
         ['y'] = 0,
         ['g'] = 0.2,
         ['default floor'] = 124,
         ['floor'] = 124,
         ['celling'] = 5,
         ['default lw'] = 1,
         ['default rw'] = 127,
         ['vertical speed'] = 0,
         ['horizontal speed'] = 0,
         ['friction'] = 0.75,
         ['radius'] = 4,
         ['m'] = 1
         }

p =     {['x'] = 15,
         ['y'] = 127 - 10,
         ['vertical speed'] = 0,
         ['horizontal speed'] = 3,
         ['radius'] = 8,
         ['m'] = 3

       }     


function count_wall(x, y, net_h, net_x, side, default, radius)
  if (y < net_h) then
    return default
  elseif (side == 'right') then 
    if (x > net_x) then
      return default
    else
      return net_x
    end
  elseif (side == 'left') then
    if (x < net_x) then
      return default
    else
      return net_x
    end
  end
end


function _update()
  
  
  s['vertical speed'] += s['g'] * s['m']
  p['vertical speed'] += s['g'] * p['m']


  
  s['left wall'] = count_wall(s['x'], 
                              s['y'], 
                              s['net h'], 
                              s['net r'], 
                              'left', 
                              s['default lw'],
                              s['radius'])
  s['right wall'] = count_wall(s['x'], 
                              s['y'], 
                              s['net h'], 
                              s['net l'], 
                              'right', 
                              s['default rw'],
                              s['radius'])


  if ((abs(s['vertical speed']) < s['g'] * 1.1) and (s['y'] >= s['floor'])) then
    s['vertical speed'] = 0
  end

  if (s['y'] >= s['floor']) then
    s['horizontal speed'] = s['friction'] * 1.2 * s['horizontal speed']
  end

  if (p['y'] >= s['floor']) then
    p['vertical speed'] = 0
  end

  if (btn(2) and p['y'] >= s['floor']) then
    p['vertical speed'] -= 8
  elseif (p['y'] >= s['floor']) then
    p['y'] = s['floor']
  end
  if (btn(1) and p['x'] + p['radius'] + s['radius'] <= s['net l']) then
    p['x'] += p['horizontal speed']
  end
    if (btn(0) and p['x'] - p['radius'] - s['radius'] >= s['default lw']) then
    p['x'] -= p['horizontal speed']
  end

  p['y'] += p['vertical speed']

  if (s['y'] > s['floor']) then
    s['vertical speed'] = -1 * s['friction'] * s['vertical speed']
    s['y'] = s['floor']
  elseif (s['y'] < s['celling']) then
    s['vertical speed'] = -1 * s['friction'] * s['vertical speed']
    s['y'] = s['celling']
  else
    s['y'] += s['vertical speed']
  end

  if (s['x'] + s['horizontal speed'] >= s['right wall']) then
    s['horizontal speed'] = -1 * s['friction'] * s['horizontal speed']
    s['x'] = s['right wall'] - s['radius']
  elseif (s['x'] + s['horizontal speed'] <= s['left wall']) then
    s['horizontal speed'] = -1 * s['friction'] * s['horizontal speed']
    s['x'] = s['left wall'] + s['radius']
  else
    s['x'] += s['horizontal speed']
  end

  hypotenuse = sqrt((s['x'] - p['x']) ^ 2 + (s['y'] - p['y']) ^ 2)
  vertical =  p['y'] - s['y']
  horizontal = p['x'] - s['x'] 


  if (hypotenuse <= s['radius'] + p['radius']) then
    s['vertical speed'] = vertical / hypotenuse * -5
    s['horizontal speed'] = horizontal / hypotenuse * -5
  end



end
 
function _draw()
  cls(1)
  -- rectfill(s['left wall'], s['floor'], s['right wall'], s['celling'] , 2)
  rectfill(s['net l'], 127, s['net r'], s['net h'], 12)
  circfill(s['x'], s['y'], s['radius'], 15)
  circfill(p['x'], p['y'], p['radius'], 12)
end
