#! /usr/bin/env ruby

$stdout.sync = true

require 'rexml/document'

all_file = File.new('all.xsd', 'w+')
all_file << "<?xml version='1.0' encoding='UTF-8'?>\n"
all_file << "<xs:schema xmlns:xs='http://www.w3.org/2001/XMLSchema'>\n\n"

errors = {}
Dir.glob('xsf/schemas/*.xsd') do |schema_file_name|
  begin
    schema = REXML::Document.new( File.new(schema_file_name) )

    # Patch schema to import local files
    patched = false
    schema.elements.each('xs:schema/xs:import') do |element|
      location = element.attributes['schemaLocation']
      original_location = location.dup

      (location['http://xmpp.org/schemas/'] = '') rescue nil
      (location['http://www.w3.org'] = '../../w3c') rescue nil
      patched = (location != original_location)
    end
    File.new(schema_file_name, 'w+') << schema if patched

    # Add this schema to all.xsd
    ns = schema.elements['xs:schema'].attributes['xmlns']
    all_file << "\t<xs:import namespace='#{ns}'\n"
    all_file << "\t\tschemaLocation='#{schema_file_name}'/>\n\n"
    print '.'
  rescue => e
    errors[schema_file_name] = e
    print 'F'
  end
end

all_file << "</xs:schema>\n"
all_file.close
puts ' Done!'

errors.sort.each do |schema_file_name, error|
  puts "#{schema_file_name}:", error.message, "\n----------------\n\n"
end
