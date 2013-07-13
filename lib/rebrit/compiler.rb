#
# rebrit/compiler.rb
#
# Copyright (C) 2003-2006,2013 Minero Aoki
#
# This program is free software.
# You can distribute or modify this program under the terms of
# the GNU LGPL, Lesser General Public License version 2.1.
#

require 'rebrit/lineinput'
require 'rebrit/textutils'
require 'stringio'
require 'uri'
require 'csv'

module Rebrit

  class Compiler

    include TextUtils

    def Compiler.compile(source)
      new.compile(source)
    end

    def initialize
      @external_link_table = nil  # FIXME
    end

    def compile(source)
      @f = LineInput.new(StringIO.new(source))
      @result = ''
      @indent_stack = [0]
      do_compile
      @result
    end

    private

    #
    # Block
    #

    CAPTION = /\A(?:={2,4}|!{1,4})/
    UL = /\A\s*\*|\A-/
    OL = /\A\s*\(\d+\)|\A\#/   # should not allow spaces before '#'
    DL = /\A:/
    CITE = /\A""|\A>/
    TABLE = /\A,|\A\|\|/
    PRE = /\A\{\{\{/
    INDENTED = /\A\s+\S/
    BLOCKEXT = /\A\[\[\#(\w+)(:.*?)?\]\]\s*\z/

    PARAGRAPH_END = Regexp.union(CAPTION, UL, OL, DL,
        CITE, TABLE, PRE, INDENTED, BLOCKEXT)

    def do_compile
      while @f.next?
        case @f.peek
        when CAPTION   then caption @f.gets
        when UL        then ul
        when OL        then ol
        when DL        then dl
        when CITE      then cite
        when TABLE     then table
        when PRE       then pre
        when INDENTED  then indented_pre   # must be placed after UL/OL
        else
          if @f.peek.strip.empty?
            @f.gets
            next
          end
          paragraph
        end
      end
    end

    def caption(line)
      head = line.slice(/\A([=!]+)/, 1)
      if head[0,1] == '!'
        level = head.length + 1
      else
        level = head.length
      end
      str = line.sub(/\A[=!]+/, '').strip
      puts "<h#{level}>#{escape_html(str)}</h#{level}>"
    end

    def paragraph
      print '<p>'
      nl = ''
      @f.until_match(PARAGRAPH_END) do |line|
        break if line.strip.empty?
        print nl + text(line.sub(/\A\~/, '').strip)
        nl = "\n"
      end
      puts '</p>'
    end

    def ul
      xlist 'ul', UL
    end

    def ol
      xlist 'ol', OL
    end

    LI_CONTINUE = {
      'ul' => /\A\s+[^\s\*]/,
      'ol' => /\A\s+(?!\(\d+\)|\#)\S/
    }

    def xlist(type, mark_re)
      puts "<#{type}>"
      push_indent(indentof(@f.peek)) {
        @f.while_match(mark_re) do |line0|
          line = unify_listitem_style(line0)
          if indent_shallower?(line)
            @f.ungets line
            break
          end
          if indent_deeper?(line)
            @f.ungets line
            xlist type, mark_re
            puts '</li>'
            next
          end
          buf = line.sub(mark_re, '').strip
          @f.while_match(LI_CONTINUE[type]) do |cont|
            buf << "\n" + cont.strip
          end
          if @f.next? and next_line_is_nested_list?(mark_re)
            puts "<li>#{text(buf)}"
          else
            puts "<li>#{text(buf)}</li>"
          end
        end
      }
      puts "</#{type}>"
    end

    def next_line_is_nested_list?(mark_re)
      line = unify_listitem_style(@f.peek)
      mark_re =~ line and indent_deeper?(line)
    end

    def unify_listitem_style(line0)
      line = line0.sub(/\A-+/) {|s| '*' * s.length }
      if /\A[\*\#]{2,}/ =~ line
      then emulate_rdstyle(line)
      else line
      end
    end

    MARK = {
      '*' => '*',
      '#' => '(0)',
    }

    def emulate_rdstyle(line)
      marks = line.slice(/\A\s*[\*\#]+/).strip
      line.sub(/\A\s*[\*\#]+\s*/) {
        if marks.size <= (@indent_stack.size - 1)
          ' ' * @indent_stack[marks.size] + MARK[marks[0,1]]
        else
          ' ' * (current_indent() + 1) + MARK[marks[0,1]]
        end
      }
    end

    def dl
      puts '<dl>'
      @f.while_match(DL) do |line|
        if /\A:|\A\s*\z/ =~ @f.peek.to_s
          # original wiki style
          _, dt, dd = line.strip.split(/\s*:\s*/, 3)
          puts "<dt>#{text(dt)}</dt><dd>#{text(dd.to_s)}</dd>"
        else
          # RD style
          dt = line.sub(DL, '').strip
          dd = ''
          @f.while_match(/\A\s+\S/) do |cont|
            dd << cont.strip << "\n"
          end
          puts "<dt>#{text(dt)}</dt>\n<dd>#{text(dd.strip)}</dd>"
        end
      end
      puts '</dl>'
    end

    def cite
      puts '<blockquote>'
      print '<p>'
      nl = ''
      @f.while_match(CITE) do |line|
        content = line.sub(CITE, '').strip
        if content.empty?
          print "</p>\n<p>"
          nl = ''
        else
          print nl + escape_html(content)
          nl = "\n"
        end
      end
      puts '</p>'
      puts '</blockquote>'
    end

    def table
      case @f.peek
      when /\A,/  then csv_table
      when /\A\|/ then bar_table
      else
        raise 'must not happen'
      end
    end

    def bar_table
      buf = []
      @f.while_match(/\A\|\|/) do |line|
        cols = line.strip.split(/(\|\|\|?)/, -1)
        cols.shift   # discard first ""
        row = []
        until cols.empty?
          isheader = (cols.shift == '|||')
          row.push [cols.shift, isheader]
        end
        buf.push row
      end
      output_table adjust_ncols(buf)
    end

    def csv_table
      buf = []
      @f.while_match(/\A,/) do |line|
        buf.push CSV.parse_line(line[1..-1]).map {|cell| [cell.to_s, false] }
      end
      output_table adjust_ncols(buf)
    end

    def adjust_ncols(rows)
      rows.each do |cols|
        while cols.last and cols.last[0].strip.empty?
          cols.pop
        end
      end
      n_maxcols = rows.map {|cols| cols.size }.max
      rows.each do |cols|
        cols.concat [['',false]] * (n_maxcols - cols.size)
      end
      rows
    end

    def output_table(rows)
      puts '<table>'
      rows.each do |cols|
        puts '<tr>' +
             cols.map {|col, isheader|
               if isheader
               then "<th>#{text(col.strip)}</th>"
               else "<td>#{text(col.strip)}</td>"
               end
             }.join('') +
             '</tr>'
      end
      puts '</table>'
    end

    def pre
      @f.gets   # discard '{{{'
      puts '<pre>'
      @f.until_terminator(/\A\}\}\}/) do |line|
        puts escape_html(line.rstrip)
      end
      puts '</pre>'
    end

    def indented_pre
      buf = []
      @f.until_match(/\A\S/) do |line|
        buf.push line
      end
      while buf.last.strip.empty?
        buf.pop 
      end
      minindent = buf.map {|line| indentof(line) }.reject {|i| i == 0 }.min
      puts '<pre>'
      buf.each do |line|
        if line.strip.empty?
          puts ''
        else
          puts escape_html(unindent(line.rstrip, minindent))
        end
      end
      puts '</pre>'
    end

    #
    # Indent
    #

    def push_indent(n)
      raise "shollower indent pushed: #{@indent_stack.inspect}" \
          unless n >= current_indent()
      @indent_stack.push n
      yield
    ensure
      @indent_stack.pop
    end

    def current_indent
      @indent_stack.last
    end

    def indent_deeper?(line)
      indentof(line) > current_indent()
    end

    def indent_shallower?(line)
      indentof(line) < current_indent()
    end

    def indentof(line)
      detab(line.slice(/\A\s*/)).length
    end

    INDENT_RE = {
      2 => /\A {2}/,
      4 => /\A {4}/,
      8 => /\A {8}/
    }

    def unindent(line, n)
      re = (INDENT_RE[n] ||= /\A {#{n}}/)
      line.sub(re, '')
    end

    #
    # Inline
    #

    BracketLink = /\[\[[!-~]+?\]\]/n
    SeemsURL = URI.regexp(%w(http https ftp))
    NeedESC = /[&"<>]/

    def text(str)
      esctable = TextUtils::ESC
      str.gsub(/(#{NeedESC})|(#{BracketLink})|(#{SeemsURL})/on) {
        if    ch  = $1 then esctable[ch]
        elsif tok = $2 then bracket_link(tok[2..-3])
        elsif tok = $3 then seems_url(tok)
        else
          raise 'must not happen'
        end
      }
    end

    def bracket_link(link)
      case link
      when /\A#/
        name, arg = $'.split(':', 2)
        mid = "inline_ext__#{name}"
        if respond_to?(mid, true)
        then __send__(mid, arg)
        else "[#{escape_html(link)}]"
        end
      when /\Aimg:/
        imglink = $'
        if SeemsURL =~ imglink and seems_image_url?(imglink)
          %Q[<img src="#{escape_html(imglink)}">]
        elsif /\A[\w\-]+:/n =~ imglink
          id, vary = *imglink.split(/:/, 2)
          href = resolve_external_link(id, vary)
          if href and seems_image_url?(href)
          then %Q[<img src="#{escape_html(href)}">]
          else "[#{escape_html(link)}]"
          end
        else
          "[#{escape_html(link)}]"
        end
      when SeemsURL
        %[<a href="#{escape_html(link)}">#{escape_html(link)}</a>]
      when /\A[\w\-]+:/n
        external_link(*link.split(/:/, 2))
      else
        escape_html(link)
      end
    end

    def seems_image_url?(url)
      /\.(?:png|jpg|jpeg|gif|bmp|tiff|tif)\z/i =~ url
    end

    def external_link(id, vary)
      anchor = "[#{id}:#{vary}]"
      if href = resolve_external_link(id, vary)
      then %Q[<a href="#{escape_html(href)}">#{escape_html(anchor)}</a>]
      else '?' + escape_html(anchor)
      end
    end

    def resolve_external_link(name, vary)
      table = @external_link_table or return nil
      return nil unless table.key?(name)
      sprintf(table[name], vary)
    end

    def seems_url(url)
      if url[-1,1] == ')' and not paren_balanced?(url)
        url = url.chop
        %Q[<a href="#{escape_html(url)}">#{escape_html(url)}</a>)]
      else
        %Q[<a href="#{escape_html(url)}">#{escape_html(url)}</a>]
      end
    end

    def paren_balanced?(str)
      str.count('(') == str.count(')')
    end

    #
    # I/O
    #

    def print(str)
      @result << str
    end

    def puts(str)
      @result << str
      @result << "\n" unless /\n\z/ =~ str
    end

  end

end
