require 'faraday'
require 'faraday_middleware'
require 'multi_json'

require_relative './models'

changes = []

Dir['./*.json'].each do |fn|
  name = File.basename(fn, '.json')
  ver = File.mtime(fn).to_i
  rule = Rule.where(name: name).first
  attrs = { name: name, version: ver, content: MultiJson.decode(File.read(fn)) }
  puts "# processing #{fn}"
  if rule && rule.version != ver
    puts "# updating"
    rule.update_attributes(attrs)
    changes << rule
  elsif !rule
    puts "# creating"
    changes << Rule.create(attrs)
  else
    puts "# nothing"
  end
end

changes.each do |rule|
  url = ENV.fetch('TATEV_REGISTRY_URL', 'http://localhost:3000')
  conn = Faraday.new(url) do |f|
    f.request(:url_encoded)
    f.request(:json)
    f.response(:json, :content_type => /\bjson$/)
    f.adapter(Faraday.default_adapter)        
  end

  puts "> #{url}/api/v1/rules/#{rule.name}/#{rule.version}"
  resp = conn.put("/api/v1/rules/#{rule.name}", rule: { version: rule.version })
  puts "< #{resp.status}"
end
