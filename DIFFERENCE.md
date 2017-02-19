## Incompatibility between liquid-lua and liquid-ruby

1. Can '`{{`','`}}`','`%}`','`{%`' appear in liquid literal string?
fragment 1
``` liquid
    {{ "abc" }}
```
fragment 2
``` liquid
    {{ "}}" }}
```
In liquid-ruby these string are matched by regexp and these strings always mean a start or a end of liquid code. But in liquid-lua these strings are processed by a lexer and these strings can appear in liquid litral string and template raw string with escape char '\\'. That is to say liquid-lua has a native escape mechanism but liquid-ruby does not. So in liquid-ruby fragment 1 will be syntax ok, fragment 2 will be syntax error. In liquid-lua both fragment 1 and fragment 2 are syntax ok.

2. Using nil as a key to index a hash(table) object.
In ruby language it is ok use nil as a key to index a hash object. e.g.,
```ruby
# In ruby language
obj = {}
obj[nil] = "hello, world"
puts obj[nil] # output "hello, world"
```
But in lua it is illegal to use nil as a key to index a table. e.g.,
```lua
-- In lua language
local obj = {}
obj[nil] = "hello, world" -- BOOM!! IT IS ILLEGAL!!
```
Since liquid-ruby maps liquid nil type to ruby nil type, So using nil as a key to index a hash in liquid ruby is totaly fine and will get a right result. Howerver, liquid-lua maps liquid nil type to lua nil type, it is syntax ok use nil as a key to index a table object in liquid-lua, but the return result will always be nil in the current implementation. 

3. Math calculation
```liquid
{{ 5 | divided_by: 2 }}
```
Liquid-lua maps liquid number type to lua number type, while liquid-ruby maps liquid number to ruby int type or float type. So number in liquid-lua default behaves like a float type. But in liquid-ruby, number behaves like a int or float type depending on its scenario. So the above fragment code in liquid-lua will be 2.5 and in liquid-ruby will be 2.

4. for-loop with literal number range
```liquid
{% for k in (1.5 .. 5.5) %} {{ k }} {% endfor %}
```
Liquid-lua only has a error mode and maps liquid literal number to lua number type, so its result will be `1.5 2.5 3.5 4.5 5.5`.
But liquid-ruby has three error modes. In the lax mode, the result is syntax ok and its result is empty.(it's weird because of its tag parser). In the strict mode, the result is syntax ok and its result is `1 2 3 4 5`.