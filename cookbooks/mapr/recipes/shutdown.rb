log "=========== Start MapR startup.rb ============="
service "mapr-warden" do
  action :stop
end

if node.role?("mapr-zookeeper")
  service "mapr-zookeeper" do
    action :stop
  end
end

