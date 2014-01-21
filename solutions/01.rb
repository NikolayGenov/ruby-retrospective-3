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
    each_with_object(Hash.new(0)) { |key, result| result[key] += 1 }
  end

  def average
    reduce(&:+) / count.to_f
  end

  def drop_every(n)
    each_slice(n).map { |slice| slice.take(n - 1) }.reduce(&:+) or []
  end

  def combine_with(other)
    longer, shorter = length > other.length ? [self, other] : [other, self]

    short_part = take(shorter.length).zip(other.take(shorter.length)).flatten(1)
    rest       = longer.drop(shorter.length)

    short_part + rest
  end
end
