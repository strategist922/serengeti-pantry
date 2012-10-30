log "=========== Start MapR startup.rb ============="

services = %w[
  "portmap"
  "mapr-zookeeper"
  "mapr-warden"
]

services.each do |name|
  next unless node.role?(name.gsub('-', '_'))
  service name do
    action :start
  end
end
