log "=========== Start MapR diskconfig.rb ============="

# disk_string = data_bag_item("nodes", node[:hostname])["disks"]
return if !node[:disk]
disk_string = node[:disk][:disk_devices].values.collect{ |disk| disk if File.exist?(disk) }.join(',')
file "/opt/mapr/disks.txt" do
  owner "mapr"
  group "mapr"
  content disk_string.gsub(",","\n") + "\n"
end

# This is for fresh install.  Need to deal with disks already set up.
bash "format_disks" do
  user "root"
  code "/opt/mapr/server/disksetup -F /opt/mapr/disks.txt"
  ignore_failure true
end
