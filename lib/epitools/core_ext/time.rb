class Time

  #
  # Relative time, in words. (eg: "1 second ago", "2 weeks from now", etc.)
  #
  def in_words
    delta   = (Time.now-self).to_i
    a       = delta.abs

    amount  = case a
      when 0
        'just now'
      when 1
        '1 second'
      when 2..59
        "second".amount(a)
      when 1.minute...1.hour
        "minute".amount(a/1.minute)
      when 1.hour...1.day
        "hour".amount(a/1.hour)
      when 1.day...7.days
        "day".amount(a/1.day)
      when 1.week...1.month
        "week".amount(a/1.week)
      when 1.month...12.months
        "month".amount(a/1.month)
      else
        "year".amount(a/1.year)
    end

    if delta < 0
      amount += " from now"
    elsif delta > 0
      amount += " ago"
    end

    amount
  end

  #
  # Which "quarter" of the year does this date fall into?
  #
  def quarter
    (month / 3.0).ceil
  end

  #
  # How many seconds have elapsed since this time?
  #
  def elapsed
    Time.now - self
  end

end


