#!/usr/bin/ruby -w
# Currency converter site
#

libdir = File.dirname(__FILE__) + '/lib'
$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)

require 'rubygems'
require 'sinatra'
require 'json'
require 'open-uri'
require 'haml'
require 'omgcsv'

class Result
  attr_reader :amount, :base, :target, :value, :json

  def initialize(amount, response)
    @json = response
    @amount = amount
    map = JSON.parse(response)
    @base,@target,@value = 
      map['result']['base'], 
      map['result']['target'],
      map['result']['value']
    [@json, @amount, @base, @target, @value].each do |val|
      val.freeze
    end
  end

  def to_s
    "#{@base}#{@amount} is #{@target}#{@value}"
  end
end

class Currency
  include OMGCSV

  attr_reader :symbol, :code, :label

  def initialize(symbol, code, label)
    @symbol = symbol
    @code = code
    @label = label
  end

  def Currency.load_all(file='resources/currencies.csv')
    data = OMGCSV::read(file)
    data.collect do |row|
      Currency.load(row)
    end
  end

  def Currency.load(row)
    Currency.new(row.symbol, row.code, row.label)
  end
end

set :haml, {:format => :html5 }
@@currencies = Currency.load_all

@@offline = false

configure :offline do
  @@offline = true
end

get '/' do
  redirect_for_params(request.params)
  @currencies = @@currencies
  case derive_format(request.accept)
  when 'text/html'
    haml :index
  end
end

get '/:base/:target/:amount' do |base, target, amount|
  @amount = amount
  @result = convert(base, target, amount)

  case derive_format(request.accept)
  when 'text/html'
    haml :result
  when 'text/json'
    @result.json
  when 'text/plain'
    @result.to_s
  end
end

helpers do
  def redirect_for_params(params)
    unless (params.empty?)
      target = '/'
      if ['amount', 'src', 'target'].all? do |param|
          params.key? param
        end
        target += "#{params['src']}/#{params['target']}/#{params['amount']}"
      end
      redirect target
    end
  end
  def derive_format(formats)
    if formats.member? 'text/html'
      'text/html'
    elsif formats.member? 'text/json'
      'text/json'
    else
      'text/plain'
    end
  end

  def query(base, targt, amnt)
    url = "http://xurrency.com/api/#{base}/#{targt}/#{amnt}"
    open(url).read
  end

  def convert(base, target, amount)
    puts request.accept
    puts "Converting #{base} #{amount} to #{target}"
    puts "We are #{@@offline ? 'offline' : 'online'}"
    if (@@offline)
      json_result = '{"result":{"value":166.24,"target":' + 
        '"gbp","base":"eur"},"status":"ok"}'
    else
      json_result = query(base, target, amount)
    end
    Result.new(amount, json_result)
  end
end

__END__

@@layout
!!! 5
%html{:lang => 'en'}
  %head
    %meta{:charset => 'utf-8'}
    %title Convertor!
    %link{:rel => 'stylesheet', :href => 'style.css'}
  %body
    =yield

@@index
%form{:method => 'get', :action=>'/'}
  %select{:id => 'src', :name => 'src'}
    - @currencies.each do |currency|
      %option{:value => currency.code}
        = currency.label
  %input{:id => 'amount', :name => 'amount', :type => 'number', :value => 1, :autofocus=>'autofocus', :min=>0, :max=> 999999999, :step => 0.1}
  %span
    in
  %select{:id=>'target', :name => 'target'}
    - @currencies.each do |currency|
      %option{:value => currency.code}
        = currency.label
  %input{:type => 'submit', :value => 'convert'}

@@result
%p did something
%p= @result.to_s
