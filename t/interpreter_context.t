use Test::Nginx::Socket::Lua;
use Cwd qw(cwd);

repeat_each(2);

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

=== TEST 1: interpreter_context set key through instance initialization
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local Liquid = require 'liquid'
            local InterpreterContext = Liquid.InterpreterContext
            local context_instance = InterpreterContext:new({['ping'] = 'pong'})
            local result = context_instance:find_var('ping')
            ngx.say(result)
        }
    }
--- request
GET /t
--- response_body
pong
--- no_error_log
[error]


=== TEST 2: interpreter_context set key through method 'define_var'
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local Liquid = require 'liquid'
            local InterpreterContext = Liquid.InterpreterContext
            local context_instance = InterpreterContext:new({})
            context_instance:define_var('ping', 'pong')
            local result = context_instance:find_var('ping')
            ngx.say(result)
        }
    }
--- request
GET /t
--- response_body
pong
--- no_error_log
[error]

=== TEST 3: interpreter context create/destroy context frame
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local Liquid = require 'liquid'
            local InterpreterContext = Liquid.InterpreterContext
            local context_instance = InterpreterContext:new({['ping'] = 'pong'})
            context_instance:newframe()
            context_instance:define_var('ping', 'hi')
            local result1 = context_instance:find_var('ping')
            ngx.say(result1)
            context_instance:destroyframe()
            local result2 = context_instance:find_var('ping')
            ngx.say(result2)
        }
    }
--- request
GET /t
--- response_body
hi
pong
--- no_error_log
[error]
