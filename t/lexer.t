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

=== TEST 1: lexer processes document to tokens
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local Liquid = require 'liquid'
            local Lexer = Liquid.Lexer
            local document =[[{{ 
                true false nil empty 
                == != > <  >= <= or and contains
                . .. [ ] | : , =
                if else elsif endif unless endunless case when endcase 
                for endfor in limit offset reversed cycle tablerow endtablerow cols break continue
                assign capture endcapture increment decrement
                include with 
                raw endraw
                comment endcomment
                1234
                '1234'
                abc_12
                }} {{- -}} {% %} {%- -%} raw string starts here
                true false nil empty 
                == != > <  >= <= or and contains
                . .. [ ] | : , =
                if else elsif endif unless endunless case when endcase 
                for endfor in limit offset reversed cycle tablerow endtablerow cols break continue
                assign capture endcapture increment decrement
                include with 
                raw endraw
                comment endcomment
                1234
                '1234'
                abc_12 raw string ends here ]]
            local lexer_instance = Lexer:new(document)
            repeat
                local token = lexer_instance:get_next_token()
                ngx.say(token:to_s())
            until token.token_type == 'EOF'
        }
    }
--- request
GET /t
--- response_body
Token(VARSTART,{{)
Token(TRUE,true)
Token(FALSE,false)
Token(NIL,nil)
Token(EMPTY,empty)
Token(EQ,==)
Token(NE,!=)
Token(GT,>)
Token(LT,<)
Token(GE,>=)
Token(LE,<=)
Token(OR,or)
Token(AND,and)
Token(CONTAINS,contains)
Token(DOT,.)
Token(DOTDOT,..)
Token(LSBRACKET,[)
Token(RSBRACKET,])
Token(PIPE,|)
Token(COLON,:)
Token(COMMA,,)
Token(ASSIGNMENT,=)
Token(IF,if)
Token(ELSE,else)
Token(ELSIF,elsif)
Token(ENDIF,endif)
Token(UNLESS,unless)
Token(ENDUNLESS,endunless)
Token(CASE,case)
Token(WHEN,when)
Token(ENDCASE,endcase)
Token(FOR,for)
Token(ENDFOR,endfor)
Token(IN,in)
Token(LIMIT,limit)
Token(OFFSET,offset)
Token(REVERSED,reversed)
Token(CYCLE,cycle)
Token(TABLEROW,tablerow)
Token(ENDTABLEROW,endtablerow)
Token(COLS,cols)
Token(BREAK,break)
Token(CONTINUE,continue)
Token(ASSIGN,assign)
Token(CAPTURE,capture)
Token(ENDCAPTURE,endcapture)
Token(INCREMENT,increment)
Token(DECREMENT,decrement)
Token(INCLUDE,include)
Token(WITH,with)
Token(RAW,raw)
Token(ENDRAW,endraw)
Token(COMMENT,comment)
Token(ENDCOMMENT,endcomment)
Token(NUM,1234)
Token(STRING,1234)
Token(ID,abc_12)
Token(VAREND,}})
Token(RAWSTRING, )
Token(VARSTARTWC,{{-)
Token(VARENDWC,-}})
Token(RAWSTRING, )
Token(TAGSTART,{%)
Token(TAGEND,%})
Token(RAWSTRING, )
Token(TAGSTARTWC,{%-)
Token(TAGENDWC,-%})
Token(RAWSTRING, raw string starts here
                true false nil empty 
                == != > <  >= <= or and contains
                . .. [ ] | : , =
                if else elsif endif unless endunless case when endcase 
                for endfor in limit offset reversed cycle tablerow endtablerow cols break continue
                assign capture endcapture increment decrement
                include with 
                raw endraw
                comment endcomment
                1234
                '1234'
                abc_12 raw string ends here )
Token(EOF,nil )

--- no_error_log
[error]
