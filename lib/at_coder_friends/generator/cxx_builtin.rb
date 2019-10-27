# frozen_string_literal: true

module AtCoderFriends
  module Generator
    module CxxBuiltinConstants
      ACF_HOME = File.realpath(File.join(__dir__, '..', '..', '..'))
      TMPL_DIR = File.join(ACF_HOME, 'templates')
      DEFAULT_TMPL = File.join(TMPL_DIR, 'cxx_builtin_default.cxx')
      INTERACTIVE_TMPL = File.join(TMPL_DIR, 'cxx_builtin_interactive.cxx')
      SCANF_FMTS = [
        'scanf("%<fmt>s", %<addr>s);',
        'REP(i, %<sz1>s) scanf("%<fmt>s", %<addr>s);',
        'REP(i, %<sz1>s) REP(j, %<sz2>s) scanf("%<fmt>s", %<addr>s);'
      ].freeze
      FMT_FMTS = { number: '%d', string: '%s', char: '%s' }.freeze
      ADDR_FMTS = {
        single: {
          number: '&%<v>s',
          string: '%<v>s'
        },
        harray: {
          number: '%<v>s + i',
          string: '%<v>s[i]',
          char: '%<v>s'
        },
        varray: {
          number: '%<v>s + i',
          string: '%<v>s[i]'
        },
        matrix: {
          number: '&%<v>s[i][j]',
          string: '%<v>s[i][j]',
          char: '%<v>s[i]'
        }
      }.freeze
      DEFAULT_OUTPUT = <<~TEXT
        int ans = 0;
        printf("%d\\n", ans);
      TEXT
      BINARY_OUTPUT_FMT = <<~TEXT
        bool cond = false;
        puts(cond ? "%s" : "%s");
      TEXT
    end

    # generates C++ source code from problem description
    class CxxBuiltin
      include CxxBuiltinConstants

      attr_reader :cfg, :pbm

      def initialize(cfg = nil)
        @cfg = cfg || {}
      end

      def process(pbm)
        src = generate(pbm)
        pbm.add_src(:cxx, src)
      end

      def generate(pbm)
        @pbm = pbm
        src = File.read(select_template)
        src = embed_lines(src, '/*** URL ***/', [pbm.url])
        src = embed_lines(src, '/*** CONSTS ***/', gen_consts)
        src = embed_lines(src, '/*** DCLS ***/', gen_decls)
        src = embed_lines(src, '/*** INPUTS ***/', gen_inputs)
        embed_lines(src, '/*** OUTPUT ***/', gen_output.split("\n"))
      end

      def embed_lines(src, pat, lines)
        re = Regexp.escape(pat)
        src.gsub(
          /^(.*)#{re}(.*)$/,
          lines.map { |s| '\1' + s + '\2' }.join("\n")
        )
      end

      def select_template(interactive = pbm.options.interactive)
        interactive ? interactive_template : default_template
      end

      def default_template
        cfg['default_template'] || DEFAULT_TMPL
      end

      def interactive_template
        cfg['interactive_template'] || INTERACTIVE_TMPL
      end

      def gen_consts(constants = pbm.constants)
        constants.map { |c| gen_const(c) }
      end

      def gen_const(c)
        v = cnv_const_value(c.value)
        if c.type == :max
          "const int #{c.name.upcase}_MAX = #{v};"
        else
          "const int MOD = #{v};"
        end
      end

      def cnv_const_value(v)
        v
          .sub(/\b10\^/, '1e')
          .sub(/\b2\^/, '1<<')
          .gsub(',', "'")
      end

      def gen_decls(inpdefs = pbm.formats)
        inpdefs.map { |inpdef| gen_decl(inpdef) }.flatten
      end

      def gen_decl(inpdef)
        case inpdef.container
        when :single
          gen_single_decl(inpdef)
        when :harray
          gen_harray_decl(inpdef)
        when :varray
          gen_varray_decl(inpdef)
        when :matrix
          gen_matrix_decl(inpdef)
        end
      end

      def gen_single_decl(inpdef)
        names = inpdef.names
        case inpdef.item
        when :number
          dcl = names.join(', ')
          "int #{dcl};"
        when :string
          names.map { |v| "char #{v}[#{v.upcase}_MAX + 1];" }
        end
      end

      def gen_harray_decl(inpdef)
        v = inpdef.names[0]
        sz = gen_arr_size(inpdef.size)[0]
        case inpdef.item
        when :number
          "int #{v}[#{sz}];"
        when :string
          "char #{v}[#{sz}][#{v.upcase}_MAX + 1];"
        when :char
          "char #{v}[#{sz} + 1];"
        end
      end

      def gen_varray_decl(inpdef)
        names = inpdef.names
        sz = gen_arr_size(inpdef.size)[0]
        case inpdef.item
        when :number
          names.map { |v| "int #{v}[#{sz}];" }
        when :string
          names.map { |v| "char #{v}[#{sz}][#{v.upcase}_MAX + 1];" }
        end
      end

      def gen_matrix_decl(inpdef)
        v = inpdef.names[0]
        sz1, sz2 = gen_arr_size(inpdef.size)
        case inpdef.item
        when :number
          "int #{v}[#{sz1}][#{sz2}];"
        when :string
          "char #{v}[#{sz1}][#{sz2}][#{v.upcase}_MAX + 1];"
        when :char
          "char #{v}[#{sz1}][#{sz2} + 1];"
        end
      end

      def gen_arr_size(szs)
        szs.map { |sz| sz =~ /\D/ ? "#{sz.upcase}_MAX" : sz }
      end

      def gen_inputs(inpdefs = pbm.formats)
        inpdefs.map { |inpdef| gen_input(inpdef) }.flatten
      end

      # rubocop:disable Metrics/AbcSize
      def gen_input(inpdef)
        dim = inpdef.size.size - (inpdef.item == :char ? 1 : 0)
        scanf = SCANF_FMTS[dim]
        sz1, sz2 = inpdef.size
        fmt = FMT_FMTS[inpdef.item] * inpdef.names.size
        addr_fmt = ADDR_FMTS[inpdef.container][inpdef.item]
        addr = inpdef.names.map { |v| format(addr_fmt, v: v) }.join(', ')
        format(scanf, sz1: sz1, sz2: sz2, fmt: fmt, addr: addr)
      end
      # rubocop:enable Metrics/AbcSize

      def gen_output(vs = pbm.options.binary_values)
        if vs
          format(BINARY_OUTPUT_FMT, *vs)
        else
          DEFAULT_OUTPUT
        end
      end
    end
  end
end