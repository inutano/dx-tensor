#!/usr/bin/env ruby
require 'json'
require 'csv'

if __FILE__ == $0
  mode = ARGV[0]
  link_json_path = ARGV[1]
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

  case mode
  when '--dataset'
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
        ["dataset", nodes.map{|id, prop| prop[:label] }].flatten, # Array of header labels
        [source_prop[:label], row_values].flatten # Array of row values
      )
    end
    puts CSV::Table.new(rows).to_csv(col_sep: "\t")

  when '--category'
    category_edges = edges.each_with_object({}) do |(edge_source_id, edge_target_hash), hash|
      edge_source_category = nodes[edge_source_id][:category]
      hash[edge_source_category] ||= {}

      edge_target_hash.each_pair do |edge_target_id, edge_prop|
        edge_target_category = nodes[edge_target_id][:category]
        counts = hash[edge_source_category][edge_target_category]
        if counts
          hash[edge_source_category][edge_target_category] = counts.to_i + edge_prop[:count].to_i
        else
          hash[edge_source_category][edge_target_category] = edge_prop[:count].to_i
        end
      end
    end

    categories = nodes.map{|id, prop| prop[:category] }.uniq
    rows = categories.map do |source_category|
      row_values = categories.map do |target_category|
        if category_edges[source_category]
          edge_start = category_edges[source_category]
          if edge_start
            edge = edge_start[target_category]
            if edge
              edge
            end
          end
        end
      end
      CSV::Row.new(
        ["category", categories].flatten, # Array of header labels
        [source_category, row_values].flatten # Array of row values
      )
    end
    puts CSV::Table.new(rows).to_csv(col_sep: "\t")

  end
end
