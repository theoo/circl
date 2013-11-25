require 'yaml'

module Comparator

  def compare_branch(locales, nodes, path)
    h1 = nodes[locales[0]]
    h2 = nodes[locales[1]]

    k1 = h1.keys
    k2 = h2.keys

    common = k1 and k2
    d2 = k2 - common
    d1 = k1 - common

    # check differences both ways and print them
    # if a key only exists in k2 then it is missing in k1, this is why
    # d1 and d2 are reversed here, to match the corresponding locale.
    [d2,  d1].each_with_index do |d,i|
      d.each do |missing_key|
        # Reversed index
        puts locales[i].to_s + [path, missing_key].join(".")
      end
    end

    # dig into common keys
    common.each do |n|
      if h1[n].is_a? Hash and h2[n].is_a? Hash
        compare_branch(
          locales,
          {locales[0] => h1[n], locales[1] => h2[n]},
          [path,n].join("."))
      else
        # if not both keys are hashes, extract which one is a string...
        locale = h1[n].is_a?(String) ? locales[0] : locales[1]
        puts locale.to_s + [path, n].join(".")
      end
    end

  end

  def compare_translations(locale1, locale2)
    # load yamls
    path = Rails.root.to_s + "/config/locales/#{locale1}/*.yml"
    FileList[path].each do |filename|
      h1 = YAML.load_file filename
      filename2 = filename.gsub(/\/#{locale1}\//, "/#{locale2}/")
      if File.exists? filename2
        h2 = YAML.load_file filename2
      else
        raise ArgumentError, "File #{filename} exists but #{filename2} doesn't exists."
      end

      puts "Comparing\t#{filename}\nand\t\t #{filename2}"
      compare_branch(
        [locale1, locale2],
        {locale1 => h1[locale1.to_s], locale2 => h2[locale2.to_s]},
        "")

    end
  end

end

namespace :i18n do
  desc 'Compare translation trees between all available locales'
  task :compare_translation_trees => :environment do
    include Comparator
    # TODO cross compare all available locales. Currently only two are compared

    locales = I18n.available_locales

    puts "Missing keys are:"
    compare_translations(locales[0], locales[1])
  end

end


