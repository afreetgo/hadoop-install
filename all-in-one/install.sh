if [ `id -u` -ne 0 ]; then
   echo "must run as root"
   exit 1
fi


HOSTNAME=`hostname`
iptables -F

#yum-config-manager --add-repo=http://archive.cloudera.com/cdh4/redhat/6/x86_64/cdh/cloudera-cdh4.repo
#sudo rpm --import http://archive.cloudera.com/cdh4/redhat/6/x86_64/cdh/RPM-GPG-KEY-cloudera

echo "[cloudera-cdh4]" >/etc/yum.repos.d/cloudera-cdh4.repo
echo "name=cdh4" >>/etc/yum.repos.d/cloudera-cdh4.repo
echo "baseurl=ftp://192.168.0.254/pub/cdh/4" >>/etc/yum.repos.d/cloudera-cdh4.repo
echo "gpgcheck = 0" >>/etc/yum.repos.d/cloudera-cdh4.repo

yum clean all

yum install -y hadoop  hadoop-debuginfo hadoop-hdfs-namenode hadoop-hdfs-datanode hadoop-hdfs-secondarynamenode hadoop-mapreduce-historyserver hadoop-yarn hadoop-yarn-resourcemanager  hadoop-yarn-nodemanager hive hive-metastore hive-server2 hive-jdbc zookeeper-server zookeeper

wget ftp://192.168.0.30/pub/idh/hadoop_related/common/jdk-1.6.0_31-fcs.x86_64.rpm
yum install jdk-1.6.0_31-fcs.x86_64.rpm

if [ -f /root/.bashrc ] ; then
    sed -i '/^export[[:space:]]\{1,\}JAVA_HOME[[:space:]]\{0,\}=/d' /root/.bashrc
    sed -i '/^export[[:space:]]\{1,\}CLASSPATH[[:space:]]\{0,\}=/d' /root/.bashrc
    sed -i '/^export[[:space:]]\{1,\}PATH[[:space:]]\{0,\}=/d' /root/.bashrc
fi
echo "" >>/root/.bashrc
echo "export JAVA_HOME=/usr/java/latest" >>/root/.bashrc
echo "export CLASSPATH=.:\$JAVA_HOME/lib/tools.jar:\$JAVA_HOME/lib/dt.jar">>/root/.bashrc
echo "export PATH=\$JAVA_HOME/bin:\$PATH" >> /root/.bashrc

source /root/.bashrc


mkdir -p /etc/{hadoop,hive}/conf.edh
rm -rf /etc/{hadoop,hive}/conf

alternatives --install /etc/hadoop/conf hadoop-conf /etc/hadoop/conf.edh 50
alternatives --set hadoop-conf /etc/hadoop/conf.edh

alternatives --install /etc/hive/conf hive-conf /etc/hive/conf.edh 50
alternatives --set hive-conf /etc/hive/conf.edh

touch /var/lib/hive/.hivehistory
chown -R hive:hive  /var/lib/hive/.hivehistory

cp -rf conf-template/hadoop/conf/* /etc/hadoop/conf
cp -rf conf-template/hive/conf/* /etc/hive/conf


sed -i "s|HOSTNAME|$HOSTNAME|g" /etc/hadoop/conf/core-site.xml
sed -i "s|HOSTNAME|$HOSTNAME|g" /etc/hadoop/conf/hdfs-site.xml 
sed -i "s|HOSTNAME|$HOSTNAME|g" /etc/hadoop/conf/mapred-site.xml 
sed -i "s|HOSTNAME|$HOSTNAME|g" /etc/hadoop/conf/yarn-site.xml 
sed -i "s|HOSTNAME|$HOSTNAME|g" /etc/hive/conf/hive-site.xml


echo "format namenode"
rm -rf /hadoop/dfs/name /hadoop/dfs/data /hadoop/dfs/namesecondary

mkdir -p /hadoop/dfs/name
chown -R hdfs:hdfs /hadoop/dfs/name
chmod 700 /hadoop/dfs/name

mkdir -p /hadoop/dfs/data
chown -R hdfs:hdfs /hadoop/dfs/data
chmod 700 /hadoop/dfs/data

mkdir -p /hadoop/dfs/namesecondary
chown -R hdfs:hdfs /hadoop/dfs/namesecondary
chmod 700 /hadoop/dfs/namesecondary


sh start.sh stop
rm -rf /hadoop/dfs/name/current
su -s /bin/bash hdfs -c 'yes Y | hadoop namenode -format >> /tmp/nn.format.log 2>&1'


su -s /bin/bash hdfs -c "hadoop fs -chmod a+rw /"
while read dir user group perm
do
   su -s /bin/bash hdfs -c "hadoop fs -mkdir $dir && hadoop fs -chmod $perm $dir && hadoop fs -chown $user:$group $dir"
     echo "[IM_CONFIG_INFO]: ."
done << EOF
/tmp hdfs hadoop 1777 
/user hdfs hadoop 777
/user/history yarn hadoop 1777
/user/history/done yarn hadoop 777
/user/root root hadoop 755
/user/hive hive hadoop 755 
/user/hive/warehouse hive hadoop 777
/yarn yarn mapred 755
EOF

echo "start hadoop"
sh start.sh start

