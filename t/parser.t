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

=== TEST 1: parse rawstring document.  
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local Liquid = require 'liquid'
            local Lexer = Liquid.Lexer
            local Parser = Liquid.Parser
            local document = "abc def ghi jkl"
            local lexer = Lexer:new(document)
            local parser = Parser:new(lexer)
            local tree = parser:document()
            ngx.say(tree:_name_())
            ngx.say(#tree)
            ngx.say(tree[1]:_name_())
            ngx.say(tree[1].value)
        }
    }
--- request
GET /t
--- response_body
Compoud
1
RawStr
abc def ghi jkl

--- no_error_log
[error]


=== TEST 2: parse 'if elsif else endif' tag.  
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local Liquid = require 'liquid'
            local Lexer = Liquid.Lexer
            local Parser = Liquid.Parser
            local document = "{% if  false  -%}{% elsif true %}{% else %}{% endif %}"
            local lexer = Lexer:new(document)
            local parser = Parser:new(lexer)
            local tree = parser:document()
            ngx.say(tree:_name_())
            ngx.say(#tree)
            ngx.say(tree[1]:_name_())
            ngx.say(tree[1].exper:_name_())
            ngx.say(tree[1].truebody:_name_())
            ngx.say(tree[1].falsebody:_name_())
        }
    }
--- request
GET /t
--- response_body
Compoud
1
Branch
Boolean
NoOp
Branch

--- no_error_log
[error]

=== TEST 3: parse 'unless elsif else endunless' tag.  
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local Liquid = require 'liquid'
            local Lexer = Liquid.Lexer
            local Parser = Liquid.Parser
            local document = "{% unless true  %}{% elsif false %}{% else %}{% endunless %}"
            local lexer = Lexer:new(document)
            local parser = Parser:new(lexer)
            local tree = parser:document()
            ngx.say(tree:_name_())
            ngx.say(#tree)
            ngx.say(tree[1]:_name_())
            ngx.say(tree[1].exper:_name_())
            ngx.say(tree[1].truebody:_name_())
            ngx.say(tree[1].falsebody:_name_())
        }
    }
--- request
GET /t
--- response_body
Compoud
1
Branch
Boolean
Branch
NoOp

--- no_error_log
[error]

=== TEST 4: parse 'case when else endcase' tag.  
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local Liquid = require 'liquid'
            local Lexer = Liquid.Lexer
            local Parser = Liquid.Parser
            local document = "{% case true  %}{% when false %}{% else %}{% endcase %}"
            local lexer = Lexer:new(document)
            local parser = Parser:new(lexer)
            local tree = parser:document()
            ngx.say(tree:_name_())
            ngx.say(#tree)
            ngx.say(tree[1]:_name_())
            ngx.say(tree[1].exper:_name_())
            ngx.say(tree[1].truebody:_name_())
            ngx.say(tree[1].falsebody:_name_())
        }
    }
--- request
GET /t
--- response_body
Compoud
1
Branch
Boolean
NoOp
Branch

--- no_error_log
[error]

=== TEST 5: parse 'for  endfor' tag.  
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local Liquid = require 'liquid'
            local Lexer = Liquid.Lexer
            local Parser = Liquid.Parser
            local document = "{% for x in foo  offset:1 limit:1 reversed %}{% endfor %}"
            local lexer = Lexer:new(document)
            local parser = Parser:new(lexer)
            local tree = parser:document()
            ngx.say(tree:_name_())
            ngx.say(#tree)
            ngx.say(tree[1]:_name_())
            ngx.say(tree[1].exp:_name_())
            ngx.say(tree[1].nonemptybody:_name_())
            ngx.say(tree[1].emptybody:_name_())
        }
    }
--- request
GET /t
--- response_body
Compoud
1
ForLoop
Field
NoOp
NoOp

--- no_error_log
[error]


=== TEST 6: parse 'break' tag.  
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local Liquid = require 'liquid'
            local Lexer = Liquid.Lexer
            local Parser = Liquid.Parser
            local document = "{% break %}"
            local lexer = Lexer:new(document)
            local parser = Parser:new(lexer)
            local tree = parser:document()
            ngx.say(tree:_name_())
            ngx.say(#tree)
            ngx.say(tree[1]:_name_())
        }
    }
--- request
GET /t
--- response_body
Compoud
1
Interrupt

--- no_error_log
[error]


=== TEST 7: parse 'continue' tag.  
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local Liquid = require 'liquid'
            local Lexer = Liquid.Lexer
            local Parser = Liquid.Parser
            local document = "{% break %}"
            local lexer = Lexer:new(document)
            local parser = Parser:new(lexer)
            local tree = parser:document()
            ngx.say(tree:_name_())
            ngx.say(#tree)
            ngx.say(tree[1]:_name_())
        }
    }
--- request
GET /t
--- response_body
Compoud
1
Interrupt

--- no_error_log
[error]

=== TEST 8: parse 'assign' tag.  
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local Liquid = require 'liquid'
            local Lexer = Liquid.Lexer
            local Parser = Liquid.Parser
            local document = "{% assign a = b %}"
            local lexer = Lexer:new(document)
            local parser = Parser:new(lexer)
            local tree = parser:document()
            ngx.say(tree:_name_())
            ngx.say(#tree)
            ngx.say(tree[1]:_name_())
        }
    }
--- request
GET /t
--- response_body
Compoud
1
Assignment

--- no_error_log
[error]

=== TEST 9: parse 'cycle' tag.  
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local Liquid = require 'liquid'
            local Lexer = Liquid.Lexer
            local Parser = Liquid.Parser
            local document = "{% cycle name: a, b, c %}"
            local lexer = Lexer:new(document)
            local parser = Parser:new(lexer)
            local tree = parser:document()
            ngx.say(tree:_name_())
            ngx.say(#tree)
            ngx.say(tree[1]:_name_())
        }
    }
--- request
GET /t
--- response_body
Compoud
1
CycleLoop

--- no_error_log
[error]

=== TEST 10: parse 'tablerow' tag.  
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local Liquid = require 'liquid'
            local Lexer = Liquid.Lexer
            local Parser = Liquid.Parser
            local document = "{% tablerow x in foo cols:2 limit:3 offset:3 %}{% endtablerow %}"
            local lexer = Lexer:new(document)
            local parser = Parser:new(lexer)
            local tree = parser:document()
            ngx.say(tree:_name_())
            ngx.say(#tree)
            ngx.say(tree[1]:_name_())
        }
    }
--- request
GET /t
--- response_body
Compoud
1
TableLoop

--- no_error_log
[error]

=== TEST 11: parse 'capture' tag.  
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local Liquid = require 'liquid'
            local Lexer = Liquid.Lexer
            local Parser = Liquid.Parser
            local document = "{% capture xx %}{% endcapture %}"
            local lexer = Lexer:new(document)
            local parser = Parser:new(lexer)
            local tree = parser:document()
            ngx.say(tree:_name_())
            ngx.say(#tree)
            ngx.say(tree[1]:_name_())
        }
    }
--- request
GET /t
--- response_body
Compoud
1
Assignment

--- no_error_log
[error]

=== TEST 12: parse 'increment' tag.  
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local Liquid = require 'liquid'
            local Lexer = Liquid.Lexer
            local Parser = Liquid.Parser
            local document = "{% increment xx %}"
            local lexer = Lexer:new(document)
            local parser = Parser:new(lexer)
            local tree = parser:document()
            ngx.say(tree:_name_())
            ngx.say(#tree)
            ngx.say(tree[1]:_name_())
        }
    }
--- request
GET /t
--- response_body
Compoud
1
IncDec

--- no_error_log
[error]

=== TEST 13: parse 'decrement' tag.  
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local Liquid = require 'liquid'
            local Lexer = Liquid.Lexer
            local Parser = Liquid.Parser
            local document = "{% decrement xx %}"
            local lexer = Lexer:new(document)
            local parser = Parser:new(lexer)
            local tree = parser:document()
            ngx.say(tree:_name_())
            ngx.say(#tree)
            ngx.say(tree[1]:_name_())
        }
    }
--- request
GET /t
--- response_body
Compoud
1
IncDec

--- no_error_log
[error]

=== TEST 14: parse 'comment' tag.  
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local Liquid = require 'liquid'
            local Lexer = Liquid.Lexer
            local Parser = Liquid.Parser
            local document = "{% comment %}  {% endcomment %}"
            local lexer = Lexer:new(document)
            local parser = Parser:new(lexer)
            local tree = parser:document()
            ngx.say(tree:_name_())
            ngx.say(#tree)
            ngx.say(tree[1]:_name_())
        }
    }
--- request
GET /t
--- response_body
Compoud
1
NoOp

--- no_error_log
[error]

=== TEST 15: parse 'raw' tag.  
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local Liquid = require 'liquid'
            local Lexer = Liquid.Lexer
            local Parser = Liquid.Parser
            local document = "{% raw %} {% endraw%}"
            local lexer = Lexer:new(document)
            local parser = Parser:new(lexer)
            local tree = parser:document()
            ngx.say(tree:_name_())
            ngx.say(#tree)
            ngx.say(tree[1]:_name_())
        }
    }
--- request
GET /t
--- response_body
Compoud
1
Str
--- no_error_log
[error]

=== TEST 16: parse 'include' tag.  
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local Liquid = require 'liquid'
            local Lexer = Liquid.Lexer
            local Parser = Liquid.Parser
            local document = "{% include '00001' for product %}"
            local lexer = Lexer:new(document)
            local parser = Parser:new(lexer)
            local tree = parser:document()
            ngx.say(tree:_name_())
            ngx.say(#tree)
            ngx.say(tree[1]:_name_())
        }
    }
--- request
GET /t
--- response_body
Compoud
1
Partial
--- no_error_log
[error]

