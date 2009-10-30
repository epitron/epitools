# Return the longest common prefix between two strings.
def longest_common_prefix(strings)
  p = nil
  strings.map{|s|s.size}.min.times do |c|
    if strings.map{|s|s[c]}.uniq.size == 1
      p = c
    else
      break
    end
  end

  strings.first[0..p] unless p.nil?
end


def longest_common_subsequence(s1, s2)
 
  num = Array.new(s1.size) { Array.new(s2.size) }
  len, ans = 0
 
  s1.scan(/./).each_with_index do |l1,i|
    s2.scan(/./).each_with_index do |l2,j|
      unless l1==l2
        num[i][j]=0
      else
        if (i==0 || j==0)
          num[i][j] = 1
        else
          num[i][j] = 1 + num[i-1][j-1]
        end
        len = ans = num[i][j] if num[i][j] > len
      end
    end
  end

  ans
 
end

if $0 == __FILE__
  prefix_strings = [
   "shenanigans, gentlemen!",
    "shenanigans has been called",
    "shenanigans: a great restaurant."
  ]
  
  subsequence_strings = [
    "i call shenanigans on you!",
    "shenanigans is a great restaurant.",
    "you like this? shenanigans!"
  ]

  p longest_common_prefix(prefix_strings)
  p longest_common_subsequence(*subsequence_strings[0..1])
end


