#!/usr/bin/env ruby

require 'bundler/inline'
require 'csv'

gemfile do
  source 'https://rubygems.org'
  gem 'mechanize', '~> 2.9'
end

cookie = ARGV.shift or fail "Please specify the value of the _filmfreeway_session cookie as an argument to this script"

agent = Mechanize.new
agent.cookie_jar << Mechanize::Cookie.new(
  domain: 'filmfreeway.com', 
  name: '_filmfreeway_session',
  path: '/',
  value: cookie
)

page = agent.get('https://filmfreeway.com/submissions?per_page=500&festival_category[]=852607&ss[]=1')

if page.link_with(text: 'Log In')
  fail "Couldn't log in - please check cookie is valid"
end

page.css('.festival-submissions .project-details a').map do |film|
  $stderr.puts film['title']
  film_page = agent.get(film['href'])
  country = film_page.at('.submission-details__section:contains("Country of Origin")')&.at('p')&.text
  runtime = film_page.at('.submission-details__section:contains("Runtime")')&.at('p')&.text
  password = film_page.at('#copy-password')&.attr('value')
  {
    title: film['title'],
    link: page.uri.merge(film['href']),
    country: country,
    runtime: runtime,
    password: password
  }
end.then do |films|
  CSV.generate do |csv|
    csv << films.first.keys
    films.each {|f| csv << f.values}
  end
end.then do |csv|
  puts csv
end
