module Asm
  class Evaluator
    operations = {
      mov: :initialize_reg,
      inc: :increase,
      dec: :decrease,
      cmp: :compare,
      jmp: :jmp,
    }

    operations.each do |operation_name, operation|
      define_method operation_name do |destination, value = 1|
        @operations_queue << [operation, destination, value ]
      end
    end

    help_operations = {
      initialize_reg: :+,
      increase:       :+,
      decrease:       :-,
    }

    help_operations.each do |operation_name, operation|
      define_method operation_name do |destination ,other|
        @registers[destination] =
        @registers[destination].public_send operation, get_value(other)
      end
    end

    def initialize(&block)
      @ax, @bx, @cx, @dx      = :ax, :bx, :cx, :dx
      @cmp, @current_position = 0, 0
      @operations_queue       = []
      @label_names            = {}
      @jumps_list = {
        jmp: :+,
        je:  :==,
        jne: :!=,
        jl:  :<,
        jle: :<=,
        jg:  :>,
        jge: :>=,
      }
      @registers = { ax: 0, bx: 0, cx: 0, dx: 0 }
      instance_eval &block
    end

    def perform_operations
      while (@current_position != @operations_queue.length)
        [@operations_queue[@current_position]].each do |operation, destination, arguments|
          if @jumps_list.has_key? operation
            label_position = @label_names.fetch(destination, destination)
            call_jump operation, label_position
          else
            public_send operation, destination, arguments
            @current_position += 1
          end
        end
      end

      @registers.values.to_a
    end

    def method_missing(name, *arguments)
      @operations_queue << [name, *arguments] if @jumps_list.has_key? name

      name
    end

    def compare(destination, other)
      @cmp = @registers[destination] <=> get_value(other)
    end

    private

    def get_value(value)
      @registers[value] or value
    end

    def call_jump(type, label_position)
      if @cmp.method(@jumps_list[type]).call 0
        @current_position  = label_position
      else
        @current_position += 1
      end
    end

    def label(name)
      @label_names[name] = @operations_queue.length
    end
  end

  def self.asm(&block)
    Evaluator.new(&block).perform_operations
  end
end
