module Graphics
  class Canvas
    attr_reader :width, :height

    def initialize(width, height)
      @width  = width
      @height = height
      @matrix = Array.new(height) { Array.new(width) {:blank} }
    end

    def set_pixel(x, y)
      @matrix[y][x] = :full
    end

    def pixel_at?(x, y)
      @matrix[y][x] == :full
    end

    def draw(figure)
      case figure
      when Point     then draw_point(figure)
      when Line      then draw_line(figure)
      when Rectangle then draw_rectangle(figure)
      end
    end

    def render_as(render)
      render.new(self).render
    end

    private
    def draw_point(point)
      set_pixel(point.x, point.y)
    end

    def draw_line(line)
      bresenham_algorithm(line.from.x, line.from.y, line.to.x, line.to.y)
    end

    def draw_rectangle(figure)
      draw_line(Line.new(figure.top_left,    figure.top_right))
      draw_line(Line.new(figure.bottom_left, figure.bottom_right))
      draw_line(Line.new(figure.top_left,    figure.bottom_left))
      draw_line(Line.new(figure.top_right,   figure.bottom_right))
    end

    def bresenham_algorithm(x_1, y_1, x_2, y_2)
      delta_x, delta_y = (x_2 - x_1).abs, (y_2 - y_1).abs
      slope_x          = x_1 < x_2 ? 1 : -1
      slope_y          = y_1 < y_2 ? 1 : -1
      error            = delta_x - delta_y

      set_pixel(x_1,y_1)

      bresenham_loop(x_1, y_1, x_2, y_2, error, slope_x, slope_y, delta_x, delta_y)
    end

    def bresenham_loop(x_1, y_1, x_2, y_2, error, slope_x, slope_y, delta_x, delta_y)
      while x_1 != x_2 or y_1 != y_2  do
        delta_error = error * 2
        x_1, error = move_point(x_1, slope_x, error, -delta_y) if -delta_error < delta_y
        y_1, error = move_point(y_1, slope_y, error,  delta_x) if  delta_error < delta_x

        set_pixel(x_1, y_1)
      end
    end

    def move_point(point, slope, error, delta_point)
      error += delta_point
      point += slope
      [point, error]
    end
  end

  class Point
    attr_reader :x, :y

    def initialize(x, y)
      @x = x
      @y = y
    end

    def ==(other)
      (self <=> other).zero?
    end

    alias_method :eql?, :==

    def hash
      @x.hash ^ @y.hash
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

    def ==(other)
      (self <=> other).zero?
    end

    alias_method :eql?, :==

    def hash
      @from.hash ^ @to.hash
    end

    def <=>(other)
      [from, to] <=> [other.from, other.to]
    end
  end

  class Rectangle
    attr_reader :top_left, :top_right, :bottom_left, :bottom_right, :left, :right

    def initialize(left, right)
      @left,@right = [left,right].minmax
      @top_left, @bottom_right = @left, @right
      flip_points if @left.y > @right.y
      @bottom_left = Point.new(@top_left.x, @bottom_right.y)
      @top_right   = Point.new(@bottom_right.x, @top_left.y)
    end

    def ==(other)
      (self <=> other).zero?
    end

    alias_method :eql?, :==

    def hash
      @top_left.hash ^ @bottom_right.hash
    end

    def <=>(other)
      [@top_left, @bottom_right] <=> [other.top_left, other.bottom_right]
    end

    private
    def flip_points
      @top_left     = Point.new @left.x, @right.y
      @bottom_right = Point.new @right.x, @left.y
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
        pixels = zero.upto(canvas.height.pred).map do |y|
          zero.upto(canvas.width.pred).map { |x| pixel_at(x, y) }
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

    class Html < Base
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
