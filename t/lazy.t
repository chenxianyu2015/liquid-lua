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

=== TEST 1: lazy method with cache.  
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
		 local Liquid = require 'liquid'
		 local Lazy = Liquid.Lazy
		 local function ping(...)
		 	ngx.say("hi")
		 	return "pong"
		 end
		 local obj = { ["test"] = ping}
		 local lazy_oj = Lazy:new(obj, {test = true})
		 ngx.say(lazy_oj.test)
		 ngx.say(lazy_oj.test)
		}
	}
--- request
GET /t
--- response_body
hi
pong
pong
--- no_error_log
[error]

=== TEST 2: lazy method without cache.  
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
		 local Liquid = require 'liquid'
		 local Lazy = Liquid.Lazy
		 local function ping(...)
		 	ngx.say("hi")
		 	return "pong"
		 end
		 local obj = { ["test"] = ping}
		 local lazy_oj = Lazy:new(obj, {test = false})
		 ngx.say(lazy_oj.test)
		 ngx.say(lazy_oj.test)
		}
	}
--- request
GET /t
--- response_body
hi
pong
hi
pong
--- no_error_log
[error]
