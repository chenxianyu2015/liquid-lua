use Test::Nginx::Socket 'no_plan';

run_tests();

__DATA__

=== TEST 1: pcall test
This is just a simple demonstration of the
echo directive provided by ngx_http_echo_module.
--- config
location = /t {
    content_by_lua_block {
    		local function pcall_call_test ( ... )
        	return true
        end
        ngx.update_time()
        local from = ngx.now()
        for k =1,10000000 do
           pcall(pcall_call_test)  -- pcall
        end
        ngx.update_time()
        local to = ngx.now()
        local result1 = to - from

        ngx.update_time()
        local from = ngx.now()
        for k =1,10000000 do
           pcall_call_test()      --call
        end
        ngx.update_time()
        local to = ngx.now()
        local result2 = to - from
        local num = result1/result2
        if num > 10 then
            ngx.say("call is faster than pcall 10 times")
        else
            ngx.say("call is not faster than pcall 10 times")
        end
    }
}
--- request
GET /t
--- response_body
call is faster than pcall 10 times
--- error_code: 200

