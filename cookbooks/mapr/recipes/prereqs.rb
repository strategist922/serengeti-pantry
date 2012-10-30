log "=========== Start MapR prereqs.rb ============="

#######################
# Set up required repos for RHEL/CentOS.  Need to make this platform independent

cookbook_file "/etc/yum.repos.d/maprtech.repo" do
  source "maprtech.repo"
  owner "root"
  group "root"
  mode "644"
end

remote_file "/tmp/epel-release-5-4.noarch.rpm" do
  source "http://mirrors.rit.edu/epel/5Server/x86_64/epel-release-5-4.noarch.rpm"
end

rpm_package "epel" do
  action :install
  source "/tmp/epel-release-5-4.noarch.rpm"
end

# clean yum cache to reload new repo files
#bash 'yum clean all'

#######################
# Install ruby-shadow from epel
package "ruby-shadow" do
  action :install
end

#######################
# Install openjdk-1.6
=begin
package "java-1.6.0-openjdk" do
  action :install
end
package "java-1.6.0-openjdk-devel" do
  action :install
end
=end

#######################
# Disable SELinux - should be able to re-enable after install
#
f = Chef::Util::FileEdit.new('/etc/selinux/config')
f.search_file_replace_line('^SELINUX=', 'SELINUX=disabled')
f.write_file

file "/selinux/enforce" do
  content "0"
end

#######################
# For now, turn off iptables. Should be able to just open up required ports.
service "iptables" do
  action [:stop, :disable]
end

#######################
# Create mapr user
user "mapr" do
  comment "MapR user"
  uid 3001
  home "/home/mapr"
  password "$1$iXcZZnYR$sp2moQUnZ5gEyTR5feeAm/"
end

#######################
# Keys for MapR user

directory "/home/mapr/.ssh" do
  owner "mapr"
  group "mapr"
  mode "700"
end

cookbook_file "/home/mapr/.ssh/authorized_keys" do
  owner "mapr"
  group "mapr"
  mode "644"
  source "id_rsa_maprtemp.pub"
end

cookbook_file "/home/mapr/.ssh/id_rsa" do
  owner "mapr"
  group "mapr"
  mode "600"
  source "id_rsa_maprtemp"
end

cookbook_file "/home/mapr/.ssh/config" do
  source "ssh_config"
  owner "mapr"
  group "mapr"
  mode "644"
end

#######################
# Other good packages to have
package "pdsh" do
  action :install
end
