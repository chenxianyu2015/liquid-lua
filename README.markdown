# liquid-lua
A lua implementation of [liquid](https://shopify.github.io/liquid/) for [OpenResty](http://openresty.org/en/) platform.
[![Build Status](https://travis-ci.org/chenxianyu2015/liquid-lua.svg?branch=master)](https://travis-ci.org/chenxianyu2015/liquid-lua)

## Introduction
Since liquid markup language has no its official language specification document , liquid-lua adopts a classic lexer/parser/interpreter implementation approch and comes up with a strict error mode, which is different from the [liquid-ruby](https://github.com/Shopify/liquid) approach(regexp tokenizer/tag parser/tag interpreter) with three error modes(lax/warning/strict mode). Due to different implementation approch, liquid-lua will behave differently from liquid-ruby in some cases.**i.e., liquid-lua is NOT 100% compatible with liquid-ruby.** More detail info about incompatibility between liquid-lua and liquid-ruby will be collected and listed in DIFFERENCE.md .
The following components of liquid-lua have been implemented:


* Lexer
* Parser
* Interpreter
* Parser context
    - A component for whitespace control feature.
* Interprerter context
    - A Component exposing lua variable to liquid engine.
* FilterSet
    - A Component exposing lua function to liquid engine. In liquid-ruby it's called `Strainer`.
* Resourcelimit
    - A simple system resource limit component for liquid engine.
* File system
    - A simple wraper of template source backend (redis/mongo/local file system).
* Lazy
    - A wraper makes a normal lua table behave like lazy hash. In liquid-ruby it's called `Drop`.
* Nodetab
    - Runtime errors can get the corresponding source text position info from Nodetab. (Linux ELF has a Systab, liquid-lua has a Nodetab.)


## Installation
### Using [OpenResty Package Manager](https://opm.openresty.org/)(Recommened)

1. Install OpenResty Package Manager if you haven't yet;
2. Run the following Openesty Package Manager commands to search and install liquid-lua package.

```shell
opm search liquid-lua
opm get chenxianyu2015/liquid-lua
```

### Manual install
1. Download zip package.
2. Extract `liquid.lua` directory from zip package.
3. Copy it to your openresty lua lib path.

### Usage:
Liquid-lua provides a frendly template interface to use which is much like liquid-ruby.
1. a 'hi tobi' example 
```lua
-- require these components
local Liquid = require 'liquid'

-- template to render
local document = 'hi {{name}}'
-- variable to render
local var = {["name"] = "tobi" }

local template = Liquid.Template:parse(document)

-- the content of result is  'hi tobi'
local result = template:render( Liquid.InterpreterContext:new(var) )
```

2. a for-loop example
```lua
-- require these components
local Liquid = require 'liquid'

-- template to render
local document = '{%for k in num%} {{k}} {% endfor%}'
-- variable to render
local var = {["num"] = {5,4,3,2,1} }

local template = Liquid.Template:parse(document)

-- the content of result is:  5  4  3  2  1
local result = template:render( Liquid.InterpreterContext:new(var) )
```


Meanwhile liquid-lua has a lot of basic and low level components, which are not frendly or easy to use. But it is easy to build your interfaces with these components.
Here are some examples to show how to use these components.


1. a 'hi tobi' example 
```lua
-- require these components
local Liquid = require 'liquid'
local Lexer = Liquid.Lexer
local Parser = Liquid.Parser
local Interpreter = Liquid.Interpreter
local InterpreterContext = Liquid.InterpreterContext

-- template to render
local document = 'hi {{name}}'
-- variable to render
local var = {["name"] = "tobi" }

-- dataflow: lexer -> parser -> interpreter
local lexer = Lexer:new(document)
local parser = Parser:new(lexer)
local interpreter = Interpreter:new(parser)

-- the content of result is  'hi tobi'
local result = interpreter:interpret( InterpreterContext:new(var) )
```

2. a for-loop example
```lua
-- require these components
local Liquid = require 'liquid'
local Lexer = Liquid.Lexer
local Parser = Liquid.Parser
local Interpreter = Liquid.Interpreter
local InterpreterContext = Liquid.InterpreterContext

-- template to render
local document = '{%for k in num%} {{k}} {% endfor%}'
-- variable to render
local var = {["num"] = {5,4,3,2,1} }

-- dataflow: lexer -> parser -> interpreter
local lexer = Lexer:new(document)
local parser = Parser:new(lexer)
local interpreter = Interpreter:new(parser)

-- the content of result is:  5  4  3  2  1
local result = interpreter:interpret( InterpreterContext:new(var) )
```

## TODO
 - More test cases
 - Duplicate and dirty code cleanup and refactoring
 - Template cache and AST cache component
 - More filters 
 
## Getting Involved
- __Report bugs__ by posting a description, full stack trace, and all relevant code in a  [GitHub issue](https://github.com/chenxianyu2015/liquid-lua/issues).

## Licence
This module is licensed under the BSD license.