def cldbs_address
  nodes = search(:node, "cluster_name:#{node[:cluster_name]} AND role:mapr_cldb")
  nodes.collect { |node| node[:fqdn] }.join(",")
end

def zookeepers_address
  nodes = search(:node, "cluster_name:#{node[:cluster_name]} AND role:mapr_zookeeper")
  nodes.collect { |node| node[:fqdn] }.join(",")
end

