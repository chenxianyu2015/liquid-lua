use Test::Nginx::Socket::Lua;
use Cwd qw(cwd);

# repeat_each(2);

plan tests => repeat_each() * (3 * blocks());

my $pwd = cwd();

our $HttpConfig = qq{
    lua_package_path "$pwd/lib/?.lua;;;";
    lua_package_cpath "/usr/local/openresty/lualib/?.so;;";
};


no_long_string();
#no_diff();

run_tests();

__DATA__

=== TEST 1: 'if elsif else endif' tag.
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local Liquid = require 'liquid'
            local Lexer = Liquid.Lexer
            local Parser = Liquid.Parser
            local Interpreter = Liquid.Interpreter
            local document = "{% if true  %} abc {% endif %}"
            local lexer = Lexer:new(document)
            local parser = Parser:new(lexer)
            local interpreter = Interpreter:new(parser)
            ngx.say(interpreter:interpret())
        }
    }
--- request
GET /t
--- response_body
 abc 

--- no_error_log
[error]


=== TEST 2: 'unless elsif else endunless' tag.
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local Liquid = require 'liquid'
            local Lexer = Liquid.Lexer
            local Parser = Liquid.Parser
            local Interpreter = Liquid.Interpreter
            local document = "{% unless false  %} abc {% else %} efg {% endunless %}"
            local lexer = Lexer:new(document)
            local parser = Parser:new(lexer)
            local interpreter = Interpreter:new(parser)
            ngx.say(interpreter:interpret())
        }
    }
--- request
GET /t
--- response_body
 abc 

--- no_error_log
[error]


=== TEST 3:  'case when endcase' tag.
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local Liquid = require 'liquid'
            local Lexer = Liquid.Lexer
            local Parser = Liquid.Parser
            local Interpreter = Liquid.Interpreter
            local document = "{% case 2  %} {% when 1 %} abc {% when 2 %} efg {% when 3 %} hij {% else %} klm {% endcase %}"
            local lexer = Lexer:new(document)
            local parser = Parser:new(lexer)
            local interpreter = Interpreter:new(parser)
            ngx.say(interpreter:interpret())
        }
    }
--- request
GET /t
--- response_body
 efg 

--- no_error_log
[error]

=== TEST 4: 'for else endfor' tag.
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local Liquid = require 'liquid'
            local Lexer = Liquid.Lexer
            local Parser = Liquid.Parser
            local Interpreter = Liquid.Interpreter
            local document = "{% for k in (1..5)  %} {{ k }} {% else %} abc {% endfor %}"
            local lexer = Lexer:new(document)
            local parser = Parser:new(lexer)
            local interpreter = Interpreter:new(parser)
            ngx.say(interpreter:interpret())
        }
    }
--- request
GET /t
--- response_body
 1  2  3  4  5 


--- no_error_log
[error]



=== TEST 5: 'cycle' tag.
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local Liquid = require 'liquid'
            local Lexer = Liquid.Lexer
            local Parser = Liquid.Parser
            local Interpreter = Liquid.Interpreter
            local document = "{% cycle \"abc\", \"def\", \"ghi\"  %}{% cycle \"abc\", \"def\", \"ghi\"  %}"
            local lexer = Lexer:new(document)
            local parser = Parser:new(lexer)
            local interpreter = Interpreter:new(parser)
            ngx.say(interpreter:interpret())
        }
    }
--- request
GET /t
--- response_body
abcdef
--- no_error_log
[error]

=== TEST 6: "tablerow' tag.
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local Liquid = require 'liquid'
            local Lexer = Liquid.Lexer
            local Parser = Liquid.Parser
            local Interpreter = Liquid.Interpreter
            local document = "{% tablerow k in (1..5) offset:1 limit:3 cols:2 %} {{k}} {% endtablerow %}"
            local lexer = Lexer:new(document)
            local parser = Parser:new(lexer)
            local interpreter = Interpreter:new(parser)
            ngx.say(interpreter:interpret())
        }
    }
--- request
GET /t
--- response_body
<tr class="row1">
<td class="col1">
 2 
</td>
<td class="col2">
 3 
</td>
</tr>
<tr class="row2">
<td class="col1">
 4 
</td>
</tr>

--- no_error_log
[error]



=== TEST 7: 'break' tag.
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local Liquid = require 'liquid'
            local Lexer = Liquid.Lexer
            local Parser = Liquid.Parser
            local Interpreter = Liquid.Interpreter
            local document = "{% for k in (1..5) %} {% if k == 3  %}  {% break %}{% endif %} {{ k }} {%endfor%}"
            local lexer = Lexer:new(document)
            local parser = Parser:new(lexer)
            local interpreter = Interpreter:new(parser)
            ngx.say(interpreter:interpret())
        }
    }
--- request
GET /t
--- response_body
  1   2    

--- no_error_log
[error]


=== TEST 8: 'continue' tag.
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local Liquid = require 'liquid'
            local Lexer = Liquid.Lexer
            local Parser = Liquid.Parser
            local Interpreter = Liquid.Interpreter
            local document = "{% for k in (1..5) %} {% if k == 3  %}  {% continue %}{% endif %} {{ k }} {%endfor%}"
            local lexer = Lexer:new(document)
            local parser = Parser:new(lexer)
            local interpreter = Interpreter:new(parser)
            ngx.say(interpreter:interpret())
        }
    }
--- request
GET /t
--- response_body
  1   2      4   5 



--- no_error_log
[error]


=== TEST 9: 'assign' tag.
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local Liquid = require 'liquid'
            local Lexer = Liquid.Lexer
            local Parser = Liquid.Parser
            local Interpreter = Liquid.Interpreter
            local document = "{% assign abc = 123  %}{{ abc }}"
            local lexer = Lexer:new(document)
            local parser = Parser:new(lexer)
            local interpreter = Interpreter:new(parser)
            ngx.say(interpreter:interpret())
        }
    }
--- request
GET /t
--- response_body
123

--- no_error_log
[error]

=== TEST 10: 'capture' tag.
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local Liquid = require 'liquid'
            local Lexer = Liquid.Lexer
            local Parser = Liquid.Parser
            local Interpreter = Liquid.Interpreter
            local document = "{% capture abc  %} defg {% endcapture %}{{ abc }}"
            local lexer = Lexer:new(document)
            local parser = Parser:new(lexer)
            local interpreter = Interpreter:new(parser)
            ngx.say(interpreter:interpret())
        }
    }
--- request
GET /t
--- response_body
 defg 
--- no_error_log
[error]


=== TEST 11: 'increment' tag.
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local Liquid = require 'liquid'
            local Lexer = Liquid.Lexer
            local Parser = Liquid.Parser
            local Interpreter = Liquid.Interpreter
            local document = "{% increment abc  %} {% increment abc  %}"
            local lexer = Lexer:new(document)
            local parser = Parser:new(lexer)
            local interpreter = Interpreter:new(parser)
            ngx.say(interpreter:interpret())
        }
    }
--- request
GET /t
--- response_body
0 1

--- no_error_log
[error]

=== TEST 12: 'decrement' tag.
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local Liquid = require 'liquid'
            local Lexer = Liquid.Lexer
            local Parser = Liquid.Parser
            local Interpreter = Liquid.Interpreter
            local document = "{% increment abc  %} {% decrement abc  %}"
            local lexer = Lexer:new(document)
            local parser = Parser:new(lexer)
            local interpreter = Interpreter:new(parser)
            ngx.say(interpreter:interpret())
        }
    }
--- request
GET /t
--- response_body
0 -1

--- no_error_log
[error]

=== TEST 13: 'include' tag.
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local Liquid = require 'liquid'
            local Lexer = Liquid.Lexer
            local Parser = Liquid.Parser
            local Interpreter = Liquid.Interpreter
            local FileSystem = Liquid.FileSystem
            local InterpreterContext = Liquid.InterpreterContext
            local var = {["aa"] =  "-----",  ["bb"] = { ["cc"] = "======" } }
            local document = "{% if true  %} abc{{ aa }}defg {% endif %} {% include 'foo' for bb  %} {% include 'foo' %} "
            local function mock_template()
                return [[{% if true  %} 12345{{ cc }}6789 {% endif %}]]
            end
            FileSystem.get = mock_template
            local lexer = Lexer:new(document)
            local parser = Parser:new(lexer)
            local interpreter = Interpreter:new(parser)
            ngx.say( interpreter:interpret( InterpreterContext:new(var) ) )
        }
    }
--- request
GET /t
--- response_body
 abc-----defg   12345======6789   123456789  

--- no_error_log
[error]

=== TEST 14: 'comment' tag.
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local Liquid = require 'liquid'
            local Lexer = Liquid.Lexer
            local Parser = Liquid.Parser
            local Interpreter = Liquid.Interpreter
            local FileSystem = Liquid.FileSystem
            local InterpreterContext = Liquid.InterpreterContext
            local document = "{% comment  %} abc {% endcomment %} defg"
            local lexer = Lexer:new(document)
            local parser = Parser:new(lexer)
            local interpreter = Interpreter:new(parser)
            ngx.say( interpreter:interpret() )
        }
    }
--- request
GET /t
--- response_body
 defg
--- no_error_log
[error]


=== TEST 15: 'raw' tag.
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local Liquid = require 'liquid'
            local Lexer = Liquid.Lexer
            local Parser = Liquid.Parser
            local Interpreter = Liquid.Interpreter
            local FileSystem = Liquid.FileSystem
            local InterpreterContext = Liquid.InterpreterContext
            local document = "{%raw%}{% if true  %} abc{{ aa }}defg {% endif %}{% endraw %}"
            local lexer = Lexer:new(document)
            local parser = Parser:new(lexer)
            local interpreter = Interpreter:new(parser)
            ngx.say( interpreter:interpret( ) )
        }
    }
--- request
GET /t
--- response_body
{% if true  %} abc{{ aa }}defg {% endif %}

--- no_error_log
[error]

=== TEST 16: whitespace control  1
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local Liquid = require 'liquid'
            local Lexer = Liquid.Lexer
            local Parser = Liquid.Parser
            local Interpreter = Liquid.Interpreter
            local FileSystem = Liquid.FileSystem
            local InterpreterContext = Liquid.InterpreterContext
            local document = "{{ 1 }}  abc  {{ 2 }}{{ 3 -}}  abc  {{- 4 }}"
            local lexer = Lexer:new(document)
            local parser = Parser:new(lexer)
            local interpreter = Interpreter:new(parser)
            ngx.say( interpreter:interpret( ) )
        }
    }
--- request
GET /t
--- response_body
1  abc  23abc4

--- no_error_log
[error]

=== TEST 17: whitespace control 2
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local Liquid = require 'liquid'
            local Lexer = Liquid.Lexer
            local Parser = Liquid.Parser
            local Interpreter = Liquid.Interpreter
            local FileSystem = Liquid.FileSystem
            local InterpreterContext = Liquid.InterpreterContext
            local document = "{% if true %}  abc  {% endif %}{% if true -%}  abc  {%- endif %}"
            local lexer = Lexer:new(document)
            local parser = Parser:new(lexer)
            local interpreter = Interpreter:new(parser)
            ngx.say( interpreter:interpret( ) )
        }
    }
--- request
GET /t
--- response_body
  abc  abc

--- no_error_log
[error]


=== TEST 18: 'for endfor' tag.
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local Liquid = require 'liquid'
            local Lexer = Liquid.Lexer
            local Parser = Liquid.Parser
            local Interpreter = Liquid.Interpreter
            local InterpreterContext = Liquid.InterpreterContext
            local document = "{% for v in values %}{{ v }}{% endfor %}"
            local lexer = Lexer:new(document)
            local parser = Parser:new(lexer)
            local interpreter = Interpreter:new(parser)
            ngx.say(interpreter:interpret(InterpreterContext:new({ values = { 'one' } })))
        }
    }
--- request
GET /t
--- response_body
one

--- no_error_log
[error]

=== TEST 19: template (friendly interface) test
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local Liquid = require 'liquid'
            local document = "{% if true %}  abc  {% endif %}{% if true -%}  abc  {%- endif %}"
            local template = Liquid.Template:parse(document)
            ngx.say( template:render() )
        }
    }
--- request
GET /t
--- response_body
  abc  abc

--- no_error_log
[error]

=== TEST 20: 'for include print variable endfor' tag.
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local Liquid = require 'liquid'
            local Lexer = Liquid.Lexer
            local Parser = Liquid.Parser
            local Interpreter = Liquid.Interpreter
            local InterpreterContext = Liquid.InterpreterContext
            local FileSystem = Liquid.FileSystem
            function FileSystem.get(location) return location end
            local document = "{% for v in values %} {% include v %} = {{ v }}{% endfor %}"
            local lexer = Lexer:new(document)
            local parser = Parser:new(lexer)
            local interpreter = Interpreter:new(parser)
            ngx.say(interpreter:interpret(InterpreterContext:new({ values = { 'one', 'two' } })))
        }
    }
--- request
GET /t
--- response_body
 one = one two = two

--- no_error_log
[error]


=== TEST 21: setting custom resource limit.
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local Liquid = require 'liquid'
            local document = "{% for i in (1..5) %}{{ i }}{% endfor %}"
            local template = Liquid.Template:parse(document)
            local limit = Liquid.ResourceLimit:new(0, 0, 3)
            local ok, err = pcall(template.render, template, nil, nil, limit)
            if not ok then ngx.say(err) end
        }
    }
--- request
GET /t
--- response_body_like
too many loopcount. limit num:3
--- no_error_log
[error]
