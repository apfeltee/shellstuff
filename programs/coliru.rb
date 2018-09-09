#!/usr/bin/ruby

=begin
note: coliru has a better API now: https://docs.google.com/document/d/18md3rLdgD9f5Wro3i7YYopJBFb_6MPCO8-0ihtxHoyM/edit

i.e.,
curl http://coliru.stacked-crooked.com/compile -d '{"cmd": "g++-4.8 main.cpp && ./a.out", "src": "#include <iostream>\nint main(){    std::cout << \"Hello World!\" << std::endl;}"}'

=end

require 'json'
require 'pp'
require 'net/http'

def shell(*args, &callback)
  Open3.popen3(*args) do |stdin, stdout, stderr|
    if callback then
      callback.call(stdin, stdout, stderr)
    end
  end
end

def post_to_url(url, data, extraheaders=nil)
  headers =
  {
    'User-Agent'   => 'User-Agent: Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko)',
  }
  if extraheaders != nil then
    extraheaders.each do |key, value|
      headers[key] = value
    end
  end
  uri = URI.parse(url)
  http = Net::HTTP.new(uri.host, uri.port)
  #http.use_ssl = true
  request = Net::HTTP::Post.new(uri.path, headers)
  request.body = data
  response = http.request(request)
  return response
end

def post_coliru(data)
  return post_to_url(
    "http://coliru.stacked-crooked.com/compile",
    data,
    {
      'Content-Type' => 'text/plain;charset=UTF-8',
      'Origin'       => 'http://coliru.stacked-crooked.com/',
      'Referer'      => 'http://coliru.stacked-crooked.com/',
    }
  )
end

cmd = ARGV.join(" ")
src = $stdin.read
data = {cmd: cmd, src: src}.to_json
#pp data
res = post_coliru(data)
pp res
#puts res.body

