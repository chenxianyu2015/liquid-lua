require 'pathname'
require 'openssl'
require 'open-uri'

task :release, :tag do |_, args|
  tag = args[:tag] or fail 'no tag'

  last_rockspec_file = Pathname(Dir['rockspecs/*.rockspec'].grep_v(/scm/).sort.last)

  rockspec = last_rockspec_file.read

  version = rockspec.match(/version = "(.+?)-\d+"/)[1]

  rockspec.gsub!(version, tag)

  url = URI(rockspec.match(/url = "(.+?)"/)[1])
  md5 = rockspec.match(/md5 = "(.+?)"/)[1]

  rockspec.gsub!(md5, OpenSSL::Digest::MD5.hexdigest(open(url).read))

  last_rockspec_file.sub(version, tag).tap do |file|
    file.write(rockspec)
    puts file
  end

end