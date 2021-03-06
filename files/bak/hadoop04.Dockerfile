# hadoop and postgresql configuration ok
# import data into hdfs and install sqoop
FROM serhatcevikel/bigdata:hadoop03

# create user
ENV NB_USER hadoop
ENV NB_UID 1000
ENV HOME /home/${NB_USER}
ENV JAVA_HOME=/usr/lib/jvm/default-java
ENV HADOOP_VERSION 2.9.2
ENV HADOOP_PREFIX=/opt/hadoop-$HADOOP_VERSION
ENV HADOOP_HOME=$HADOOP_PREFIX
ENV HADOOP_CONF_DIR=/etc/hadoop
ENV MULTIHOMED_NETWORK=1
ENV USER=root

USER root

COPY . ${HOME}
RUN chown -R ${NB_UID} ${HOME}

RUN \
        
    # install q 
    qdeblink=$(lynx -listonly -nonumbers -dump "https://github.com/harelba/q/releases" | grep -P "\.deb$" | head -1); \
    qdebfile=${qdeblink##*/}; \

    wget -P ${HOME}/binder $qdeblink; \
    dpkg -i ${HOME}/binder/$qdebfile; \
    rm ${HOME}/binder/$qdebfile; \
    
    # start ssh
    service ssh start;\
    sudo -H -u ${NB_USER} bash -c "export JAVA_HOME=/usr/lib/jvm/default-java; \
    yes Y | ${HADOOP_HOME}/bin/hdfs namenode -format && \
    ${HADOOP_HOME}/sbin/start-dfs.sh && \
    ${HADOOP_HOME}/bin/hdfs dfs -put $HOME/data/ / && \
    ${HADOOP_HOME}/sbin/stop-dfs.sh";\
    service ssh stop;


# install sqoop
ENV SQOOP_HOME=/opt/sqoop
ENV SQOOP_VERSION=1.4.7
#ENV HADOOP_COMMON_HOME=$HADOOP_HOME/share/hadoop/common
#ENV HADOOP_HDFS_HOME=$HADOOP_HOME/share/hadoop/hdfs
#ENV HADOOP_MAPRED_HOME=$HADOOP_HOME/share/hadoop/mapreduce
#ENV HADOOP_YARN_HOME=$HADOOP_HOME/share/hadoop/yarn
ENV PATH=$SQOOP_HOME/bin:$PATH

USER root
RUN mkdir -p $SQOOP_HOME && \
    chown -R $NB_UID $SQOOP_HOME;


USER ${NB_USER}
RUN curl -o /tmp/sqoop-$SQOOP_VERSION.bin__hadoop-2.6.0.tar.gz \
    http://ftp.itu.edu.tr/Mirror/Apache/sqoop/$SQOOP_VERSION/sqoop-$SQOOP_VERSION.bin__hadoop-2.6.0.tar.gz && \
    
    tar -xvf /tmp/sqoop-$SQOOP_VERSION.bin__hadoop-2.6.0.tar.gz -C $SQOOP_HOME --strip-components=1 && \
    rm /tmp/sqoop-$SQOOP_VERSION.bin__hadoop-2.6.0.tar.gz && \
    cp ${JAVA_HOME}/lib/postgresql-42.2.5.jar $SQOOP_HOME/lib;

# add directive to delete copied folders, as the previous version
USER ${NB_USER}
RUN rm -r $HOME/{hadoop_config,binder};

USER ${NB_USER}
ENV SHELL /usr/bin/bash
WORKDIR ${HOME}

