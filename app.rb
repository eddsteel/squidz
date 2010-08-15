#!/usr/bin/ruby -w
# Currency converter site
#

require 'rubygems'
require 'sinatra'
require 'json'
require 'open-uri'
require 'haml'
require 'omgcsv'

class Result
  attr_reader :amount, :base, :target, :value, :json

  def initialize(amount, response, currencies)
    @json = response
    @amount = amount
    map = JSON.parse(response)
    @currencies = currencies
    base,target,value =
      map['result']['base'],
      map['result']['target'],
      map['result']['value']
    @base = currencies.find {|currency| currency.code == base}
    raise "Can't find #{base}" if @base.nil?
    @target = currencies.find {|currency| currency.code == target}
    raise "Can't find #{target}" if @target.nil?
    @value = round(value.to_f)
    [@json, @amount, @base, @target, @value].each do |val|
      val.freeze
    end
  end

  def to_s
    "#{@target.to_s_s}#{@value}"
  end

  def to_h
    "#{@base.to_s_s}#{@amount} is " +
    "<span class='target-value'>#{@target.to_s_s}" +
    "#{@value}</span>"
  end

  private
  def round(n, dps=2)
    dp_val = 10 ** dps
    n.to_i + (((n - (n.to_i)) * dp_val).to_i).to_f / dp_val
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

  def to_s_s
    return @symbol if @symbol
    return @code.upcase
  end

  def ==(other)
    other.symbol == @symbol &&
      other.code == @code &&
      other.label == @label
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
    haml :page, :locals => {:title => nil, :base => nil,
      :target => nil, :amount => nil}
  end
end

get '/:base/:target/:amount' do |base, target, amount|
  @currencies = @@currencies
  @amount = amount
  @result = convert(base, target, amount)

  case derive_format(request.accept)
  when 'text/html'
    haml :page, :locals => {:title=> @result.to_s,
      :base => base, :target => target, :amount => amount}
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
    if (@@offline)
      json_result = %Q[{"result":{"value":166.241,"target":"#{target}","base":"#{base}"},"status":"ok"}]
    else
      json_result = query(base, target, amount)
    end
    Result.new(amount, json_result, @@currencies)
  end
end

# TODO:
# AJAX

__END__

@@layout
!!! 5
%html{:lang => 'en'}
  %head
    %meta{:charset => 'utf-8'}
    %title
      = title || 'Convertor!'
    %link{:rel => 'stylesheet', :href => '/style.css'}
  %body
    =yield

@@page
%form{:method => 'get', :action=>'/'}
  %select{:id => 'src', :name => 'src'}
    - @currencies.each do |currency|
      %option{:value => currency.code, :selected => base && base == currency.code ? 'selected' : nil}
        = currency.label
  %input{:id => 'amount', :name => 'amount', :type => 'number', :value => 1, :autofocus=>'autofocus', :min=>0, :max=> 999999999, :step => 0.1}
  %span
    in
  %select{:id=>'target', :name => 'target'}
    - target_currencies = [@currencies[1], @currencies[0]] + @currencies[2..-1]
    - target_currencies.each do |currency|
      %option{:value => currency.code, :selected => target && target == currency.code ? 'selected' : nil}
        = currency.label
  %input{:type => 'submit', :value => 'convert'}
- if @result
  .result
    = @result.to_h
