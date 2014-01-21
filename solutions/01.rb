class Integer
  def prime?
    self > 1 and (2..Math.sqrt(self)).all? { |div| remainder(div).nonzero? }
  end

  def prime_factors
    factor = (2...abs).find { |div| remainder(div).zero? }
    factor.nil? ? [abs] : [factor] + (abs / factor).prime_factors
  end

  def harmonic
    (1..self).map(&:reciprocal).reduce(&:+)
  end

  def reciprocal
    1 / to_r
  end

  def digits
    abs.to_s.chars.map(&:to_i)
  end
end

class Array
  def frequencies
    reduce(Hash.new(0)) { |value,key| value if value[key] += 1 }
  end

  def average
    reduce { |sum,number| sum + number } / count.to_f
  end

  def drop_every(n)
    select.each_with_index { |_,i| (i + 1).remainder(n).nonzero? }
  end

  #OPTIMIZE
  def combine_with(other)
    list = []

    until count.zero? and other.count.zero? do
      list << shift unless empty?
      list << other.shift unless other.empty?
    end

    list
  end
end
