FROM centos:8

VOLUME /var/lib/docker
VOLUME /opt/buildagent/work
VOLUME /opt/buildagent/logs
VOLUME /data/teamcity_agent/conf
VOLUME /opt/buildagent/plugins
ENV DOCKER_HOST "unix:///var/run/docker.sock"
ENV DOCKER_BIN "/usr/bin/docker"
ENV DOCKER_IN_DOCKER start
ENV DOTNET_CLI_TELEMETRY_OPTOUT 1
ENV AGENT_CONF_FILE_NAME "buildAgent.properties"
EXPOSE 9090
# RUN  cat /opt/buildagent/bin/agent.sh
ENTRYPOINT [ "/bin/bash","/run-services.sh" ]
WORKDIR /
RUN sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-Linux-* &&\
    sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-Linux-*

COPY ./root/ /

RUN chmod 0755 /run-*.sh /services/*

RUN yum install -y java-11-openjdk-devel git yum-utils 

# RUN yum install -y git  yum-utils
# RUN wget https://download.docker.com/linux/centos/docker-ce.repo -O /etc/yum.repos.d/docker-ce.repo
# RUN yum-config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo 
RUN yum-config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo  && yum install -y docker-ce
RUN yum install -y python39 gcc python39-devel  krb5-workstation krb5-libs krb5-devel 

# installing build agent

RUN yum install -y unzip && curl -o /tmp/buildAgent.zip -k https://teamcity.ksoft.biz/update/buildAgent.zip && \
    unzip /tmp/buildAgent.zip -d /opt/buildagent && \
    mkdir -p /data/teamcity_agent/conf && \
    cp -r /opt/buildagent/conf /opt/buildagent/conf_dist && \
    # ls -al /opt/buildagent/conf_dist/ && \
    #rm /opt/buildagent/lib/log4j-1.2.12.jar && \
    #rm /opt/buildagent/lib/log4j-1.2.12-json-layout.jar && \
    #wget http://archive.apache.org/dist/logging/log4j/1.2.17/log4j-1.2.17.jar -O /opt/buildagent/lib/log4j-1.2.17.jar && \
    #wget http://archive.apache.org/dist/logging/log4j/1.2.17/log4j-1.2.17-json-layout.jar -O /opt/buildagent/lib/log4j-1.2.17-json-layout.jar && \
    rm -f -r /tmp/*

# USER 1000

RUN python3 -m pip install --upgrade pip setuptools wheel 
# RUN yum install -y krb5-workstation krb5-libs krb5-devel 

RUN python3 -m pip install ansible pywinrm pywinrm[kerberos] kerberos requests requests-kerberos 

RUN ansible-galaxy collection install \
    community.kubernetes \
    community.crypto \
    community.general \
    community.libvirt

ENV POWERSHELL_VERSION=7.1.0

RUN curl https://packages.microsoft.com/config/rhel/7/prod.repo | tee /etc/yum.repos.d/microsoft.repo && yum install -y powershell

RUN yum install dotnet-sdk-6.0 -y


# USER root
