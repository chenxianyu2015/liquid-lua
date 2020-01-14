local cjson = require 'cjson'
local Liquid = {}
local Lexer = {}
local Parser = {}
local Interpreter = {}
local InterpreterContext = {}
local ParserContext = {}
local FileSystem = {}
local FilterSet = {}
local Lazy = {}
local ResourceLimit = {}
local Nodetab = {}

Liquid._VERSION = "0.1.2"

--Truthy and falsy
local TRUE = "TRUE"    -- "true"
local FALSE = "FALSE"  -- "false"
local NIL = "NIL"      -- "nil"
local EMPTY = "EMPTY"  -- "empty"
-- Basic operators
local EQ = "EQ"        -- "=="
local NE = "NE"        -- "!="
local GT = "GT"        -- ">"
local LT = "LT"        -- "<"
local GE = "GE"        -- ">="
local LE = "LE"        -- "<="
local OR = "OR"        -- "or"
local AND = "AND"      -- "and"
local CONTAINS = "CONTAINS"    -- "contains"
--Objects token
local VARSTART = "VARSTART"    -- "{{"
local VAREND = "VAREND"        -- "{{"
--Tag
local TAGSTART = "TAGSTART"    -- "{%"
local TAGEND = "TAGEND"        -- "%}"
--Whitespace control
local TAGSTARTWC = "TAGSTARTWC" --"{%-"
local TAGENDWC = "TAGENDWC"     --"-%}"
local VARSTARTWC = "VARSTARTWC" --"{{-"
local VARENDWC = "VARENDWC"     --"-}}"
--Range
local LPAREN = "LPAREN"         --"("
local RPAREN = "RPAREN"         --")"
local DOTDOT = "DOTDOT"         --".."
--Object field
local DOT = "DOT"               --"."
local LSBRACKET= "LSBRACKET"    --"["
local RSBRACKET = "RSBRACKET"   --"]"
-- filter
local PIPE = "PIPE"             --"|"
local COLON = "COLON"           --":"
local COMMA = "COMMA"           --","
local ASSIGNMENT = "ASSIGNMENT" --"="
-- condition
local IF = "IF"                 --"if"
local ELSE = "ELSE"             --"else"
local ELSIF = "ELSIF"           --"elsif"
local ENDIF = "ENDIF"           --"endif"
local UNLESS = "UNLESS"         --"unless"
local ENDUNLESS = "ENDUNLESS"   --"endunless"
local CASE = "CASE"             --"case"
local WHEN = "WHEN"             --"when"
local ENDCASE = "ENDCASE"       --"endcase"
--Iteration
local FOR = "FOR"               --"for"
local ENDFOR = "ENDFOR"         --"endfor"
local IN = "IN"                 --"in"
local LIMIT = "LIMIT"           --"limit"
local OFFSET = "OFFSET"         --"offset"
local REVERSED = "REVERSED"     --"reversed"
local CYCLE = "CYCLE"           --"cycle"
local TABLEROW = "TABLEROW"     --"tablerow"
local ENDTABLEROW = "ENDTABLEROW"  --"endtablerow"
local COLS = "COLS"             --"cols"
local BREAK = "BREAK"           --"break"
local CONTINUE = "CONTINUE"     --"continue"
--Variable
local ASSIGN = "ASSIGN"         --"assign"
local CAPTURE = "CAPTURE"       --"capture"
local ENDCAPTURE = "ENDCAPTURE" --"endcapture"
local INCREMENT = "INCREMENT"   --"increment"
local DECREMENT = "DECREMENT"   --"decrement"
-- Generic token
local NUM = "NUM"
local STRING = "STRING"
local ID = "ID"
local RAWSTRING = "RAWSTRING"
--Template reuse
local INCLUDE = "INCLUDE"
local WITH = "WITH"
--Comment
local COMMENT = "COMMENT"
local ENDCOMMENT = "ENDCOMMENT"
--Raw
local RAW = "RAW"
local ENDRAW = "ENDRAW"
--EOF
local EOF = 'EOF'
--
-- Token
local Token = {}
--
function Token:new( token_type, value )
    -- body
    local instance = {}
    setmetatable(instance, {__index = Token})
    instance.token_type = token_type
    instance.value = value
    return instance
end
--
function Token:to_s( ... )
    -- body
    if self.value then
      return ("Token(" .. self.token_type .."," ..self.value..")")
    else
      return ("Token(" .. self.token_type ..",nil )")
    end
end
--
--
local KEYWORDS = {
--Truthy and falsy
  ["true"] = Token:new(TRUE, "true")
 ,["false"] = Token:new(FALSE, "false")
 ,["nil"] = Token:new(NIL, "nil")
 ,["empty"] = Token:new(EMPTY, "empty")
--Basic operators
 ,["or"] = Token:new(OR, "or")
 ,["and"] = Token:new(AND, "and")
 ,["contains"] = Token:new(CONTAINS, "contains")
--Condition
 ,["if"] = Token:new(IF, "if")
 ,["else"] = Token:new(ELSE, "else")
 ,["elsif"] = Token:new(ELSIF, "elsif")
 ,["endif"] = Token:new(ENDIF, "endif")
 ,["unless"] = Token:new(UNLESS, "unless")
 ,["endunless"] = Token:new(ENDUNLESS, "endunless")
 ,["case"] = Token:new(CASE, "case")
 ,["when"] = Token:new(WHEN, "when")
 ,["endcase"] = Token:new(ENDCASE, "endcase")
--Iteration
 ,["for"] = Token:new(FOR, "for")
 ,["endfor"] = Token:new(ENDFOR, "endfor")
 ,["in"] = Token:new(IN, "in")
 ,["limit"] = Token:new(LIMIT, "limit")
 ,["offset"] = Token:new(OFFSET, "offset")
 ,["reversed"] = Token:new(REVERSED, "reversed")
 ,["cycle"] = Token:new(CYCLE, "cycle")
 ,["tablerow"] = Token:new(TABLEROW, "tablerow")
 ,["endtablerow"] = Token:new(ENDTABLEROW, "endtablerow")
 ,["cols"] = Token:new(COLS, "cols")
 ,["break"] = Token:new(BREAK, "break")
 ,["continue"] = Token:new(CONTINUE, "continue")
--Variable
 ,["assign"] = Token:new(ASSIGN, "assign")
 ,["capture"] = Token:new(CAPTURE, "capture")
 ,["endcapture"] = Token:new(ENDCAPTURE, "endcapture")
 ,["increment"] = Token:new(INCREMENT, "increment")
 ,["decrement"] = Token:new(DECREMENT, "decrement")
--Template reuse
 ,["include"] = Token:new(INCLUDE, "include")
 ,["with"] = Token:new(WITH, "with")
 --Comment
 ,["comment"] = Token:new(COMMENT, "comment")
 ,["endcomment"] = Token:new(ENDCOMMENT, "endcomment")
 --
 ,["raw"] = Token:new(RAW, "raw")
 ,["endraw"] = Token:new(ENDRAW, "endraw")
}

--Raw string mode 0;  liquid code mode 1
local RMODE = 0
local CMODE = 1
-- Lexer
-- local Lexer = {}
--
function Lexer:new( text )
    -- body
    local instance = {}
    setmetatable(instance, {__index = Lexer})
    instance.text = text
    instance.pos = 1
    instance.current_token = nil
    instance.current_char = text:sub(1, 1)
    instance.text_length = #(text)
    -- 0 for raw string; 1 for liquid code
    instance.token_mode = RMODE
    return instance
end
--
function Lexer:line_cols_pos( position )
    -- body
    local line_num = 1
    local pre_pos = 1
    local pos = position or self.pos
    local str = string.sub(self.text, 1, pos)
    local index = 1
    repeat
        local from, to = str:find("\n", index)
        if to then
            index = to + 1
            line_num = line_num + 1
            pre_pos = to
        end
    until from == nil
    local cols_pos = pos - pre_pos
    return line_num, cols_pos
end
--
function Lexer:raise_error( info )
    -- todo:  detail error info
    local line_num, cols_pos = self:line_cols_pos()
    local str = "Error parsing input; Stop position is at: line " .. line_num .. " cols: " .. cols_pos
    if info and type(info) == "string" then
        str = str .. ".\n info:" .. info
    end
    error(str)
end
--
function Lexer:advance( ... )
    -- body
    self.pos = self.pos + 1
    if self.pos > self.text_length then
        self.current_char = nil
    else
        self.current_char = self.text:sub(self.pos, self.pos)
    end
end
--
function Lexer:rawstring( ... )
    -- num -> {'-'}(\d)*
    local i = self.pos
    while self.current_char do
        if self.current_char == '{' then
            local t = self:peek(1)
            if (t == '{') or (t == '%') then
               break
            end
        end
        if self.current_char == '%' or self.current_char == '}' then
            local t = self:peek(1)
            if t == '}' then
               self:raise_error("unexpect escape tag_end \'%}\' or var_end \'}}\' in raw string ")
            end
        end
        self:advance()
    end
    --find tag/var start, so change token mode
    self.token_mode = CMODE
    local result = nil
    -- deal with situation of document start with '{{' or '{%'
    if self.pos > i then
      local result = self.text:sub(i, self.pos - 1)
      return result
    else
      return result
    end
end
--
function Lexer:tag_start_wc( ... )
    -- body
    local i = self.pos
    if self.current_char == '{' then
        local t = self:peek(1)
        if t == '%' then
            local c = self:peek(2)
            if c == '-' then
                self:advance()
                self:advance()
                self:advance()
                return  self.text:sub(i, self.pos -1)
            end
        end
    end
end
--
function Lexer:var_start_wc( ... )
    -- body
    local i = self.pos
    if self.current_char == '{' then
        local t = self:peek(1)
        if t == '{' then
            local c = self:peek(2)
            if c == '-' then
                self:advance()
                self:advance()
                self:advance()
                return self.text:sub(i, self.pos -1)
            end
        end
    end
end
--
function Lexer:tag_end_wc( ... )
    -- body
    local i = self.pos
    if self.current_char == '-' then
        local t = self:peek(1)
        if t == '%' then
            local c = self:peek(2)
            if c == '}' then
                self:advance()
                self:advance()
                self:advance()
                return  self.text:sub(i, self.pos -1)
            end
        end
    end
end
--
function Lexer:var_end_wc( ... )
    -- body
    local i = self.pos
    if self.current_char == '-' then
        local t = self:peek(1)
        if t == '}' then
            local c = self:peek(2)
            if c == '}' then
                self:advance()
                self:advance()
                self:advance()
                return self.text:sub(i, self.pos -1)
            end
        end
    end
end
--
function Lexer:tag_end( ... )
    -- body
    local i = self.pos
    if self.current_char == '%' then
        local t = self:peek(1)
        if t == '}' then
            self:advance()
            self:advance()
            return  self.text:sub(i, self.pos -1)
        end
    end
end
--
function Lexer:var_end( ... )
    -- body
    local i = self.pos
    if self.current_char == '}' then
        local t = self:peek(1)
        if t == '}' then
            self:advance()
            self:advance()
            return self.text:sub(i, self.pos -1)
        end
    end
end
--
function Lexer:tag_start( ... )
    -- body
    local i = self.pos
    if self.current_char == '{' then
        local t = self:peek(1)
        if t == '%' then
            local c = self:peek(2)
            if c ~= '-' then
                self:advance()
                self:advance()
                return self.text:sub(i, self.pos -1)
            end
        end
    end
end
--
function Lexer:var_start( ... )
    -- body
    local i = self.pos
    if self.current_char == '{' then
        local t = self:peek(1)
        if t == '{' then
            local c = self:peek(2)
            if c ~= '-' then
                self:advance()
                self:advance()
                return  self.text:sub(i, self.pos -1)
            end
        end
    end
end
--
function Lexer:num( ... )
    local i = self.pos
    if self.current_char and self.current_char:find('-') then
        self:advance()
        while self.current_char and self.current_char:find('%d') do
            self:advance()
        end
        if (self.pos - 1) == i then
            return nil
        end
    end
    while self.current_char and self.current_char:find('%d') do
        self:advance()
    end
    if self.current_char then
        if  self.current_char:find('%.') then
            local t = self:peek(1)
            if t == "." then
                return self.text:sub(i, self.pos - 1)  -- may be a num in Range type
            elseif t:find('%d') then
                self:advance()
                while self.current_char and self.current_char:find('%d') do  -- float number
                    self:advance()
                end
            end
        end
        if self.current_char then
            if self.current_char:find('%a') then -- keep this condition ? ID token already be handled
                self:raise_error("expect a number, but got letter!")
            else
                return self.text:sub(i, self.pos - 1)
            end
        else
            return self.text:sub(i, self.pos - 1)
        end
    else
        return self.text:sub(i, self.pos - 1)
    end
end
--
function Lexer:string( ... )
    -- num -> "{a-zA-Z...}*"
    local result = ''
    if self.current_char and self.current_char:find('\'') then
        self:advance()
        while self.current_char do
            if self.current_char:find('\\') then
                local t = self:peek(1)
                if t then
                    if t == 'a' then
                        self:advance()
                        self:advance()
                        result = result .. "\a"
                    elseif t == 'b' then
                        self:advance()
                        self:advance()
                        result = result .. "\b"
                    elseif t == 'f' then
                        self:advance()
                        self:advance()
                        result = result .. "\f"
                    elseif t == 'n' then
                        self:advance()
                        self:advance()
                        result = result .. "\n"
                    elseif t == 'r' then
                        self:advance()
                        self:advance()
                        result = result .. "\r"
                    elseif t == 'v' then
                        self:advance()
                        self:advance()
                        result = result .. "\v"
                    elseif t == '\\' then
                        self:advance()
                        self:advance()
                        result = result .. "\\"
                    elseif t == '\"' then
                        self:advance()
                        self:advance()
                        result = result .. "\""
                    elseif t == '\'' then
                        self:advance()
                        self:advance()
                        result = result .. "\'"
                    elseif t == '\n' then
                        self:advance()  -- line num debug info
                        self:advance()
                    elseif t == '\r' then
                        self:advance()  -- line num debug info
                        self:advance()
                    else
                        self:advance()  -- NO hex number? so just discard '\'
                    end
                else
                    self:raise_error("unclosed string!")
                end
            end
            if self.current_char:find('\'') then
                 self:advance()
                 break
            end
            result = result .. self.current_char
            self:advance()
        end
        return result
    end
    if self.current_char and self.current_char:find('\"') then
        self:advance()
        while self.current_char do
            if self.current_char:find('\\') then
                local t = self:peek(1)
                if t then
                    if t == 'a' then
                        self:advance()
                        result = result .. "\a"
                    elseif t == 'b' then
                        self:advance()
                        result = result .. "\b"
                    elseif t == 'f' then
                        self:advance()
                        result = result .. "\f"
                    elseif t == 'n' then
                        self:advance()
                        result = result .. "\n"
                    elseif t == 'r' then
                        self:advance()
                        result = result .. "\r"
                    elseif t == 'v' then
                        self:advance()
                        result = result .. "\v"
                    elseif t == '\\' then
                        self:advance()
                        result = result .. "\\"
                    elseif t == '\"' then
                        self:advance()
                        result = result .. "\""
                    elseif t == '\'' then
                        self:advance()
                        result = result .. "\'"
                    elseif t == '\n' then
                        self:advance()  -- line num debug info
                    elseif t == '\r' then
                        self:advance()  -- line num debug info
                    else
                        self:advance()  -- NO hex number? so just discard '\'
                    end
                else
                    self:raise_error("unclosed string!")
                end
            end
            if self.current_char:find('\"') then
                 self:advance()
                 break
            end
            result = result .. self.current_char
            self:advance()
        end
        return result
    end
end
--
function Lexer:id( ... )
    local i = self.pos
    if self.current_char and (self.current_char:find('%a')  or self.current_char:find('_')) then
        self:advance()
        while self.current_char do
            if self.current_char:find('%a') then
                self:advance()
            elseif self.current_char:find('%d') then
                self:advance()
            elseif self.current_char:find('-') then
                self:advance()
            elseif self.current_char:find('_') then
                self:advance()
            else
                break
            end
        end
        return self.text:sub(i, self.pos -1)
    end
end
--
function Lexer:skip_whitespace( ... )
    -- body
    while self.current_char and self.current_char:find('%s') do
        self:advance()
    end
end
--
function Lexer:peek( n )
    -- body
    local p = self.pos + n
    if p <= self.text_length then
        return self.text:sub(p, p)
    else
        return nil
    end
end
--
function Lexer:get_next_token( ... )
    -- body
    while self.current_char do
        if self.token_mode == RMODE then
            local result = self:rawstring()
            if result then
                return Token:new(RAWSTRING, result)
            else
                self.token_mode = CMODE
            end
        else
            if self.current_char:find('%s') then
               self:skip_whitespace()
               goto CONTINUE
            end
            if self.current_char == '{' then
                local result = nil
                result = self:tag_start()
                if result then
                    return Token:new(TAGSTART, result)
                end
                result = self:tag_start_wc()
                if result then
                    return Token:new(TAGSTARTWC, result)
                end
                result = self:var_start()
                if result then
                    return Token:new(VARSTART, result)
                end
                result = self:var_start_wc()
                if result then
                    return Token:new(VARSTARTWC, result)
                end
                self:raise_error("expect tag_start\'{%\' or var_start\'{{\', but got a lonely \'{\'")
            end
            if self.current_char == '-' then
                local result = nil
                result = self:tag_end_wc()
                if result then
                    self.token_mode = RMODE
                    return Token:new(TAGENDWC, result)
                end
                result = self:var_end_wc()
                if result then
                    self.token_mode = RMODE
                    return Token:new(VARENDWC, result)
                end
                result = self:num()
                if result then
                    return Token:new(NUM, tonumber(result))
                end
                self:raise_error("expect tag_end\'-%}\' or var_end\'-}}\' or minus number, but got a lonely \'-\'")
            end
            if self.current_char == '%' then
                local result = nil
                result = self:tag_end()
                if result then
                    self.token_mode = RMODE
                    return Token:new(TAGEND, result)
                end
                self:raise_error("expect tag_end\'-%}\', but got a lonely \'%\'")
            end
            if self.current_char == '}' then
                local result = nil
                result = self:var_end()
                if result then
                    self.token_mode = RMODE
                    return Token:new(VAREND, result)
                end
                self:raise_error("expect var_end\'}}\', but got a lonely \'%\'")
            end
            if self.current_char:find('%d') then
                local result = nil
                result = self:num()
                if result then
                    return Token:new(NUM, tonumber(result))
                end
                self:raise_error()
            end
            if self.current_char:find('%a') or self.current_char:find('_') then
                local result = self:id()
                return (KEYWORDS[result] or Token:new(ID, result))
            end
            if self.current_char == '\''  or self.current_char == '\"' then
                local result = self:string()
                return Token:new(STRING, result)
            end
            if self.current_char == '=' then
                if self:peek(1) == '=' then
                    self:advance()
                    self:advance()
                    return Token:new(EQ, '==')
                else
                    self:advance()
                    return Token:new(ASSIGNMENT, '=')
                end
            end
            if self.current_char == '>' then
                if self:peek(1) == '=' then
                    self:advance()
                    self:advance()
                    return Token:new(GE, '>=')
                else
                    self:advance()
                    return Token:new(GT, '>')
                end
            end
            if self.current_char == '<' then
                if self:peek(1) == '=' then
                    self:advance()
                    self:advance()
                    return Token:new(LE, '<=')
                else
                    self:advance()
                    return Token:new(LT, '<')
                end
            end
            if self.current_char == '.' then
                if self:peek(1) == '.' then
                    self:advance()
                    self:advance()
                    return Token:new(DOTDOT, '..')
                else
                    self:advance()
                    return Token:new(DOT, '.')
                end
            end
            if self.current_char == '(' then
                self:advance()
                return Token:new(LPAREN, '(')
            end
            if self.current_char == ')' then
                self:advance()
                return Token:new(RPAREN, ')')
            end
            if self.current_char == '[' then
                self:advance()
                return Token:new(LSBRACKET, '[')
            end
            if self.current_char == ']' then
                self:advance()
                return Token:new(RSBRACKET, ']')
            end
            if self.current_char == '!' then
                if self:peek(1) == '=' then
                    self:advance()
                    self:advance()
                    return Token:new(NE, '!=')
                else
                     self:raise_error("expect \'!=\', but got a lonely \'!\'")
                end
            end
            if self.current_char == '|' then
                self:advance()
                return Token:new(PIPE, '|')
            end
            if self.current_char == ':' then
                self:advance()
                return Token:new(COLON, ':')
            end
            if self.current_char == ',' then
                self:advance()
                return Token:new(COMMA, ',')
            end
            self:raise_error()
        end
        ::CONTINUE::
    end
    if self.pos >= self.text_length then
        return Token:new(EOF, nil)
    end
end
--
------------------------------------------------------------AST node begin -----------------------------------------------------------
local NoOp = {}
function NoOp:new( ... )
    -- body
    local instance = {}
    setmetatable(instance, {__index = NoOp})
    return instance
end
function NoOp:_name_( ... )
    -- body
    return 'NoOp'
end
--Num
local Num = {}
function Num:new( token )
    -- body
    local instance = {}
    setmetatable(instance, {__index = Num})
    instance.token = token
    instance.value = token.value
    return instance
end
function Num:_name_( ... )
    -- body
    return "Num"
end
--String
local Str = {}
function Str:new( token )
    -- body
    local instance = {}
    setmetatable(instance, {__index = Str})
    instance.token = token
    instance.value = token.value
    return instance
end
function Str:_name_( ... )
    -- body
    return 'Str'
end
--
--RawStr
local RawStr = {}
function RawStr:new( token , parser_context)
    -- body
    local instance = {}
    setmetatable(instance, {__index = RawStr})
    instance.token = token
    if parser_context.whitespace_lstrip_flag then
        instance.value = string.lstrip(token.value)
        parser_context.whitespace_lstrip_flag = false
    else
        instance.value = token.value
    end
    return instance
end
function RawStr:rstrip( ... )
   --body
   self.value = string.rstrip(self.value)
end
function RawStr:_name_( ... )
    -- body
    return 'RawStr'
end
--
--BinOp
local BinOp = {}
function BinOp:new( left, op, right )
    -- body
    local instance = {}
    setmetatable(instance, {__index = BinOp})
    instance.left = left
    instance.op = op
    instance.right = right
    return instance
end
function BinOp:_name_( ... )
    -- body
    return 'BinOp'
end
--if/unless control flow
local Branch = {}
function Branch:new( exper, truebody, falsebody )
    -- body
    local instance = {}
    setmetatable(instance, {__index = Branch})
    instance.exper = exper
    if truebody then
        instance.truebody = truebody
    else
        instance.truebody = NoOp:new()
    end
    if falsebody then
        instance.falsebody = falsebody
    else
        instance.falsebody = NoOp:new()
    end
    return instance
end
--
function Branch:_name_( ... )
    -- body
    return 'Branch'
end
--
--Loop -> for xx in xx
local ForLoop = {}
function ForLoop:new( element, exp, limit, offset, reversed, nonemptybody, emptybody )
    -- body
    local instance = {}
    setmetatable(instance, {__index = ForLoop})
    instance.element = element
    instance.exp = exp
    instance.limit = limit
    instance.offset = offset
    instance.reversed = reversed
    instance.nonemptybody = nonemptybody
    instance.emptybody = emptybody
    return instance
end
function ForLoop:_name_( ... )
    -- body
    return 'ForLoop'
end
--
--Compoud ->statement list
local Compoud = {}
function Compoud:new( ... )
    -- body
    local instance = {}
    setmetatable(instance, {__index = Compoud})
    return instance
end
function Compoud:_name_( ... )
    -- body
    return 'Compoud'
end
--
--Assignment
local Assignment = {}
function Assignment:new( id, exp )
    -- body
    local instance = {}
    setmetatable(instance, {__index = Assignment})
    instance.id = id
    instance.exp = exp
    return instance
end
function Assignment:_name_( ... )
    -- body
    return 'Assignment'
end
-- Boolean
local Boolean = {}
function Boolean:new( token )
    -- body
    local instance = {}
    setmetatable(instance, {__index = Boolean})
    instance.token = token
    if token.token_type == TRUE then
        instance.value = true
    elseif token.token_type == FALSE then
        instance.value = false
    else
        error("Invalid true or false")
    end
    return instance
end
function Boolean:_name_( ... )
    -- body
    return 'Boolean'
end
--Field
local Field = {}
function Field:new( var, field )
    -- body
    local instance = {}
    setmetatable(instance, {__index = Field})
    instance.var = var
    instance.field = field
    return instance
end
function Field:_name_( ... )
    -- body
    return 'Field'
end
--Filter
local Filter = {}
function Filter:new( filter_name, params )
    -- body
    local instance = {}
    setmetatable(instance, {__index = Filter})
    instance.filter_name = filter_name
    instance.params = params
    return instance
end
function Filter:_name_( ... )
    -- body
    return 'Filter'
end
--Empty
local Empty = {}
function Empty:new( token )
    -- body
    local instance = {}
    setmetatable(instance, {__index = Empty})
    instance.method_name = token.value
    instance.default_value = ''
    return instance
end
function Empty:_name_( ... )
    -- body
    return 'Empty'
end
--Range
local Range = {}
function Range:new( start_var, end_var )
    -- body
    local instance = {}
    setmetatable(instance, {__index = Range})
    instance.start_var = start_var
    instance.end_var = end_var
    return instance
end
function Range:_name_( ... )
    -- body
    return 'Range'
end
--Nil
local Nil = {}
function Nil:new( token )
    -- body
    local instance = {}
    setmetatable(instance, {__index = Nil})
    instance.token = token
    instance.value = nil
    return instance
end
function Nil:_name_( ... )
    -- body
    return 'Nil'
end
--
local Var = {}
function Var:new( node )
    -- body
    local instance = {}
    setmetatable(instance, {__index = Var})
    instance.value = node
    return instance
end
function Var:_name_( ... )
    -- body
    return 'Var'
end
--
--
local Interrupt = {}
function Interrupt:new( token )
    -- body
    local instance = {}
    setmetatable(instance, {__index = Interrupt})
    instance.token = token
    return instance
end
function Interrupt:_name_( ... )
    -- body
    return 'Interrupt'
end
--
local CycleLoop = {}
function CycleLoop:new( ... )
    -- body
    local instance = {}
    setmetatable(instance, {__index = CycleLoop})
    instance.group_name = nil
    instance.elementarray = {}
    return instance
end
function CycleLoop:_name_( ... )
    -- body
    return 'CycleLoop'
end
--
local TableLoop = {}
function TableLoop:new( element, exp, limit, offset, cols, blockbody )
    -- body
    local instance = {}
    setmetatable(instance, {__index = TableLoop})
    instance.element = element
    instance.exp = exp
    instance.limit = limit
    instance.offset = offset
    instance.cols = cols
    instance.blockbody = blockbody
    return instance
end
function TableLoop:_name_( ... )
    -- body
    return 'TableLoop'
end
--
local IncDec = {}
function IncDec:new( id, op_type )
    -- body
    local instance = {}
    setmetatable(instance, {__index = IncDec})
    instance.id = id
    instance.op_type = op_type
    return instance
end
function IncDec:_name_( ... )
    -- body
    return 'IncDec'
end
--
local Partial = {}
function Partial:new( location, interpretercontext, parser_context )
    -- body
    local instance = {}
    setmetatable(instance, {__index = Partial})
    instance.location = location
    instance.interpretercontext = interpretercontext
    instance.parser_context = parser_context
    return instance
end
function Partial:_name_( ... )
    -- body
    return 'Partial'
end
-------------------------------------------------------------AST node end----------------------------------------------------------------


-------------------------------------------------------------Parser begin----------------------------------------------------------------
-- local Parser = {}
function Parser:new( lexer, parser_context )
    -- body
    local instance = {}
    setmetatable(instance, {__index = Parser})
    instance.lexer = lexer
    instance.parser_context = parser_context or ParserContext:new()
    instance.current_token = lexer:get_next_token()
    instance.pos = lexer.pos
    instance.nodetab = Nodetab:new()
    return instance
end
--
function Parser:raise_error( info )
    -- body
    local line_num, cols_pos = self.lexer:line_cols_pos()
    local str = "Invalid syntax: parsing stoped at: line ".. line_num .. " cols: " .. cols_pos .. " current_token is " .. self.current_token:to_s()
    if info and type(info) then
        str = str .. "\n info: " .. info
    end
    error(str)
end
--
function Parser:eat( token_type )
    -- body
    if self.current_token.token_type == token_type then
        self.current_token = self.lexer:get_next_token()
        self.pos = self.lexer.pos
    else
        self:raise_error("expect to get token_type is " .. token_type)
    end
end
--
function Parser:set_whitespace_lstrip_flag( ... )
    self.parser_context.whitespace_lstrip_flag = true
end
--
function Parser:set_whitespace_rstrip_flag( ... )
    self.parser_context.whitespace_rstrip_flag = true
end
--
function Parser:reset_whitespace_lstrip_flag( ... )
    self.parser_context.whitespace_lstrip_flag = false
end
--
function Parser:reset_whitespace_rstrip_flag( ... )
    self.parser_context.whitespace_rstrip_flag = false
end
--
function Parser:eat_tagend_or_tagendwc( ... )
    if self.current_token.token_type == TAGEND then
        self:eat(TAGEND)
        self:reset_whitespace_lstrip_flag()
        self:reset_whitespace_rstrip_flag()
        return false
    elseif self.current_token.token_type == TAGENDWC then
        self:eat(TAGENDWC)
        self:set_whitespace_lstrip_flag()    -- lstrip_flag followed by rawstr is  prefix style
        self:reset_whitespace_rstrip_flag()
        return true
    else
        self:raise_error(" expect tag_end : \'%} or -%}\'")
    end
end
--
local BFWORDS_TEMP = { ELSE, ELSIF, ENDIF, ENDUNLESS, WHEN, ENDCASE, ENDFOR, ENDTABLEROW, ENDCAPTURE, ENDCOMMENT, ENDRAW}
local BFWORDS = {}
for i,v in ipairs(BFWORDS_TEMP) do
    BFWORDS[v] = i
end
function Parser:blockfollow( ... )
    local token_type = self.current_token.token_type
    if BFWORDS[token_type] then
        return  false
    else
        return true
    end
end
--
function Parser:document( ... )
    -- body
    local node = self:block()
    if self.current_token.token_type ~= EOF then
        self:raise_error()
    end
    return node
end
--
function Parser:block( ... )
    -- document : (RAWSTRING | state)*
    local node = Compoud:new()
    while self.current_token.token_type ~= EOF do
        if self.current_token.token_type == RAWSTRING then
            local temp = RawStr:new(self.current_token, self.parser_context)
            table.insert(node, temp)
            self:eat(RAWSTRING)
        else
            if self.current_token.token_type == TAGSTART
                or self.current_token.token_type == TAGSTARTWC then
                if self.current_token.token_type == TAGSTARTWC then
                    local temp = node[#node]
                    if temp and type(temp) == "table" and type(temp._name_) == "function" and temp:_name_() == "RawStr" then
                        temp:rstrip()
                    end
                end
                self:reset_whitespace_lstrip_flag()
                self:eat(self.current_token.token_type)
                if not self:blockfollow() then
                    if #node == 0 then
                        return NoOp:new()
                     end
                     return node
                end
                local temp = self:tag()
                table.insert(node, temp)
            elseif self.current_token.token_type == VARSTART
                or self.current_token.token_type == VARSTARTWC then
                if self.current_token.token_type == VARSTARTWC then
                    local temp = node[#node]
                    if temp and type(temp) == "table" and type(temp._name_) == "function" and temp:_name_() == "RawStr" then
                        temp:rstrip()
                    end
                end
                self:eat(self.current_token.token_type)
                local temp = self:var()
                table.insert(node, temp)
            else
                self:raise_error("expect tag_start: \'{%\' or \'{%-\' ; var_start \'{{ \' or \'{{-\'")
            end
        end
    end
    return node
end
--
function Parser:tag( ... )
--[[    state : tag_if
              | tag_unless
              | tag_case
              | tag_for
              | tag_cycle
              | tag_tablerow
              | tag_break
              | tag_continue
              | tag_assign
              | tag_capture
              | tag_increment
              | tag_decrement
              | tag_include
              | tag_comment
              | tag_raw
]]
    local method = "tag_" .. self.current_token.value
    if self[method] and type(self[method]) == "function" then
        return self[method](self)
    else
        self:raise_error("undefined tag: " .. self.current_token.value)
    end
end
--
function Parser:tag_if( ... )
    --[[ tag_if -> TAGSTART IF condexper  TAGEND
                       block
                   (TAGSTART ELSIF condexper TAGEND
                       block)*
                   {TAGSTART ELSE TAGEND
                       block}
                   TAGSTART ENDIF TAGEND]]
    local branch = Branch:new()
    if self.current_token.token_type == IF then
        self:eat(IF)
        branch.exper = self:condexper()
        self:eat_tagend_or_tagendwc() 
        branch.truebody = self:block()
        local node = branch
        -- self:eat(TAGSTART) or self:eat(TAGSTARTWC)  because block eated it
        while self.current_token.token_type == ELSIF do
            local subbranch = Branch:new()
            self:eat(ELSIF)
            subbranch.exper = self:condexper()
            self:eat_tagend_or_tagendwc()
            subbranch.truebody = self:block()
            branch.falsebody = subbranch
            branch = subbranch
        end
        if self.current_token.token_type == ELSE then
            self:eat(ELSE)
            self:eat_tagend_or_tagendwc()
            branch.falsebody = self:block()
        end
        if self.current_token.token_type == ENDIF then
            self:eat(ENDIF)
            self:eat_tagend_or_tagendwc()
        end
        return node
    end
end
--
function Parser:tag_unless( ... )
    --[[ tag_if -> TAGSTART UNLESS condexper  TAGEND
                       block
                   (TAGSTART ELSIF condexper TAGEND
                       block)*
                   {TAGSTART ELSE TAGEND
                       block}
                   TAGSTART ENDUNLESS TAGEND]]
    local branch = Branch:new()
    if self.current_token.token_type == UNLESS then
        self:eat(UNLESS)
        branch.exper = self:condexper()
         self:eat_tagend_or_tagendwc()
        branch.falsebody = self:block()
        local node = branch
        -- self:eat(TAGSTART) or self:eat(TAGSTARTWC)  because block eated it
        while self.current_token.token_type == ELSIF do
            local subbranch = Branch:new()
            self:eat(ELSIF)
            subbranch.exper = self:condexper()
            self:eat_tagend_or_tagendwc()
            subbranch.truebody = self:block()
            branch.truebody = subbranch
            branch = subbranch
        end
        if self.current_token.token_type == ELSE then
            self:eat(ELSE)
            self:eat_tagend_or_tagendwc()
            branch.truebody = self:block()
        end
        if self.current_token.token_type == ENDUNLESS then
            self:eat(ENDUNLESS)
            self:eat_tagend_or_tagendwc()
        end
        return node
    end
end
--
function Parser:tag_case( ... )
    --[[ tag_if -> TAGSTART CASE exper  TAGEND
                       block
                   (TAGSTART when exper TAGEND
                       block)*
                   {TAGSTART ELSE TAGEND
                       block}
                   TAGSTART ENDCASE TAGEND]]
    local branch = Branch:new()
    branch.exper = Boolean:new(Token:new(FALSE, 'false'))
    local node = branch
    if self.current_token.token_type == CASE then
        self:eat(CASE)
        local temp = self:exper()
         self:eat_tagend_or_tagendwc()
        self:block()
        -- self:eat(TAGSTART) or self:eat(TAGSTARTWC)  because block eated it
        while self.current_token.token_type == WHEN do
            local subbranch = Branch:new()
            self:eat(WHEN)
            local cond2 = self:exper()
            subbranch.exper = BinOp:new(temp, EQ, cond2)
            self:eat_tagend_or_tagendwc()
            subbranch.truebody = self:block()
            branch.falsebody = subbranch
            branch = subbranch
        end
        if self.current_token.token_type == ELSE then
            self:eat(ELSE)
            self:eat_tagend_or_tagendwc()
            branch.falsebody = self:block()
        end
        if self.current_token.token_type == ENDCASE then
            self:eat(ENDCASE)
            self:eat_tagend_or_tagendwc()
        end
        return node
    end
end
--
function Parser:condexper( ... )
    --[[ condexper : andexper ( OR andexper)*
    ]]
    local left = self:andexper()
    while self.current_token.token_type == OR do
        self:eat(OR)
        local right = self:andexper()
        left = BinOp:new(left, OR, right)
    end
    return left
end
function Parser:andexper( ... )
    --[[ andexper : relexper ( AND relexper)*
    ]]
    local left = self:relexper()
    while self.current_token.token_type == AND do
        self:eat(AND)
        local right = self:relexper()
        left = BinOp:new(left, AND, right)
    end
    return left
end
function Parser:relexper( ... )
    --[[ relexper : exper { EQ exper
                                                | NE exper
                                                | GE exper
                                                | GT exper
                                                | LE exper
                                                | LT exper
                                                | CONTAINS exper}
    ]]
    local RELATION = {[EQ] = true, [NE] = true, [GE] = true, [GT] = true, [LE] = true, [LT] = true, [CONTAINS] = true}
    local pos_info = {}
    local left = self:exper()
    local token_type = self.current_token.token_type
    if RELATION[token_type] then
        self:eat(token_type)
        pos_info.op = self.pos
        local right = self:exper()
        left = BinOp:new(left, token_type, right)
    end
    self.nodetab:set_pos(left, pos_info)
    return left
end

function Parser:exper( ... )
    --[[ exper : exp | EMPTY
    ]]
    local node = nil
    if self.current_token.token_type == EMPTY then
        self:eat(EMPTY)
        node = Empty:new(self.current_token)
    else
        node = self:exp()
    end
    return node
end

function Parser:exp( ... )
    --[[ exp : factor ( PIPE filter)*
    ]]
    local param = self:factor()
    while self.current_token.token_type == PIPE do
        self:eat(PIPE)
        local filter_node = self:filter()
        table.insert(filter_node.params, 1, param)
        param = filter_node
    end
    return param
end

function Parser:factor( ... )
    --[[ factor : STRING
                            | NUM
                            | TRUE
                            | FALSE
                            | NIL
                            | range
                            | ID ( lookup )*
    ]]
    local node = nil
    if self.current_token.token_type == STRING then
        node = Str:new(self.current_token)
        self:eat(STRING)
    elseif self.current_token.token_type == NUM then
        node = Num:new(self.current_token)
        self:eat(NUM)
    elseif self.current_token.token_type == TRUE then
        node = Boolean:new(self.current_token)
        self:eat(TRUE)
    elseif self.current_token.token_type == FALSE then
        node = Boolean:new(self.current_token)
        self:eat(FALSE)
    elseif self.current_token.token_type == NIL then
        node = Nil:new(self.current_token)
        self:eat(NIL)
    elseif self.current_token.token_type == ID then
        node = Field:new(nil, Str:new(self.current_token))
        self:eat(ID)
        while self.current_token.token_type == DOT
            or self.current_token.token_type == LSBRACKET do
            local field = self:lookup()
            node = Field:new(node, field)
        end
    elseif self.current_token.token_type == LPAREN then
        node = self:range()
    else
        self:raise_error()
    end
    return node
end
--
function Parser:lookup( ... )
    --[[ lookup : ( DOT ID | LSBRACKET factor RSBRACKET)
    ]]
    if self.current_token.token_type == DOT then
        self:eat(DOT)
        local node = Str:new(self.current_token)
        self:eat(ID)
        return node
    elseif self.current_token.token_type == LSBRACKET then
        self:eat(LSBRACKET)
        local node = self:factor()
        self:eat(RSBRACKET)
        return node
    else
        self:raise_error("object's field lookup expect dot dot \'..\' style or square \'[]\'  ")
    end
end
--
function Parser:range( ... )
    --[[ lookup : ( LPAREN factor DOTDOT factor RPAREN)
    ]]
    local pos_info = {}
    local node = {}
    if self.current_token.token_type == LPAREN then
        self:eat(LPAREN)
        pos_info.left = self.pos
        local start_var = self:factor()
        self:eat(DOTDOT)
        pos_info.right = self.pos
        local end_var = self:factor()
        self:eat(RPAREN)
        node = Range:new(start_var, end_var)
    else
        self:raise_error(" expect range type ")
    end
    self.nodetab:set_pos(node, pos_info)
    return node
end
--
function Parser:filter( ... )
    --[[
    filter : ID ( COLON paramlist)
    ]]
    local pos_info = {}
    local filter_name = nil
    if self.current_token.token_type == ID then
        filter_name = self.current_token.value
        self:eat(ID)
        pos_info.filter_name = self.pos
    else
        self:raise_error()
    end
    local params = {}
    if self.current_token.token_type == COLON then
        self:eat(COLON)
        params = self:paramlist()
    end
    local node = Filter:new(filter_name, params)
    self.nodetab:set_pos(node, pos_info)
    return node
end
--
function Parser:paramlist( ... )
    --[[
    paramlist : factor (COMMA factor)*
    ]]
    local params = {}
    local param = self:factor()
    table.insert(params, param)
    while self.current_token.token_type == COMMA do
        self:eat(COMMA)
        param = self:factor()
        table.insert(params, param)
    end
    return params
end
--
function Parser:tag_for( ... )
    --[[
    tag_for :  TAGSTART FOR ID IN exp (LIMIT COLON exp | OFFSET COLON exp | REVERSED)* TAGEND
               block
               {
                TAGSTART ELSE TAGEND
                   block
               }
                TAGSTART ENDFOR TAGEND
    ]]
    local element = nil
    local exp = nil
    local limit = nil
    local offset = nil
    local reversed = false
    local nonemptybody = NoOp:new()
    local emptybody = NoOp:new()
    local pos_info = {}
    if self.current_token.token_type == FOR then
        self:eat(FOR)
        pos_info.for_pos = self.pos
        local temp_token = self.current_token
        self:eat(ID)
        element = temp_token.value
        self:eat(IN)
        exp = self:exp()
        while self.current_token.token_type == LIMIT
            or self.current_token.token_type == OFFSET
            or self.current_token.token_type == REVERSED do

            if self.current_token.token_type == LIMIT then
                self:eat(LIMIT)
                self:eat(COLON)
                pos_info.limit_pos = self.pos
                limit = self:exp()
            end
            if self.current_token.token_type == OFFSET then
                self:eat(OFFSET)
                self:eat(COLON)
                pos_info.offset_pos = self.pos
                offset = self:exp()
            end
            if self.current_token.token_type == REVERSED then
                self:eat(REVERSED)
                reversed = true
            end
        end
        self:eat_tagend_or_tagendwc()
        nonemptybody = self:block()
        if self.current_token.token_type == ELSE then
            self:eat(ELSE)
            self:eat_tagend_or_tagendwc()
            emptybody = self:block()
        end
        if self.current_token.token_type == ENDFOR then
            self:eat(ENDFOR)
            self:eat_tagend_or_tagendwc()
            local node = ForLoop:new(element, exp, limit, offset, reversed, nonemptybody, emptybody)
            self.nodetab:set_pos(node, pos_info)
            return node
        else
            self:raise_error()
        end
    end
end
--
function Parser:var( ... )
    -- var : VARSTART exp VAREND
    local pos_info = {}
    pos_info.pos = self.pos
    local node = self:exp()
    local token_type = self.current_token.token_type
    if token_type == VAREND or token_type == VARENDWC then
        if token_type == VARENDWC then
            self:set_whitespace_lstrip_flag()
        end
        self:reset_whitespace_rstrip_flag()
        self:eat(self.current_token.token_type)
    else
        self:raise_error("expect var_end \'}}\' or \'-}}\' ")
    end
    local node = Var:new(node)
    self.nodetab:set_pos(node, pos_info)
    return node
end
--
function Parser:tag_break( ... )
    -- tag_break: TAGSTART BREAK TAGEND
    self:eat(BREAK)
    self:eat_tagend_or_tagendwc()
    return Interrupt:new(KEYWORDS["break"])
end
--
function Parser:tag_continue( ... )
    -- tag_break: TAGSTART CONTINUE TAGEND
    self:eat(CONTINUE)
    self:eat_tagend_or_tagendwc()
    return Interrupt:new(KEYWORDS["continue"])
end
--
function Parser:tag_assign( ... )
    -- assign : TAGSTART ASSIGN ID ASSIGNMENT factor TAGEND
    self:eat(ASSIGN)
    local id = self.current_token.value
    self:eat(ID)
    self:eat(ASSIGNMENT)
    local exp = self:exp()
    self:eat_tagend_or_tagendwc()
    return Assignment:new(id, exp)
end
--
function Parser:tag_cycle( ... )
    -- tag_cycle : TAGSTART CYCLE {factor COLON} factor (COMMA factor)* TAGEND
    local pos_info = {}
    pos_info.pos = self.pos
    self:eat(CYCLE)
    local group_name = self:factor()
    local elementarray = {}
    local group_name_flag = false
    if self.current_token.token_type == COLON then
        group_name_flag = true
        self:eat(COLON)
        table.insert(elementarray, self:factor())
    end
    while self.current_token.token_type == COMMA do
        self:eat(COMMA)
        table.insert(elementarray, self:factor())
    end
    self:eat_tagend_or_tagendwc()
    local node = CycleLoop:new()
    if group_name_flag then
        node.group_name = group_name
        node.elementarray = elementarray
    else
        table.insert(elementarray, 1, group_name)
        node.group_name = nil
        node.elementarray = elementarray
    end
    self.nodetab:set_pos(node, pos_info)
    return node
end
--
function Parser:tag_tablerow( ... )
    --[[
    tag_tablerow :  TAGSTART TABLEROW ID IN exp (LIMIT COLON exp | OFFSET COLON exp | COLS COLON exp)* TAGEND
                 block
                TAGSTART ENDTABLEROW TAGEND
    ]]
    local element = nil
    local exp = nil
    local limit = nil
    local offset = nil
    local cols = nil
    local blockbody = NoOp:new()
    local pos_info = {}

    self:eat(TABLEROW)
    pos_info.tablerow_pos = self.pos
    local element = self.current_token.value
    self:eat(ID)
    self:eat(IN)
    exp = self:exp()
    while self.current_token.token_type == LIMIT 
        or self.current_token.token_type == OFFSET
        or self.current_token.token_type == COLS  do

        if self.current_token.token_type == LIMIT then
            self:eat(LIMIT)
            pos_info.limit_pos = self.pos
            self:eat(COLON)
            limit = self:exp()
        end

        if self.current_token.token_type == OFFSET then
            self:eat(OFFSET)
            pos_info.offset_pos = self.pos
            self:eat(COLON)
            offset = self:exp()
        end
        if self.current_token.token_type == COLS then
            self:eat(COLS)
            pos_info.cols_pos = self.pos
            self:eat(COLON)
            cols = self:exp()
        end
    end
    self:eat_tagend_or_tagendwc()
    blockbody = self:block()
    if self.current_token.token_type == ENDTABLEROW then
        self:eat(ENDTABLEROW)
        self:eat_tagend_or_tagendwc()
    else
        self:raise_error()
    end
    local node = TableLoop:new(element, exp, limit, offset, cols, blockbody)
    self.nodetab:set_pos(node, pos_info)
    return node
end
--
function Parser:tag_capture( ... )
    --[[ tag_capture : TAGSTART CAPTURE ID TAGEND
                     {block}
                     TAGSTART ENDCAPTURE TAGEND
]]

    self:eat(CAPTURE)
    local id = self.current_token.value
    self:eat(ID)
    self:eat_tagend_or_tagendwc()
    local block = self:block()
    self:eat(ENDCAPTURE)
    self:eat_tagend_or_tagendwc()
    return Assignment:new(id, block)
end
--
function Parser:tag_increment( ... )
    -- body
    self:eat(INCREMENT)
    local id = self.current_token.value
    self:eat(ID)
    self:eat_tagend_or_tagendwc()
    return IncDec:new(id, INCREMENT)
end
--
function Parser:tag_decrement( ... )
    -- body
    self:eat(DECREMENT)
    local id = self.current_token.value
    self:eat(ID)
    self:eat_tagend_or_tagendwc()
    return IncDec:new(id, DECREMENT)
end
--
function Parser:tag_comment( ... )
    -- body
    self:eat(COMMENT)
    self:eat_tagend_or_tagendwc()
    self:block()
    self:eat(ENDCOMMENT)
    self:eat_tagend_or_tagendwc()
    return NoOp:new()
end
--
function Parser:tag_raw( ... )
    -- tag_raw: TAGSTART RAW TAGEND
    local flag = 1
    local pos = self.lexer.pos
    self:eat(RAW)
    local begin_pos = self.lexer.pos
    local end_pos = nil
    local end_pos_array = {}
    self:eat_tagend_or_tagendwc()
    local output = {}
    local pre_token_array = {}
    while self.current_token.token_type ~= EOF and flag >= 1 do
        if #pre_token_array >= 2 then -- to keep pre TAGSTART token
            table.remove(pre_token_array)
        end
        table.insert(pre_token_array, 1, self.current_token)
        if #end_pos_array >= 3 then -- to keep pre TAGSTART position
            table.remove(end_pos_array)
        end
        table.insert(end_pos_array, 1, self.lexer.pos)
        if self.current_token.token_type == RAW then
            flag = flag + 1
        end
        if self.current_token.token_type == ENDRAW then
            flag = flag - 1
        end
        if flag == 0 then
            if pre_token_array[2].token_type == TAGSTART then
                end_pos = end_pos_array[3] - 1
            else
                self:raise_error("unmatched \'raw\' - \'endraw\' pairs: the start raw tag is found at " .. pos)
            end
        end
        self:eat(self.current_token.token_type)
    end
    if flag ~= 0 then
          error("unmatched \'raw\' - \'endraw\' pairs: the start raw tag is found at " .. pos)
    end
    self:eat_tagend_or_tagendwc()
    local result = string.sub(self.lexer.text, begin_pos, end_pos)
    return Str:new(Token:new(STRING, result))
end
--
function Parser:tag_include( ... )
    -- tag_include: TAGSTART INCLUDE exp { WITH exp }  TAGEND | TAGSTART INCLUDE exp { FOR exp } TAGEND
    local pos_info = {}
    self:eat(INCLUDE)
    pos_info.include_pos = self.pos
    local exp = self:exp()
    local exp2 = nil
    if self.current_token.token_type == WITH or self.current_token.token_type == FOR then
        self:eat(self.current_token.token_type)
        exp2 = self:exp()
    end
    self:eat_tagend_or_tagendwc()
    local node = Partial:new(exp, exp2, self.parser_context)
    self.nodetab:set_pos(node, pos_info)
    return node
end
-------------------------------------------------------------Parser end----------------------------------------------------------------

-------------------------------------------------------------Interpreter begin---------------------------------------------------------
-- local Interpreter = {}
function Interpreter:new( parser )
    -- body
    local instance = {}
    setmetatable(instance, {__index = Interpreter})
    instance.parser = parser
    instance.interrupt_flag = false -- mark unhandled 'break/continue'
    instance.interrupt_type = nil   -- mark unhandled 'break/continue' type(nil/break/conntinue)
    instance.tree = parser:document()
    return instance
end
--
function Interpreter:raise_error( info, node, key)
    -- body
    if node and key then
        local pos_info = self.parser.nodetab:get_pos(node)
        if pos_info then
            local pos = pos_info[key]
            local line_num, cols_pos = self.parser.lexer:line_cols_pos(pos)
            local str = "Liquid runtime error, stoped at line_num: " .. line_num.. " cols:" .. cols_pos 
            if info then
                str = str .. ". INFO: " .. info
            end
            error(str)
        elseif info then
            error("Liquid runtime error: ( missing detail location info ) " .. info)
        else
            error("Liquid runtime error.( missing detail location info )")
        end
    else
        if info then
            error("Liquid runtime error( missing detail location info )" .. info)
        else
            error("Liquid runtime error( missing detail location info )")
        end
    end
end
--
function Interpreter:visit( node )
    -- body
    local method = "visit_" .. node:_name_()
    if method == "visit_Interrupt" then
        self.interrupt_flag = true
        self.interrupt_type = node.token.token_type
    elseif self[method] and type(self[method]) == 'function' then
        return self[method](self, node)
    else
        return self:generic_visit(node)
    end
end
--
function Interpreter:generic_visit( node )
    -- body
    error('visit_' .. node:_name_() .. ' method not found')
end
--
function Interpreter:interpret( context, filterset, resourcelimit, filesystem )
    -- body
    self.interpretercontext = context or InterpreterContext:new({})
    self.filterset = filterset or FilterSet:new()
    self.resourcelimit = resourcelimit or ResourceLimit:new()
    self.filesystem = filesystem or FileSystem:new()
    return self:visit(self.tree)
end
function Interpreter:visit_Num( node )
    return node.value
end
--
function Interpreter:visit_Str( node )
    return node.value
end
--
function Interpreter:visit_RawStr( node )
    return node.value
end
--
function Interpreter:visit_Boolean( node )
    return node.value
end
--
function Interpreter:visit_Nil( node )
    return node.value
end
--
function Interpreter:visit_Range( node )
    -- body
    local from = self:visit(node.start_var)
    local to = self:visit(node.end_var)
    if type(from) == "number" and type(to) == "number" then
        if from == to then
            return({from})
        else
            local result = {}
            for k = from, to, 1 do
                self.resourcelimit:check_loopcount()
                table.insert(result, k)
            end
            return(result)
        end
    else
        error("Invalid range value, expect number type, but got:" .. "*from:*" .. type(from) .. "*to:*" .. type(to))
    end
end
--
function Interpreter:visit_Compoud( node )
    -- body
    local output = {}
    for k,v in ipairs(node) do
        if self.interrupt_flag then
            return self:safe_concat(output, '')
        end
        local result = self:visit(v)
        if result ~= nil then
            table.insert(output, result)
        end
    end
    return self:safe_concat(output, '')
end
--
function Interpreter:visit_Branch( node )
    -- body
    local cond = self:visit(node.exper)
    if cond then
        return self:visit(node.truebody)
    else
        return self:visit(node.falsebody)
    end
end
--
function Interpreter:visit_NoOp( node )
    -- body
end
--
function Interpreter:visit_Var( node )
    -- body
    local temp = self:visit(node.value)
    local result = self:obj2str(temp)
    if result == nil then
        self:raise_error("please manually convert table to string", node, 'pos')
    else
        return temp
    end
end
--
function Interpreter:visit_BinOp( node )
    local left_name = node.left:_name_()
    local right_name = node.right:_name_()
    local op = node.op
    if left_name == "Empty" or right_name == "Empty" then
        if op == EQ or op == NE then
            if left_name == right_name then
                if op == EQ then
                    return true
                else
                    return false
                end
            end

            if left_name == "Empty" then
                local right_value = self:visit(node.right)
                local str = self:obj2str(right_value)
                if not str or str == '' then
                    if op == EQ then
                        return true
                    else
                        return false
                    end
                end
                if type(right_value) == "table" then
                    if next(right_value) or (str and str ~= '') then
                        if op == NE then
                            return true
                        else
                            return false
                        end
                    else
                        if op == EQ then
                            return true
                        else
                            return false
                        end
                    end
                end
                self:raise_error("Invalid empty comparision", node, 'op')
            else
                local left_value = self:visit(node.left)
                local str = self:obj2str(left_value)

                if not str or str == '' then
                    if op == EQ then
                        return true
                    else
                        return false
                    end
                end

                if type(left_value) == "table" then
                    if next(left_value) or (str and str ~= '') then
                        if op == NE then
                            return true
                        else
                            return false
                        end
                    else
                        if op == EQ then
                             return true
                        else
                             return false
                        end
                    end
                end
                self:raise_error("Invalid empty comparision", node, 'op')
            end
        else
            self:raise_error("Invalid empty comparision", node, 'op')
        end
    end

    if op == CONTAINS then
        local left_value = self:visit(node.left)
        local right_value = self:visit(node.right)
        if type(right_value) == "string" then
            if type(left_value) == "string" then
                return string.find(left_value, left_value)
            elseif type(left_value) == "table" then
                for i, v in left_value do
                     if type(v) == "string" then
                         if string.find(v, right_value) then
                             return true
                         end
                     end
                end
                return false
            end
        else
            self:raise_error("keywords \'contains\' can only be used for string, the right value is not a string ",node, 'op')
        end
    end

    if op == EQ then
        local left_value = self:visit(node.left)
        local right_value = self:visit(node.right)
        if type(left_value) == "table" and type(right_value) == "table" then
            local t1 = cjson.encode(left_value)
            local t2 = cjson.encode(right_value)
            return (t1 == t2)
        end
        return (left_value == right_value)
    end

    if op == NE then
        local left_value = self:visit(node.left)
        local right_value = self:visit(node.right)
        if type(left_value) == "table" and type(right_value) == "table" then
            local t1 = cjson.encode(left_value)
            local t2 = cjson.encode(right_value)
            return (t1 ~= t2)
        end
        return (left_value ~= right_value)
    end

    if op == AND then -- for shortcut feature
        local left_value = self:visit(node.left)
        if not left_value then
            return left_value
        end
        local right_value = self:visit(node.right)
        return right_value
    end

    if op == OR then -- for shortcut feature
        local left_value = self:visit(node.left)
        if left_value then
            return left_value
        end
        local right_value = self:visit(node.right)
        return right_value
    end

    if (op == GT) or (op == GE) or (op == LT) or (op == LE)  then
        local left_value = self:visit(node.left)
        local right_value = self:visit(node.right)
        if type(left_value) == type(right_value) then
            if type(left_value) == "string" or type(left_value) == 'number' then
                if op == GT then
                    return (left_value > right_value)
                elseif op == GE then
                    return (left_value >= right_value)
                elseif op == LT then
                    return (left_value < right_value)
                elseif op == LE then
                    return (left_value <= right_value)
                end
            else
                self:raise_error("Invalid \'>\' comparision on this value type, expect string type or number type", node, 'op')
            end
        else
            self:raise_error("Invalid comparision between different type", node, 'op')
        end
    end
end
--
function Interpreter:visit_ForLoop( node )
    -- body
    local element = node.element
    local exp = node.exp
    local limit = node.limit
    local offset = node.offset
    local reversed = node.reversed

    exp = self:visit(exp) -- add validation
    if type(exp) ~= "table" then
        exp = {}
    end
    local exp_length = #exp

    local from = 1
    if offset then
        local temp = self:visit(offset)
        local result = tonumber(temp)
        if result == nil or (result % 1 ~= 0)  then
            self:raise_error("in ForLoop, param offset value need to be an int type or int litral string ", node, 'offset_pos')
        end
        from = result + 1
        if from > exp_length then
            from = exp_length
        end
    end

    local to = exp_length
    if limit then
        local temp = self:visit(limit)
        local result = tonumber(temp)
        if result == nil or (result % 1 ~= 0)  then
            self:raise_error("in ForLoop, param limit value need to be an int type or int litral string ", node, 'limit_pos')
        end
        to = from + result - 1
        if to > exp_length then
            to = exp_length
        end
    end

    local output = {}
    if (to - from) >= 0 then
        self.interpretercontext:newframe()
        local step = 1
        if reversed then
            step = -1
            from, to = to, from
        end
        for k = from, to, step do
            self.resourcelimit:check_loopcount()
            self.interpretercontext:define_var(element, exp[k])
            if self.interrupt_flag == true then
                self.interrupt_flag = false
                if self.interrupt_type == BREAK then
                    self.interpretercontext:destroyframe()
                    self.interrupt_type = nil
                    break
                end
                self.interrupt_type = nil
            end
            local result = self:visit(node.nonemptybody)
            if result then
                table.insert(output, result)
            end
        end
        self.interpretercontext:destroyframe()
    else
        local result = self:visit(node.emptybody)
        if result then
            table.insert(output, result)
        end
    end
    if self.interrupt_flag == true then  -- last loop may have 'break/continue'
        self.interrupt_type = nil
        self.interrupt_flag = false
    end
    local result = self:safe_concat(output, '')
    self.resourcelimit:check_length(#result)
    return result
end
--
function Interpreter:visit_TableLoop( node )
    -- body
    local element = node.element
    local exp = node.exp
    local limit = node.limit
    local offset = node.offset
    local cols = node.cols

    exp = self:visit(exp) 
    if type(exp) ~= "table" then
        exp = {}
    end
    local exp_length = #exp

    local from = 1
    if offset then
        local temp = self:visit(offset)
        local result = tonumber(temp)
        if result == nil or (result % 1 ~= 0)  then
            self:raise_error("in TablerowLoop, param offset value need to be an int type or int litral string ", node, 'offset_pos')
        end
        from = result + 1
        if from > exp_length then
            from = exp_length
        end
    end

    local to = exp_length
    if limit then
        local temp = self:visit(limit)
        local result = tonumber(temp)
        if result == nil or (result % 1 ~= 0)  then
            self:raise_error("in TablerowLoop, param limit value need to be an int type or int litral string ", node, 'offset_pos')
        end
        to = from + result - 1
        if to > exp_length then
            to = exp_length
        end
    end

    if cols then
        cols = self:visit(cols)
        if ( cols == 0) or (cols % 1 ~= 0) then
            self:raise_error("in TablerowLoop, param limit cols, expect an int type or int litral string:", node, 'cols_pos')
        end
    else
        cols = exp_length
    end

    local output = {}
    if (to - from) >= 1 then
        self.interpretercontext:newframe()
        local step = 1
        for k = from, to, step do
            self.resourcelimit:check_loopcount()
            self.interpretercontext:define_var(element, exp[k])
            if self.interrupt_flag == true then
                self.interrupt_type = nil
                self.interrupt_flag = false
                if self.interrupt_type == BREAK then
                    self.interpretercontext:destroyframe()
                    break
                end
            end
            local index = k - from + 1
            local temp_cols_num = index % cols
            local temp_row_num = (index - temp_cols_num) / cols + 1
            local tr_str = nil
            if temp_cols_num == 1 then
                local tr_str = "<tr class=\"row" .. temp_row_num .. "\">"
                table.insert(output, tr_str)
            end
            if temp_cols_num == 0 then
                temp_cols_num = cols
            end
            local td_str = "<td class=\"col".. temp_cols_num .."\">"
            table.insert(output, td_str)
            local result = self:visit(node.blockbody)
            if result then
                table.insert(output, result)
            end
            table.insert(output, "</td>")
            if temp_cols_num == cols or k == to then
                table.insert(output, "</tr>")
            end
        end
        self.interpretercontext:destroyframe()
    else
        local result = self:visit(node.emptybody)
        if result then
            table.insert(output, result)
        end
    end
    if self.interrupt_flag == true then  -- last loop may have 'break/continue'
        self.interrupt_type = nil
        self.interrupt_flag = false
    end
    local result = self:safe_concat(output, '\n')
    self.resourcelimit:check_length(#result)
    return result
end
--
function Interpreter:visit_Field( node )
    -- body
    if node.var == nil then
        return self.interpretercontext:find_var(self:visit(node.field))
    else
        local var = self:visit(node.var)
        local field = self:visit(node.field)
        if type(var) == "table" and ( field ~= nil )then
            if type(field) == "number" then
                return var[(field + 1)]
            else
                return var[field]
            end
        else
            return nil
        end
    end
end
--
function Interpreter:visit_Filter( node)
    -- body
    local filter_name = node.filter_name
    local filter = self.filterset:find_filter(filter_name)
    if filter == nil then
        self:raise_error("cannot find filter: " .. node.filter_name, node, 'filter_name')
    end

    local params = {}
    for i,v in ipairs(node.params) do
        table.insert(params, self:visit(v))
    end
    local status, err = pcall(filter, table.unpack(params))
    if status then
        return err
    else
        self:raise_error("filter invoke fails", node, 'filter_name')
    end
end
--
function Interpreter:visit_Partial( node )
    -- body
    self.resourcelimit:check_subtemplate_num()
    local filesystem = self.filesystem
    local t = node.parser_context
    local location = self:visit(node.location)
    local file = filesystem:generic_get(location)
    local lexer = Lexer:new(file)
    local parser = Parser:new(lexer, node.parser_context)
    local context = self.interpretercontext
    context:newframe()
    if node.interpretercontext then
        local temp = self:visit(node.interpretercontext)
        if type(temp) == "table" then
            for k,v in pairs(temp) do
                context:define_var(k, v)
            end
        else
            self:raise_error("Invalid Interpreter Context in INCLUDE tag", node, 'include_pos')
        end
    end
    local interpreter = Interpreter:new(parser)
    local result = interpreter:interpret(context, self.filterset, self.resourcelimit, self.filesystem)
    context:destroyframe()
    self.resourcelimit:check_length(#result)
    return result
end
--
function Interpreter:visit_CycleLoop( node )
    -- body
    local group_name = node.group_name
    if group_name then
        group_name = self:visit(group_name)
    end
    local length = #(node.elementarray)
    local cycle_value = {}
    for i,v in ipairs(node.elementarray) do
        table.insert(cycle_value, self:visit(v))
    end
    local obj = {["_group_name"] = group_name, ["_cycle_value"] = cycle_value}
    -- get json string as index
    local index = cjson.encode(obj)
    local result = self.interpretercontext:find_var(index) -- array(table) index
    if result and type(result) == "number" then
        result = (result + 1) % length
        if result == 0 then
            result = result + 1
        end
        self.interpretercontext:define_var(index, result, 1)
        local t = self:obj2str(cycle_value[result])
        if t then
            return t
        else
            self:raise_error(" CycleLoop please manually convert table to string, index:" .. result, node, 'pos')
        end
    elseif result == nil then
        result = 1
        self.interpretercontext:define_var(index, result, 1)
        local t = self:obj2str(cycle_value[result])
        if t then
            return t
        else
            self:raise_error(" CycleLoop please manually convert table to string, index:" .. result, node, 'pos')
        end
    end
end
--
function Interpreter:visit_Assignment( node )
    -- body
    local id = node.id
    local value = self:visit(node.exp)
    self.interpretercontext:define_var(id, value, 1)
end
--
function Interpreter:visit_IncDec( node)
    local inc_dec_context = self.interpretercontext:find_var(IncDec)  --is this buggy if using IncDec as key?
    if inc_dec_context then
        local result = inc_dec_context:find_var(node.id)
        if not result then
            result = 0
        else
            if node.op_type == INCREMENT then
                result = result + 1
            elseif node.op_type == DECREMENT then
                result = result - 1
            end
        end
        inc_dec_context:define_var(node.id, result, 1)
        return result
    else
        local result = 0
        inc_dec_context = InterpreterContext:new({})
        inc_dec_context:define_var(node.id, result, 1)
        self.interpretercontext:define_var(IncDec, inc_dec_context, 1)
        return result
    end
end
-------------------------------------------------------------Interpreter end---------------------------------------------------------

-------------------------------------------------------------InterpreterContext begin ---------------------------------------------------------
-- local InterpreterContext = {}
function InterpreterContext:new( context )
    -- body
    local instance = {}
    setmetatable(instance, {__index = InterpreterContext})
    instance.stackframe = {}
    if type(context) ~= "table" then
        error("Initilied fail! context should be a table type ")
    end
    table.insert(instance.stackframe, context)
    return instance
end
--
function InterpreterContext:define_var( name, value, stack_level)
    -- body
    if not stack_level then
        stack_level = #(self.stackframe)
    elseif not type(stack_level) == "number" then
        error(" stack_level should be a number type")
    end
    local context = self.stackframe[stack_level]
    if type(context) ~= "table" then
        error("Invalid stackframe! ")
    end
    context[name] = value
end
--
function InterpreterContext:find_var( name )
    -- body
    if name == nil then
        error("Invalid var name")
    end

    -- Just returns the full context if the value if self.
    if name == "self" then
        return self.stackframe
    end

    local value = nil
    local length = #(self.stackframe)
    local step = -1
    for i = length, 1, step do
        value = self.stackframe[i][name]
        if value then break end
    end
    return value
end
--
function InterpreterContext:newframe( ... )
    -- body
    table.insert(self.stackframe, {})
end
--
function InterpreterContext:destroyframe( ... )
    -- body
    local length = #(self.stackframe)
    if length == 0 then
        error("Invalid stackframe")
    elseif length > 1 then
        table.remove(self.stackframe)
    end
end
-------------------------------------------------------------InterpreterContext end ---------------------------------------------------------
-------------------------------------------------------------ParserContext begin ---------------------------------------------------------
-- local ParserContext = {}
function ParserContext:new( ... )
    local instance = {}
    setmetatable(instance, {__index = ParserContext})
    instance.whitespace_lstrip_flag = false
    instance.whitespace_rstrip_flag = false
    return instance
end
-------------------------------------------------------------ParserContext end ---------------------------------------------------------
-------------------------------------------------------------FileSystem begin ---------------------------------------------------------
-- local FileSystem = {}
function FileSystem:new( get, error_handler )
    -- body
    local instance = {}
    setmetatable(instance, {__index = FileSystem})
    instance.get = get
    instance.text = nil
    instance.error_handler = error_handler
    return instance
end
--
function FileSystem:generic_get( location )
    local error_handler = self.error_handler
    -- body
    if self.get and type(self.get) == "function" then
        local ok, ret = pcall(self.get, location)

        if ok and ret then
            return tostring(ret)
        elseif ok then
            return error_handler(location, "cannot render empty template" )
        else
            return error_handler(location, ret)
        end
    else
        return error_handler(location, "method to get template file is not defined !!")
    end
end
--
function FileSystem.error_handler(location, err)
    return error(string.format("error when getting template %q: %s", location, err))
end
-------------------------------------------------------------FileSystem end ---------------------------------------------------------
-------------------------------------------------------------Lazy begin ---------------------------------------------------------
-- local Lazy = {}
function Lazy:new( obj, fields )
    -- body
    local instance = {}
    instance.obj = obj
    instance.fields = fields or {}
    instance.flags = {}
    setmetatable(instance, {
        __index = function ( t, k )
            -- body
            local temp = t.obj[k]
            if type(temp) == "function" then
                if t.fields[k] == true then
                    if t.flags[k] then
                        return temp
                    else
                        t.flags[k] = true
                        local result = temp()
                        t.obj[k] = result
                        return result
                    end
                elseif t.fields[k] == false then
                    return temp()
                else
                    return nil
                end
            else
                return temp
            end
        end
        }
    )
    return instance
end
--
-- local ResourceLimit = {}
function ResourceLimit:new( length_limit, subtemplate_num, loopcount )
    -- body
    local instance = {}
    setmetatable(instance,{ __index = ResourceLimit})
    instance.length_limit = length_limit or 100000
    instance.subtemplate_num_limit = subtemplate_num or 10
    instance.loopcount_limit = loopcount or 50000
    instance.length = 0
    instance.subtemplate_num = 0
    instance.loopcount = 0
    return instance
end
--
function ResourceLimit:check_length( num )
    -- body
    self.length = self.length + num
    if self.length + num > self.length_limit then
        error("document fails length limit. length limit:" .. self.length_limit)
    end
end
--
function ResourceLimit:check_subtemplate_num( )
    -- body
    self.subtemplate_num = self.subtemplate_num  + 1
    if self.subtemplate_num > self.subtemplate_num_limit then
        error("too many sub template. limit num:" .. self.subtemplate_num_limit)
    end
end
--
function ResourceLimit:check_loopcount( ) -- inline this function  for better performance?
    -- body
    self.loopcount = self.loopcount  + 1
    if self.loopcount > self.loopcount_limit then
        error("too many loopcount. limit num:" .. self.loopcount_limit)
    end
end
-------------------------------------------------------------Lazy end ---------------------------------------------------------
-------------------------------------------------------------Nodetab end ---------------------------------------------------------
-- local Nodetab = {}
function Nodetab:new( ... )
    -- body
    local instance = {}
    setmetatable(instance, {__index = Nodetab})
    instance.locations ={}
    return instance
end
function Nodetab:set_pos( k, v )
    -- body
    self.locations[k] = v
end
function Nodetab:get_pos( k )
    -- body
    return self.locations[k]
end
-------------------------------------------------------------Nodetab end ---------------------------------------------------------
------------------------------------------------------------- friendly interface begin ---------------------------------------------------------
local Template = {}
function Template:parse( text , parser_context)
    -- body
    local instance = {}
    setmetatable(instance, {__index = Template})
    instance.lexer = Lexer:new(text)
    instance.parser = Parser:new(instance.lexer, parser_context)
    instance.interpreter = Interpreter:new(instance.parser)
    return instance
end
function Template:render( context, filterset, resourcelimit, filesystem )
    -- body
    local t_interpretercontext = context or InterpreterContext:new({})
    local t_filterset = filterset or FilterSet:new()
    local t_resourcelimit = resourcelimit or ResourceLimit:new()
    local t_filesystem = filesystem or FileSystem:new()

    return self.interpreter:interpret( t_interpretercontext, t_filterset, t_resourcelimit, t_filesystem )
end
------------------------------------------------------------- friendly interface end ---------------------------------------------------------
------------------------------------------------------------- helper methods begin ---------------------------------------------------------
function string:lstrip( ... )
    local ws = [[(\A\s*)]]
    return ngx.re.sub(self, ws, '')
end
--
function string:rstrip( ... )
    local ws = [[(\s*\z)]]
    return ngx.re.sub(self, ws, '')
end

do
    local empty_t = {}
    local function mt__tostring(obj)
        return (getmetatable(obj) or empty_t).__tostring
    end

    function Interpreter:obj2str( obj )
        -- body
        local obj_type = type(obj)
        if obj_type == "nil" then
            return ''
        elseif obj_type == "number" then
            return tostring(obj)
        elseif obj_type == "string" then
            return obj
        elseif obj_type == "boolean" then
            return tostring(obj)
        elseif type(mt__tostring(obj)) == 'function' then
            return tostring(obj) or ''
        end
    end

    function Interpreter:safe_concat(t, d)
        local tmp = {}

        -- string keys are ignored by concat anyway
        for i,v in ipairs(t) do
            tmp[i] = Interpreter:obj2str(v)
        end

        return table.concat(tmp, d)
    end
end
------------------------------------------------------------- helper methods end ---------------------------------------------------------
-------------------------------------------------------------FilterSet begin ---------------------------------------------------------
-- local FilterSet = {}
FilterSet.filterset = {}
--
function FilterSet:new( ... )
    local instance = {}
    setmetatable(instance, {__index = FilterSet})
    instance.filterset = {}
    for k,v in pairs(self.filterset) do
        instance.filterset[k] = v
    end
    return instance
end
--
function FilterSet:add_filter( filter_name, filter_function )
    if type(filter_name) == 'string' and type(filter_function) == 'function' then
        self.filterset[filter_name] = filter_function
    end
end
--

--
function FilterSet:remove_filter( filter_name )
    if type(filter_name) == 'string' then
        self.filterset[filter_name] = nil
    end
end
--
function FilterSet:find_filter( filter_name )
    if type(filter_name) == 'string' then
       return self.filterset[filter_name]
    end
end

local function is_iterator(o)
    local mt = getmetatable(o)

    return mt and mt.__ipairs
end

local function iterator(o)
    if type(o) == 'table' or is_iterator(o) then
        return o
    else
        return { o }
    end
end

--=== array filter begin
local function join( a, b)
    -- body
    return Interpreter:safe_concat(iterator(a), b or ' ')
end
local function first( a )
    -- body
    return iterator(a)[1]
end
local function size( a )
    -- body
    return(#iterator(a))
end
local function last( a )
    -- body
    return iterator(a)[size(a)]
end
local function concat( a, b)
    -- body
    local temp = {}
    for i,v in ipairs(iterator(a)) do
        table.insert(temp, v)
    end
    for i,v in ipairs(iterator(b)) do
        table.insert(temp, v)
    end
    return temp
end
local function index( a, b)
    -- body
    return iterator(a)[(b + 1)]
end
local function map( a, map_field)
    -- body
    local temp = {}
    for i,v in ipairs(a) do
        table.insert(temp, v[map_field])
    end
    return join(temp, '')
end
local function reverse( a )
    -- body
    local temp = {}
    local it = iterator(a)
    local num = size(a)
    for k = num, 1, -1 do
        table.insert(temp, it[k])
    end
    return temp
end

local function sort( a, sort_field)
    -- body
    local t = {}
    for i,v in ipairs(iterator(a)) do
        table.insert(t, v)
    end
    if not sort_field then
        table.sort(t)
        return t
    else
        table.sort( t, 
            function ( e1, e2 ) return (e1[sort_field] < e2[sort_field]) end )
        return t
    end
end
local function uniq( a )
    -- body
    local t = {}
    local result = {}
    for i,v in ipairs(iterator(a)) do
        local k = cjson.encode(v)
        if not t[k] then
            t[k] = true
            table.insert(result, v)
        end
    end
    return result
end
--=== array filter end
--=== math filter begin
local abs = math.abs
local ceil = math.ceil
local function divided_by( a, b )
    if tonumber(b) == 0 then
        error(" cannot dived by zero")
    end
    return( a / b )
end
local floor = math.floor
local function minus( a, b )
    return( a - b)
end
local function plus( a, b )
    return( a + b)
end
local function round( a, b )
    local mult = 10^(b or 0)
    return math.floor(a*mult + 0.5 ) / mult
end
local function times( a, b )
    -- body
    return (a * b)
end
local function modulo( a, b )
    -- body
    return (a % b)
end
--=== math filter end

--=== String filter begin
local function append( str1, str2 )
    -- body
    return (str1 .. str2)
end
local function capitalize( str )
    -- body
    return string.gsub(str,"^%l", string.upper)
end
local function downcase( str )
    -- body
    return string.lower(str)
end
local function escape( str )
    -- body
    local html = {
        ["<"] = "&lt;",
        [">"] = "&gt;",
        ["&"] = "&amp;",
        ["\'"] = "&#039;",
        ["\""] = "&quot;"
    }
    return string.gsub(tostring(str), "[\'\"<>&]", function(char)
        return html[char] or char
    end)
end
local function newline_to_br( str )
    -- body
    return string.gsub(str, '\n', '<br />')
end
local function prepend( str, str_prepend )
    -- body
    return (str_prepend .. str)
end
local function remove( str , pattern)
    -- body
    return string.gsub(str, pattern, '')
end
local function remove_first( str, pattern)
    -- body
    return string.gsub(str, pattern,'', 1)
end
local function replace( str, pattern, str_replace )
    -- body
    return string.gsub(str, pattern, str_replace)
end
local function replace_first( str, pattern, str_replace  )
    -- body
    return string.gsub(str, pattern, str_replace, 1)
end
local function slice( str, from, to )
    -- body
    return string.sub(str,from + 1, to +1)
end
local function split( str, pattern )
    -- body
    local result = {}
    local index = 1
    repeat
        local from, to = string.find( str, pattern, index)
        if from then
            if from > index then
                table.insert(result, string.sub(str, index, from-1))
            else
                table.insert(result, string.sub(str, index, index))
            end
            if to > from then
                index = to + 1
            else
                index = from + 1
            end
        end
    until from == nil
    if index < #str then
        table.insert(result, string.sub(str, index))
    end
    return result
end
local function strip( str )
    -- body
    return str:lstrip():rstrip()
end
local function lstrip( str )
    -- body
    return str:lstrip()
end
local function rstrip( str )
    -- body
    return str:rstrip()
end
local function strip_newlines( str )
    -- body
    return string.gsub(str, '\n', '')
end
local function upcase( str )
    -- body
    return string.upper(str)
end
local function url_encode( str )
    -- body
    local str1 = string.gsub (str, "\n", "\r\n")
    local str2 = string.gsub (str1, "([^%w ])",
        function (c)
            local except = {['$'] = true,['-'] = true,['_'] = true,['.'] = true,['+'] = true,['!'] = true,
                            ['*'] = true,['\''] = true,['('] = true,[')'] = true,[','] = true }
            if except[c] then
                return c
            else
                return string.format ("%%%02X", string.byte(c))
            end
        end)
    local str3 = string.gsub (str2, " ", "+")
    return str3
end
local function url_decode( str )
    -- body
    local str1 = string.gsub (str, "%%(%x%x)",
        function (c) return string. char(tonumber(c, 16)) end)
    return str1
end
local function str_reverse( str )
    -- body
    return string.reverse(str)
end
--=== String filter end
--=== Additional filter begin
local function json( obj )
    -- body
    return cjson.encode(obj)
end


local function get(obj, key)
    return obj[key]
end

--=== Additional filter end



--========================================================== add filers to FilterSet instance================================
--Array filter 
FilterSet:add_filter("join", join )
FilterSet:add_filter("first", first )
FilterSet:add_filter("last", last )
FilterSet:add_filter("concat", concat )
FilterSet:add_filter("index", index )
FilterSet:add_filter("map", map )
FilterSet:add_filter("reverse", reverse )
FilterSet:add_filter("size", size )
FilterSet:add_filter("sort", sort )
FilterSet:add_filter("uniq", uniq )
--Math filter
FilterSet:add_filter("abs", abs )
FilterSet:add_filter("ceil", ceil )
FilterSet:add_filter("divided_by", divided_by )
FilterSet:add_filter("floor", floor )
FilterSet:add_filter("minus", minus )
FilterSet:add_filter("plus", plus )
FilterSet:add_filter("round", round )
FilterSet:add_filter("times", times )
FilterSet:add_filter("modulo", modulo )
--String filter
FilterSet:add_filter("append", append )
FilterSet:add_filter("capitalize", capitalize )
FilterSet:add_filter("downcase", downcase )
FilterSet:add_filter("escape", escape )
FilterSet:add_filter("prepend", prepend )
FilterSet:add_filter("remove", remove )
FilterSet:add_filter("remove_first", remove_first )
FilterSet:add_filter("replace", replace )
FilterSet:add_filter("replace_first", replace_first )
FilterSet:add_filter("slice", slice )
FilterSet:add_filter("split", split )
FilterSet:add_filter("strip", strip )
FilterSet:add_filter("lstrip", lstrip )
FilterSet:add_filter("rstrip", rstrip )
FilterSet:add_filter("strip_newlines", strip_newlines )
FilterSet:add_filter("upcase", upcase )
FilterSet:add_filter("url_encode", url_encode )
FilterSet:add_filter("url_decode", url_decode )
FilterSet:add_filter("str_reverse", str_reverse )

--Additinal filter
FilterSet:add_filter("json", json )
FilterSet:add_filter("get", get)






-------------------------------------------------------------Filter end ---------------------------------------------------------
-- local Liquid = {}
Liquid.Lexer = Lexer
Liquid.Parser = Parser
Liquid.Interpreter = Interpreter
Liquid.InterpreterContext = InterpreterContext
Liquid.FilterSet = FilterSet
Liquid.ResourceLimit = ResourceLimit
Liquid.FileSystem = FileSystem
Liquid.ParserContext = ParserContext
Liquid.Lazy = Lazy
Liquid.Template = Template
return Liquid
