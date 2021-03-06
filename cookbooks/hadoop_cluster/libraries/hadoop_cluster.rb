#
#   Portions Copyright (c) 2012 VMware, Inc. All Rights Reserved.
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#

module HadoopCluster

  # whether the node itself has namenode role
  def is_namenode
    node.role?("hadoop_namenode")
  end

  # The namenode's hostname, or the local node's numeric ip if 'localhost' is given.
  def namenode_address
    return node[:fqdn] if is_namenode or is_journalnode
    # if the user has specified the namenode ip, use it.
    namenode_ip_conf || provider_fqdn(node[:hadoop][:namenode_service_name], !is_namenode)
  end

  def namenode_port
    # if the user has specified the namenode port, use it.
    namenode_port_conf || node[:hadoop][:namenode_service_port]
  end

  # whether the node itself has journalnode role
  def is_journalnode
    node.role?("hadoop_journalnode")
  end

  # whether the node itself had zookeeper role
  def is_zookeeper
    node.role?("zookeeper")
  end

  # whether the node itself facet_index equal 0
  def is_primary_namenode
    node[:facet_index] == 0
  end

  def journalnodes_address
    if is_journalnode
      all_provider_public_ips_for_role("hadoop_journalnode")
    else
      set_action(HadoopCluster::ACTION_WAIT_FOR_SERVICE, node[:hadoop][:journalnode_service_name])
      journalnode_count = all_nodes_count({"role" => "hadoop_journalnode"})
      all_provider_public_ips(node[:hadoop][:journalnode_service_name], true, journalnode_count)
    end
  end

  def zookeepers_address
    if is_zookeeper
      all_provider_public_ips_for_role("zookeeper")
    else
      set_action(HadoopCluster::ACTION_WAIT_FOR_SERVICE, node[:hadoop][:zookeeper_service_name])
      zookeeper_count = all_nodes_count({"role" => "zookeeper"})
      all_provider_public_ips(node[:hadoop][:zookeeper_service_name], true, zookeeper_count)
    end
  end

  # All facet names which have hadoop_namenode role
  def namenode_facet_names
    servers = all_nodes({"role" => "hadoop_namenode"})
    if !is_journalnode and !is_namenode
      set_action(HadoopCluster::ACTION_WAIT_FOR_SERVICE, node[:hadoop][:namenode_service_name])
      wait_for(node[:hadoop][:namenode_service_name], {"provides_service" => node[:hadoop][:namenode_service_name]}, true, servers.count)
    end
    servers.map{ |server| facet_name_of_server(server) }.uniq.sort
  end

  def namenode_facet_addresses
    facet_names = namenode_facet_names
    facet_names.map do | name |
      servers = all_nodes({"role" => "hadoop_namenode", "facet_name" => name})
      {name => servers.map{ |server| ip_of(server) }}
    end
  end

  # The cluster HDFS Namenode HA or federation is enabled if more than 1 node has hadoop_namenode role
  def cluster_has_hdfs_ha_or_federation
    servers = all_nodes({"role" => "hadoop_namenode"})
    servers.count > 1
  end

  # The cluster has only federation if namenode number equal group number which has hadoop_namenode role and namenode number more than 1
  def cluster_has_only_federation
    facet_name_count = namenode_facet_names.count
    namenode_count = all_nodes({"role" => "hadoop_namenode"}).count
    namenode_count > 1 and facet_name_count ==  namenode_count
  end

  # The node Namenode HA is enabled if more than 1 node has hadoop_namenode role in the same facet
  def namenode_ha_enabled
    servers = all_nodes({"role" => "hadoop_namenode", "facet_name" => node[:facet_name]})
    servers.count > 1
  end

  # whether the node itself has secondarynamenode role
  def is_secondarynamenode
    node.role?("hadoop_secondarynamenode")
  end

  # The resourcemanager's hostname, or the local node's numeric ip if 'localhost' is given.
  # The resourcemanager in hadoop-0.23 is vary similar to the jobtracker in hadoop-0.20.
  def resourcemanager_address
    provider_fqdn(node[:hadoop][:resourcemanager_service_name])
  end

  # whether the node itself has jobtracker role
  def is_jobtracker
    node.role?("hadoop_jobtracker")
  end

  # whether any node in the cluster has jobtracker role
  def jobtracker_node
    nodes = all_nodes({"role" => "hadoop_jobtracker"})
    (nodes and nodes.size > 0) ? nodes[0] : nil
  end

  # The jobtracker's hostname, or the local node's numeric ip if 'localhost' is given.
  def jobtracker_address
    return node[:fqdn] if is_jobtracker
    ip = jobtracker_ip_conf
    if !ip
      jobtracker = jobtracker_node
      if jobtracker
        if is_namenode or is_secondarynamenode or is_journalnode
          # namenode and secondarynamenode don't require the jobtracker service is running
          ip = jobtracker[:fqdn]
        else
          ip = provider_fqdn(node[:hadoop][:jobtracker_service_name], !is_jobtracker)
        end
      else
        # return empty string if the cluster doesn't have a jobtracker (e.g. an HBase cluster)
        ip = ""
      end
    end
    ip
  end

  def jobtracker_port
    # if the user has specified the jobtracker port, use it.
    jobtrackerport_conf || node[:hadoop][:jobtracker_service_port]
  end

  # The erb template variables for generating Hadoop xml configuration files in $HADDOP_HOME/conf/
  def hadoop_template_variables
    vars = {
      :hadoop_home            => hadoop_home_dir,
      :hadoop_hdfs_home       => hadoop_hdfs_dir,
      :namenode_address       => namenode_address,
      :namenode_port          => namenode_port,
      :jobtracker_address     => jobtracker_address,
      :mapred_local_dirs      => formalize_dirs(mapred_local_dirs),
      :dfs_name_dirs          => formalize_dirs(dfs_name_dirs),
      :dfs_data_dirs          => formalize_dirs(dfs_data_dirs),
      :fs_checkpoint_dirs     => formalize_dirs(fs_checkpoint_dirs),
      :local_hadoop_dirs      => formalize_dirs(local_hadoop_dirs),
      :persistent_hadoop_dirs => formalize_dirs(persistent_hadoop_dirs),
      :all_cluster_volumes    => all_cluster_volumes
    }
    vars[:resourcemanager_address] = resourcemanager_address if is_hadoop_yarn?

    if node[:hadoop][:cluster_has_hdfs_ha_or_federation]
      vars[:nameservices] = namenode_facet_names
      vars[:namenode_facets] = namenode_facet_addresses
    end

    if node[:hadoop][:namenode_ha_enabled]
      vars[:zookeepers_address] = zookeepers_address
      vars[:journalnodes_address] = journalnodes_address
    end

    vars
  end

  def hadoop_package package_name
    hadoop_major_version = node[:hadoop][:hadoop_handle]
    hadoop_home = hadoop_home_dir
    # component is one of ['hadoop', 'namenode', 'datanode', 'jobtracker', 'tasktracker', 'secondarynamenode']
    component = package_name.split('-').last

    # Install from tarball
    if node[:hadoop][:install_from_tarball] then
      tarball_url = current_distro['hadoop']
      tarball_filename = tarball_url.split('/').last
      tarball_pkgname = tarball_filename.split('.tar.gz').first

      if package_name == node[:hadoop][:packages][:hadoop][:name] then
        # install hadoop base package
        install_dir = [File.dirname(hadoop_home), tarball_pkgname].join('/')
        already_installed = File.exists?("#{install_dir}/lib")
        if already_installed then
          Chef::Log.info("#{tarball_filename} has already been installed. Will not re-install.")
          return
        end

        set_action(ACTION_INSTALL_PACKAGE, component)

        execute "install #{tarball_pkgname} from tarball if not installed" do
          not_if do already_installed end

          Chef::Log.info "start installing package #{tarball_pkgname} from tarball"
          command %Q{
            if [ ! -f /usr/local/src/#{tarball_filename} ]; then
              echo 'downloading tarball #{tarball_filename}'
              cd /usr/local/src/
              wget --tries=3 #{tarball_url}

              if [ $? -ne 0 ]; then
                echo '[ERROR] downloading tarball failed'
                exit 1
              fi
            fi

            echo 'extract the tarball'
            prefix_dir=`dirname #{hadoop_home}`
            install_dir=$prefix_dir/#{tarball_pkgname}
            mkdir -p $install_dir
            cd $install_dir
            tar xzf /usr/local/src/#{tarball_filename} --strip-components=1
            chown -R hdfs:hadoop $install_dir

            echo 'create symbolic links'
            ln -sf -T $install_dir $prefix_dir/#{hadoop_major_version}
            ln -sf -T $install_dir #{hadoop_home}
            mkdir -p /etc/#{hadoop_major_version}
            ln -sf -T #{hadoop_home}/conf /etc/#{hadoop_major_version}/conf
            ln -sf -T /etc/#{hadoop_major_version} /etc/hadoop

            # create hadoop logs directory, otherwise created by root:root with 755
            mkdir             #{hadoop_home}/logs
            chmod 777         #{hadoop_home}/logs
            chown hdfs:hadoop #{hadoop_home}/logs

            echo 'create hadoop command in /usr/bin/'
            cat <<EOF > /usr/bin/hadoop
#!/bin/sh
export HADOOP_HOME=#{hadoop_home}
exec #{hadoop_home}/bin/hadoop "\\$@"
EOF
            chmod 777 /usr/bin/hadoop
            test -d #{hadoop_home}
          }

          # Install the hadoop package at Chef compile phase instead of converge phase,
          # so other nodes depends on namenode (or hbase master) service can download and install the package first,
          # and then wait for namenode service to be ready. This can reduce the cluster creation time remarkably.
          action :nothing
        end.run_action(:run)

      end

      if ['namenode', 'datanode', 'jobtracker', 'tasktracker', 'secondarynamenode'].include?(component) then
        %W[hadoop-0.20-#{component}].each do |service_file|
          Chef::Log.info "installing #{service_file} as system service"
          template "/etc/init.d/#{service_file}" do
            owner "root"
            group "root"
            mode  "0755"
            variables( {:hadoop_version => hadoop_major_version} )
            source "#{service_file}.erb"
            action :nothing
          end.run_action(:create)
        end
      end
      return
    end

    # Install from rpm/apt packages
    set_bootstrap_action(ACTION_INSTALL_PACKAGE, component, true)
    package package_name do
      if node[:hadoop][:package_version] != 'current'
        version node[:hadoop][:package_version]
      end
    end
  end

  # Make a hadoop-owned directory
  def make_hadoop_dir dir, dir_owner="hadoop", dir_mode="0755"
    directory dir do
      owner    dir_owner
      group    "hadoop"
      mode     dir_mode
      action   :create
      recursive true
    end
  end

  def ensure_hadoop_owns_hadoop_dirs dir, dir_owner, dir_mode="0755"
    execute "Make sure hadoop owns hadoop dirs" do
      command %Q{chown -R #{dir_owner}:hadoop #{dir}}
      command %Q{chmod -R #{dir_mode}         #{dir}}
      not_if{ (File.stat(dir).uid == dir_owner) && (File.stat(dir).gid == 300) }
    end
  end

  # Create a symlink to a directory, wiping away any existing dir that's in the way
  def force_link dest, src
    return if dest == src
    directory(dest) do
      action :delete
      recursive true
      not_if { File.symlink?(dest) }
      not_if { File.exists?(dest) and File.exists?(src) and File.realpath(dest) == File.realpath(src) }
    end
    link(dest) { to src }
  end

  def make_link src, target
    return if src == target
    link(src) do
      to target
      not_if { File.exists?(src) }
    end
  end

  # log dir for hadoop daemons
  def local_hadoop_log_dir
    dir = node[:disk][:data_disks].keys[0] if node[:hadoop][:use_data_disk_as_log_vol]
    dir ||= '/mnt/hadoop'
    File.join(dir, 'hadoop/log')
  end

  def local_hadoop_dirs
    dirs = node[:disk][:data_disks].map do |mount_point, device|
      mount_point + '/hadoop' if File.exists?(node[:disk][:disk_devices][device])
    end
    dirs.compact!
    dirs.unshift('/mnt/hadoop') if node[:hadoop][:use_root_as_scratch_vol]
    dirs.uniq
  end

  def persistent_hadoop_dirs
    dirs = local_hadoop_dirs
    dirs.unshift('/mnt/hadoop') if node[:hadoop][:use_root_as_persistent_vol]
    dirs.uniq
  end

  # The HDFS data. Spread out across persistent storage only
  def dfs_data_dirs
    persistent_hadoop_dirs.map{|dir| File.join(dir, 'hdfs/data')}
  end
  # The HDFS metadata. Keep this on two different volumes, at least one persistent
  def dfs_name_dirs
    dirs = persistent_hadoop_dirs.map{|dir| File.join(dir, 'hdfs/name')}
    unless node[:hadoop][:extra_nn_metadata_path].nil?
      dirs << File.join(node[:hadoop][:extra_nn_metadata_path].to_s, node[:cluster_name], 'hdfs/name')
    end
    dirs
  end
  # HDFS metadata checkpoint dir. Keep this on two different volumes, at least one persistent.
  def fs_checkpoint_dirs
    dirs = persistent_hadoop_dirs.map{|dir| File.join(dir, 'hdfs/secondary')}
    unless node[:hadoop][:extra_nn_metadata_path].nil?
      dirs << File.join(node[:hadoop][:extra_nn_metadata_path].to_s, node[:cluster_name], 'hdfs/secondary')
    end
    dirs
  end
  # Local storage during map-reduce jobs. Point at every local disk.
  def mapred_local_dirs
    local_hadoop_dirs.map{|dir| File.join(dir, 'mapred/local')}
  end

  # Hadoop 0.23 requires hadoop directory path in conf files to be in URI format
  def formalize_dirs dirs
    if is_hadoop_yarn?
      'file://' + dirs.join(',file://')
    else
      dirs.join(',')
    end
  end

  # return true if installing hadoop 0.23
  def is_hadoop_yarn?
    node[:hadoop][:is_hadoop_yarn] == true
  end

  # HADOOP_HOME
  def hadoop_home_dir
    node[:hadoop][:hadoop_home_dir]
  end

  # hadoop hdfs dir
  def hadoop_hdfs_dir
    node[:hadoop][:hadoop_hdfs_dir]
  end

  def bin_hadoop_daemon_sh
    '/usr/lib/hadoop/bin/hadoop-daemon.sh'
  end

  def sbin_hadoop_daemon_sh
    '/usr/lib/hadoop/sbin/hadoop-daemon.sh'
  end

  def path_of_hadoop_daemon_sh
    File.exists?(bin_hadoop_daemon_sh) ? bin_hadoop_daemon_sh : sbin_hadoop_daemon_sh
  end

  # in Hadoop 0.23 hadoop-daemon.sh is in /usr/lib/hadoop/bin/, while in Hadoop 0.20 it's in /usr/lib/hadoop/sbin/
  def check_hadoop_daemon_sh
    from = bin_hadoop_daemon_sh
    target = sbin_hadoop_daemon_sh
    link(from) do
      not_if { File.exist?(from) }
      only_if { File.exist?(target) }
      to target
    end
  end

  # this is just a stub to prevent code broken
  def all_cluster_volumes
    nil
  end

  def hadoop_ha_package component
    if ['namenode', 'jobtracker'].include?(component) then
      if node[:hadoop][:ha_enabled] then
        ha_installed = File.exists?("/usr/lib/hadoop/monitor/vsphere-ha-#{component}-monitor.sh")
        if ha_installed then
          Chef::Log.info("HA monitor for #{component} has already been installed. Will not re-install.")
          return
        end

        pkg = "hmonitor-vsphere-#{component}-daemon"
        set_bootstrap_action(ACTION_INSTALL_PACKAGE, pkg)
        package pkg do
          action :install
          notifies :create, resources("ruby_block[#{pkg}]"), :immediately
        end

        # put libVMGuestAppMonitorNative.so in /usr/lib/hadoop/lib/native/, so hadoop daemons can find it.
        force_link('/usr/lib/hadoop/lib/native/libVMGuestAppMonitorNative.so', '/usr/lib/hadoop/monitor/libVMGuestAppMonitorNative.so')
      end
    end
  end

  def enable_ha_service svc
    if node[:hadoop][:ha_enabled] then
      set_bootstrap_action(ACTION_START_SERVICE, svc)
      service svc do
        action [ :disable, :start ]
        supports :status => true, :restart => true
        notifies :create, resources("ruby_block[#{svc}]"), :immediately
      end
    end
  end

  # Return rsa pub key
  def node_rsa_pub_key facet_index
    wait_for("node-rsa-pub-key", {"facet_name" => node[:facet_name], "facet_index" => facet_index, "rsa_pub_key" => "*"})
    server = all_nodes({"facet_name" => node[:facet_name], "facet_index" => facet_index}).first
    server[:rsa_pub_key]
  end

  # Hortonworks hmonitor can not monitor standby namenode service and jobtracker service in the CDH4 distro
  def hortonworks_hmonitor_enabled
    !(node[:hadoop][:distro_name] =~ /cdh4/)
  end

end

class Chef::Recipe
  include HadoopCluster
end

class Chef::Resource::Directory
  include HadoopCluster
end

class Chef::Resource::Service
  include HadoopCluster
end
