# -*- coding: utf-8 -*-
require 'tracer'

def tokenizer(s)
  s.gsub(%r<[()]>,' \& ').split
end

def read_from(tokens)
  if tokens.length == 0
    raise SyntaxError "unexpected EOF while reading "
  end

  token = tokens.shift
  case token
  when '('
    l = []
    until tokens[0] == ')'
      l.push(read_from(tokens))
    end
    tokens.shift # => pop ')'
    l
  when ')'
    raise SyntaxError "unexpected ')'"
  else
    atom(token)
  end
  
end


module Kernel
  def Symbol(obj)
    obj.intern
  end
end

def atom(token, type=[:Integer, :Float, :Symbol])
  send(type.shift, token)
rescue ArgumentError
  retry
end

def read(s)
  read_from(tokenizer(s))
end
alias :parse :read


def _eval(x, env=$global_env)
  case x
  when Symbol
    env.find(x)[x]
  when Array
    case x.first
    when :quote
      _, exp = x
      exp
    when :if
      _, test, conseq, alter = x
      _eval((_eval(test, env) ? conseq : alter), env )
    when :set
      _, var, exp = x
      env.find(var)[var] = _eval(exp, env)
    when :define
      _, var, exp = x
      env[var] = _eval(exp, env)
      nil
    when :lambda
      _, vars, exp = x
      lambda {|*args| _eval(exp, Env.new(vars, args, env))}
    when :begin
      x[1..-1].inject(nil) {|val, exp| val = _eval(exp, env)}
    else
      proc, *exps = x.inject([]) {|mem, exp| mem << _eval(exp,env)}
      proc[*exps]
    end
  else
    x
  end
end

class Env < Hash
  def initialize(params=[], args=[], outer=[])
    h = Hash[params.zip(args)]
    self.merge!(h)
    @outer = outer
    
  end

  def find(key)
    self.has_key?(key) ? self : @outer.find(key)
  end
end

def add_globals(env)
  env.merge!(
    {
     :+     => -> x,y{x+y},      :-      => -> x,y{x-y},
     :*    => -> x,y{x*y},       :/     => -> x,y{x/y},
     :not    => -> x{!x},        :>    => -> x,y{x>y},
     :<     => -> x,y{x<y},      :>=     => -> x,y{x>=y},
     :<=   => -> x,y{x<=y},      :'='   => -> x,y{x==y},
     :equal? => -> x,y{x.equal?(y)}, :eq?   => -> x,y{x.eql? y},
     :length => -> x{x.length},  :cons => -> x,y{[x,y]},
     :car   => -> x{x[0]},       :cdr    => -> x{x[1..-1]},
     :append => -> x,y{x+y},     :list  => -> *x{[*x]},
     :list?  => -> x{x.instance_of?(Array)},
     :null? => -> x{x.empty?},   :symbol? => -> x{x.instance_of?(Symbol)}
    }
  )
  env
end

$global_env = add_globals(Env.new)


def to_string(exp)
  puts (exp.instance_of?(Array))  ? '(' + exp.map(&:to_s).join(" ") + ')' : "#{exp}"
end

require "readline"

def lepl
  while line = Readline.readline("lisr> ", true)
    val = _eval(parse line)
    to_string(val) unless val.nil?
  end
end
      
(define y 1)
