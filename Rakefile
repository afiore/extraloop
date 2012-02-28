require "date"
require 'pry'

def releases
  releases = `git tag -l v[0-9]*`.split(/\n/).map { |v| v.gsub(/^v/, '').split(".").map(&:to_i) }
  releases.empty? && [[0,0,1]] || releases
end

def new_release
  last_version, new_version = releases.last, releases.last
  new_version[-1]+=1
  new_version
end


def gemspec_file
  Dir["*.gemspec"].first
end

gem_name = File.open(gemspec_file, "r") do |file|
  file.readlines.each do |line|
    break $2 if line.match /\.name\s*=\s*("|')([^"']*)("|')/
  end
end

desc "Updates gemspec with new version number and release date"
task :update_gemspec do
  File.open(gemspec_file, "r+") do |file|
    version_regex = Regexp.new "(\.version\s*=\s*)(['\"])(#{releases.last.join('.')})(['\"])"
    date_regex = /(.date\s*=\s*)(['\"])(\d{4}-\d{2}-\d{2})(['\"])/
    lines = file.readlines

    lines.each do |line|
      line.gsub!(version_regex, "#{$1}'#{new_release.join('.')}'") if line.match(version_regex)
      line.gsub!(date_regex, "#{$1}'#{Date.today}'") if line.match(date_regex)
    end

    file.pos = 0
    file.print(lines.join)
    file.truncate(file.pos)
  end
end

desc "Adds an updated gemspec file to the git index and issue a git commit"
task :commit do
  `git add #{gemspec_file} && git commit -m "Updated gemspec for new release: #{new_release.join('.')}"`
end

desc "Tags the current commit with the current release version number"
task :tag_release do
  `git tag v#{new_release.join('.')}`
end


desc "Pushes and upsyncs tags with the github repo"
task :github_push do
  `git push origin master`
  `git push origin master --tags`
end

desc "Builds the Rubygem"
task :build_gem do
  `gem build #{gemspec_file}`
end

desc "Pushes the new gem to www.rubygems.org"
task :push_gem do
  `gem push #{gem_name}-#{new_release.join('.')}.gem`
end

desc "Automatically builds a new gem version and pushes it to rubygems.org"
task :make_release => [:update_gemspec, :commit, :build_gem, :push_gem, :tag_release, :github_push] do
  puts "done :)"
end
