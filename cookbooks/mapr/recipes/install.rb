log "=========== Start MapR install.rb ============="

client_only = false
cldb_list = Array.new
zookeeper_list = Array.new

=begin
nodes = data_bag("nodes")
nodes.each do |id|
  curnode = data_bag_item("nodes", id)
  # Install packages on node if curnode contains the packages for this node
  if curnode["ip"] == node[:ipaddress]
    curnode.each do |val|
      if (val[0] =~ /^mapr-/) and (curnode[val[0]])
        package val[0] do
          action :install
        end
      end
    end
  end
  if curnode["mapr-cldb"]
    cldb_list.push(curnode["id"])
  end
  if curnode["mapr-zookeeper"]
    zookeeper_list.push(curnode["id"])
  end
  if curnode["client_only"]
    client_only = true
  end
end
=end

package 'portmap' # nfsserver needs it

pkgs = %w[
  mapr-cldb
  mapr-zookeeper
  mapr-jobtracker
  mapr-tasktracker
  mapr-fileserver
  mapr-nfs
  mapr-metrics
  mapr-webserver
]
pkgs.each do |name|
  package name do
    only_if { node.roles.include?(name.gsub('-', '_')) }
  end
next
  execute "install #{name}" do
    not_if "rpm -q #{name}"
    only_if { node.role?(name.gsub('-', '_')) }
    command %Q{ yum -y install #{name} }
  end
end

#######################
# Set JAVA_HOME
# This must be in ruby_block since /opt/mapr/conf/env.sh doesn't exist at compile time.  Only at run time after the code above executes
file = '/opt/mapr/conf/env.sh'
java_home = '/usr/local/jdk'
execute "set_java_home" do
  not_if "grep '^export JAVA_HOME' #{file}"
  command %Q{
    sed -i -e 's|^#export JAVA_HOME=.*|export JAVA_HOME=#{java_home}|' #{file}
  }
end

execute "configure mapr" do
  user "root"
  command "/opt/mapr/server/configure.sh -C " + cldbs_address + " -Z " + zookeepers_address
end

