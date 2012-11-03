#
# Cookbook Name:: solr
# Recipe:: default
#
# Copyright (C) 2012 Felipe Gonçalves Coury
# 
# All rights reserved - Do Not Redistribute
#

remote_file "/tmp/apache-solr-4.0.0.tgz" do
  owner "root"
  source "#{node[:solr][:apache_mirror]}/lucene/solr/4.0.0/apache-solr-4.0.0.tgz"
  checksum "4b7ac4fdc1f1610f2d13e8dddf310e9d61620c00c463ba24e0f385a4c5c6f3ec"
  mode "0644"
  action :create_if_missing
end

remote_file "/tmp/commons-logging-1.1.1-bin.tar.gz" do
  owner "root"
  source "#{node[:solr][:apache_mirror]}/commons/logging/binaries/commons-logging-1.1.1-bin.tar.gz"
  mode "0644"
  action :create_if_missing
end

directory node[:solr][:path] + "/data" do
  owner "tomcat6"
  action :create
  recursive true
end

cookbook_file "/etc/tomcat6/Catalina/localhost/solr.xml" do
  owner "tomcat6"
end

execute "extract_solr" do
  cwd "/tmp"
  command <<-EOS
    set -e

    cd /tmp
    tar zxf commons-logging-1.1.1-bin.tar.gz
    cd /tmp/commons-*
    cp *.jar /usr/share/tomcat6/lib

    cd /tmp
    tar zxf apache-solr-4.0.0.tgz
    cd /tmp/apache-solr-*
    cp -R example/solr/* /opt/solr
    cp -R example/webapps/solr.war /opt/solr

    chown -R tomcat6:tomcat6 /opt/solr

    cp dist/*.jar /usr/share/tomcat6/lib
    cp dist/solrj-lib/*.jar /usr/share/tomcat6/lib
    cp contrib/extraction/lib/* /usr/share/tomcat6/lib

    attempt=1
    until [ -d /var/lib/tomcat6/webapps/solr/WEB-INF/lib ] || [ $attempt -gt 30 ]; do
      sleep 1
      attempt=$(( $attempt + 1 ))
    done

    if [ $attempt -gt 30 ]; then
      echo "solr tomcat application didn't appear after 30s, failing."
      exit 1
    fi

    cp dist/*.jar /var/lib/tomcat6/webapps/solr/WEB-INF/lib
    cp dist/solrj-lib/*.jar /var/lib/tomcat6/webapps/solr/WEB-INF/lib

    chown -R tomcat6:tomcat6 /var/lib/tomcat6/webapps/solr
  EOS
  creates "/var/lib/tomcat6/webapps/solr/WEB-INF/lib/apache-solr-cell-4.0.0.jar"
end

template "/opt/solr/collection1/conf/solrconfig.xml" do
  owner "tomcat6"
  source "solrconfig.xml.erb"
end

template "/opt/solr/collection1/conf/schema.xml" do
  owner "tomcat6"
  source "schema.xml.erb"
  notifies :run, "execute[restart-tomcat]"
end

execute "restart-tomcat" do
  command "/etc/init.d/tomcat6 restart"
  action :nothing
end

