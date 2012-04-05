#!/usr/bin/env rake
require "bundler/gem_tasks"
require 'rake/testtask'
require 'rdoc/task'

desc 'Run  unit tests.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

task :default => [:test]