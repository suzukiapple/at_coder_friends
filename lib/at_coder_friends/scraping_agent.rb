# frozen_string_literal: true

require 'mechanize'
require 'logger'
require 'English'

module AtCoderFriends
  # scrapes AtCoder contest site and
  # - fetches problems
  # - submits sources
  class ScrapingAgent
    BASE_URL_FMT = 'http://%<contest>s.contest.atcoder.jp/'
    LANG_TBL = {
      'cxx' => '3003',
      'cs'  => '3006',
      'rb'  => '3024'
    }.freeze

    def initialize(contest, config)
      @config = config
      @agent = Mechanize.new
      # @agent.log = Logger.new(STDERR)
      @contest = contest.delete('#').downcase
      @base_url = format(BASE_URL_FMT, contest: @contest)
    end

    def login
      sleep 0.1
      page = @agent.get(@base_url + 'login')
      form = page.forms[0]
      form.field_with(name: 'name').value = @config['user']
      form.field_with(name: 'password').value = @config['password']
      sleep 0.1
      form.submit
    end

    def submit_src(q, lang_id, src)
      sleep 0.1
      page = @agent.get(@base_url + 'submit')
      form = page.forms[0]
      selectlist = form.field_with(name: 'task_id')
      task_id = selectlist.options.find { |opt| opt.text.start_with?(q) }.value
      selectlist.value = task_id
      form.field_with(name: "language_id_#{task_id}").value = lang_id
      form.field_with(name: 'source_code').value = src
      sleep 0.1
      form.submit
    end

    def fetch_assignments
      url = @base_url + 'assignments'
      puts "fetch assignments from #{url} ..."
      sleep 0.1
      ret = {}
      page = @agent.get(url)
      ('A'..'Z').each do |q|
        link = page.link_with(text: q)
        next unless link
        ret[q] = link.href
      end
      ret
    end

    def fetch_problem(q, url)
      puts "fetch problem from #{url} ..."
      sleep 0.1
      page = @agent.get(url)
      Problem.new(q) do |pbm|
        if @contest == 'arc001'
          page.search('//h3').each do |h3|
            sections = page.search(
              '//h3[.="' + h3.content + '"]/following-sibling::section'
            )
            next if sections.empty?
            section = sections[0]
            parse_section(pbm, h3, section)
          end
        else
          page.search('//*[./h3]').each do |section|
            h3 = section.search('h3')[0]
            parse_section(pbm, h3, section)
          end
        end
      end
    end

    def parse_section(pbm, h3, section)
      title = h3.content.strip
      text = section.content
      code = section.search('pre')[0]&.content || ''
      case title
      when /^制約$/
        pbm.desc += text
      when /^入力$/, /^入出力$/
        pbm.desc += text
        pbm.fmt = code
      when /^入力例\s*(?<no>[\d０-９]+)$/
        pbm.add_smp($LAST_MATCH_INFO[:no], :in, code)
      when /^出力例\s*(?<no>[\d０-９]+)$/
        pbm.add_smp($LAST_MATCH_INFO[:no], :exp, code)
      end
    end

    def submit(path)
      prog = File.basename(path)
      base, ext = prog.split('.')
      q = base.split('_')[0]
      src = File.read(path, encoding: Encoding::UTF_8)
      lang_id = LANG_TBL[ext.downcase]
      unless lang_id
        puts ".#{ext} is not available."
        return
      end
      puts "***** submit #{prog} *****"
      login
      submit_src(q, lang_id, src)
    end

    def fetch_all
      login
      assignments = fetch_assignments
      assignments.map do |q, url|
        pbm = fetch_problem(q, url)
        yield pbm if block_given?
        pbm
      end
    end
  end
end
