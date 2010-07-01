module Labs
  module_function

  HTML_DIR = 'git_tutorial/html'

  class Lab
    attr_reader :name, :number, :lines
    attr_accessor :next, :prev

    def initialize(name, number)
      @name = name
      @number = number
      @lines = ""
    end

    def empty?
      @lines.empty?
    end

    def <<(line)
      @lines << line
    end

    def filename
      "lab_%02d.html" % number
    end

    def to_html
      RedCloth.new(lines).to_html
    end
  end

  def make_sample_name(lab_number, word)
    SAMPLES_DIR + ("/%03d_%s.txt" % [lab_number, word])
  end

  def generate_labs(io)
    lab_index = -1
    labs = []
    mode = :direct
    gathered_line = ''
    io.each do |line|
      next if line =~ /^\s*-+\s*$/ # omit dividers
      next if line =~ /^[+][a-z]/  # omit hidden commands
      line.sub!(/^[-!]/,'')        # remove force and execute ignore chars
      case mode
      when :direct
        if line =~ /^h1.\s+(.+)$/
          lab_index += 1
          lab = Lab.new($1, lab_index+1)
          lab.prev = labs.last
          labs.last.next = lab if labs.last
          lab.lines << line.sub(/h1\./, "h1. Lab #{lab_index+1}: ")
          labs << lab
        elsif line =~ /^pre*\(.*\)\.\s*$/
          mode = :gather1
          gathered_line = line.strip
        elsif line =~ /^p(\([(a-z){}]*)?\.\s+/
          mode = :gather
          gathered_line = line.strip
        elsif line =~ /^Execute:$/i
          mode = :gather1
          labs[lab_index] << "p(command). Execute:\n\n"
          gathered_line = "pre(instructions)."
        elsif line =~ /^File:\s+(\S+)$/i
          file_name = $1
          labs[lab_index] << "p(filename). File: #{file_name}\n\n"
          gathered_line = "<pre class=\"file\">"
          mode = :file
        elsif line =~ /^Output:\s*$/
          labs[lab_index] << "p(command). Output:\n\n"
          gathered_line = "<pre class=\"sample\">"
          mode = :file
        elsif line =~ /^Set: +\w+=.*$/
          # Skip set lines
        elsif line =~ /^=\w+/
          # Skip include lines
        else
          labs[lab_index] << line unless lab_index < 0
        end
      when :gather1
        labs[lab_index] << gathered_line << " " << line
        mode = :direct
      when :gather
        if line =~ /^\s*$/
          labs[lab_index] << gathered_line << "\n\n"
          mode = :direct
        else
          gathered_line << " " << line.strip
        end
      when :file
        if line =~ /^EOF$/
          labs[lab_index] << "</pre>\n"
          mode = :direct
        elsif line =~ /^=(\w+)/
          sample_name = make_sample_name(lab_index+1, $1)
          open(sample_name) do |ins|
            ins.each do |sample_line|
              labs[lab_index] << "#{gathered_line}#{sample_line}"
              gathered_line = ''
            end
          end
        else
          labs[lab_index] << "#{gathered_line}#{line}"
          gathered_line = ''
        end
      end
    end
    write_index_html(labs)
    labs.each do |lab|
      write_lab_html(lab)
    end
  end

  def nav_links(f, lab)
    partial("nav", binding)
  end

  def partial(template, bnd)
    result = open("templates/#{template}.html.erb") do |tpl|
      template_string = tpl.read
      template_string.gsub!(/-%>/, "%>@NONEWLINE@")
      ERB.new(template_string).result(bnd)
    end
    result.gsub(/@NONEWLINE@\n/, '')
  end

  def write_index_html(labs)
    File.open("#{HTML_DIR}/index.html", "w") do |f|
      f.puts partial('index', binding)
    end
  end

  def write_lab_html(lab)
    lab_html = lab.to_html
    File.open("#{HTML_DIR}/#{lab.filename}", "w") { |f|
      f.puts partial('lab', binding)
    }
  end
end

require 'rubygems'
require 'redcloth'
require 'rake/clean'

CLOBBER.include(Labs::HTML_DIR)

directory Labs::HTML_DIR

desc "Create the Lab HTML"
task :labs => [Labs::HTML_DIR, "src/labs.txt", "rakelib/labs.rake"] do |t|
  cp "src/labs.css", "#{Labs::HTML_DIR}/labs.css"
  cp "src/edgecase.gif", "#{Labs::HTML_DIR}/edgecase.gif"
  puts "Generating HTML"
  File.open("src/labs.txt") { |f| Labs.generate_labs(f) }
end

desc "View the Labs"
task :view do
  sh "open #{Labs::HTML_DIR}/index.html"
end
