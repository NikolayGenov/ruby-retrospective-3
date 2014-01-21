module Graphics
  class Point
    attr_reader :x, :y

    def initialize(x, y)
      @x = x
      @y = y
    end

    def rasterize_on(canvas)
      canvas.set_pixel x, y
    end

    def ==(other)
      (self <=> other).zero?
    end

    alias_method :eql?, :==

    def hash
      x.hash ^ y.hash
    end

    def <=>(other)
      [x, y] <=> [other.x, other.y]
    end
  end

  class Line
    attr_reader :from, :to

    def initialize(from, to)
      @from, @to = [from,to].minmax
    end

    def rasterize_on(canvas)
      BresenhamLineRasterization.new(from.x, from.y, to.x, to.y).rasterize_on(canvas)
    end

    def ==(other)
      (self <=> other).zero?
    end

    alias_method :eql?, :==

    def hash
      from.hash ^ to.hash
    end

    def <=>(other)
      [from, to] <=> [other.from, other.to]
    end

    class BresenhamLineRasterization
      def initialize(from_x, from_y, to_x, to_y)
        @from_x, @from_y = from_x, from_y
        @to_x, @to_y     = to_x, to_y
        @steep_slope     = (@to_y - @from_y).abs > (@to_x - @from_x).abs
      end

      def rasterize_on(canvas)
        rotate_coordinates_by_ninety_degrees if @steep_slope
        swap_from_and_to if @from_x > @to_x

        draw_line_pixels_on canvas
      end

      def rotate_coordinates_by_ninety_degrees
        @from_x, @from_y = @from_y, @from_x
        @to_x,   @to_y   = @to_y,   @to_x
      end

      def swap_from_and_to
        @from_x, @to_x = @to_x, @from_x
        @from_y, @to_y = @to_y, @from_y
      end

      def error_delta
        delta_x =  @to_x - @from_x
        delta_y = (@to_y - @from_y).abs.to_f

        delta_y / delta_x
      end

      def vertical_drawing_direction
        @from_y < @to_y ? 1 : -1
      end

      def draw_line_pixels_on(canvas)
        @error = 0.0
        @y     = @from_y

        @from_x.upto(@to_x).each do |x|
          set_pixel_on canvas, x, @y
          calculate_next_y_approximation
        end
      end

      def calculate_next_y_approximation
        @error += error_delta

        if @error * 2 >= 1
          @error -= 1
          @y += vertical_drawing_direction
        end
      end

      def set_pixel_on(canvas, x, y)
        if @steep_slope
          canvas.set_pixel y, x
        else
          canvas.set_pixel x, y
        end
      end
    end
  end

  class Rectangle
    attr_reader :top_left, :bottom_right, :left, :right

    def initialize(left, right)
      @left,@right = [left,right].minmax
      @top_left, @bottom_right = @left, @right
      flip_points if @left.y > @right.y
    end

    def rasterize_on(canvas)
      [
        Line.new(top_left,     top_right),
        Line.new(top_right,    bottom_right),
        Line.new(bottom_right, bottom_left),
        Line.new(bottom_left,  top_left)
      ].each { |line| line.rasterize_on canvas }
    end

    def bottom_left
      Point.new top_left.x,     bottom_right.y
    end

    def top_right
      Point.new bottom_right.x, top_left.y
    end

    def ==(other)
      (self <=> other).zero?
    end

    alias_method :eql?, :==

    def hash
      top_left.hash ^ bottom_right.hash
    end

    def <=>(other)
      [top_left, bottom_right] <=> [other.top_left, other.bottom_right]
    end

    private

    def flip_points
      @top_left     = Point.new left.x,  right.y
      @bottom_right = Point.new right.x, left.y
    end
  end

  class Canvas
    attr_reader :width, :height

    def initialize(width, height)
      @width  = width
      @height = height
      @pixels = {}
    end

    def set_pixel(x, y)
      @pixels[[x, y]] = true
    end

    def pixel_at?(x, y)
      @pixels[[x, y]]
    end

    def draw(figure)
      figure.rasterize_on(self)
    end

    def render_as(renderer)
      renderer.new(self).render
    end
  end

  module Renderers
    class Base
      attr_reader :canvas

      def initialize(canvas)
        @canvas = canvas
      end

      def render
        raise NotImplementedError
      end
    end

    class Ascii < Base
      def render
        pixels = 0.upto(canvas.height.pred).map do |y|
          0.upto(canvas.width.pred).map { |x| pixel_at(x, y) }
        end

        join_lines pixels.map { |line| join_pixels line }
      end

      private

      def pixel_at(x, y)
        canvas.pixel_at?(x, y) ? full_pixel : blank_pixel
      end

      def full_pixel
        '@'.freeze
      end

      def blank_pixel
        '-'.freeze
      end

      def join_pixels(line)
        line.join(''.freeze)
      end

      def join_lines(lines)
        lines.join("\n".freeze)
      end
    end

    class Html < Ascii
      TEMPLATE ='<!DOCTYPE html>
        <html>
        <head>
        <title>Rendered Canvas</title>
        <style type="text/css">
        .canvas {
          font-size: 1px;
          line-height: 1px;
        }
        .canvas * {
          display: inline-block;
          width: 10px;
          height: 10px;
          border-radius: 5px;
        }
        .canvas i {
          background-color: #eee;
        }
        .canvas b {
          background-color: #333;
        }
        </style>
        </head>
        <body>
        <div class="canvas">
          %s
        </div>
        </body>
        </html>
      '.freeze

      def render
        TEMPLATE % super
      end

      private

      def full_pixel
        '<b></b>'.freeze
      end

      def blank_pixel
        '<i></i>'.freeze
      end

      def join_lines(lines)
        lines.join('<br>'.freeze)
      end
    end
  end
end
