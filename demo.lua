-- demo-forth.lua  © Dirk Laurie 2018, MIT license similar to Lua's
-- Interactive micro-Forth interpreter.
-- Usage: lua -i demo-forth

-- TODO This is just a proof-of-concept. 

local G = {}
for k,v in pairs(_ENV) do G[k]=v end

vm = require "stacle.vm"

vocab = require "stacle.micro"
stack = vm(vocab)

local list = {}
for k,v in pairs(stack.lexicon) do list[#list+1] = k end
table.sort(list)

local globals = {}
for k,v in pairs(_ENV) do if not G[k] then
  globals[#globals+1] = k
end end
table.sort(globals)

vocab.SHOWSTACK(stack)

print("=== Forth Demo ===")
print("The following words are known:\n   " .. table.concat(list,' '))
print("The following globals are known:\n   " .. table.concat(globals,' '))

print[[
To return to the Forth interpreter, type 'stack:REPL()'.
To define a new Forth primitive CMD, type 
   vocab.CMD = function(stack) LUA CODE end.
]]

stack:REPL()



