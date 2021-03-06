# vim: syntax=ruby:expandtab:shiftwidth=2:softtabstop=2:tabstop=2

# Copyright 2013-present Facebook
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'mixlib/config'
require 'taste_tester/logging'
require 'between_meals/util'

module TasteTester
  # Config file parser and config object
  # Uses Mixlib::Config v1 syntax so it works in Chef10 omnibus...
  # it's compatible with v2, so it should work in 11 too.
  module Config
    extend Mixlib::Config
    extend TasteTester::Logging
    extend BetweenMeals::Util

    repo "#{ENV['HOME']}/ops"
    repo_type 'git'
    base_dir 'chef'
    cookbook_dirs ['cookbooks']
    role_dir 'roles'
    databag_dir 'databags'
    config_file '/etc/taste-tester-config.rb'
    plugin_path '/etc/taste-tester-plugin.rb'
    chef_zero_path '/opt/chef/embedded/bin/chef-zero'
    verbosity Logger::WARN
    timestamp false
    user 'root'
    ref_file "#{ENV['HOME']}/.chef/taste-tester-ref.json"
    checksum_dir "#{ENV['HOME']}/.chef/checksums"
    skip_repo_checks false
    chef_client_command 'chef-client'
    testing_time 3600
    chef_port_range [5000, 5500]
    tunnel_port 4001
    timestamp_file '/etc/chef/test_timestamp'
    use_ssh_tunnels false
    use_ssl true
    chef_zero_logging true

    skip_pre_upload_hook false
    skip_post_upload_hook false
    skip_pre_test_hook false
    skip_post_test_hook false
    skip_repo_checks_hook false

    def self.cookbooks
      cookbook_dirs.map do |x|
        File.join(repo, base_dir, x)
      end
    end

    def self.relative_cookbook_dirs
      cookbook_dirs.map do |x|
        File.join(base_dir, x)
      end
    end

    def self.roles
      File.join(repo, base_dir, role_dir)
    end

    def self.relative_role_dir
      File.join(base_dir, role_dir)
    end

    def self.databags
      File.join(repo, base_dir, databag_dir)
    end

    def self.relative_databag_dir
      File.join(base_dir, databag_dir)
    end

    def self.chef_port
      range = chef_port_range.first.to_i..chef_port_range.last.to_i
      range.to_a.shuffle.each do |port|
        unless port_open?(port)
          return port
        end
      end
      logger.error 'Could not find a free port in range' +
        " [#{chef_port_range.first}, #{chef_port_range.last}]"
      exit 1
    end

    def self.testing_end_time
      if TasteTester::Config.testing_until
        TasteTester::Config.testing_until.strftime('%y%m%d%H%M.%S')
      else
        (Time.now + TasteTester::Config.testing_time).strftime('%y%m%d%H%M.%S')
      end
    end
  end
end
