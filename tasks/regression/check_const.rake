# frozen_string_literal: true

require_relative 'regression'

module AtCoderFriends
  # tasks for regression
  module Regression
    module_function

    CONST_PAT = {
      mod: /
        (.{,30}(?:
          で割った|modulo|mod\b|divided\s+by|dividing\s+by
        ).{,30})
      /xmi,
      max: /
        (.{,30}(?:
          ≦|≤|\\le|&leq?;
          |＜|\\lt|&lt;
          |以上.{1,25}以下の整数
        ).{,30})
      /xmi
    }.freeze

    def collect(tgt)
      open_const_report('collect', tgt) do |f|
        local_pbm_list.each do |contest, q, url|
          page = agent.get(url)
          body = page.body.force_encoding('utf-8')
          ms = body.scan(CONST_PAT[tgt.to_sym])
          ms.each do |m|
            s = m[0].delete("\r\n")
            f.puts [contest, q, tsv_escape(s)].join("\t")
          end
        end
      end
    end

    def check_mod
      open_const_report('check', 'mod') do |f|
        local_pbm_list.each do |contest, q, url|
          pbm = local_scraping_agent(nil, contest).fetch_problem(q, url)
          Parser::Sections.process(pbm)
          Parser::Modulo.process(pbm)
          pbm.constants.each do |cnst|
            f.puts [contest, q, cnst.value].join("\t")
          end
        end
      end
    end

    def check_max
      open_const_report('check', 'max') do |f|
        local_pbm_list.each do |contest, q, url|
          pbm = local_scraping_agent(nil, contest).fetch_problem(q, url)
          Parser::Sections.process(pbm)
          Parser::Constraints.process(pbm)
          pbm.constants.each do |cns|
            f.puts [contest, q, "#{cns.name}:#{cns.value}"].join("\t")
          end
        end
      end
    end

    def merge_list(tgt)
      tbl = load_merge_list(tgt)
      save_merge_list(tgt, tbl)
    end

    def load_merge_list(tgt)
      tbl = {}
      %w[collect check]
        .map { |act| load_const_report(act, tgt) }
        .each
        .with_index(1) do |data, n|
          data
            .group_by { |contest, q, _| "#{contest}\t#{q}" }
            .map { |key, grp| [key, grp.map { |row| row[2] }.join("\n")] }
            .each do |key, txt|
              tbl[key] ||= { 'v1' => '', 'v2' => '' }
              tbl[key]["v#{n}"] = '"' + txt + '"'
            end
        end
      tbl
    end

    def save_merge_list(tgt, tbl)
      open_const_report('merge', tgt) do |f|
        tbl.sort.each do |k, h|
          f.puts [k, h['v1'], h['v2']].join("\t")
        end
      end
    end

    def open_const_report(act, tgt)
      open_report("#{act}_#{tgt}.txt") { |f| yield f }
    end

    def load_const_report(act, tgt)
      file = report_path("#{act}_#{tgt}.txt")
      Encoding.default_external = 'utf-8'
      CSV.read(file, col_sep: "\t", headers: false)
    end
  end
end

namespace :regression do
  desc 'list all mod values'
  task :collect_mod do
    AtCoderFriends::Regression.collect('mod')
  end

  desc 'check extracted mod values'
  task :check_mod do
    AtCoderFriends::Regression.check_mod
  end

  desc 'merge mod values list'
  task :merge_mod do
    AtCoderFriends::Regression.merge_list('mod')
  end

  desc 'list all max values'
  task :collect_max do
    AtCoderFriends::Regression.collect('max')
  end

  desc 'check extracted max values'
  task :check_max do
    AtCoderFriends::Regression.check_max
  end

  desc 'merge max values list'
  task :merge_max do
    AtCoderFriends::Regression.merge_list('max')
  end
end
