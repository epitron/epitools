strings = [
  "i call shenanigans on you!",
  "shenanigans is a great restaurant.",
  "you like this? shenanigans!"
]

# Return the longest common prefix between two strings.  If max is
# specified then the longest common prefix cannot exceed it
def common_prefix(s1, s2, max = nil, min = 3)
  shortest = [s1.size, s2.size].min
  shortest.times do |i|
    if s1[i] != s2[i]
      if i >= min
      common = s1.slice(0, i) 
  end
  return s1.slice(0, min)
end


def lcs(s1, s2)
 
  num = Array.new(s1.size) { Array.new(s2.size) }
  len, ans = 0
 
  s1.scan(/./).each_with_index do |l1,i |
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


p lcs(strings[0], strings[1])


