# frozen_string_literal: true

module AtCoderFriends
  # holds problem information
  class Problem
    SECTION_INTRO = 'INTRODUCTION'
    SECTION_STATEMENT = 'STATEMENT'
    SECTION_TASK = 'TASK'
    SECTION_IN_FMT = 'INPUT_FORMAT'
    SECTION_OUT_FMT = 'OUTPUT_FORMAT'
    SECTION_IO_FMT = 'INOUT_FORMAT'
    SECTION_CONSTRAINTS = 'CONSTRAINTS'
    SECTION_IN_SMP = 'INPUT_SAMPLE_%<no>s'
    SECTION_IN_SMP_PAT = /^INPUT_SAMPLE_(?<no>\d+)$/.freeze
    SECTION_OUT_SMP = 'OUTPUT_SAMPLE_%<no>s'
    SECTION_OUT_SMP_PAT = /^OUTPUT_SAMPLE_(?<no>\d+)$/.freeze
    SECTION_IO_SMP = 'INOUT_SAMPLE'

    SampleData = Struct.new(:no, :ext, :txt)

    # holds information about input format
    class InputFormat
      ITEM_RANK = { number: 1, decimal: 2, string: 3 }.freeze

      attr_reader :container
      attr_accessor :names, :size, :delim, :items


      def initialize(
        container, item,
        names = nil, size = nil,
        delim = '', items = []
      )
        @container = container
        @item = item
        @names = names
        @size = size
        @delim = delim
        @items = items
      end

      def to_s
        if container == :unknown
          "#{container} #{item}"
        else
          "#{container} #{item}(#{items}) #{names} #{size} #{delim}"
        end
      end

      def item
        @item || @items.max_by { |k| ITEM_RANK[k] } || :number
      end

      def components
        @components ||=
          case container
          when :varray_matrix
            varray_matrix_components
          when :matrix_varray
            matrix_varray_components
          end
      end

      def varray_matrix_components
        [
          self.class.new(
            :varray, nil, names[0..-2], size[0..0],
            delim, items[0..-2]
          ),
          self.class.new(
            :matrix, item, names[-1..-1], size,
            delim, items[-1..-1] || []
          )
        ]
      end

      def matrix_varray_components
        [
          self.class.new(
            :matrix, item, names[0..0], size,
            delim, items[0..0]
          ),
          self.class.new(
            :varray, nil, names[1..-1], size[0..0],
            delim, items[1..-1] || []
          )
        ]
      end
    end

    Constant = Struct.new(:name, :type, :value)

    Options = Struct.new(:interactive, :binary_values)

    SourceCode = Struct.new(:ext, :txt)

    attr_reader :q, :samples, :sources, :options
    attr_accessor :page, :sections, :formats_src, :constants

    def initialize(q, page = Mechanize::Page.new)
      @q = q
      @page = page
      @sections = {}
      @samples = []
      @formats_src = []
      @constants = []
      @options = Options.new
      @sources = []
      yield self if block_given?
    end

    def url
      @url ||= page.uri.to_s
    end

    def body_content
      @body_content ||= page.search('body')[0]&.content
    end

    def formats
      @formats ||= formats_src.reject { |f| f.container == :unknown }
    end

    def add_smp(no, ext, txt)
      @samples << SampleData.new(no, ext, txt)
    end

    def add_src(ext, txt)
      @sources << SourceCode.new(ext, txt)
    end
  end
end
