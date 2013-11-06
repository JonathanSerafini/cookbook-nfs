#
# Cookbook Name:: nfs
# Providers:: export
#
# Copyright 2012, Riot Games
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
#

action :create do
  ro_rw = new_resource.writeable ? "rw" : "ro"
  sync_async = new_resource.sync ? "sync" : "async"

  if new_resource.anonuser
    new_resource.options << "anonuid=#{find_uid(new_resource.anonuser)}"
  end

  if new_resource.anongroup
    new_resource.options << "anongid=#{find_gid(new_resource.anongroup)}"
  end

  options = new_resource.options.join(',')
  options = ",#{options}" unless options.empty?

  export_line = "#{new_resource.directory} #{new_resource.network}(#{ro_rw},#{sync_async}#{options})\n"

  execute "exportfs" do
    command "exportfs -ar"
    action :nothing
  end

  if ::File.zero? '/etc/exports' or not ::File.exists? '/etc/exports'
    r = file '/etc/exports' do
      content export_line
      if node['platform'] == 'freebsd'
      notifies :restart, "service[#{node['nfs']['service']['server']}]"
      else notifies :run, "execute[exportfs]"
      end
      action :nothing
    end
    r.run_action(:create)
  else
    r = append_if_no_line "export #{new_resource.name}" do
      path "/etc/exports"
      line export_line
      if node['platform'] == 'freebsd'
      notifies :restart, "service[#{node['nfs']['service']['server']}]"
      else notifies :run, "execute[exportfs]"
      end
      action :nothing
    end
    r.run_action(:edit)
  end
  
  new_resource.updated_by_last_action(true) if r.updated_by_last_action?
end

private

# Finds the UID for the given user name
#
# @param [String] username
# @return
def find_uid(username)
uid = nil
Etc.passwd do |entry|
  if entry.name == username
    uid = entry.uid
    break
  end
end
uid
end

# Finds the GID for the given group name
#
# @param [String] groupname
# @return [Integer] the matching GID or nil
def find_gid(groupname)
gid = nil
Etc.group do |entry|
  if entry.name == groupname
    gid = entry.gid
    break
  end
end
gid
end
