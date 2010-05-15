require 'pp'
require 'rubygems'
require 'colorize'

# TODO: Pick a backtrace format. (Also, add a method to replace default backtracer.)
# TODO: This chould be in a class.

class Array

  def split_when(&block)

    chunks = []
    start = 0

    for i in 0...self.size-1

      split_here = yield(self[i], self[i+1])
      if split_here
        chunks << self[start..i]
        start = i+1
      end

    end

    chunks << self[start..-1]
    chunks

  end

end


class Line

  attr_accessor :path, :num, :meth, :dir, :filename

  def initialize(path, num, meth)
    
    @path = path
    @num = num
    @meth = meth
    @gem = false
    
    @dir, @filename = File.split(path)
    
    if @dir =~ %r{^/usr/lib/ruby/gems/1.8/gems/(.+)}
      @dir = "[gem] #{$1}"
      @gem = true
    end
    
  end

  def gem?
    @gem 
  end

  def codeline
    l = @num.to_i - 1
    open(path).readlines[l]
  end
  
end


def parse_lines(backtrace)
  backtrace.map do |line|
    case line
      when /^\s+(.+):(\d+):in \`(.+)'/
        Line.new($1, $2, $3)
      when /^\s+(.+):(\d+)/
        Line.new($1, $2, '')
      when /^\s+$/
        next
      else
        raise "huh?!"
    end
  end.compact
end


def color_backtrace_1(lines)
  groups = lines.split_when { |line,nextline| line.path != nextline.path }
  for group in groups
    dir, filename = File.split(group.first.path)
    puts "#{filename.green} (#{dir.light_white})"
    # /usr/local/lib/site_ruby/1.8/rubygems/custom_require.rb
    #      234: require | 553: new_constants_in |
    group.each do |line|
      puts "  |_ #{line.num.magenta}: #{line.meth.light_yellow.underline}"
    end
    #puts "  |_ " + group.map{|line| "#{line.num.magenta}: #{line.meth.light_yellow}"}.join(' | '.red)
  end
end



def color_backtrace_2(lines, options={})

  groups = lines.reverse.split_when { |line,nextline| line.path != nextline.path }

  if options[:no_gems]
    groups = groups.split_when { |a, nexta| a.first.gem? != nexta.first.gem? }
    groups.map! { |group| group.first.gem? ? [] : group }
  end

  
  for group in groups
    if group.empty?
      puts " ... ignored ... "
      puts
      next
    end

    firstline = group.first

    # custom_require.rb (/usr/local/lib/site_ruby/1.8/rubygems)
    #      234: require          => super
    #      553: new_constants_in =>

    #puts "#{firstline.filename.green} (#{firstline.dir.light_white})"
    puts "#{firstline.filename.underline} (#{firstline.dir.light_white})"
    
    max_methsize = group.map { |line| line.meth.size}.max
    group.each do |line|
      pad = " " * (max_methsize - line.meth.size)
      puts "  #{line.num.magenta}: #{line.meth.light_yellow}#{pad}"
      puts "    #{"|_".blue} #{line.codeline.strip}"
    end
    puts
  end
  
end


def python_backtrace(lines)
  #groups = lines.reverse.split_when { |line,nextline| line.path != nextline.path }
  lines = lines.reverse

  puts "Traceback (most recent call last):"

  for line in lines
    puts %{  File "#{line.path}", line #{line.num}, in #{line.meth}}
    puts %{    #{line.codeline.strip}}
  end
end

def debug_backtrace(lines)
  lines.each do |line|
    p line.path
  end
end


if $0 == __FILE__
  backtrace = %{
      /usr/lib/ruby/gems/1.8/gems/activerecord-2.1.0/lib/active_record/attribute_methods.rb:256:in `method_missing'
      vendor/plugins/attribute_fu/lib/attribute_fu/associations.rb:28:in `method_missing'
      app/helpers/admin/products_helper.rb:17:in `description_column'
      vendor/plugins/active_scaffold/lib/helpers/list_column_helpers.rb:11:in `send'
      vendor/plugins/active_scaffold/lib/helpers/list_column_helpers.rb:11:in `get_column_value'
      vendor/plugins/active_scaffold/frontends/default/views/_list_record.rhtml:10:in `_run_erb_47vendor47plugins47active_scaffold47frontends47default47views47_list_record46rhtml'
      vendor/plugins/active_scaffold/lib/data_structures/action_columns.rb:68:in `each'
      vendor/plugins/active_scaffold/lib/data_structures/action_columns.rb:55:in `each'
      vendor/plugins/active_scaffold/frontends/default/views/_list_record.rhtml:9:in `_run_erb_47vendor47plugins47active_scaffold47frontends47default47views47_list_record46rhtml'
      /usr/lib/ruby/gems/1.8/gems/actionpack-2.1.0/lib/action_view/base.rb:338:in `send'
      /usr/lib/ruby/gems/1.8/gems/actionpack-2.1.0/lib/action_view/base.rb:338:in `execute'
      /usr/lib/ruby/gems/1.8/gems/actionpack-2.1.0/lib/action_view/template_handlers/compilable.rb:29:in `send'
      /usr/lib/ruby/gems/1.8/gems/actionpack-2.1.0/lib/action_view/template_handlers/compilable.rb:29:in `render'
      /usr/lib/ruby/gems/1.8/gems/actionpack-2.1.0/lib/action_view/partial_template.rb:20:in `render'
      /usr/lib/ruby/gems/1.8/gems/actionpack-2.1.0/lib/action_controller/benchmarking.rb:26:in `benchmark'
      /usr/lib/ruby/gems/1.8/gems/activesupport-2.1.0/lib/active_support/core_ext/benchmark.rb:8:in `realtime'
      /usr/lib/ruby/gems/1.8/gems/actionpack-2.1.0/lib/action_controller/benchmarking.rb:26:in `benchmark'
      /usr/lib/ruby/gems/1.8/gems/actionpack-2.1.0/lib/action_view/partial_template.rb:19:in `render'
      /usr/lib/ruby/gems/1.8/gems/actionpack-2.1.0/lib/action_view/template.rb:22:in `render_template'
      /usr/lib/ruby/gems/1.8/gems/actionpack-2.1.0/lib/action_view/partial_template.rb:28:in `render_member'
      /usr/lib/ruby/gems/1.8/gems/actionpack-2.1.0/lib/action_view/partials.rb:142:in `render_partial_collection_with_known_partial_path'
      /usr/lib/ruby/gems/1.8/gems/actionpack-2.1.0/lib/action_view/partials.rb:141:in `map'
      /usr/lib/ruby/gems/1.8/gems/actionpack-2.1.0/lib/action_view/partials.rb:141:in `render_partial_collection_with_known_partial_path'
      /usr/lib/ruby/gems/1.8/gems/actionpack-2.1.0/lib/action_view/partials.rb:135:in `render_partial_collection'
      /usr/lib/ruby/gems/1.8/gems/actionpack-2.1.0/lib/action_view/base.rb:271:in `render_without_active_scaffold'
      vendor/plugins/active_scaffold/lib/extensions/action_view_rendering.rb:55:in `render_without_haml'
      /usr/lib/ruby/gems/1.8/gems/haml-2.0.2/lib/haml/helpers/action_view_mods.rb:6:in `render'
      vendor/plugins/active_scaffold/frontends/default/views/_list.rhtml:21:in `_run_erb_47vendor47plugins47active_scaffold47frontends47default47views47_list46rhtml'
      /usr/lib/ruby/gems/1.8/gems/actionpack-2.1.0/lib/action_view/base.rb:338:in `send'
      /usr/lib/ruby/gems/1.8/gems/actionpack-2.1.0/lib/action_view/base.rb:338:in `execute'
      /usr/lib/ruby/gems/1.8/gems/actionpack-2.1.0/lib/action_view/template_handlers/compilable.rb:29:in `send'
      /usr/lib/ruby/gems/1.8/gems/actionpack-2.1.0/lib/action_view/template_handlers/compilable.rb:29:in `render'
      /usr/lib/ruby/gems/1.8/gems/actionpack-2.1.0/lib/action_view/partial_template.rb:20:in `render'
      /usr/lib/ruby/gems/1.8/gems/actionpack-2.1.0/lib/action_controller/benchmarking.rb:26:in `benchmark'
      /usr/lib/ruby/gems/1.8/gems/activesupport-2.1.0/lib/active_support/core_ext/benchmark.rb:8:in `realtime'
      /usr/lib/ruby/gems/1.8/gems/actionpack-2.1.0/lib/action_controller/benchmarking.rb:26:in `benchmark'
      /usr/lib/ruby/gems/1.8/gems/actionpack-2.1.0/lib/action_view/partial_template.rb:19:in `render'
      /usr/lib/ruby/gems/1.8/gems/actionpack-2.1.0/lib/action_view/template.rb:22:in `render_template'
      /usr/lib/ruby/gems/1.8/gems/actionpack-2.1.0/lib/action_view/partials.rb:110:in `render_partial'
      /usr/lib/ruby/gems/1.8/gems/actionpack-2.1.0/lib/action_view/base.rb:273:in `render_without_active_scaffold'
      vendor/plugins/active_scaffold/lib/extensions/action_view_rendering.rb:55:in `render_without_haml'
      /usr/lib/ruby/gems/1.8/gems/haml-2.0.2/lib/haml/helpers/action_view_mods.rb:6:in `render'
      vendor/plugins/active_scaffold/frontends/default/views/list.rhtml:9:in `_run_erb_47vendor47plugins47active_scaffold47frontends47default47views47list46rhtml'
      /usr/lib/ruby/gems/1.8/gems/actionpack-2.1.0/lib/action_view/base.rb:338:in `send'
      /usr/lib/ruby/gems/1.8/gems/actionpack-2.1.0/lib/action_view/base.rb:338:in `execute'
      /usr/lib/ruby/gems/1.8/gems/actionpack-2.1.0/lib/action_view/template_handlers/compilable.rb:29:in `send'
      /usr/lib/ruby/gems/1.8/gems/actionpack-2.1.0/lib/action_view/template_handlers/compilable.rb:29:in `render'
      /usr/lib/ruby/gems/1.8/gems/actionpack-2.1.0/lib/action_view/template.rb:35:in `render'
      /usr/lib/ruby/gems/1.8/gems/actionpack-2.1.0/lib/action_view/template.rb:22:in `render_template'
      /usr/lib/ruby/gems/1.8/gems/actionpack-2.1.0/lib/action_view/base.rb:245:in `render_file'
      /usr/lib/ruby/gems/1.8/gems/actionpack-2.1.0/lib/action_controller/base.rb:1108:in `render_for_file'
      /usr/lib/ruby/gems/1.8/gems/actionpack-2.1.0/lib/action_controller/base.rb:865:in `render_with_no_layout'
      /usr/lib/ruby/gems/1.8/gems/actionpack-2.1.0/lib/action_controller/base.rb:880:in `render_with_no_layout'
      /usr/lib/ruby/gems/1.8/gems/actionpack-2.1.0/lib/action_controller/layout.rb:251:in `render_without_benchmark'
      /usr/lib/ruby/gems/1.8/gems/actionpack-2.1.0/lib/action_controller/benchmarking.rb:51:in `render_without_active_scaffold'
      /usr/lib/ruby/gems/1.8/gems/activesupport-2.1.0/lib/active_support/core_ext/benchmark.rb:8:in `realtime'
      /usr/lib/ruby/gems/1.8/gems/actionpack-2.1.0/lib/action_controller/benchmarking.rb:51:in `render_without_active_scaffold'
      vendor/plugins/active_scaffold/lib/extensions/action_controller_rendering.rb:13:in `render'
      vendor/plugins/active_scaffold/lib/actions/list.rb:37:in `list'
      /usr/lib/ruby/gems/1.8/gems/actionpack-2.1.0/lib/action_controller/mime_responds.rb:131:in `call'
      /usr/lib/ruby/gems/1.8/gems/actionpack-2.1.0/lib/action_controller/mime_responds.rb:131:in `custom'
      /usr/lib/ruby/gems/1.8/gems/actionpack-2.1.0/lib/action_controller/mime_responds.rb:160:in `call'
      /usr/lib/ruby/gems/1.8/gems/actionpack-2.1.0/lib/action_controller/mime_responds.rb:160:in `respond'
      /usr/lib/ruby/gems/1.8/gems/actionpack-2.1.0/lib/action_controller/mime_responds.rb:154:in `each'
      /usr/lib/ruby/gems/1.8/gems/actionpack-2.1.0/lib/action_controller/mime_responds.rb:154:in `respond'
      /usr/lib/ruby/gems/1.8/gems/actionpack-2.1.0/lib/action_controller/mime_responds.rb:107:in `respond_to'
      vendor/plugins/active_scaffold/lib/actions/list.rb:35:in `list'
      vendor/plugins/active_scaffold/lib/actions/list.rb:8:in `index'
      /usr/lib/ruby/gems/1.8/gems/actionpack-2.1.0/lib/action_controller/base.rb:1162:in `send'
      /usr/lib/ruby/gems/1.8/gems/actionpack-2.1.0/lib/action_controller/base.rb:1162:in `perform_action_without_filters'
      /usr/lib/ruby/gems/1.8/gems/actionpack-2.1.0/lib/action_controller/filters.rb:580:in `call_filters'
      /usr/lib/ruby/gems/1.8/gems/actionpack-2.1.0/lib/action_controller/filters.rb:573:in `perform_action_without_benchmark'
      /usr/lib/ruby/gems/1.8/gems/actionpack-2.1.0/lib/action_controller/benchmarking.rb:68:in `perform_action_without_rescue'
      /usr/lib/ruby/1.8/benchmark.rb:293:in `measure'
      /usr/lib/ruby/gems/1.8/gems/actionpack-2.1.0/lib/action_controller/benchmarking.rb:68:in `perform_action_without_rescue'
      /usr/lib/ruby/gems/1.8/gems/actionpack-2.1.0/lib/action_controller/rescue.rb:201:in `perform_action_without_caching'
      /usr/lib/ruby/gems/1.8/gems/actionpack-2.1.0/lib/action_controller/caching/sql_cache.rb:13:in `perform_action'
      /usr/lib/ruby/gems/1.8/gems/activerecord-2.1.0/lib/active_record/connection_adapters/abstract/query_cache.rb:33:in `cache'
      /usr/lib/ruby/gems/1.8/gems/activerecord-2.1.0/lib/active_record/query_cache.rb:8:in `cache'
      /usr/lib/ruby/gems/1.8/gems/actionpack-2.1.0/lib/action_controller/caching/sql_cache.rb:12:in `perform_action'
      /usr/lib/ruby/gems/1.8/gems/actionpack-2.1.0/lib/action_controller/base.rb:529:in `send'
      /usr/lib/ruby/gems/1.8/gems/actionpack-2.1.0/lib/action_controller/base.rb:529:in `process_without_filters'
      /usr/lib/ruby/gems/1.8/gems/actionpack-2.1.0/lib/action_controller/filters.rb:569:in `process_without_session_management_support'
      /usr/lib/ruby/gems/1.8/gems/actionpack-2.1.0/lib/action_controller/session_management.rb:130:in `sass_old_process'
      /usr/lib/ruby/gems/1.8/gems/haml-2.0.2/lib/sass/plugin/rails.rb:19:in `process'
      /usr/lib/ruby/gems/1.8/gems/actionpack-2.1.0/lib/action_controller/base.rb:389:in `process'
      /usr/lib/ruby/gems/1.8/gems/actionpack-2.1.0/lib/action_controller/dispatcher.rb:149:in `handle_request'
      /usr/lib/ruby/gems/1.8/gems/actionpack-2.1.0/lib/action_controller/dispatcher.rb:107:in `dispatch'
      /usr/lib/ruby/gems/1.8/gems/actionpack-2.1.0/lib/action_controller/dispatcher.rb:104:in `synchronize'
      /usr/lib/ruby/gems/1.8/gems/actionpack-2.1.0/lib/action_controller/dispatcher.rb:104:in `dispatch'
      /usr/lib/ruby/gems/1.8/gems/actionpack-2.1.0/lib/action_controller/dispatcher.rb:120:in `dispatch_cgi'
      /usr/lib/ruby/gems/1.8/gems/actionpack-2.1.0/lib/action_controller/dispatcher.rb:35:in `dispatch'
      /usr/lib/ruby/gems/1.8/gems/mongrel-1.1.5/lib/mongrel/rails.rb:76:in `process'
      /usr/lib/ruby/gems/1.8/gems/mongrel-1.1.5/lib/mongrel/rails.rb:74:in `synchronize'
      /usr/lib/ruby/gems/1.8/gems/mongrel-1.1.5/lib/mongrel/rails.rb:74:in `process'
      /usr/lib/ruby/gems/1.8/gems/mongrel-1.1.5/lib/mongrel.rb:159:in `process_client'
      /usr/lib/ruby/gems/1.8/gems/mongrel-1.1.5/lib/mongrel.rb:158:in `each'
      /usr/lib/ruby/gems/1.8/gems/mongrel-1.1.5/lib/mongrel.rb:158:in `process_client'
      /usr/lib/ruby/gems/1.8/gems/mongrel-1.1.5/lib/mongrel.rb:285:in `run'
      /usr/lib/ruby/gems/1.8/gems/mongrel-1.1.5/lib/mongrel.rb:285:in `initialize'
      /usr/lib/ruby/gems/1.8/gems/mongrel-1.1.5/lib/mongrel.rb:285:in `new'
      /usr/lib/ruby/gems/1.8/gems/mongrel-1.1.5/lib/mongrel.rb:285:in `run'
      /usr/lib/ruby/gems/1.8/gems/mongrel-1.1.5/lib/mongrel.rb:268:in `initialize'
      /usr/lib/ruby/gems/1.8/gems/mongrel-1.1.5/lib/mongrel.rb:268:in `new'
      /usr/lib/ruby/gems/1.8/gems/mongrel-1.1.5/lib/mongrel.rb:268:in `run'
      /usr/lib/ruby/gems/1.8/gems/mongrel-1.1.5/lib/mongrel/configurator.rb:282:in `run'
      /usr/lib/ruby/gems/1.8/gems/mongrel-1.1.5/lib/mongrel/configurator.rb:281:in `each'
      /usr/lib/ruby/gems/1.8/gems/mongrel-1.1.5/lib/mongrel/configurator.rb:281:in `run'
      /usr/lib/ruby/gems/1.8/gems/mongrel-1.1.5/bin/mongrel_rails:128:in `run'
      /usr/lib/ruby/gems/1.8/gems/mongrel-1.1.5/lib/mongrel/command.rb:212:in `run'
      /usr/lib/ruby/gems/1.8/gems/mongrel-1.1.5/bin/mongrel_rails:281
      /usr/lib/ruby/gems/1.8/gems/activesupport-2.1.0/lib/active_support/dependencies.rb:502:in `load'
      /usr/lib/ruby/gems/1.8/gems/activesupport-2.1.0/lib/active_support/dependencies.rb:502:in `load'
      /usr/lib/ruby/gems/1.8/gems/activesupport-2.1.0/lib/active_support/dependencies.rb:354:in `new_constants_in'
      /usr/lib/ruby/gems/1.8/gems/activesupport-2.1.0/lib/active_support/dependencies.rb:502:in `load'
      /usr/lib/ruby/gems/1.8/gems/rails-2.1.0/lib/commands/servers/mongrel.rb:64
      /usr/local/lib/site_ruby/1.8/rubygems/custom_require.rb:27:in `gem_original_require'
      /usr/local/lib/site_ruby/1.8/rubygems/custom_require.rb:27:in `require'
      /usr/lib/ruby/gems/1.8/gems/activesupport-2.1.0/lib/active_support/dependencies.rb:509:in `require'
      /usr/lib/ruby/gems/1.8/gems/activesupport-2.1.0/lib/active_support/dependencies.rb:354:in `new_constants_in'
      /usr/lib/ruby/gems/1.8/gems/activesupport-2.1.0/lib/active_support/dependencies.rb:509:in `require'
      /usr/lib/ruby/gems/1.8/gems/rails-2.1.0/lib/commands/server.rb:39
      /usr/local/lib/site_ruby/1.8/rubygems/custom_require.rb:27:in `gem_original_require'
      /usr/local/lib/site_ruby/1.8/rubygems/custom_require.rb:27:in `require'
      script/server:3
  }.split("\n").select{|line| line.any?}
  
  lines = parse_lines(backtrace)
  #debug_backtrace(lines)
  #color_backtrace_1(lines)
  #python_backtrace(lines)
  color_backtrace_2(lines)#, :no_gems=>true)
end

