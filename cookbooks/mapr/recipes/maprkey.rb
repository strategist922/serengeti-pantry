log "=========== Start MapR maprkey.rb ============="

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
