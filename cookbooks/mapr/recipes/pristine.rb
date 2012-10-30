log "Remove all MapR components"

#######################
# Unmount /mapr
bash "unmount_mapr" do
  user "root"
  # umount will fail if /mapr not mounted.  This is crude.
  returns [0,1]
  code "umount /mapr"
end

service "mapr-warden" do
  action :stop
end
service "mapr-zookeeper" do
  action :stop
end

bash "remove_rpms" do
  code "rpm -e $(rpm -qa --qf '%{NAME}\n' | grep mapr)"
  returns [0,1]
end

file "/etc/yum.repos.d/maprtech.repo" do
  action :delete
end

file "/tmp/epel-release-6-7.noarch.rpm" do
  action :delete
end

package "epel" do
  action :purge
end

#######################
# Install ruby-shadow from epel

package "ruby-shadow" do
  action :purge
end

#######################
# Install openjdk-1.6

package "java-1.6.0-openjdk" do
  action :purge
end
package "java-1.6.0-openjdk-devel" do
  action :purge
end

#######################
# Set /etc/security/limits.conf for root and mapr

#######################
# Enable SELinux
f = Chef::Util::FileEdit.new('/etc/selinux/config')
f.search_file_replace_line('^SELINUX=', 'SELINUX=enabled')
f.write_file

file "/selinux/enforce" do
  content "1"
end


#######################
# Remove mapr user
user "mapr" do
  action :remove
end

directory "/home/mapr" do
  action :delete
  recursive true
end

#directory "/root/.ssh" do
#  action :delete
#  recursive true
#end

directory "/opt/mapr" do
  action :delete
  recursive true
end

#######################
# Set JAVA_HOME in root and mapr .bashrc - Is bash default shell on ubuntu, suse also?

#######################
# Other good packages to have

package "pdsh" do
  action :purge
end


