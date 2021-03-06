#!/bin/sh

HOSTNAME=`hostname`
EDH_PATH=/etc/edh
NODES_FILE=$EDH_PATH/conf/nodes
ZK_HOSTNAME=`cat $NODES_FILE |tr '\n' ','|  sed 's/,$//'`
SLAVES=`cat $NODES_FILE`


for srv in hadoop hbase hive zookeeper ;do
	echo "[INFO]:copy ${srv} template conf files to /etc/${srv}/conf"
	cp -u ${EDH_PATH}/template/${srv}/* /etc/${srv}/conf
	chmod 755 -R /etc/${srv}/conf
done


echo "Update hadoop conf files ..."
sed -i "s|localhost|$HOSTNAME|g" /etc/hadoop/conf/core-site.xml
sed -i "s|localhost|$HOSTNAME|g" /etc/hadoop/conf/hdfs-site.xml
sed -i "s|localhost|$HOSTNAME|g" /etc/hadoop/conf/mapred-site.xml
sed -i "s|localhost|$HOSTNAME|g" /etc/hadoop/conf/yarn-site.xml
sed -i "s|localhost|$HOSTNAME|g" /etc/hive/conf/hive-site.xml
sed -i "s|localhost|$HOSTNAME|g" /etc/hbase/conf/hbase-site.xml
sed -i "s|localhost|$SLAVES|g" /etc/hadoop/conf/slaves
sed -i "s|localhost|$SLAVES|g" /etc/hbase/conf/regionservers
sed -i "s|zkhost|$ZK_HOSTNAME|g" /etc/hbase/conf/hbase-site.xml

pscp -h $NODES_FILE ${EDH_PATH}/template/postgresql-9.1-901.jdbc4.jar /usr/lib/hive/lib/postgresql-jdbc.jar

for node in `cat $NODES_FILE` ;do
	for srv in hadoop hbase hive zookeeper ;do
		echo "[INFO]:Syn ${srv} conf files to ${node}'s /etc/${srv}/conf"
		rsync /etc/${srv}/conf.edh root@$node:/etc/${srv} -avz --delete
	done
done
