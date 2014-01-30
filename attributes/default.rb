#
# Cookbook Name:: docker_registry
# Attributes:: default
#
# Author:: Alex Kestner <akestner@healthguru.com>
#
# Copyright 2013, Alex Kestner
#
# Licensed under the Apache License, Version 2.0 (the 'License');
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an 'AS IS' BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_attribute 'docker::default'

case node.chef_environment
    when 'production', 'prod'
        flavor = 'prod'
    else
        flavor = 'dev'
end

# core docker config
default[:docker_registry][:name] = 'docker_registry'
default[:docker_registry][:user] = 'docker'
default[:docker_registry][:group] = 'docker'
default[:docker_registry][:path] = "/opt/#{node[:docker_registry][:name]}"
default[:docker_registry][:port] = 5000
default[:docker_registry][:url] = (node[:docker_registry][:url] || node[:hostname] || node[:fqdn])

# template sources
default[:docker_registry][:init_type] = 'upstart'
default[:docker_registry][:init_template] = 'docker-container.conf.erb'
default[:docker_registry][:bind_socket] = "/var/run/#{node[:docker_registry][:name]}.sock"
#default[:docker_registry][:socket_template] = 'docker-container.socket.erb'
default[:docker_registry][:dockerfile_template] = 'Dockerfile.erb'

# docker-registry specifics
default[:docker_registry][:flavor] = flavor
default[:docker_registry][:storage] = 's3'
default[:docker_registry][:storage_path] = "registry/#{flavor}"
default[:docker_registry][:repository] = (node[:docker_registry][:repository] || flavor)
default[:docker_registry][:container_name] = (node[:docker_registry][:build_registry] ? node[:docker_registry][:name] : 'registry')
default[:docker_registry][:container_tag] = '0.0.1'
default[:docker_registry][:registry] = "#{node[:docker_registry][:url]}:#{node[:docker_registry][:port]}/"

# are we building a docker-registry container?
default[:docker_registry][:build_registry] = true

# authentication/data_bags/s3
force_default[:docker_registry][:data_bag] = 'docker_registry'
default[:docker_registry][:data_bag_item] = 'auth'

# these should ideally be set in an encrypted data_bag
default[:docker_registry][:secret_key] = nil
default[:docker_registry][:s3_access_key_id] = nil
default[:docker_registry][:s3_secret_access_key] = nil

default[:docker_registry][:s3_encrypt] = false
default[:docker_registry][:s3_secure] = true

# docker container mappings -- ports, directories, environment vars
default[:docker_registry][:ports_hash] = { node[:docker_registry][:port] => node[:docker_registry][:port] }
default[:docker_registry][:ports] = node[:docker_registry][:ports_hash].map { |host, container| "#{host}:#{container}" }
default[:docker_registry][:volumes] = ["#{node[:docker_registry][:path]}:/var/www/docker-registry"]
default[:docker_registry][:env_vars] = ["DOCKER_REGISTRY_CONFIG=/var/www/docker-registry/config/config.yml"]

# misc. docker container config
default[:docker_registry][:detach] = true
default[:docker_registry][:tty] = true
default[:docker_registry][:standalone] = false
default[:docker_registry][:index_endpoint] = 'https://index.docker.io'
default[:docker_registry][:disable_token_auth] = false
default[:docker_registry][:publish_exposed_ports] = false
default[:docker_registry][:git_source_url] = 'https://github.com/dotcloud/docker-registry.git'
default[:docker_registry][:git_source_ref] = 'master'

# nginx load balancer core config
default[:docker_registry][:nginx][:server_port] = 80
default[:docker_registry][:nginx][:server_url] = node[:docker_registry][:url]
default[:docker_registry][:nginx][:owner] = node[:docker_registry][:user]
default[:docker_registry][:nginx][:group] = node[:docker_registry][:group]
default[:docker_registry][:nginx][:config_dir] = '/etc/nginx'

# setup nginx upstream{...} block from docker container 'link' vars
upstream_host_var = "#{node[:docker_registry][:name].upcase}_PORT_#{node[:docker_registry][:port]}_TCP_ADDR"
upstream_port_var = "#{node[:docker_registry][:name].upcase}_PORT_#{node[:docker_registry][:port]}_TCP_PORT"
default[:docker_registry][:nginx][:upstream_host] = ENV[upstream_host_var] || node[:docker_registry][:url]
default[:docker_registry][:nginx][:upstream_port] = ENV[upstream_port_var] || node[:docker_registry][:port]
default[:docker_registry][:nginx][:upstream_socket] = node[:docker_registry][:bind_socket] || nil

# nginx basic_auth & ssl config
default[:docker_registry][:nginx][:auth_greeting] = 'HealthGuru\'s Docker Registry'
default[:docker_registry][:nginx][:auth_users_file] = ::File.join(node[:docker_registry][:nginx][:config_dir],
                                                                  "#{node[:docker_registry][:name]}_passwd").to_s
default[:docker_registry][:nginx][:auth_users_template] = 'etc_nginx_passwd.erb'
default[:docker_registry][:nginx][:ssl] = false
default[:docker_registry][:nginx][:ssl_path] = '/etc/ssl'
default[:docker_registry][:nginx][:certificate_path] = nil
default[:docker_registry][:nginx][:certificate_key_path] = nil
default[:docker_registry][:nginx][:set_host_header] = true
