Using chef recipes to install a MapR cluster on RHEL/CentOS

1. As root, install Ruby and Chef on each node in the cluster
  a. rpm -Uvh http://rbel.frameos.org/rbel6
  b. yum -y install ruby ruby-devel ruby-ri ruby-rdoc gcc gcc-c++ automake autoconf make curl dmidecode rubygems
  c. gem install chef --no-ri --no-rdoc

2. As root, unpack the chef tar on one node.  This doc assumes it's unpacked in
   ~root but it can be anywhere.
  a. tar xvf chef.tar

3. Modify databags to set the cluster configuration
  a.  After unpacking the tar, there will be sample databags in 
      ~root/chef/databags/nodes/node<N>.json.  Create one json file for each
      node in the cluster setting the "id" field to the hostname, "ip" field to
      the ip address, "disks" to a comma separated list of disks to be used by
      MapR, and set each mapr-XXX package to true if you want that component
      installed.  A sample node json file will look like this:
           {
             "id": "ip-10-152-166-196",
             "ip": "10.152.166.196",
             "disks": "/dev/xvdj,/dev/xvdk,/dev/xvdl,/dev/xvdm,/dev/xvdn",
             "mapr-cldb": false,
             "mapr-zookeeper": false,
             "mapr-jobtracker": false,
             "mapr-tasktracker": true,
             "mapr-fileserver": true,
             "mapr-nfs": false,
             "mapr-metrics": true,
             "mapr-webserver": false
           }
      Note that components that are not desired can be marked false or just 
      eliminated from the file.
  
  b.  If you will be installing metrics, modify the 
      ~root/chef/databags/mysql/mysqldb.json file setting the "mysqlconnect"
      field to the mysql server's <hostname>:<port>.  If you change the 
      default username and password in mysqldb.json, be sure to change them
      in ~root/chef/cookbooks/mysql/files/default/maprgrants.sql also.  A
      sample mysqldb.json file will look like this:
           {
             "id": "mysqldb",
             "mysqlconnect": "ip-10-120-10-112:3306",
             "mysqluser": "mapr",
             "mysqlpwd": "mapr"
           }

4.  Distribute the chef directory structure to all nodes in the cluster.
  a. cd ~root; tar cvf chef.tar ./chef
  b. copy chef.tar to each node and untar in ~root

5. Run chef recipes on all nodes simultaneously.  This will install
   MapR components as described in the nodes databags and start MapR.
  a.  chef-solo -c ~/chef/config/solo.rb -j ~/chef/config/node.json

6. If you don't have a metrics database for the cluster, as root run the 
   mysql::install recipe on the node that will be your mysql server.
  a.  chef-solo -c ~/chef/config/solo.rb -o "mysql::install"

7. Log in to the UI on a web server node at https://<webserver>:8443,
   obtain an M5 license from the web, and apply the license.

8. Once the cluster is running, configure metrics on every node where
   metrics is installed:
  a.  chef-solo -c ~/chef/config/solo.rb -j ~/chef/config/metricsconfig.json

