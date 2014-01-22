module Asm
  class Register
    class << self
      attr_accessor :flag
    end

    attr_reader :value

    def initialize
      @value = 0
    end

    def mov(source)
      @value = get_value source
    end

    def inc(source)
      @value += get_value(source)
    end

    def dec(source)
      @value -= get_value source
    end

    def cmp(source)
      self.class.flag = @value <=> get_value(source)
    end

    private

    def get_value(source)
      source.is_a?(self.class) ? source.value : source
    end
  end

  class Asm

    REGISTERS = [:ax,:bx, :cx, :dx]

    REGISTER_OPERATIONS = [:mov, :inc, :dec, :cmp]

    JUMPS = {
      jmp: :+,
      je:  :==,
      jne: :!=,
      jl:  :<,
      jle: :<=,
      jg:  :>,
      jge: :>=,
    }

    REGISTER_OPERATIONS.each do |operation|
      define_method operation do |target, value = 1|
        push_operation target, operation, value
      end
    end

    JUMPS.each do |jump_name, compare_operation|
      check_operation = -> { Register.flag.public_send compare_operation, 0}
      define_method jump_name do |target|
        push_jump(target, check_operation)
      end
    end

    def initialize(&block)
      @commands            = []
      @label_names         = Hash.new { |_, key| key }
      @registers           = Hash.new { |hash, key| hash[key] = Register.new }
      @instruction_pointer = 0
      instance_eval(&block)
    end

    def perform_operations
      while @instruction_pointer < @commands.length
        @instruction_pointer = @commands[@instruction_pointer].call
      end

      self
    end

    def label(name)
      @label_names[name] = @commands.length
    end

    def get_registers_values
      REGISTERS.map { |register| @registers[register].value }
    end

    def method_missing(name, *arguments)
      REGISTERS.member?(name) ? @registers[name] : name
    end

    private

    def push_jump(target, check_flag)
      @commands << -> do
        check_flag.call ? @label_names[target] : @instruction_pointer + 1
      end
    end

    def push_operation(target, operation, value)
      @commands << -> do
        target.send operation, value

        @instruction_pointer + 1
      end
    end
  end

  def self.asm(&block)
    Asm.new(&block).perform_operations.get_registers_values
  end
end
