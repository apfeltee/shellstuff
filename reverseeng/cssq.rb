#!/usr/bin/ruby

## similar to the 'nokogiri' exe itself, BUTT!
## prints queried nodes in an arguably more user-friendly way.
## nokogiri's default mode is, frankly, a mess.

require "pp"
require "ostruct"
require "optparse"
require "json"
require "nokogiri"

=begin
Nokogiri::XML(File.read("default_levels.xml")).css("prop[n]").each do |elem|
  puts elem.attributes["n"].value
end

=end

=begin
%(*args)                                        Nokogiri::XML::Element (Nokogiri::XML::Searchable)
/(*args)                                        Nokogiri::XML::Element (Nokogiri::XML::Searchable)
<<(node_or_tags)                                 Nokogiri::XML::Element (Nokogiri::XML::Node)
[](name)                                         Nokogiri::XML::Element (Nokogiri::XML::Node)
[]=(name, value)                                  Nokogiri::XML::Element (Nokogiri::XML::Node)
accept(visitor)                                      Nokogiri::XML::Element (Nokogiri::XML::Node)
add_child(node_or_tags)                                 Nokogiri::XML::Element (Nokogiri::XML::Node)
add_namespace(arg1, arg2)                                   Nokogiri::XML::Element (Nokogiri::XML::Node)
add_namespace_definition(arg1, arg2)                                   Nokogiri::XML::Element (Nokogiri::XML::Node)
add_next_sibling(node_or_tags)                                 Nokogiri::XML::Element (Nokogiri::XML::Node)
add_previous_sibling(node_or_tags)                                 Nokogiri::XML::Element (Nokogiri::XML::Node)
after(node_or_tags)                                 Nokogiri::XML::Element (Nokogiri::XML::Node)
all?()                                             Nokogiri::XML::Element (Enumerable)
any?()                                             Nokogiri::XML::Element (Enumerable)
at(*args)                                        Nokogiri::XML::Element (Nokogiri::XML::Searchable)
at_css(*args)                                        Nokogiri::XML::Element (Nokogiri::XML::Searchable)
at_xpath(*args)                                        Nokogiri::XML::Element (Nokogiri::XML::Searchable)
attr(name)                                         Nokogiri::XML::Element (Nokogiri::XML::Node)
attribute(arg1)                                         Nokogiri::XML::Element (Nokogiri::XML::Node)
attribute_nodes()                                             Nokogiri::XML::Element (Nokogiri::XML::Node)
attribute_with_ns(arg1, arg2)                                   Nokogiri::XML::Element (Nokogiri::XML::Node)
attributes()                                             Nokogiri::XML::Element (Nokogiri::XML::Node)
before(node_or_tags)                                 Nokogiri::XML::Element (Nokogiri::XML::Node)
blank?()                                             Nokogiri::XML::Element (Nokogiri::XML::Node)
canonicalize(*mode, *inclusive_namespaces, *with_comments) Nokogiri::XML::Element (Nokogiri::XML::Node)
cdata?()                                             Nokogiri::XML::Element (Nokogiri::XML::Node)
child()                                             Nokogiri::XML::Element (Nokogiri::XML::Node)
children()                                             Nokogiri::XML::Element (Nokogiri::XML::Node)
children=(node_or_tags)                                 Nokogiri::XML::Element (Nokogiri::XML::Node)
chunk()                                             Nokogiri::XML::Element (Enumerable)
chunk_while()                                             Nokogiri::XML::Element (Enumerable)
collect()                                             Nokogiri::XML::Element (Enumerable)
collect_concat()                                             Nokogiri::XML::Element (Enumerable)
comment?()                                             Nokogiri::XML::Element (Nokogiri::XML::Node)
content()                                             Nokogiri::XML::Element (Nokogiri::XML::Node)
content=(string)                                       Nokogiri::XML::Element (Nokogiri::XML::Node)
count(*arg1)                                        Nokogiri::XML::Element (Enumerable)
create_external_subset(arg1, arg2, arg3)                             Nokogiri::XML::Element (Nokogiri::XML::Node)
create_internal_subset(arg1, arg2, arg3)                             Nokogiri::XML::Element (Nokogiri::XML::Node)
css(*args)                                        Nokogiri::XML::Element (Nokogiri::XML::Searchable)
css_path()                                             Nokogiri::XML::Element (Nokogiri::XML::Node)
cycle(*arg1)                                        Nokogiri::XML::Element (Enumerable)
decorate!()                                             Nokogiri::XML::Element (Nokogiri::XML::Node)
default_namespace=(url)                                          Nokogiri::XML::Element (Nokogiri::XML::Node)
delete(name)                                         Nokogiri::XML::Element (Nokogiri::XML::Node)
description()                                             Nokogiri::XML::Element (Nokogiri::XML::Node)
detect(*arg1)                                        Nokogiri::XML::Element (Enumerable)
do_xinclude(*options, &block)                             Nokogiri::XML::Element (Nokogiri::XML::Node)
document()                                             Nokogiri::XML::Element (Nokogiri::XML::Node)
document?()                                             Nokogiri::XML::Element (Nokogiri::XML::Node)
drop(arg1)                                         Nokogiri::XML::Element (Enumerable)
drop_while()                                             Nokogiri::XML::Element (Enumerable)
each()                                             Nokogiri::XML::Element (Nokogiri::XML::Node)
each_cons(arg1)                                         Nokogiri::XML::Element (Enumerable)
each_entry(*arg1)                                        Nokogiri::XML::Element (Enumerable)
each_slice(arg1)                                         Nokogiri::XML::Element (Enumerable)
each_with_index(*arg1)                                        Nokogiri::XML::Element (Enumerable)
each_with_object(arg1)                                         Nokogiri::XML::Element (Enumerable)
elem?()                                             Nokogiri::XML::Element (Nokogiri::XML::Node)
element?()                                             Nokogiri::XML::Element (Nokogiri::XML::Node)
element_children()                                             Nokogiri::XML::Element (Nokogiri::XML::Node)
elements()                                             Nokogiri::XML::Element (Nokogiri::XML::Node)
encode_special_chars(arg1)                                         Nokogiri::XML::Element (Nokogiri::XML::Node)
entries(*arg1)                                        Nokogiri::XML::Element (Enumerable)
external_subset()                                             Nokogiri::XML::Element (Nokogiri::XML::Node)
find(*arg1)                                        Nokogiri::XML::Element (Enumerable)
find_all()                                             Nokogiri::XML::Element (Enumerable)
find_index(*arg1)                                        Nokogiri::XML::Element (Enumerable)
first(*arg1)                                        Nokogiri::XML::Element (Enumerable)
first_element_child()                                             Nokogiri::XML::Element (Nokogiri::XML::Node)
flat_map()                                             Nokogiri::XML::Element (Enumerable)
fragment(tags)                                         Nokogiri::XML::Element (Nokogiri::XML::Node)
fragment?()                                             Nokogiri::XML::Element (Nokogiri::XML::Node)
get_attribute(name)                                         Nokogiri::XML::Element (Nokogiri::XML::Node)
grep(arg1)                                         Nokogiri::XML::Element (Enumerable)
grep_v(arg1)                                         Nokogiri::XML::Element (Enumerable)
group_by()                                             Nokogiri::XML::Element (Enumerable)
has_attribute?(arg1)                                         Nokogiri::XML::Element (Nokogiri::XML::Node)
html?()                                             Nokogiri::XML::Element (Nokogiri::XML::Node)
inject(*arg1)                                        Nokogiri::XML::Element (Enumerable)
inner_html(*args)                                        Nokogiri::XML::Element (Nokogiri::XML::Node)
inner_html=(node_or_tags)                                 Nokogiri::XML::Element (Nokogiri::XML::Node)
inner_text()                                             Nokogiri::XML::Element (Nokogiri::XML::Node)
internal_subset()                                             Nokogiri::XML::Element (Nokogiri::XML::Node)
key?(arg1)                                         Nokogiri::XML::Element (Nokogiri::XML::Node)
keys()                                             Nokogiri::XML::Element (Nokogiri::XML::Node)
lang()                                             Nokogiri::XML::Element (Nokogiri::XML::Node)
lang=(arg1)                                         Nokogiri::XML::Element (Nokogiri::XML::Node)
last_element_child()                                             Nokogiri::XML::Element (Nokogiri::XML::Node)
lazy()                                             Nokogiri::XML::Element (Enumerable)
line()                                             Nokogiri::XML::Element (Nokogiri::XML::Node)
map()                                             Nokogiri::XML::Element (Enumerable)
matches?(selector)                                     Nokogiri::XML::Element (Nokogiri::XML::Node)
max(*arg1)                                        Nokogiri::XML::Element (Enumerable)
max_by(*arg1)                                        Nokogiri::XML::Element (Enumerable)
member?(arg1)                                         Nokogiri::XML::Element (Enumerable)
min(*arg1)                                        Nokogiri::XML::Element (Enumerable)
min_by(*arg1)                                        Nokogiri::XML::Element (Enumerable)
minmax()                                             Nokogiri::XML::Element (Enumerable)
minmax_by()                                             Nokogiri::XML::Element (Enumerable)
name=(arg1)                                         Nokogiri::XML::Element (Nokogiri::XML::Node)
namespace()                                             Nokogiri::XML::Element (Nokogiri::XML::Node)
namespace=(ns)                                           Nokogiri::XML::Element (Nokogiri::XML::Node)
namespace_definitions()                                             Nokogiri::XML::Element (Nokogiri::XML::Node)
namespace_scopes()                                             Nokogiri::XML::Element (Nokogiri::XML::Node)
namespaced_key?(arg1, arg2)                                   Nokogiri::XML::Element (Nokogiri::XML::Node)
namespaces()                                             Nokogiri::XML::Element (Nokogiri::XML::Node)
native_content=(arg1)                                         Nokogiri::XML::Element (Nokogiri::XML::Node)
next()                                             Nokogiri::XML::Element (Nokogiri::XML::Node)
next=(node_or_tags)                                 Nokogiri::XML::Element (Nokogiri::XML::Node)
next_element()                                             Nokogiri::XML::Element (Nokogiri::XML::Node)
next_sibling()                                             Nokogiri::XML::Element (Nokogiri::XML::Node)
node_name()                                             Nokogiri::XML::Element (Nokogiri::XML::Node)
node_name=(arg1)                                         Nokogiri::XML::Element (Nokogiri::XML::Node)
node_type()                                             Nokogiri::XML::Element (Nokogiri::XML::Node)
none?()                                             Nokogiri::XML::Element (Enumerable)
one?()                                             Nokogiri::XML::Element (Enumerable)
parent()                                             Nokogiri::XML::Element (Nokogiri::XML::Node)
parent=(parent_node)                                  Nokogiri::XML::Element (Nokogiri::XML::Node)
parse(string_or_io, *options)                       Nokogiri::XML::Element (Nokogiri::XML::Node)
partition()                                             Nokogiri::XML::Element (Enumerable)
path()                                             Nokogiri::XML::Element (Nokogiri::XML::Node)
pointer_id()                                             Nokogiri::XML::Element (Nokogiri::XML::Node)
prepend_child(node_or_tags)                                 Nokogiri::XML::Element (Nokogiri::XML::Node)
previous()                                             Nokogiri::XML::Element (Nokogiri::XML::Node)
previous=(node_or_tags)                                 Nokogiri::XML::Element (Nokogiri::XML::Node)
previous_element()                                             Nokogiri::XML::Element (Nokogiri::XML::Node)
previous_sibling()                                             Nokogiri::XML::Element (Nokogiri::XML::Node)
processing_instruction?()                                             Nokogiri::XML::Element (Nokogiri::XML::Node)
read_only?()                                             Nokogiri::XML::Element (Nokogiri::XML::Node)
reduce(*arg1)                                        Nokogiri::XML::Element (Enumerable)
reject()                                             Nokogiri::XML::Element (Enumerable)
remove()                                             Nokogiri::XML::Element (Nokogiri::XML::Node)
remove_attribute(name)                                         Nokogiri::XML::Element (Nokogiri::XML::Node)
replace(node_or_tags)                                 Nokogiri::XML::Element (Nokogiri::XML::Node)
reverse_each(*arg1)                                        Nokogiri::XML::Element (Enumerable)
search(*args)                                        Nokogiri::XML::Element (Nokogiri::XML::Searchable)
select()                                             Nokogiri::XML::Element (Enumerable)
serialize(*args, &block)                                Nokogiri::XML::Element (Nokogiri::XML::Node)
set_attribute(name, value)                                  Nokogiri::XML::Element (Nokogiri::XML::Node)
slice_after(*arg1)                                        Nokogiri::XML::Element (Enumerable)
slice_before(*arg1)                                        Nokogiri::XML::Element (Enumerable)
slice_when()                                             Nokogiri::XML::Element (Enumerable)
sort()                                             Nokogiri::XML::Element (Enumerable)
sort_by()                                             Nokogiri::XML::Element (Enumerable)
swap(node_or_tags)                                 Nokogiri::XML::Element (Nokogiri::XML::Node)
take(arg1)                                         Nokogiri::XML::Element (Enumerable)
take_while()                                             Nokogiri::XML::Element (Enumerable)
text()                                             Nokogiri::XML::Element (Nokogiri::XML::Node)
text?()                                             Nokogiri::XML::Element (Nokogiri::XML::Node)
to_a(*arg1)                                        Nokogiri::XML::Element (Enumerable)
to_h(*arg1)                                        Nokogiri::XML::Element (Enumerable)
to_html(*options)                                     Nokogiri::XML::Element (Nokogiri::XML::Node)
to_str()                                             Nokogiri::XML::Element (Nokogiri::XML::Node)
to_xhtml(*options)                                     Nokogiri::XML::Element (Nokogiri::XML::Node)
to_xml(*options)                                     Nokogiri::XML::Element (Nokogiri::XML::Node)
traverse(&block)                                       Nokogiri::XML::Element (Nokogiri::XML::Node)
type()                                             Nokogiri::XML::Element (Nokogiri::XML::Node)
unlink()                                             Nokogiri::XML::Element (Nokogiri::XML::Node)
values()                                             Nokogiri::XML::Element (Nokogiri::XML::Node)
write_html_to(io, *options)                                 Nokogiri::XML::Element (Nokogiri::XML::Node)
write_to(io, *options)                                 Nokogiri::XML::Element (Nokogiri::XML::Node)
write_xhtml_to(io, *options)                                 Nokogiri::XML::Element (Nokogiri::XML::Node)
write_xml_to(io, *options)                                 Nokogiri::XML::Element (Nokogiri::XML::Node)
xml?()                                             Nokogiri::XML::Element (Nokogiri::XML::Node)
xpath(*args)                                        Nokogiri::XML::Element (Nokogiri::XML::Searchable)
zip(*arg1)                                        Nokogiri::XML::Element (Enumerable)
=end

DEFAULT_OPTIONS = {
  mode: "html",
  querymethod: "css",
  outhnd: $stdout,
}

def ioredfmt(io, prefmt, fmt, *args)
  str = ((args.length == 0) ? fmt : sprintf(fmt, *args))
  io.printf(prefmt, str)
end


class CSSQueryProgram
  attr_accessor :opts

  def initialize()
    @opts = OpenStruct.new(DEFAULT_OPTIONS)
    @out = @opts.outhnd
  end

  def fail(fmt, *args)
    ioredfmt($stderr, "ERROR: %s\n", fmt, *args)
    exit(1)
  end

  def oflush
    @opts.outhnd.flush
  end

  def owrite(str)
    @opts.outhnd.write(str)
    oflush
  end

  def oputs(*strs)
    strs.each do |str|
      @opts.outhnd.puts(str)
    end
    oflush
  end

  def oprintf(fmt, *args)
    @opts.outhnd.printf(fmt, *args)
    oflush
  end

  def load_document(data, filename)
    @filename = filename
    @rawdata = data
    case @opts.mode
      when "xml" then
        return Nokogiri::XML(data)
      when "html" then
        return Nokogiri::HTML(data)
      else
        fail("unsupported mode %p", @opts.mode)
    end
  end

  def load_file(io, filename)
    @document = load_document(io.read, filename)
  end

  def query_raw(q, &b)
    @document.send(@opts.querymethod, q).each(&b)
  end

  def query_dump(q)
    query_raw(q) do |elem|
      dump_main(elem)
    end
  end

  def dump_node(elem)
    name = elem.name
    attribs = elem.attributes

      if !@opts.raw then
        oprintf("Node[%p] = ", name)
      end
      if attribs.empty? then
        if @opts.raw then
          oputs("Attributes{}")
        end
      else
        if !@opts.raw then
          oputs("Attributes{")
        end
        #["n", #<Nokogiri::XML::Attr:0x301626188 name="n" value="MinTimeToGiveCollisionDamage">]
        attribs.each do |name, xmlattr|
          if @opts.raw then
            if @opts.onlyvalue then
              oprintf("%s\n", xmlattr.value)
            else
              oprintf("%s=%p\n", name, xmlattr.value)
            end
          else
            oprintf("  %p=%p;\n", name, xmlattr.value)
          end
        end
        if !@opts.raw then
          oputs("}\n")
        end
      end

  end

  def dump_main(thing)
    if thing.is_a?(Array) || thing.is_a?(Nokogiri::XML::NodeSet) then
      thing.each{|t| dump_main(t) }
    else
      dump_node(thing)
    end
  end

  def main(q)
    query_dump(q)
  end
end

begin
  cq = CSSQueryProgram.new
  OptionParser.new{|prs|
    prs.on("-m<mode>", "--mode=<mode>", "set parsing mode: 'xml' or 'html' (default: #{DEFAULT_OPTIONS[:mode]})"){|v|
      cq.opts.mode = v
    }
    prs.on("-r", "--raw", "output values plainly"){
      cq.opts.raw = true
    }
    prs.on("-v", "--value", "--values", "emit values only; requires '--raw'"){
      cq.opts.onlyvalue = true
    }
  }.parse!
  query = ARGV.shift
  if query.nil? then
    $stderr.printf("usage: %s <query> [<file>]\n", $0)
    exit(1)
  else
    if ARGV.empty? then
      cq.load_file($stdin, "<stdin>")
      cq.main(query)
    else
      ARGV.each do |file|
        File.open(file, "rb") do |fh|
          cq.load_file(fh, file)
          cq.main(query)
        end
      end
    end
  end
end
