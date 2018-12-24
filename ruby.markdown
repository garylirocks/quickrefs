Ruby Cheatsheet
===============

- [Preface](#preface)
- [Iteration](#iteration)
    - [each](#each)
- [Strings](#strings)
- [Hashes](#hashes)
- [Sorting](#sorting)
- [Symbols](#symbols)
- [Blocks](#blocks)
- [Procs](#procs)
- [lambda](#lambda)
- [OOP](#oop)


## Preface

Source:

* [CodeCademy Ruby Course][codecademy_ruby]


## Iteration

```ruby
for i in 1..3           # including end point, output 1, 2, 3
    puts i
end

for i in 1...3          # excluding end point, output 1, 2
    puts i
end
```

### each

```ruby
arr = (1..5).to_a       # to array
arr.each { |i|
    puts i
}
```


## Strings

```ruby
s = 'a quick fox'
s.split

# output
["a", "quick", "fox"]
```


## Hashes

```ruby
family = {
    "Homer" => "dad",
    "Marge" => "mom",
    "Lisa" => "sister",
    "Maggie" => "sister",
    "Abe" => "grandpa",
    "Santa's Little Helper" => "dog"
}

family.each { |x, y| puts "#{x}: #{y}" }

# output
Homer: dad
Marge: mom
Lisa: sister
Maggie: sister
Abe: grandpa
Santa's Little Helper: dog
```


## Sorting

```ruby
a = [2, 8, 3, 9]
# => [2, 8, 3, 9]

a.sort!
# => [2, 3, 8, 9]

ahash = {a: 8, b: 5, c: 10}
# => {:a=>8, :b=>5, :c=>10}

ahash.sort_by {|k, v| v}        # sorting a hash by value
# => [[:b, 5], [:a, 8], [:c, 10]]


books = ["Charlie and the Chocolate Factory", "War and Peace", "Utopia", "A Brief History of Time", "A Wrinkle in Time"]

# To sort our books in ascending order, in-place
books.sort! { |firstBook, secondBook| firstBook <=> secondBook }

# Sort your books in descending order, in-place below
books.sort! { |firstBook, secondBook| -(firstBook <=> secondBook) }
```


## Symbols

There's only one copy of any particular symbol

```ruby
puts "string".object_id
puts "string".object_id

puts :symbol.object_id
puts :symbol.object_id

# output
# 10822060
# 10821680
# 318568
# 318568
```

Converting between strings and symbols

```ruby
:abc.to_s
# => "abc"

"abc".to_sym
# => :abc

"abc".intern   # another way to convert strings to symbols
# => :abc
```

Symbol keys are faster:

```ruby
require 'benchmark'

string_AZ = Hash[("a".."z").to_a.zip((1..26).to_a)]
symbol_AZ = Hash[(:a..:z).to_a.zip((1..26).to_a)]

string_time = Benchmark.realtime do
    100_000.times { string_AZ["r"] }
end

symbol_time = Benchmark.realtime do
    100_000.times { symbol_AZ[:r] }
end

puts "String time: #{string_time} seconds."
puts "Symbol time: #{symbol_time} seconds."

### output ###
# String time: 0.039612948 seconds.
# Symbol time: 0.020612846 seconds.
```


## Blocks

Blocks are delimited by `do..end` or `{}`, which can be provided to method with `yield`

```ruby
def double(n)
    yield n
end

double(100) { |x| x * 2 }
```


## Procs

Procs are like named blocks, use `&proc_name` where a block is needed,
**procs are objects, while blocks are not**

```ruby
square = Proc.new {|x| x ** 2}
#   => #<Proc:0x0000000174bc50@(irb):1>

[1,2,3].map(&square)
#   => [1, 4, 9]
```

Pass proc as a parameter to a method(with yield)

```ruby
def greeter (name)
    puts 'before yield'
    yield
    puts 'before another yield'
    yield
end

sayHello = Proc.new { puts "Hello there!" }
greeter('gary', &sayHello)

### output
# before yield
# Hello there!
# before another yield
# Hello there!
```

Convert methods to procs:

```ruby
a = [1, 2, 3]
# => [1, 2, 3]

a.map(&:to_s)
# => ["1", "2", "3"]
```


## lambda

```ruby
strings = ["leonardo", "donatello", "raphael", "michaelangelo"]
#   => ["leonardo", "donatello", "raphael", "michaelangelo"]

symbolize = lambda { |x| x.to_sym }
#   => #<Proc:0x0000000170d130@(irb):25 (lambda)>

symbols = strings.collect(&symbolize)
#   => [:leonardo, :donatello, :raphael, :michaelangelo]
```

lambda and proc comparison:

* lambda checks the number of args, proc does not
* when lambda returns, it pass control back to the calling method, proc does not

example

```ruby
mySym_proc = Proc.new { |x| x.to_sym }
#   => #<Proc:0x000000017981e0@(irb):35>

mySym_lambda = lambda { |x| x.to_sym }
#   => #<Proc:0x0000000178b5f8@(irb):36 (lambda)>

mySym_lambda.call('ab', 'cd')    # throw an error when args number do not match
#   ArgumentError: wrong number of arguments (2 for 1)
#       from (irb):36:in `block in irb_binding'
#       from (irb):39:in `call'
#       from (irb):39
#       from /home/lee/.rvm/rubies/ruby-2.1.0/bin/irb:11:in `<main>'

mySym_lambda.call('ab')
#   => :ab

mySym_proc.call('ab', 'cd')  # just ignores unexpected elements
#   => :ab
```

example:

```ruby
def call_proc
    p = Proc.new {
            puts "proc call"
            return
        }
    p.call
    puts "after proc call"  # will not be executed
end

def call_lambda
    l = lambda {
            puts "lambda call"
            return
        }
    l.call
    puts "after lambda call"
end

call_proc
call_lambda

### output
# proc call
# lambda call
# after lambda call
```


## OOP

Class definition basics:

```ruby
class Message
    @@messages_sent = 0     # class variable starts with '@@'

    def initialize(from, to)
        @from = from        # instance variable starts with '@'
        @to = to

        @@messages_sent += 1
    end
end

class Email < Message
    def initialize(from, to)
        super               # call superclass's method with the same name
    end
end

my_message = Message.new('Gary', 'Jack')
```

Attribute access and modify:

```ruby
class Person
    attr_reader :name
    attr_writer :job
    attr_accessor :job      # both read and write

    def initialize(name, job)
        @name = name
        @job = job
    end
end
```

Include module in a class (mixins):

```ruby
class Angle
    include Math              # include the Math module
    attr_accessor :radians

    def initialize(radians)
        @radians = radians
    end

    def cosine
        cos(@radians)           # do not need 'Math::' prefix anymore
    end
end

acute = Angle.new(1)
acute.cosine
```

[codecademy_ruby]: http://www.codecademy.com/
