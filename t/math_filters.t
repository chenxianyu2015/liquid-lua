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

=== TEST 1: 'abs' filter.
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local Liquid = require 'liquid'
            local Lexer = Liquid.Lexer
            local Parser = Liquid.Parser
            local Interpreter = Liquid.Interpreter
            local document = "{% assign a = -5  %}{{a}} {{a | abs}} "
            local lexer = Lexer:new(document)
            local parser = Parser:new(lexer)
            local interpreter = Interpreter:new(parser)
            ngx.say(interpreter:interpret())
        }
    }
--- request
GET /t
--- response_body
-5 5 

--- no_error_log
[error]

=== TEST 2: 'ceil' filter.
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local Liquid = require 'liquid'
            local Lexer = Liquid.Lexer
            local Parser = Liquid.Parser
            local Interpreter = Liquid.Interpreter
            local document = "{% assign a = 1.2  %}{{a}} {{a | ceil}} "
            local lexer = Lexer:new(document)
            local parser = Parser:new(lexer)
            local interpreter = Interpreter:new(parser)
            ngx.say(interpreter:interpret())
        }
    }
--- request
GET /t
--- response_body
1.2 2 

--- no_error_log
[error]


=== TEST 3: 'divided_by' filter.
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local Liquid = require 'liquid'
            local Lexer = Liquid.Lexer
            local Parser = Liquid.Parser
            local Interpreter = Liquid.Interpreter
            local document = "{% assign a = 5  %}{{a}} {{a | divided_by: 3}} "
            local lexer = Lexer:new(document)
            local parser = Parser:new(lexer)
            local interpreter = Interpreter:new(parser)
            ngx.say(interpreter:interpret())
        }
    }
--- request
GET /t
--- response_body
5 1.6666666666667 

--- no_error_log
[error]

=== TEST 4: 'minus' filter.
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local Liquid = require 'liquid'
            local Lexer = Liquid.Lexer
            local Parser = Liquid.Parser
            local Interpreter = Liquid.Interpreter
            local document = "{% assign a = 5  %}{{a}} {{a | minus: 3}} "
            local lexer = Lexer:new(document)
            local parser = Parser:new(lexer)
            local interpreter = Interpreter:new(parser)
            ngx.say(interpreter:interpret())
        }
    }
--- request
GET /t
--- response_body
5 2 

--- no_error_log
[error]

=== TEST 5: 'floor' filter.
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local Liquid = require 'liquid'
            local Lexer = Liquid.Lexer
            local Parser = Liquid.Parser
            local Interpreter = Liquid.Interpreter
            local document = "{% assign a = 5.2  %}{{a}} {{a | floor }} "
            local lexer = Lexer:new(document)
            local parser = Parser:new(lexer)
            local interpreter = Interpreter:new(parser)
            ngx.say(interpreter:interpret())
        }
    }
--- request
GET /t
--- response_body
5.2 5 

--- no_error_log
[error]

=== TEST 6: 'plus' filter.
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local Liquid = require 'liquid'
            local Lexer = Liquid.Lexer
            local Parser = Liquid.Parser
            local Interpreter = Liquid.Interpreter
            local document = "{% assign a = 5.2  %}{{a}} {{a | plus: 1 }} "
            local lexer = Lexer:new(document)
            local parser = Parser:new(lexer)
            local interpreter = Interpreter:new(parser)
            ngx.say(interpreter:interpret())
        }
    }
--- request
GET /t
--- response_body
5.2 6.2 

--- no_error_log
[error]

=== TEST 7: 'round' filter.
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local Liquid = require 'liquid'
            local Lexer = Liquid.Lexer
            local Parser = Liquid.Parser
            local Interpreter = Liquid.Interpreter
            local document = "{% assign a = 5.22  %}{{a}} {{a | round: 1 }} "
            local lexer = Lexer:new(document)
            local parser = Parser:new(lexer)
            local interpreter = Interpreter:new(parser)
            ngx.say(interpreter:interpret())
        }
    }
--- request
GET /t
--- response_body
5.22 5.2 

--- no_error_log
[error]

=== TEST 8: 'round' filter.
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local Liquid = require 'liquid'
            local Lexer = Liquid.Lexer
            local Parser = Liquid.Parser
            local Interpreter = Liquid.Interpreter
            local document = "{% assign a = 5.22  %}{{a}} {{a | times: 100 }} "
            local lexer = Lexer:new(document)
            local parser = Parser:new(lexer)
            local interpreter = Interpreter:new(parser)
            ngx.say(interpreter:interpret())
        }
    }
--- request
GET /t
--- response_body
5.22 522 

--- no_error_log
[error]

=== TEST 9: 'modulo' filter.
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local Liquid = require 'liquid'
            local Lexer = Liquid.Lexer
            local Parser = Liquid.Parser
            local Interpreter = Liquid.Interpreter
            local document = "{% assign a = 5   %}{{a}} {{a | modulo: 2 }} "
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
