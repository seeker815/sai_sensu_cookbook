begin
  require 'rubygems'
  require 'bundler'
  require 'rake'
  require 'json'
  require 'jsonlint/rake_task'
rescue LoadError
  puts "\e[31mCouldn't load required gems, have you run \e[35m`bundle exec tony check`\e[31m recently?\e[0m"
  puts "\e[31mYou prolly need to \e[35m`bundle update`\e[31m with the latest Kitchen...\e[0m"
  exit 2
end



def master?
  `git rev-parse --abbrev-ref HEAD`.strip == 'master'
end


def test_kitchen?
  File.exist? '.kitchen.yml'
end


def realm?
  !kitchen? && `git ls-files` =~ /\bBerksfile\.lock\b/
end


def kitchen?
  `git ls-files` =~ /\bGemfile\b/
end


def versioned?
  File.exist? 'VERSION'
end


def current_version
  File.read('VERSION').strip
end


def youre_dirty?
  dirty = `git diff HEAD --numstat`.split("\n").length > 0
  raise '`git diff` failed' unless $?.exitstatus.zero?
  dirty
end


def youre_dirty!
  if youre_dirty?
    raise "You you have uncommitted changes! Commit or stash before continuing."
  end
end


def youre_behind?
  `git fetch --tags`
  raise '`git fetch --tags` failed' unless $?.exitstatus.zero?
  behind = `git log ..origin/master --oneline`.split("\n").length > 0
  raise '`git log` failed' unless $?.exitstatus.zero?
  return behind
end


def youre_behind!
  if youre_behind?
    raise "You're out of sync with the remote! Try 'git pull --rebase'"
  end
end


def bump component
  youre_dirty!
  youre_behind!
  `bundle exec tony bump #{component}`
  raise '`tony bump` failed' unless $?.exitstatus.zero?
  if realm?
    `bundle exec berks`
    raise '`berks` failed' unless $?.exitstatus.zero?
    `git add Berksfile.lock`
    raise '`git add` failed' unless $?.exitstatus.zero?
  end
  version = current_version
  `git add VERSION`
  raise '`git add` failed' unless $?.exitstatus.zero?
  `git commit -m "Version bump to #{version}"`
  raise '`git commit` failed' unless $?.exitstatus.zero?
  `git tag -a v#{version} -m v#{version}`
  raise '`git tag` failed' unless $?.exitstatus.zero?
  puts 'Version is now "%s"' % version
end


def bump_and_release component=nil
  bump component unless component == :nop
  youre_dirty!
  youre_behind!
  `git push`
  raise '`git push` failed' unless $?.exitstatus.zero?
  `git push --tags`
  raise '`git push --tags` failed' unless $?.exitstatus.zero?
end


def repo_root_dir
  root_dir = `git rev-parse --show-toplevel`.strip
  raise '`git rev-parse` failed' unless $?.exitstatus.zero?
  root_dir
end


def json_files kind
  Dir[File.join(repo_root_dir, kind, '**', '*.json')]
end


def check_items kind
  json_files(kind).each do |item_path|
    item_name = File.basename(item_path, '.json')
    item_file = File.read item_path
    item      = JSON.parse item_file
    item_id   = item['id'] || item['name']
    if item_id && item_name != item_id
      raise 'Invalid %s: %s' % [ kind, item_name ]
    end
  end
end


def check_role_and_environment_naming
  cookbook_name = File.basename repo_root_dir

  env_names = json_files('environments').map { |f| File.basename(f, '.json') }

  es = env_names.select { |n| !(n =~ /^#{cookbook_name}/) }
  unless es.empty?
    raise 'Hey, I found an environment not named after the realm! (%s)' % es.join(', ')
  end

  role_names = json_files('roles').map { |f| File.basename(f, '.json') }

  rs = role_names.select { |n| !(n =~ /^#{cookbook_name}/) }
  unless rs.empty?
    raise 'Hey, I found a role not named after the realm! (%s)' % rs.join(', ')
  end

  cs = role_names & env_names

  unless cs.empty?
    raise "Hey, I found a role with the same name as an environment! (%s)" % cs.join(', ')
  end
end


def prettify_json_files commit=false
  puts 'Prettifying JSON files'
  json_files('*').each do |path|
    reformatted = JSON.pretty_generate(JSON.parse(File.read(path)))
    File.open(path, 'w') { |f| f.puts reformatted }
    `git add #{path} >/dev/null 2>&1`
  end
  `git commit -m 'Prettify JSON files [automated]'` if commit
end


def lint commit=false
  if kitchen? # skip most linting
    check_items 'data_bags'
    prettify_json_files commit
    return
  end

  system "bundle exec knife cookbook test #{File.basename repo_root_dir} -o .."
  raise '`knife cookbook test` failed' unless $?.exitstatus.zero?
  system 'bundle exec foodcritic .' # Merely a suggestion, no "raise" here

  unless realm?
    if Dir.exist? File.join(repo_root_dir, 'environments')
      raise "Hey, I found environments, but this isn't realm!"
    end

    if Dir.exist? File.join(repo_root_dir, 'roles')
      raise "Hey, I found roles, but this isn't realm!"
    end

    if Dir.exist? File.join(repo_root_dir, 'data_bags')
      raise "Hey, I found data bags, but this isn't realm!"
    end

  else # realm
    check_items 'environments'
    check_items 'roles'
    check_items 'data_bags'
    check_role_and_environment_naming
    prettify_json_files commit
  end
end


CHEFDK_PATH = '/opt/chefdk'
REQUIRE_RUBY_VERSION = '2.1'
RECOMMEND_RUBY_VERSION = '2.3'

def which cmd ; `which #{cmd}`.strip end

def shebang cmd
  File.read(which(cmd)).lines.first.strip
rescue
  puts "\e[31mCould not calculate shebang for %s\e[0m" % cmd.inspect
  nil
end

def shebangs cmds ; Hash[cmds.map { |c| [ c, shebang(c) ] }] end

def check_installation
  if Gem::Version.new(RUBY_VERSION) < Gem::Version.new(REQUIRE_RUBY_VERSION)
    puts "\e[31mWhoa! Looks like you got an old version of Ruby!\e[0m"
    puts
    puts <<-END.gsub(/^ +/,'').strip
      Your Ruby installation is a little too old to support. We ask that
      users upgrade to at least v#{REQUIRE_RUBY_VERSION}. We recommend at least v#{RECOMMEND_RUBY_VERSION} for best
      results. There are lots of ways to accomplish this:

      - Homebrew: `brew install ruby`
      - Source: https://www.ruby-lang.org/en/documentation/installation#building-from-source
      - chruby+ruby-install: https://github.com/postmodern/chruby#readme
      - rbenv+ruby-build: https://github.com/rbenv/rbenv#readme
      - RVM: https://rvm.io

      Make sure you update Bundler, too (`gem install bundler`)

      You should fix this ASAP.
    END
    raise
  end

  unless File.exist? CHEFDK_PATH
    puts "\e[31mWhoa! Looks like you don't have ChefDK installed!\e[0m"
    puts
    puts <<-END.gsub(/^ +/,'').strip
      While the Kitchen distributes all the Chef-related tooling you need,
      some tools like Vagrant expect ChefDK to be installed. Chef provides
      omnibus packages for most platforms:

      - https://downloads.chef.io/chef-dk

      Note that although ChefDK should be installed, it should not be on
      your PATH, as the embedded tools may conflict with those provided by
      the Kitchen. The Kitchen will use ChefDK as necessary.

      You should fix this ASAP.
    END
    raise
  end

  if ENV['PATH'] =~ /chefdk/
    puts "\e[31mWhoa! Looks like you got ChefDK on your PATH!\e[0m"
    puts
    puts <<-END.gsub(/^ +/,'').strip
      The Kitchen distributes all the Chef-related tooling you need,
      acting as a kind of ChefDK tailored for Blue Jeans. Unfortunately,
      ChefDK sometimes distributes conflicting tooling, so we ask users
      to avoid putting ChefDK on their PATH but leave it installed. The
      Kitchen will use ChefDK as necessary.

      You should fix this ASAP.
    END
    raise
  end

  err = false
  { # Which commands important for what tooling
    'Ruby' => %w[ gem bundle ],
    'Chef' => %w[ rake berks tony foodcritic kitchen ]
  }.each do |tooling, check_commands|
    check_shebangs = shebangs check_commands
    unless check_shebangs.values.uniq.size == 1
      puts "\e[33mHead's up: I seem some conflicting shebang lines.\e[0m"
      puts
      puts <<-END.gsub(/^ +/,'')
        The Kitchen depends on a stable, clean installation of #{tooling}
        tooling. We expect that all these Gems are managed by the same
        installation, but it's easy for things to get messy:
      END
      check_shebangs.each do |cmd, shebang|
        puts '- %s: %s' % [
          cmd, shebang ? shebang.inspect : 'missing?'
        ]
      end
      puts <<-END.gsub(/^ +/,'').rstrip

        Depending on your Ruby install method, this may not actually be an
        issue at all, but it could aid in debugging. You might also try simply
        prefixing your command with `bundle exec` to execute within the context
        of the current gem bundle.
      END
      err = true
    end
  end

  puts "\e[32mYour Kitchen installation looks good\e[0m" unless err
end



JsonLint::RakeTask.new do |t|
  t.paths = %w[ **/*.json ]
end

desc 'Check your Kitchen installation'
task :check do
  check_installation
end


desc 'Perform syntax check and linting'
task lint: :jsonlint do
  lint
end
task full_lint: :jsonlint do
  lint true
end


if test_kitchen?
  desc 'Execute default Test Kitchen test suite'
  task test: :lint do
    system 'bundle exec kitchen test'
  end
end


if versioned?
  desc 'Print the current version'
  task :version do
    puts current_version
  end
end



if master?
  if kitchen?
    desc 'Release a Kitchen update'
    task release: %w[ check full_lint ] do
      bump_and_release :nop
    end

  else
    namespace :release do
      desc 'Release new major version'
      task major: %w[ check full_lint ] do
        bump_and_release :major
      end

      desc 'Release new minor version'
      task minor: %w[ check full_lint ] do
        bump_and_release :minor
      end

      task patch: %w[ check full_lint ] do
        bump_and_release :patch
      end
    end

    desc 'Release a new patch version'
    task release: %w[ release:patch ]
  end


  if realm?
    desc 'Apply Berksfile lock to an environment'
    task :constrain, [ :env ] do |_, args|
      check_installation
      youre_dirty!
      youre_behind!
      envs = json_files('environments').map { |f| File.basename(f, '.json') }
      raise 'Could not find local environment "%s"' % args[:env] unless envs.include?(args[:env])
      `git tag -a #{args[:env]} -m #{args[:env]} --force`
      raise '`git tag` failed' unless $?.exitstatus.zero?
      `git push origin #{args[:env]} --force`
      raise '`git push` failed' unless $?.exitstatus.zero?
    end
  end
end