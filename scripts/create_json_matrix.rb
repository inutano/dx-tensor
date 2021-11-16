#!/usr/bin/env ruby
require 'json'

if __FILE__ == $0
  link_json_path = ARGV[0]
  link_json = JSON.load(open(link_json_path))

  nodes = link_json["nodes"].map.with_object({}){|n, obj| obj[n["id"]] = { label: n["label"], category: n["category"] } }
  p nodes
end
