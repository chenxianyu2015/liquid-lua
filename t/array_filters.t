use Test::Nginx::Socket::Lua;
use Cwd qw(cwd);

# repeat_each(2);

plan tests => repeat_each() * (3 * blocks());

my $pwd = cwd();

our $HttpConfig = qq|
    lua_package_path "$pwd/lib/?.lua;;;";
    lua_package_cpath "/usr/local/openresty/lualib/?.so;;";
    init_by_lua_block { Liquid = require 'liquid' }
|;


no_long_string();
#no_diff();

run_tests();

__DATA__

=== TEST 1: 'join' filter.
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local Liquid = require 'liquid'
            local Lexer = Liquid.Lexer
            local Parser = Liquid.Parser
            local Interpreter = Liquid.Interpreter
            local document = "{% assign a = (1..5) | join:',' %} {{a}} "
            local lexer = Lexer:new(document)
            local parser = Parser:new(lexer)
            local interpreter = Interpreter:new(parser)
            ngx.say(interpreter:interpret())
        }
    }
--- request
GET /t
--- response_body
 1,2,3,4,5 

--- no_error_log
[error]

=== TEST 2: 'first' filter.
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local Liquid = require 'liquid'
            local Lexer = Liquid.Lexer
            local Parser = Liquid.Parser
            local Interpreter = Liquid.Interpreter
            local document = "{% assign a = (1..5) | first %}  {{a}} "
            local lexer = Lexer:new(document)
            local parser = Parser:new(lexer)
            local interpreter = Interpreter:new(parser)
            ngx.say(interpreter:interpret())
        }
    }
--- request
GET /t
--- response_body
  1 
 
--- no_error_log
[error]

=== TEST 3: 'last' filter.
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local Liquid = require 'liquid'
            local Lexer = Liquid.Lexer
            local Parser = Liquid.Parser
            local Interpreter = Liquid.Interpreter
            local document = "{% assign a = (1..5) | last %}  {{a}} "
            local lexer = Lexer:new(document)
            local parser = Parser:new(lexer)
            local interpreter = Interpreter:new(parser)
            ngx.say(interpreter:interpret())
        }
    }
--- request
GET /t
--- response_body
  5 
 
--- no_error_log
[error]

=== TEST 4: 'concat' filter.
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local Liquid = require 'liquid'
            local Lexer = Liquid.Lexer
            local Parser = Liquid.Parser
            local Interpreter = Liquid.Interpreter
            local document = "{% assign a = (1..5) | concat:(5..10) %}  {% for k in a %} {{k}} {% endfor %} "
            local lexer = Lexer:new(document)
            local parser = Parser:new(lexer)
            local interpreter = Interpreter:new(parser)
            ngx.say(interpreter:interpret())
        }
    }
--- request
GET /t
--- response_body
   1  2  3  4  5  5  6  7  8  9  10  
 
--- no_error_log
[error]

=== TEST 5: 'index' filter.
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local Liquid = require 'liquid'
            local Lexer = Liquid.Lexer
            local Parser = Liquid.Parser
            local Interpreter = Liquid.Interpreter
            local document = "{% assign a = (1..5) | concat:(5..10) %} {{a | index:0}} {{a[4]}} "
            local lexer = Lexer:new(document)
            local parser = Parser:new(lexer)
            local interpreter = Interpreter:new(parser)
            ngx.say(interpreter:interpret())
        }
    }
--- request
GET /t
--- response_body
 1 5 
 
--- no_error_log
[error]

=== TEST 6: 'map' filter.
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local Liquid = require 'liquid'
            local Lexer = Liquid.Lexer
            local Parser = Liquid.Parser
            local Interpreter = Liquid.Interpreter
            local InterpreterContext = Liquid.InterpreterContext
            local document = "{% assign collection_titles  = collections |  map: 'title' %} {{collection_titles }} "
            local lexer = Lexer:new(document)
            local parser = Parser:new(lexer)
            local interpreter = Interpreter:new(parser)
            ngx.say(interpreter:interpret(InterpreterContext:new({collections = {{title = "Spring"},{title = "Summer"},{title = "Fall"}, {title = "Winter"}} })))
        }
    }
--- request
GET /t
--- response_body
 SpringSummerFallWinter 
 
--- no_error_log
[error]

=== TEST 7: 'reverse' filter.
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local Liquid = require 'liquid'
            local Lexer = Liquid.Lexer
            local Parser = Liquid.Parser
            local Interpreter = Liquid.Interpreter
            local document = "{% assign a = (1..5) | reverse %} {{a | index:0}} {{a[4]}} "
            local lexer = Lexer:new(document)
            local parser = Parser:new(lexer)
            local interpreter = Interpreter:new(parser)
            ngx.say(interpreter:interpret())
        }
    }
--- request
GET /t
--- response_body
 5 1 
 
--- no_error_log
[error]


=== TEST 8: 'size' filter.
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local Liquid = require 'liquid'
            local Lexer = Liquid.Lexer
            local Parser = Liquid.Parser
            local Interpreter = Liquid.Interpreter
            local document = "{% assign a = (1..5)   %} {{a | size}}"
            local lexer = Lexer:new(document)
            local parser = Parser:new(lexer)
            local interpreter = Interpreter:new(parser)
            ngx.say(interpreter:interpret())
        }
    }
--- request
GET /t
--- response_body
 5
 
--- no_error_log
[error]

=== TEST 9: 'sort' filter.
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local Liquid = require 'liquid'
            local Lexer = Liquid.Lexer
            local Parser = Liquid.Parser
            local Interpreter = Liquid.Interpreter
            local InterpreterContext = Liquid.InterpreterContext
            local document = "{% assign collection_titles  = collections | sort: 'title' %} {{collection_titles[0][\"title\"]}}"
            local lexer = Lexer:new(document)
            local parser = Parser:new(lexer)
            local interpreter = Interpreter:new(parser)
            ngx.say(interpreter:interpret(InterpreterContext:new({collections = {{title = "Spring"},{title = "Summer"},{title = "Fall"}, {title = "Winter"}} })))
        }
    }
--- request
GET /t
--- response_body
 Fall

--- no_error_log
[error]

=== TEST 10: 'uniq' filter.
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local Liquid = require 'liquid'
            local Lexer = Liquid.Lexer
            local Parser = Liquid.Parser
            local Interpreter = Liquid.Interpreter
            local InterpreterContext = Liquid.InterpreterContext
            local document = "{% assign a  = (1..5) | concat: (1..5) %} {{a | json }} {{a | uniq | json}}"
            local lexer = Lexer:new(document)
            local parser = Parser:new(lexer)
            local interpreter = Interpreter:new(parser)
            ngx.say(interpreter:interpret(InterpreterContext:new({collections = {{title = "Spring"},{title = "Summer"},{title = "Fall"}, {title = "Winter"}} })))
        }
    }
--- request
GET /t
--- response_body
 [1,2,3,4,5,1,2,3,4,5] [1,2,3,4,5]

--- no_error_log
[error]



=== TEST 11: 'join' filter works on strings
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            ngx.say( Liquid.Template:parse([[
              {{- str | join: ' - ' -}}
            ]]):render(Liquid.InterpreterContext:new({ str = "string" })) )
        }
    }
--- request
GET /t
--- response_body
string
--- no_error_log
[error]

=== TEST 12: 'first' filter works strings
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            ngx.say( Liquid.Template:parse([[
              {{- str | first -}}
            ]]):render(Liquid.InterpreterContext:new({ str = "string" })) )
        }
    }
--- request
GET /t
--- response_body
string
--- no_error_log
[error]



=== TEST 13: 'last' filter works on strings
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            ngx.say( Liquid.Template:parse([[
                {{- str | last -}}
            ]]):render( Liquid.InterpreterContext:new({ str = "string" })) )
        }
    }
--- request
GET /t
--- response_body
string
--- no_error_log
[error]

=== TEST 14: 'concat' filter works on strings
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            ngx.say( Liquid.Template:parse([[
              {%- assign a = "string" | concat:(1..3) -%}
              {%- assign b = "string" | concat: "another" -%}
              {%- for k in a %} {{k}} {%- endfor -%}
              {%- for k in b %} {{k}} {%- endfor -%}
            ]]):render())
        }
    }
--- request
GET /t
--- response_body
 string 1 2 3 string another
--- no_error_log
[error]

=== TEST 5: 'index' filter works on strings
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            ngx.say( Liquid.Template:parse([[
              {{- "string"| index: 0 -}}
            ]]):render() )
        }
    }
--- request
GET /t
--- response_body
string
--- no_error_log
[error]


=== TEST 16: 'reverse' filter works on strings
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            ngx.say( Liquid.Template:parse([[
              {{- "string" | reverse | join -}}
            ]]):render() )
        }
    }
--- request
GET /t
--- response_body
string
--- no_error_log
[error]



=== TEST 17: 'size' filter works on strings
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            ngx.say( Liquid.Template:parse([[
              {{- "string" | size -}}
            ]]):render() )
        }
    }
--- request
GET /t
--- response_body
1
--- no_error_log
[error]



=== TEST 18: 'sort' filter works on strings
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            ngx.say( Liquid.Template:parse([[
              {{- "string" | sort | join -}}
            ]]):render() )
        }
    }
--- request
GET /t
--- response_body
string

--- no_error_log
[error]



=== TEST 19: 'uniq' filter works on strings
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            ngx.say( Liquid.Template:parse([[
              {{- "string" | uniq | join -}}
            ]]):render() )
        }
    }
--- request
GET /t
--- response_body
string
--- no_error_log
[error]
