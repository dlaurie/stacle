-- forth/vm.lua  © Dirk Laurie 2018, MIT license similar to Lua's
-- A Virtual Machine for Forth-like languages

local append, tconcat, tmove, tremove, tunpack, clone
local define, enddef, concat, erase, execute, methods

-- Applies actions[k]..actions[n] to the stack
execute = function(stack,actions,k,n)
  k = k or 1
  n = n or #actions
  local aborting, _define
  local runlevel = 1
---
  local runerror = function(reason)
    error("Bad action "..k..": "..reason,runlevel)
  end
--- 
  _define = function()
    runlevel = 2
    local program = {}
    k = k+1
    local start = k
    if k>n then goto unfinished end
    arg = actions[k]
    if stack.lexicon[arg] then
      runerror"not implemented: redefinition"
    end
    if type(arg)~="string" then
      runerror("expected string, got "..type(arg))
    end
    name = arg   
    while k<n do
      k = k+1
      arg = actions[k]
      if arg==enddef then 
        local actions = program
        stack.lexicon[name] = 
          function(stack)
            execute(stack,actions)
          end
        name, program = nil, nil
        runlevel = 1
        return
       elseif arg==define then
        runerror"not implemented: nested definition"
      else append(program,arg)
      end
    end
::unfinished::
    error("'define' at "..(start-1).." not matched by 'enddef'")
  end
---
  while k<=n do
    if aborting then return 'aborting' end
    local arg = actions[k]
    if arg==define then _define()
    elseif arg==enddef then runerror"'enddef' with no previous 'define'"
    elseif arg == nil then
      if stack.donil then stack:donil() end
    elseif type(arg) == 'function' then arg(stack)
    else append(stack,arg)
    end
    k = k+1
  end
  return stack
end

local run = function(stack,...)
  return execute(stack,{...},1,select('#',...))
end

-- Create a new stack
local newstack = function(lexicon,stack)
  local ok
  if type(lexicon) == 'string' then
    ok, lexicon = pcall(require,"forth."..lexicon)
    if not ok then
      error(lexicon)
    end
  end
  if type(lexicon)~='table' then
    return [[
Usage:
    VM = require"forth.vm"
    vm = VM(lexicon[,stack])
where `lexicon` is either a user-supplied (possibly empty) table of methods 
or a string `lang` such that `require "forth.lang"` provides such a table.
]]
  end
  stack = stack or {}
  stack.lexicon = lexicon
  return setmetatable( stack, {
--    __metatable = "Virtual Machine for Forth-like languages",
    __index = setmetatable(clone(methods),{__index=function(stack,idx)      
       return (rawget(stack,"lexicon") or {})[idx] end}),
    __call = run, 
    __tostring = function(stack)  
      if stack.tostring then return stack:tostring() 
        else return concat(stack)
      end
    end;
    __len = function(stack)  
      return stack.top or rawlen(stack)
    end;
    })
end

append, tconcat, tmove, tremove, tunpack = 
  table.insert, table.concat, table.move, table.remove, table.unpack

-- parse code, return array of actions
-- If a word is not in stack.lexicon, evaluate it as Lua if possible,
-- otherwise keep word as a string.
local parse = function(stack,code)  
  local words = {}
  local vocab = stack.lexicon or {}
  local doword = function(word)
    local f = load("return "..word,nil,nil,vocab)
    if f then local ok,result = pcall(f) 
      if ok then return result end
    end
  end
  code:gsub("%S+",function(word)
    words[#words+1] = vocab[word] or doword(word) or word
    end)
  return words
end

-- compile code, returning a function of a sequence
local compile = function(stack,code)
  local actions = parse(stack,code)
  return function(stk)
    return execute(stk,actions)
  end
end

-- interactive loop
local REPL = function(stack)
  print"Press Ctrl-D once to drop down to Lua, twice to exit"
  while true do
    print(stack)
    code = io.read()
    if not code then break end
    compile(stack,code)(stack)
  end
end

-- string representation of stack
concat = function(stack,delim,from,to)
  local tbl = {}
  for k=from or 1,to or #stack do append(tbl,tostring(stack[k])) end
  return tconcat(tbl,delim or ' ')
end

-- enter definition mode
define = function(stack)
  return "Preparing a new definition"
end

-- exit definition mode
enddef = function(stack)
  return "Finishing a new definition"
end

-- erase and return specified block
erase = function(stack,from,to)
  local n=#stack
  from = from or 1
  to = to or n
  if not (from>=1 and from<=n) then 
    error("bad argument #1 to 'erase', expected in range 1 to "..n..
     ", got "..from)
  end
  if from>to then return end
  local ans = tmove(stack,from,to,1,{})    
  tmove(stack,to+1,2*to-from+1,from)
  return tunpack(ans)
end;

-- pop elements off stack
local pop = function(stack,count)
  local n=#stack
  count = count or 1
  if count > n then
    error("bad argument #1 to 'pop', expected <= "..n..", got "..count)
  end
  return erase(stack,n-count+1,n)
end

methods = { run=run, execute=execute, parse=parse, compile=compile, REPL=REPL, 
  concat=concat, define=define, enddef=enddef, erase=erase, pop=pop}

-- shallow copy of table
clone = function(tbl)
  local cloned={}
  for k,v in pairs(tbl) do cloned[k]=v end
  return cloned
end

return newstack


