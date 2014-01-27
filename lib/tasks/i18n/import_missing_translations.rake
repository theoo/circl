require 'yaml'

module Translator
  PATHS = %w(app lib public)
  EXTENSIONS = %w(haml hamlc rb erb coffee)
  PATTERN = /I18n\.t\(['"]([^'"]*?)['"]/

  #IDEA: flatten to i18n scope in an array and arr1&arr2 or arr1-arr2
  #FIXME handle defaults (:default => "blabla")
  #FIXME don't .humanize for != en

  def returning(value)
    yield(value)
    value
  end

  def convert_hash_to_ordered_hash_and_sort(object, deep = false)
    if object.is_a?(Hash)
      res = returning(Hash.new) do |map|
        object.each {|k, v| map[k] = deep ? convert_hash_to_ordered_hash_and_sort(v, deep) : v }
      end
      return res.class[res.sort {|a, b| a[0].to_s <=> b[0].to_s } ]
    elsif deep && object.is_a?(Array)
      array = Array.new
      object.each_with_index {|v, i| array[i] = convert_hash_to_ordered_hash_and_sort(v, deep) }
      return array
    else
      return object
    end
  end

  def handle_entity(scope, values)
    I18n.available_locales.each do |lang|
      lang = lang.to_s
      hash = { lang => { scope => values } }

      filename = "config/locales/#{lang}/#{scope}.yml"
      if File.exists?(filename)
        existing = YAML.load_file(filename)
        hash.deep_merge!(existing)
      end

      hash = convert_hash_to_ordered_hash_and_sort(hash, true)

      File.open(filename, 'w') do |f|
        f << YAML.dump(hash, :line_width => 999999)
      end
    end
  end

  def i18n_scope_to_hash(scope)
    #ary = scope.split('.').reverse
    #hsh = {ary.shift => default}
    #hsh = {ary.shift => hsh} until ary.empty?
    #hsh
    h = {}
    tokens = scope.split('.')
    h[tokens.first] = (tokens.size > 1) ? i18n_scope_to_hash(tokens[1..-1].join('.')) : "MISSING_TRANSLATION " + tokens.first.humanize.downcase
    h
  end
end

namespace :i18n do
  desc 'import translations'
  task :import_missing_translations => :environment do
    include Translator

    paths = PATHS.each_with_object([]) do |path, arr|
      EXTENSIONS.each do |ext|
        arr << "#{path}/**/*.#{ext}"
      end
    end

    hashes = FileList[*paths].each_with_object({}) do |filename, h|
      File.read(filename).scan(PATTERN) do |scopes|
        scopes.each do |scope|
          h.deep_merge!(i18n_scope_to_hash(scope))
        end
      end
      h
    end

    hashes.each do |entity, values|
      handle_entity(entity, values)
    end
  end
end
