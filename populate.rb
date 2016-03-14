require 'multi_json'
require_relative './models'

Dir['./*.json'].each do |fn|
  name = File.basename(fn, '.json')
  ver = File.mtime(fn).to_i
  rule = Rule.where(name: name).first
  attrs = { name: name, version: ver, content: MultiJson.decode(File.read(fn)) }
  puts "# processing #{fn}"
  if rule && rule.version != ver
    puts "# updating"
    rule.update_attributes(attrs)
  elsif !rule
    puts "# creating"
    Rule.create(attrs)
  else
    puts "# nothing"
  end
end
