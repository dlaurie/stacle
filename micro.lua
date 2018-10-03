-- stacle/micro.lua  © Dirk Laurie 2018, MIT license similar to Lua's
-- Primitives of Micro FORTH

local VM = require"stacle.vm"
local vm = VM{}
local concat,    define,    enddef,    erase,    pop = 
   vm.concat, vm.define, vm.enddef, vm.erase, vm.pop

return {
  SHOWSTACK = function(stack)
    stack.tostring = function(stack) return concat(stack).." ok" end
  end;
  HIDESTACK = function(stack)
    stack.tostring = function(stack) return "ok" end
  end;
  [':'] = define;
  [';'] = enddef;
  DUP = function(stack)  -- { a -- a a }
    local n = #stack
    stack[n+1] = stack[n]
  end;
  ['+'] = function(stack)  -- { a -- a+a }
    local n = #stack
    stack[n-1], stack[n] = stack[n-1] + stack[n]
  end;
  ['-'] = function(stack)  -- { a -- a-a }
    local n = #stack
    stack[n-1], stack[n] = stack[n-1] - stack[n]
  end;
  ['*'] = function(stack)  -- { a -- a*a }
    local n = #stack
    stack[n-1], stack[n] = stack[n-1] * stack[n]
  end;
  ['/'] = function(stack)  -- { a -- a/a }
    local n = #stack
    stack[n-1], stack[n] = stack[n-1] / stack[n]
  end;
  OVER = function(stack)  -- { a b -- a b a }
    local n = #stack
    stack[n+1] = stack[n-1]
  end;
  SWAP = function(stack)  -- { a b -- b a }
    local n = #stack
    stack[n-1], stack[n] = stack[n], stack[n-1]
  end;
  ROT = function(stack)  -- { a b c -- b c a }
    local n = #stack
    stack[n-2], stack[n-1], stack[n] = stack[n-1], stack[n], stack[n-2]
  end;
  DROP = pop;
  CLEAR = erase;
}
 


