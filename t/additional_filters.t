use Test::Nginx::Socket 'no_plan';
use Cwd qw(cwd);

my $pwd = cwd();

our $HttpConfig = qq{
    lua_package_path "$pwd/lib/?.lua;;;";
    lua_package_cpath "/usr/local/openresty/lualib/?.so;;";
};

run_tests();

__DATA__

=== TEST 1: get filter.
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local context = {}
            context.foo = "123"

            local Liquid = require 'liquid'
            local document = 'SELF::{{ self | first | get: "foo" }}'

            local template = Liquid.Template:parse(document)
            ngx.say(template:render( Liquid.InterpreterContext:new(context)))
        }
    }
--- request
GET /t
--- response_body
SELF::123

=== TEST 2: get filter with non alphanumeric keys
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local context = {}
            context["foo/bar"] = "123"

            local Liquid = require 'liquid'
            local document = 'SELF::{{ self | first | get: "foo/bar" }}'

            local template = Liquid.Template:parse(document)
            ngx.say(template:render( Liquid.InterpreterContext:new(context)))
        }
    }
--- request
GET /t
--- response_body
SELF::123
