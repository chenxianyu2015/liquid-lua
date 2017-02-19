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

=== TEST 1: global filter .  
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local Liquid = require 'liquid'
            local FilterSet = Liquid.FilterSet
            local function pong(...)
                ngx.say("hi")
            end
            FilterSet:add_filter("ping", pong)
            local filter1 = FilterSet:find_filter("ping")
            filter1()
            local instance = FilterSet:new()
            local filter2 = instance:find_filter("ping")
            filter2()
        }
    }
--- request
GET /t
--- response_body
hi
hi

--- no_error_log
[error]


=== TEST 2: instance filter .  
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local Liquid = require 'liquid'
            local FilterSet = Liquid.FilterSet
            local function pong(...)
                ngx.say("hi")
            end
            local filter = FilterSet:find_filter("ping")
            ngx.say(type(filter))
            local instance1 = FilterSet:new()
            instance1:add_filter("ping", pong)
            local filter1 = instance1:find_filter("ping")
            filter1()
            local instance2 = FilterSet:new()
            local filter2 = instance2:find_filter("ping")
            ngx.say(type(filter2))
        }
    }
--- request
GET /t
--- response_body
nil
hi
nil

--- no_error_log
[error]

