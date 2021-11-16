#!/usr/bin/env ruby
require 'json'
require 'csv'

if __FILE__ == $0
  link_json_path = ARGV[0]
  link_json = JSON.load(open(link_json_path))

  # Returns a hash like { "1" => {:label => "uniprot", :category => "protein"}, ... }
  nodes = link_json["nodes"].map.with_object({}) do |node, hash|
    hash[node["id"]] = {
      label: node["label"],
      category: node["category"],
    }
  end

  # Returns a hash like { "1" => {"2" => { :count => 1000, :source_count => 2000, :target_count => 4000 }, ... }, ... }
  edges = link_json["edges"].each_with_object({}) do |edge, hash|
    hash[edge["source"]] ||= {}
    hash[edge["source"]][edge["target"]] = {
      count: edge["count"],
      source_count: edge["source_count"],
      target_count: edge["target_count"],
    }
  end

  rows = nodes.map do |source_id, source_prop|
    row_values = nodes.map do |target_id, target_prop|
      if source_id != target_id
        edge_start = edges[source_id]
        if edge_start
          edge = edge_start[target_id]
          if edge
            edge[:count]
          end
        end
      end
    end

    CSV::Row.new(
      ["labels", nodes.map{|id, prop| prop[:label] }].flatten, # Array of header labels
      [source_prop[:label], row_values].flatten # Array of row values
    )
  end
  puts CSV::Table.new(rows).to_csv(col_sep: "\t")
end
