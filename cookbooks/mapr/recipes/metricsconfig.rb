log "=========== Start MapR metricsconfig.rb ============="

mysqlconnect = false

if data_bag_item("nodes", node[:hostname])["mapr-metrics"]
  mysqlconnect = data_bag_item("mysql", "mysqldb")["mysqlconnect"]
  mysqluser = data_bag_item("mysql", "mysqldb")["mysqluser"]
  mysqlpwd = data_bag_item("mysql", "mysqldb")["mysqlpwd"]
  configure_str = "/opt/mapr/server/configure.sh -R -d " + mysqlconnect + " -du " +  mysqluser + " -dp " + mysqlpwd + " -ds metrics"
  maprcli1_str = "maprcli config save -values \'{\"jm_db.user\":\"" + mysqluser + \
                                            "\", \"jm_db.passwd\":\"" + mysqlpwd + \
                                            "\", \"jm_db.schema\":\"metrics\"}\'"
  maprcli2_str = "maprcli config save -values \'{\"jm_db.url\":\"" + mysqlconnect + "\"}\'"
  maprcli3_str = "maprcli config save -values \'{\"jm_configured\":\"1\"}\'"
end

print configure_str + "\n"
print maprcli1_str + "\n"
print maprcli2_str + "\n"
print maprcli3_str + "\n"

=begin
bash "configure-metricsdb" do
  user "root"
  if mysqlconnect
    code configure_str + " && " + maprcli1_str + " && " + maprcli2_str + " && " +  maprcli3_str
  else
    code ":"
  end
end
=end

bash "configure-metricsdb" do
  user "root"
  if mysqlconnect
    code configure_str 
  else
    code ":"
  end
end
bash "configure-metricsdb" do
  user "root"
  if mysqlconnect
    code maprcli1_str
  else
    code ":"
  end
end
bash "configure-metricsdb" do
  user "root"
  if mysqlconnect
    code maprcli2_str
  else
    code ":"
  end
end
bash "configure-metricsdb" do
  user "root"
  if mysqlconnect
    code maprcli3_str
  else
    code ":"
  end
end
