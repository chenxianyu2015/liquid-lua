use Test::Nginx::Socket::Lua;
use Cwd qw(cwd);

plan tests => repeat_each() * (3 * blocks());

my $pwd = cwd();

our $HttpConfig = qq{
    lua_package_path "$pwd/lib/?.lua;;;";
    lua_package_cpath "/usr/local/openresty/lualib/?.so;;";
};

no_long_string();
run_tests();

__DATA__

=== TEST 1: 'contains' operator.
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local Liquid = require 'liquid'
            local Lexer = Liquid.Lexer
            local Parser = Liquid.Parser
            local Interpreter = Liquid.Interpreter
            local document = "{% if 'abc' contains 'def' %}yes{% else %}no {% endif %}"..
            "{% if 'abcd' contains 'bc' %}yes {% else %}no{% endif %}"..
            "{% assign var = 'abc afooa ghi' | split: ' ' %}{% if var contains 'foo' %}yes{% else %}no {% endif %}"..
            "{% assign var = 'abc def ghi' | split: ' ' %}{% if var contains 'def' %}yes {% else %}no{% endif %}"
            local lexer = Lexer:new(document)
            local parser = Parser:new(lexer)
            local interpreter = Interpreter:new(parser)
            ngx.say(interpreter:interpret())
        }
    }
--- request
GET /t
--- response_body
no yes no yes 
--- no_error_log
[error]

=== TEST 2: '==' operator.
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local Liquid = require 'liquid'
            local Lexer = Liquid.Lexer
            local Parser = Liquid.Parser
            local Interpreter = Liquid.Interpreter
            local document = "{% if 'abc' == 'def' %}yes{% else %}no {% endif %}"..
            "{% if 'abcd' == 'abcd' %}yes {% else %}no{% endif %}"..
            "{% assign var = 'abc def' | split: ' ' %}"..
            "{% assign var2 = 'abc def ghi' | split: ' ' %}"..
            "{% if var == var2 %}yes{% else %}no {% endif %}"..
            "{% assign var = 'abc def ghi' | split: ' ' %}"..
            "{% assign var2 = 'abc def ghi' | split: ' ' %}"..
            "{% if var == var2 %}yes {% else %}no{% endif %}"
            local lexer = Lexer:new(document)
            local parser = Parser:new(lexer)
            local interpreter = Interpreter:new(parser)
            ngx.say(interpreter:interpret())
        }
    }
--- request
GET /t
--- response_body
no yes no yes 
--- no_error_log
[error]

=== TEST 3: '!=' operator.
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local Liquid = require 'liquid'
            local Lexer = Liquid.Lexer
            local Parser = Liquid.Parser
            local Interpreter = Liquid.Interpreter
            local document = "{% if 'abc' != 'def' %}yes {% else %}no{% endif %}"..
            "{% if 'abcd' != 'abcd' %}yes{% else %}no {% endif %}"..
            "{% assign var = 'abc def' | split: ' ' %}"..
            "{% assign var2 = 'abc def ghi' | split: ' ' %}"..
            "{% if var != var2 %}yes {% else %}no{% endif %}"..
            "{% assign var = 'abc def ghi' | split: ' ' %}"..
            "{% assign var2 = 'abc def ghi' | split: ' ' %}"..
            "{% if var != var2 %}yes{% else %}no {% endif %}"
            local lexer = Lexer:new(document)
            local parser = Parser:new(lexer)
            local interpreter = Interpreter:new(parser)
            ngx.say(interpreter:interpret())
        }
    }
--- request
GET /t
--- response_body
yes no yes no 
--- no_error_log
[error]
