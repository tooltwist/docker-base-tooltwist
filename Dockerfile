#
#	Setup a blank tooltwist server, based on phusion/baseimage.
#

# PART 1 - Copied from offical Tomcat image, but using Java JDK rather than JRE
# See https://github.com/docker-library/tomcat/blob/7da0fe6d6ba425faf5706ad13f1b6970a5192dd5/8-jre7/Dockerfile
FROM java:7-jdk

ENV CATALINA_HOME /home/tooltwist/server/tomcat
ENV PATH $CATALINA_HOME/bin:$PATH
RUN mkdir -p "$CATALINA_HOME"
WORKDIR $CATALINA_HOME

# see https://www.apache.org/dist/tomcat/tomcat-8/KEYS
RUN gpg --keyserver pool.sks-keyservers.net --recv-keys \
	05AB33110949707C93A279E3D3EFE6B686867BA6 \
	07E48665A34DCAFAE522E5E6266191C37C037D42 \
	47309207D818FFD8DCD3F83F1931D684307A10A5 \
	541FBE7D8F78B25E055DDEE13C370389288584E7 \
	61B832AC2F1C5A90F0F9B00A1C506407564C17A3 \
	79F7026C690BAA50B92CD8B66A3AD3F4F22C4FED \
	9BA44C2621385CB966EBA586F72C284D731FABEE \
	A27677289986DB50844682F8ACB77FC2E86E29AC \
	A9C5DF4D22E99998D9875A5110C01C5A2F6059E7 \
	DCFD35E0BF8CA7344752DE8B6FB21E8933C60243 \
	F3A04C595DB5B6A5F1ECA43E3B7BBB100D811BBE \
	F7DA48BB64BCB84ECBA7EE6935CD23C10D498E23

ENV TOMCAT_MAJOR 8
ENV TOMCAT_VERSION 8.0.32
ENV TOMCAT_TGZ_URL https://www.apache.org/dist/tomcat/tomcat-$TOMCAT_MAJOR/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz

RUN set -x \
	&& curl -fSL "$TOMCAT_TGZ_URL" -o tomcat.tar.gz \
	&& curl -fSL "$TOMCAT_TGZ_URL.asc" -o tomcat.tar.gz.asc \
	&& gpg --verify tomcat.tar.gz.asc \
	&& tar -xvf tomcat.tar.gz --strip-components=1 \
	&& rm bin/*.bat \
	&& rm tomcat.tar.gz*

EXPOSE 8080
#CMD ["catalina.sh", "run"]




# PART 2 - Below here is our contribution to the file.
ENV HOME /root

# Regenerate SSH host keys. baseimage-docker does not contain any, so you
# have to do that yourself. You may also comment out this instruction; the
# init system will auto-generate one during boot.
#RUN /etc/my_init.d/00_regen_ssh_host_keys.sh

# Use baseimage-docker's init system.
#CMD ["/sbin/my_init"]

# ...put your own build instructions here...
USER root
RUN apt-get update
#RUN apt-get install -q -y openjdk-7-jdk
#RUN apt-get install -q -y imagemagick
#RUN apt-get install -q -y nodejs npm
#RUN apt-get install -q -y git git-core
#RUN apt-get install -q -y ruby1.9.1
RUN apt-get install -y curl vim

# Install ToolTwist CLI
#RUN npm install -g tooltwist

# create user tooltwist
RUN adduser --shell /bin/bash --disabled-password --gecos "ToolTwist,,," --home /home/tooltwist tooltwist

# Make Gradle run faster later by getting JARs downloaded as we can (at this stage)
#ENV GRADLE_USER_HOME /home/tooltwist/.gradle
#ADD getjars /tmp/getjars
#RUN cd /tmp/getjars && ./gradlew --version && ./gradlew assemble && rm -rf /tmp/getjars

# Install basic server files
ADD resources/skeleton /home/tooltwist/
#RUN cd /home/tooltwist; git clone https://github.com/tooltwist/serverkit.git

# Install tomcat
#ADD resources/apache-tomcat-7.0.55.tar.gz /home/tooltwist/server/
#RUN rm -rf /home/tooltwist/server/tomcat \
#	&& mv /home/tooltwist/server/apache-tomcat-7.0.55 /home/tooltwist/server/tomcat \
#	&& rm -rf /home/tooltwist/server/tomcat/webapps/docs \
#	&& rm -rf /home/tooltwist/server/tomcat/webapps/examples \
#	&& rm -rf /home/tooltwist/server/tomcat/webapps/host_manager \
#	&& rm -rf /home/tooltwist/server/tomcat/webapps/manager
#&& rm -rf /home/tooltwist/server/tomcat/webapps/ROOT
RUN rm -rf $CATALINA_HOME/webapps/docs \
	&& rm -rf $CATALINA_HOME/webapps/examples \
	&& rm -rf $CATALINA_HOME/webapps/host_manager \
	&& rm -rf $CATALINA_HOME/webapps/manager
#&& rm -rf /home/tooltwist/server/tomcat/webapps/ROOT

# Install an SSH of your choice for the root user.
#ADD my_key.pub /tmp/my_key.pub
#RUN cat /tmp/my_key.pub >> /root/.ssh/authorized_keys && rm -f /tmp/my_key.pub

# Prepare SSH
# Note: I could not get SSH into the tooltwist account to work. We've have to be
# happy with root access, but that should be ok as it's only for rare debug purposes..
#ADD resources/authorized_keys /home/tooltwist/.ssh/
#RUN chmod 700 /home/tooltwist/.ssh
#RUN chmod 644 /home/tooltwist/.ssh/authorized_keys

# Environment variables for user tooltwist
ADD resources/tooltwist_rc /home/tooltwist/.tooltwist_rc
RUN echo ". ~/.tooltwist_rc" >> /home/tooltwist/.profile 

RUN chown -R tooltwist:tooltwist /home/tooltwist

# Add a nice startup message for root
#RUN echo 'echo ""'
#RUN echo 'echo ""'
#RUN echo 'echo "    Please switch to the tooltwist user:"'
#RUN echo 'echo ""'
#RUN echo 'echo "    $ su - tooltwist"'
#RUN echo 'echo ""'

RUN echo 'echo ""' >> /root/.profile
RUN echo 'echo -n "    Switch to user tooltwist [Y/n]?"' >> /root/.profile
RUN echo 'read ans; echo ""; [ "${ans}" == "" -o "${ans}" == "y" -o "${ans}" == "Y" ] && echo "$ su - tooltwist" && echo "" && exec su - tooltwist' >> /root/.profile

# Add a startup script for Tomcat
# See https://github.com/phusion/baseimage-docker#running-scripts-during-container-startup
#RUN mkdir -p /etc/my_init.d
#ADD resources/start_tomcat.sh /etc/my_init.d/start_tomcat.sh
#RUN chmod +x /etc/my_init.d/start_tomcat.sh
EXPOSE 8080

# Run start_fipserver as a daemon
# See https://github.com/phusion/baseimage-docker#adding-additional-daemons
#RUN mkdir /etc/service/fipserver
#ADD resources/start_fipserver.sh /etc/service/fipserver/run
#RUN chmod +x /etc/service/fipserver/run
#EXPOSE 39393

## Add a function used by DotCI to update packages for the version specified in .ci.yml
#RUN echo 'function install_packages { echo ZZZZZ install_packages "$@" ; }' >> /root/.bashrc

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

CMD [ "su", "tooltwist", "-c", ". .tooltwist_rc; cd server/tomcat/bin; ./startup.sh;" ]
