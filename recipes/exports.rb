#
# Cookbook Name:: nfs
# Recipe:: exports
#

node['nfs']['exports'].each do |export|
  nfs_export export['directory'] do
    %w{network writeable sync anonuser anongroup options}.each do |attr|
      send(attr,export[attr]) if export[attr]
    end
  end
end

