FROM centos:centos6
MAINTAINER Kubomoto Osamu <kubomoto@gos-pa.co.jp>

# timezone
RUN cp /usr/share/zoneinfo/Asia/Tokyo /etc/localtime

# lang
RUN sed -i -e 's#^LANG=.*#LANG="ja_JP.UTF-8"#'  /etc/sysconfig/i18n

# RPM
RUN rpm -ivh https://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
RUN rpm -ivh http://rpms.famillecollet.com/enterprise/remi-release-6.rpm

# System Update & Install packages
RUN yum -y update
RUN yum -y install httpd
RUN yum -y install php php-gd php-mysql php-intl php-xml php-xmlrpc php-soap php-pecl-apc php-odbc php-mbstring
RUN sed -ri 's/;date.timezone =/date.timezone = Asia\/Tokyo/g' /etc/php.ini
RUN yum -y install mysql mysql-server

# sshd
RUN yum install -y openssh-server
RUN echo 'root:root' |chpasswd
RUN sed -ri 's/#PermitRootLogin yes/PermitRootLogin yes/g' /etc/ssh/sshd_config && \
    sed -ri 's/#RSAAuthentication yes/RSAAuthentication yes/g' /etc/ssh/sshd_config && \
    sed -ri 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/g' /etc/ssh/sshd_config && \
    sed -ri 's/#AuthorizedKeysFile     .ssh\/authorized_keys/AuthorizedKeysFile     .ssh\/authorized_keys/g' /etc/ssh/sshd_config && \
    sed -ri 's/#UsePAM no/UsePAM no/g' /etc/ssh/sshd_config
RUN /etc/init.d/sshd start
RUN /etc/init.d/sshd stop

RUN service mysqld start && \
    /usr/bin/mysqladmin -u root password "root"

# monit
RUN yum install -y monit

# monit
RUN mkdir /var/monit
RUN mv /etc/monit.conf /etc/monit.conf.org

ADD BuildFiles/etc/monit.conf /etc/monit.conf
RUN chmod 700 /etc/monit.conf

# sshd
ADD BuildFiles/etc/monit.d/sshd /etc/monit.d/sshd

# httpd
ADD BuildFiles/etc/monit.d/httpd /etc/monit.d/httpd

# mysqld
ADD BuildFiles/etc/monit.d/mysqld /etc/monit.d/mysqld

EXPOSE 80 22 2812
CMD ["/usr/bin/monit", "-I", "-c", "/etc/monit/monitrc"]
